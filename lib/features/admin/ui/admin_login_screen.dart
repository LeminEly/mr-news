import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../app/router.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController(text: 'Abdellahi@g.com');
  final _passwordController = TextEditingController(text: 'as1234');

  bool _obscure = true;
  bool _isLoading = false;
  String? _errorMessage;

  late final AnimationController _tapCtrl;

  @override
  void initState() {
    super.initState();
    _tapCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.0,
      upperBound: 0.04,
    );
  }

  @override
  void dispose() {
    _tapCtrl.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? v) {
    final t = (v ?? '').trim();
    if (t.isEmpty) return 'Email obligatoire';
    final ok = RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(t);
    if (!ok) return 'Email invalide';
    return null;
  }

  String? _validatePassword(String? v) {
    final t = (v ?? '');
    if (t.length < 6) return 'Minimum 6 caractères';
    return null;
  }

  Future<void> _login() async {
    setState(() => _errorMessage = null);
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);

    try {
      final supabase = Supabase.instance.client;
      
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      if (email == 'Abdellahi@g.com' && password == 'as1234') {
        // Use the router bypass to guarantee access without relying on Supabase state
        bypassAdminAuth = true;

        if (!mounted) return;
        // GoRouter.go replaces the stack, preventing back navigation
        context.go(AppRoutes.adminDashboard);
      } else {
        throw 'Email ou mot de passe incorrect (Admin)';
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = e.toString());
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: AppColors.error,
          content: Text(
            e.toString(),
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textOnPrimary),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  InputDecoration _decoration({
    required String label,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: AppColors.textSecondary),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: AppColors.surfaceVariant,
      enabledBorder: const OutlineInputBorder(
        borderRadius: AppRadius.buttonRadius,
        borderSide: BorderSide(color: AppColors.border),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: AppRadius.buttonRadius,
        borderSide: BorderSide(color: AppColors.primary, width: 1.6),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final error = _errorMessage;
    final scale = 1.0 - _tapCtrl.value;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        title: Text(
          'Administration',
          style: AppTextStyles.headlineSmall.copyWith(color: AppColors.textOnPrimary),
        ),
      ),
      body: SingleChildScrollView(
        padding: AppSpacing.pagePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Column(
              children: [
                const Icon(Icons.admin_panel_settings, color: AppColors.primary, size: 72),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Espace Administrator',
                  style: AppTextStyles.displayMedium.copyWith(color: AppColors.textPrimary),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxxl),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: _decoration(
                      label: 'Adresse email',
                      icon: Icons.email_outlined,
                    ),
                    validator: _validateEmail,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscure,
                    decoration: _decoration(
                      label: 'Mot de passe',
                      icon: Icons.lock_outlined,
                      suffixIcon: IconButton(
                        onPressed: () => setState(() => _obscure = !_obscure),
                        icon: Icon(
                          _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    validator: _validatePassword,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            if (error != null)
              Container(
                padding: AppSpacing.cardPadding,
                decoration: BoxDecoration(
                  color: AppColors.errorLight,
                  borderRadius: AppRadius.cardRadius,
                  border: Border.all(color: AppColors.error),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.error),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        error,
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: AppSpacing.xxl),
            GestureDetector(
              onTapDown: (_) => _tapCtrl.forward(),
              onTapUp: (_) => _tapCtrl.reverse(),
              onTapCancel: () => _tapCtrl.reverse(),
              child: Transform.scale(
                scale: scale,
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.textOnPrimary,
                      shape: const RoundedRectangleBorder(borderRadius: AppRadius.buttonRadius),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.textOnPrimary,
                            ),
                          )
                        : Text(
                            'Connect',
                            style: AppTextStyles.buttonLarge.copyWith(color: AppColors.textOnPrimary),
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
