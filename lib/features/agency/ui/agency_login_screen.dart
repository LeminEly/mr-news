import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';

import 'package:mauritanie_news/shared/theme/app_theme.dart';
import 'package:mauritanie_news/features/agency/data/agency_auth_service.dart';
import 'package:mauritanie_news/app/router.dart';
import 'package:mauritanie_news/shared/models/agency_model.dart';

class AgencyLoginScreen extends StatefulWidget {
  const AgencyLoginScreen({super.key});

  @override
  State<AgencyLoginScreen> createState() => _AgencyLoginScreenState();
}

class _AgencyLoginScreenState extends State<AgencyLoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

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

    try {
      final supabase = Supabase.instance.client;
      final authService = AgencyAuthService(supabase);
      
      final agency = await authService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (agency == null) {
        throw 'Profil agence introuvable';
      }

      // Check status
      if (agency.status == AgencyStatus.rejected) {
        await supabase.auth.signOut();
        throw 'Votre compte a été refusé par l\'administration.';
      } else if (agency.status == AgencyStatus.suspended) {
        await supabase.auth.signOut();
        throw 'Votre compte est suspendu.';
      }

      if (!mounted) return;
      
      // If accepted or pending, we go to dashboard. 
      // The AgencyDashboardGate in router.dart will show the appropriate screen.
      context.go(AppRoutes.agencyDashboard);
      
      messenger.showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.success,
          content: Text('Connexion réussie'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      String errorMsg = e.toString();
      if (errorMsg.contains('Exception:')) {
        errorMsg = errorMsg.split('Exception:').last.trim();
      }
      
      setState(() => _errorMessage = errorMsg);
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: AppColors.error,
          content: Text(
            errorMsg,
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
          'Connexion Agence',
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
                const Icon(Icons.newspaper, color: AppColors.primary, size: 72),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Espace Agence',
                  style: AppTextStyles.displayMedium.copyWith(color: AppColors.textPrimary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Connectez-vous pour gérer vos articles',
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
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
                  const SizedBox(height: AppSpacing.sm),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: AppColors.info,
                            content: Text(
                              'Fonctionnalité bientôt disponible',
                              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textOnPrimary),
                            ),
                          ),
                        );
                      },
                      child: Text(
                        'Mot de passe oublié ?',
                        style: AppTextStyles.labelMedium.copyWith(color: AppColors.primary),
                      ),
                    ),
                  ),
                ],
              ),
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
                            'Se connecter',
                            style: AppTextStyles.buttonLarge.copyWith(color: AppColors.textOnPrimary),
                          ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Pas encore de compte ? ',
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                ),
                TextButton(
                  onPressed: () => context.push(AppRoutes.agencyRegister),
                  child: Text(
                    'Créer un compte',
                    style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

