import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gap/gap.dart';

import 'package:mauritanie_news/features/agency/localization/agency_l10n.dart';
import 'package:mauritanie_news/features/agency/ui/agency_language_switch.dart';
import 'package:mauritanie_news/shared/theme/app_theme.dart';
import 'package:mauritanie_news/features/agency/data/agency_auth_service.dart';
import 'package:go_router/go_router.dart';
import 'package:mauritanie_news/app/router.dart';
import 'package:mauritanie_news/shared/models/agency_model.dart';

class AgencyRegisterScreen extends StatefulWidget {
  const AgencyRegisterScreen({super.key});

  @override
  State<AgencyRegisterScreen> createState() => _AgencyRegisterScreenState();
}

class _AgencyRegisterScreenState extends State<AgencyRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _websiteController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _obscure1 = true;
  bool _obscure2 = true;
  bool _isLoading = false;
  String? _errorMessage;

  MediaType _mediaType = MediaType.newsAgency;
  Uint8List? _logoBytes;
  String? _logoFileExt;

  Uint8List? _docBytes;
  String? _docFileName;
  String? _docFileExt;

  @override
  void dispose() {
    _nameController.dispose();
    _websiteController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  String? _validateName(String? v, AgencyLocalizations l10n) {
    final t = (v ?? '').trim();
    if (t.length < 2) return l10n.t('min_2_chars');
    return null;
  }

  String? _validateWebsite(String? v, AgencyLocalizations l10n) {
    final t = (v ?? '').trim();
    if (!t.startsWith('https://')) return l10n.t('website_https');
    return null;
  }

  String? _validateEmail(String? v, AgencyLocalizations l10n) {
    final t = (v ?? '').trim();
    if (t.isEmpty) return l10n.t('email_required');
    final ok = RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(t);
    if (!ok) return l10n.t('email_invalid');
    return null;
  }

  String? _validatePassword(String? v, AgencyLocalizations l10n) {
    final t = v ?? '';
    if (t.length < 8) return l10n.t('min_8_chars');
    return null;
  }

  String? _validateConfirm(String? v, AgencyLocalizations l10n) {
    if ((v ?? '') != _passwordController.text) return l10n.t('password_mismatch');
    return null;
  }

  Future<void> _pickLogo() async {
    if (kIsWeb) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.info,
          content: Text(
            context.agencyL10n.t('logo_web_unavailable'),
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textOnPrimary),
          ),
        ),
      );
      return;
    }
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 88,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    if (!mounted) return;
    setState(() {
      _logoBytes = bytes;
      _logoFileExt = picked.path.split('.').last.toLowerCase();
    });
  }

  void _clearLogo() {
    setState(() {
      _logoBytes = null;
      _logoFileExt = null;
    });
  }

  Future<void> _pickDocument() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      setState(() {
        _docBytes = file.bytes;
        _docFileName = file.name;
        _docFileExt = file.extension?.toLowerCase();
      });
    } catch (e) {
      debugPrint('Error picking document: $e');
    }
  }

  void _clearDocument() {
    setState(() {
      _docBytes = null;
      _docFileName = null;
      _docFileExt = null;
    });
  }

  double _strength() {
    final len = _passwordController.text.length;
    if (len <= 5) return 0.25;
    if (len <= 8) return 0.6;
    return 1.0;
  }

  Color _strengthColor(double v) {
    if (v < 0.4) return AppColors.error;
    if (v < 0.9) return AppColors.warning;
    return AppColors.success;
  }

  String _strengthLabel(double v, AgencyLocalizations l10n) {
    if (v < 0.4) return l10n.t('strength_weak');
    if (v < 0.9) return l10n.t('strength_medium');
    return l10n.t('strength_strong');
  }

  InputDecoration _decoration({
    required String label,
    required IconData icon,
    String? hint,
    Widget? suffixIcon,
    String? helper,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      helperText: helper,
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

  Future<void> _register() async {
    setState(() => _errorMessage = null);
    if (_formKey.currentState?.validate() != true) return;

    setState(() => _isLoading = true);

    try {
      final supabase = Supabase.instance.client;
      final authService = AgencyAuthService(supabase);

      await authService.register(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        agencyName: _nameController.text.trim(),
        websiteUrl: _websiteController.text.trim(),
        mediaType: _mediaType,
        logoBytes: _logoBytes,
        logoFileExt: _logoFileExt,
        documentBytes: _docBytes,
        documentFileExt: _docFileExt,
      );

      if (!mounted) return;

      // Connexion optionnelle (peut échouer si confirmation email requise).
      try {
        await authService.login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      } catch (loginError) {
        debugPrint(
          '[AgencyRegisterScreen] Connexion post-inscription ignorée: $loginError',
        );
      }

      if (!mounted) return;

      final successL10n =
          Localizations.of<AgencyLocalizations>(context, AgencyLocalizations) ??
              AgencyLocalizations(const Locale('fr'));

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.check_circle, color: AppColors.success),
              const SizedBox(width: AppSpacing.sm),
              Text(
                successL10n.t('register_success_title'),
                style: AppTextStyles.headlineSmall.copyWith(
                  color: AppColors.textOnPrimary,
                ),
              ),
            ],
          ),
          content: Text(
            successL10n.t('register_success_body'),
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textOnPrimary,
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: Text(successL10n.t('understood')),
            ),
          ],
        ),
      );

      if (!mounted) return;
      context.go(AppRoutes.agencyPending);
    } catch (e, stack) {
      debugPrint('[AgencyRegisterScreen] Erreur inscription: $e\n$stack');
      if (!mounted) return;
      final msg = e is String
          ? e
          : e.toString().replaceFirst('Exception: ', '').trim();
      setState(() => _errorMessage = msg.isEmpty
          ? 'L\'inscription a échoué. Veuillez réessayer.'
          : msg);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.agencyL10n;
    final error = _errorMessage;
    final strength = _strength();
    final strengthColor = _strengthColor(strength);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        title: Text(
          l10n.t('register_title'),
          style: AppTextStyles.headlineSmall.copyWith(color: AppColors.textOnPrimary),
        ),
        actions: const [
          AgencyLanguageSwitcher(compact: true),
          SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: SingleChildScrollView(
        padding: AppSpacing.pagePadding,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Column(
                children: [
                  const Icon(Icons.business_center, color: AppColors.primary, size: 64),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    l10n.t('join_platform'),
                    style: AppTextStyles.headlineLarge.copyWith(color: AppColors.textPrimary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    l10n.t('register_subtitle'),
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xxxl),
              Text(
                l10n.t('agency_info_section'),
                style: AppTextStyles.labelLarge.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _nameController,
                decoration: _decoration(
                  label: l10n.t('agency_name'),
                  icon: Icons.business_outlined,
                  hint: l10n.t('agency_name_hint'),
                ),
                validator: (v) => _validateName(v, l10n),
              ),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _websiteController,
                keyboardType: TextInputType.url,
                decoration: _decoration(
                  label: l10n.t('website'),
                  icon: Icons.language_outlined,
                  hint: l10n.t('website_hint'),
                ),
                validator: (v) => _validateWebsite(v, l10n),
              ),
              const SizedBox(height: AppSpacing.lg),
              DropdownButtonFormField<MediaType>(
                value: _mediaType,
                decoration: _decoration(
                  label: l10n.t('media_type'),
                  icon: Icons.category_outlined,
                ),
                items: [
                  DropdownMenuItem(value: MediaType.newsAgency, child: Row(children: [const Icon(Icons.rss_feed_rounded, size: 18, color: AppColors.primary), const Gap(AppSpacing.sm), Text(l10n.t('media_news_agency'))])),
                  DropdownMenuItem(value: MediaType.newspaper, child: Row(children: [const Icon(Icons.newspaper_rounded, size: 18, color: AppColors.primary), const Gap(AppSpacing.sm), Text(l10n.t('media_newspaper'))])),
                  DropdownMenuItem(value: MediaType.blog, child: Row(children: [const Icon(Icons.edit_note_rounded, size: 18, color: AppColors.primary), const Gap(AppSpacing.sm), Text(l10n.t('media_blog'))])),
                  DropdownMenuItem(value: MediaType.tvChannel, child: Row(children: [const Icon(Icons.tv_rounded, size: 18, color: AppColors.primary), const Gap(AppSpacing.sm), Text(l10n.t('media_tv'))])),
                  DropdownMenuItem(value: MediaType.radio, child: Row(children: [const Icon(Icons.radio_rounded, size: 18, color: AppColors.primary), const Gap(AppSpacing.sm), Text(l10n.t('media_radio'))])),
                  DropdownMenuItem(value: MediaType.other, child: Row(children: [const Icon(Icons.more_horiz_rounded, size: 18, color: AppColors.primary), const Gap(AppSpacing.sm), Text(l10n.t('media_other'))])),
                ],
                onChanged: (v) {
                  if (v == null) return;
                  setState(() => _mediaType = v);
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                l10n.t('logo_optional'),
                style: AppTextStyles.labelLarge.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: kIsWeb ? null : _pickLogo,
                      icon: const Icon(Icons.add_photo_alternate_outlined, color: AppColors.primary),
                      label: Text(
                        l10n.t('pick_logo'),
                        style: AppTextStyles.buttonMedium.copyWith(color: AppColors.primary),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.primary),
                        shape: const RoundedRectangleBorder(borderRadius: AppRadius.buttonRadius),
                      ),
                    ),
                  ),
                  if (_logoBytes != null) ...[
                    const SizedBox(width: AppSpacing.md),
                    IconButton(
                      onPressed: _clearLogo,
                      icon: const Icon(Icons.close, color: AppColors.error),
                      tooltip: l10n.t('remove_logo'),
                    ),
                  ],
                ],
              ),
              if (_logoBytes != null) ...[
                const SizedBox(height: AppSpacing.md),
                Align(
                  alignment: Alignment.centerLeft,
                  child: ClipRRect(
                    borderRadius: AppRadius.imageRadius,
                    child: Image.memory(
                      _logoBytes!,
                      height: 88,
                      width: 88,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              Text(
                l10n.t('document_section'),
                style: AppTextStyles.labelLarge.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isLoading ? null : _pickDocument,
                      icon: const Icon(Icons.upload_file, color: AppColors.primary),
                      label: Text(
                        _docFileName ?? l10n.t('pick_document'),
                        style: AppTextStyles.buttonMedium.copyWith(color: AppColors.primary),
                        overflow: TextOverflow.ellipsis,
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.primary),
                        shape: const RoundedRectangleBorder(borderRadius: AppRadius.buttonRadius),
                      ),
                    ),
                  ),
                  if (_docBytes != null) ...[
                    const SizedBox(width: AppSpacing.md),
                    IconButton(
                      onPressed: _clearDocument,
                      icon: const Icon(Icons.close, color: AppColors.error),
                      tooltip: l10n.t('remove_document'),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              const Divider(color: AppColors.border),
              const SizedBox(height: AppSpacing.xl),
              Text(
                l10n.t('account_section'),
                style: AppTextStyles.labelLarge.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: _decoration(
                  label: l10n.t('professional_email'),
                  icon: Icons.email_outlined,
                ),
                validator: (v) => _validateEmail(v, l10n),
              ),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscure1,
                onChanged: (_) => setState(() {}),
                decoration: _decoration(
                  label: '${l10n.t('password')} *',
                  icon: Icons.lock_outlined,
                  helper: l10n.t('min_8_chars'),
                  suffixIcon: IconButton(
                    onPressed: () => setState(() => _obscure1 = !_obscure1),
                    icon: Icon(
                      _obscure1 ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                validator: (v) => _validatePassword(v, l10n),
              ),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _confirmController,
                obscureText: _obscure2,
                decoration: _decoration(
                  label: l10n.t('confirm_password'),
                  icon: Icons.lock_outlined,
                  suffixIcon: IconButton(
                    onPressed: () => setState(() => _obscure2 = !_obscure2),
                    icon: Icon(
                      _obscure2 ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                validator: (v) => _validateConfirm(v, l10n),
              ),
              const SizedBox(height: AppSpacing.xxl),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  LinearProgressIndicator(
                    minHeight: 6,
                    value: strength,
                    backgroundColor: AppColors.surfaceVariant,
                    valueColor: AlwaysStoppedAnimation<Color>(strengthColor),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    l10n.tf('password_strength',
                        params: {'level': _strengthLabel(strength, l10n)}),
                    style: AppTextStyles.labelMedium.copyWith(color: strengthColor),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xxl),
              AnimatedOpacity(
                opacity: error == null ? 0 : 1,
                duration: const Duration(milliseconds: 250),
                child: error == null
                    ? const SizedBox.shrink()
                    : Container(
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
              ),
              const SizedBox(height: AppSpacing.xxl),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _register,
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
                          l10n.t('create_my_account'),
                          style: AppTextStyles.buttonLarge.copyWith(color: AppColors.textOnPrimary),
                        ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Container(
                padding: AppSpacing.cardPadding,
                decoration: BoxDecoration(
                  color: AppColors.infoLight,
                  borderRadius: AppRadius.cardRadius,
                  border: Border.all(color: AppColors.info),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline, color: AppColors.info),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        l10n.t('register_review_note'),
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.info),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${l10n.t('already_account')} ',
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                  ),
                  TextButton(
                    onPressed: () => context.go(AppRoutes.agencyLogin),
                    child: Text(
                      l10n.t('sign_in'),
                      style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

