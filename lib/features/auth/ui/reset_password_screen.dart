import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/theme/app_theme.dart';
import '../../feed/providers/feed_providers.dart';
import '../../../core/localization/l10n.dart';
import '../data/password_reset_service.dart';

enum _ResetStep { requestCode, verifyCode, newPassword }

/// Écran de réinitialisation du mot de passe par code OTP (admin + agence).
class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key, this.initialEmail});

  /// Email pré-rempli depuis l'écran de connexion.
  final String? initialEmail;

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  _ResetStep _step = _ResetStep.requestCode;
  bool _isLoading = false;
  String? _errorMessage;

  PasswordResetService get _service =>
      PasswordResetService(ref.read(supabaseClientProvider));

  @override
  void initState() {
    super.initState();
    if (widget.initialEmail != null && widget.initialEmail!.isNotEmpty) {
      _emailController.text = widget.initialEmail!;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await action();
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _sendCode() => _run(() async {
        await _service.sendResetCode(_emailController.text);
        if (!mounted) return;
        _showSnack(context.l10n.translate('reset_code_sent'));
        setState(() => _step = _ResetStep.verifyCode);
      });

  Future<void> _verifyCode() => _run(() async {
        await _service.verifyCode(
          email: _emailController.text,
          token: _codeController.text,
        );
        if (!mounted) return;
        setState(() => _step = _ResetStep.newPassword);
      });

  Future<void> _updatePassword() => _run(() async {
        await _service.updatePassword(_passwordController.text);
        if (!mounted) return;
        _showSnack(context.l10n.translate('reset_success'));
        context.pop();
      });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          l10n.translate('reset_title'),
          style: AppTextStyles.headlineSmall,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.lg),
                const Icon(Icons.lock_reset, color: AppColors.primary, size: 56),
                const SizedBox(height: AppSpacing.xl),
                ..._buildStep(l10n),
                const SizedBox(height: AppSpacing.xl),
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: AppColors.error),
                      textAlign: TextAlign.center,
                    ),
                  ),
                _primaryButton(l10n),
                if (_step == _ResetStep.verifyCode) ...[
                  const SizedBox(height: AppSpacing.sm),
                  TextButton(
                    onPressed: _isLoading ? null : _sendCode,
                    child: Text(l10n.translate('reset_resend_code')),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildStep(AppLocalizations l10n) {
    switch (_step) {
      case _ResetStep.requestCode:
        return [
          Text(
            l10n.translate('reset_email_hint'),
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: l10n.translate('email'),
              prefixIcon: const Icon(Icons.email_outlined),
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? l10n.translate('required_field') : null,
          ),
        ];
      case _ResetStep.verifyCode:
        return [
          Text(
            l10n.translate('reset_code_hint'),
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
          TextFormField(
            controller: _codeController,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
            decoration: InputDecoration(
              labelText: l10n.translate('reset_code_label'),
              prefixIcon: const Icon(Icons.pin_outlined),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return l10n.translate('required_field');
              if (v.trim().length < 6) return l10n.translate('reset_code_hint');
              return null;
            },
          ),
        ];
      case _ResetStep.newPassword:
        return [
          TextFormField(
            controller: _passwordController,
            obscureText: true,
            decoration: InputDecoration(
              labelText: l10n.translate('reset_new_password'),
              prefixIcon: const Icon(Icons.lock_outline),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return l10n.translate('required_field');
              if (v.length < 6) return l10n.translate('password_too_short');
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: _confirmController,
            obscureText: true,
            decoration: InputDecoration(
              labelText: l10n.translate('reset_confirm_password'),
              prefixIcon: const Icon(Icons.lock_outline),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return l10n.translate('required_field');
              if (v != _passwordController.text) {
                return l10n.translate('passwords_no_match');
              }
              return null;
            },
          ),
        ];
    }
  }

  Widget _primaryButton(AppLocalizations l10n) {
    final (label, action) = switch (_step) {
      _ResetStep.requestCode => (l10n.translate('reset_send_code'), _sendCode),
      _ResetStep.verifyCode => (l10n.translate('reset_verify'), _verifyCode),
      _ResetStep.newPassword => (l10n.translate('reset_update'), _updatePassword),
    };
    return ElevatedButton(
      onPressed: _isLoading ? null : action,
      style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
      child: _isLoading
          ? const CircularProgressIndicator()
          : Text(label),
    );
  }
}
