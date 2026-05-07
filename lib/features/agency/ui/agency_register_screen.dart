import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:mauritanie_news/app/router.dart';
import 'package:gap/gap.dart';

import 'package:mauritanie_news/shared/theme/app_theme.dart';
import 'package:mauritanie_news/features/agency/data/agency_auth_service.dart';
import 'package:mauritanie_news/features/agency/ui/agency_login_screen.dart';
import 'package:mauritanie_news/features/agency/ui/agency_dashboard_screen.dart';

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

  String _mediaType = 'news_agency';
  Uint8List? _logoBytes;
  String? _logoFileExt;

  @override
  void dispose() {
    _nameController.dispose();
    _websiteController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  String? _validateName(String? v) {
    final t = (v ?? '').trim();
    if (t.length < 2) return 'Minimum 2 caractères';
    return null;
  }

  String? _validateWebsite(String? v) {
    final t = (v ?? '').trim();
    if (!t.startsWith('https://')) return 'Le site doit commencer par https://';
    return null;
  }

  String? _validateEmail(String? v) {
    final t = (v ?? '').trim();
    if (t.isEmpty) return 'Email obligatoire';
    final ok = RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(t);
    if (!ok) return 'Email invalide';
    return null;
  }

  String? _validatePassword(String? v) {
    final t = v ?? '';
    if (t.length < 8) return 'Minimum 8 caractères';
    return null;
  }

  String? _validateConfirm(String? v) {
    if ((v ?? '') != _passwordController.text) return 'Les mots de passe ne correspondent pas';
    return null;
  }

  Future<void> _pickLogo() async {
    if (kIsWeb) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.info,
          content: Text(
            'Le logo depuis la galerie n’est pas disponible sur le web.',
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

  String _strengthLabel(double v) {
    if (v < 0.4) return 'Faible';
    if (v < 0.9) return 'Moyen';
    return 'Fort';
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
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

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
      );

      final agency = await authService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;
      context.go(AppRoutes.agencyDashboard, extra: agency);
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = e.toString());
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: AppColors.error,
          content: Text(
            'Inscription impossible',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textOnPrimary),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final error = _errorMessage;
    final strength = _strength();
    final strengthColor = _strengthColor(strength);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        title: Text(
          'Créer un compte Agence',
          style: AppTextStyles.headlineSmall.copyWith(color: AppColors.textOnPrimary),
        ),
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
                    'Rejoindre la plateforme',
                    style: AppTextStyles.headlineLarge.copyWith(color: AppColors.textPrimary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Créez votre espace de publication et commencez à diffuser vos actualités',
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xxxl),
              Text(
                'Informations de l’agence',
                style: AppTextStyles.labelLarge.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _nameController,
                decoration: _decoration(
                  label: 'Nom de l’agence *',
                  icon: Icons.business_outlined,
                  hint: 'Ex: Agence Mauritanie Presse',
                ),
                validator: _validateName,
              ),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _websiteController,
                keyboardType: TextInputType.url,
                decoration: _decoration(
                  label: 'Site web *',
                  icon: Icons.language_outlined,
                  hint: 'https://monagence.mr',
                ),
                validator: _validateWebsite,
              ),
              const SizedBox(height: AppSpacing.lg),
              DropdownButtonFormField<String>(
                initialValue: _mediaType,
                decoration: _decoration(
                  label: 'Type de média',
                  icon: Icons.category_outlined,
                ),
                items: const [
                  DropdownMenuItem(value: 'news_agency', child: Row(children: [Icon(Icons.rss_feed_rounded, size: 18, color: AppColors.primary), Gap(AppSpacing.sm), Text('Agence de presse')])),
                  DropdownMenuItem(value: 'newspaper', child: Row(children: [Icon(Icons.newspaper_rounded, size: 18, color: AppColors.primary), Gap(AppSpacing.sm), Text('Presse écrite')])),
                  DropdownMenuItem(value: 'blog', child: Row(children: [Icon(Icons.edit_note_rounded, size: 18, color: AppColors.primary), Gap(AppSpacing.sm), Text('Blog')])),
                  DropdownMenuItem(value: 'tv_channel', child: Row(children: [Icon(Icons.tv_rounded, size: 18, color: AppColors.primary), Gap(AppSpacing.sm), Text('Télévision')])),
                  DropdownMenuItem(value: 'radio', child: Row(children: [Icon(Icons.radio_rounded, size: 18, color: AppColors.primary), Gap(AppSpacing.sm), Text('Radio')])),
                  DropdownMenuItem(value: 'other', child: Row(children: [Icon(Icons.more_horiz_rounded, size: 18, color: AppColors.primary), Gap(AppSpacing.sm), Text('Autre')])),
                ],
                onChanged: (v) {
                  if (v == null) return;
                  setState(() => _mediaType = v);
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Logo (optionnel)',
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
                        'Choisir un logo',
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
                      tooltip: 'Retirer le logo',
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
              const SizedBox(height: AppSpacing.xl),
              const Divider(color: AppColors.border),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'Informations de connexion',
                style: AppTextStyles.labelLarge.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: _decoration(
                  label: 'Email professionnel *',
                  icon: Icons.email_outlined,
                ),
                validator: _validateEmail,
              ),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscure1,
                onChanged: (_) => setState(() {}),
                decoration: _decoration(
                  label: 'Mot de passe *',
                  icon: Icons.lock_outlined,
                  helper: 'Minimum 8 caractères',
                  suffixIcon: IconButton(
                    onPressed: () => setState(() => _obscure1 = !_obscure1),
                    icon: Icon(
                      _obscure1 ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                validator: _validatePassword,
              ),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _confirmController,
                obscureText: _obscure2,
                decoration: _decoration(
                  label: 'Confirmer mot de passe *',
                  icon: Icons.lock_outlined,
                  suffixIcon: IconButton(
                    onPressed: () => setState(() => _obscure2 = !_obscure2),
                    icon: Icon(
                      _obscure2 ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                validator: _validateConfirm,
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
                    'Force du mot de passe : ${_strengthLabel(strength)}',
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
                          'Créer mon compte',
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
                        'Votre compte sera examiné par notre équipe. Vous pourrez publier dès validation.',
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
                    'Déjà un compte ? ',
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const AgencyLoginScreen()),
                      );
                    },
                    child: Text(
                      'Se connecter',
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

