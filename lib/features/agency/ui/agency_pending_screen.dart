import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gap/gap.dart';

import 'package:mauritanie_news/shared/theme/app_theme.dart';
import 'package:mauritanie_news/features/agency/data/agency_auth_service.dart';
import 'package:mauritanie_news/features/agency/ui/agency_login_screen.dart';

class AgencyPendingScreen extends StatefulWidget {
  const AgencyPendingScreen({super.key});

  @override
  State<AgencyPendingScreen> createState() => _AgencyPendingScreenState();
}

class _AgencyPendingScreenState extends State<AgencyPendingScreen> {
  Future<void> _logout() async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      await AgencyAuthService(Supabase.instance.client).logout();
      if (!mounted) return;
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AgencyLoginScreen()),
        (route) => false,
      );
    } catch (_) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: AppColors.error,
          content: Text(
            'Erreur de déconnexion',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textOnPrimary),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        title: Text(
          'Validation',
          style: AppTextStyles.headlineSmall.copyWith(color: AppColors.textOnPrimary),
        ),
      ),
      body: Center(
        child: Padding(
          padding: AppSpacing.pagePadding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: 1),
                duration: const Duration(seconds: 3),
                builder: (context, t, child) {
                  return Transform.rotate(
                    angle: t * 6.283185307179586,
                    child: child,
                  );
                },
                onEnd: () => setState(() {}),
                child: const Icon(
                  Icons.hourglass_empty,
                  size: 80,
                  color: AppColors.warning,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Compte en attente de validation',
                style: AppTextStyles.headlineMedium.copyWith(color: AppColors.textPrimary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Notre équipe examine votre demande.\nVous recevrez une notification dès validation.',
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              Container(
                padding: AppSpacing.chipPadding,
                decoration: BoxDecoration(
                  color: AppColors.warningLight,
                  borderRadius: AppRadius.chipRadius,
                  border: Border.all(color: AppColors.warning),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.access_time_rounded, size: 16, color: AppColors.warning),
                    const Gap(AppSpacing.sm),
                    Text(
                      'En attente',
                      style: AppTextStyles.labelMedium.copyWith(color: AppColors.warning, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              OutlinedButton(
                onPressed: _logout,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.error),
                  foregroundColor: AppColors.error,
                  minimumSize: const Size.fromHeight(52),
                  shape: const RoundedRectangleBorder(borderRadius: AppRadius.buttonRadius),
                ),
                child: Text(
                  'Se déconnecter',
                  style: AppTextStyles.buttonLarge.copyWith(color: AppColors.error),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

