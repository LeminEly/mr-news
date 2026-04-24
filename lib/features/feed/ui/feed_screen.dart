import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:mauritanie_news/shared/theme/app_theme.dart';
import 'package:mauritanie_news/features/agency/data/agency_auth_service.dart';
import 'package:mauritanie_news/features/agency/ui/agency_login_screen.dart';
import 'package:mauritanie_news/features/agency/ui/agency_dashboard_screen.dart';

class FeedScreen extends StatelessWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        title: Text(
          'Fil d’actualité',
          style: AppTextStyles.headlineSmall.copyWith(color: AppColors.textOnPrimary),
        ),
        actions: const [SizedBox(width: AppSpacing.sm)],
      ),
      body: Padding(
        padding: AppSpacing.pagePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Écran Feed (UI à compléter).',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                final navigator = Navigator.of(context);
                try {
                  final supabase = Supabase.instance.client;
                  final authService = AgencyAuthService(supabase);
                  final agency = await authService.getCurrentAgency();
                  if (!context.mounted) return;

                  if (agency != null) {
                    navigator.push(
                      MaterialPageRoute(
                        builder: (_) => AgencyDashboardScreen(agency: agency),
                      ),
                    );
                    return;
                  }

                  navigator.push(
                    MaterialPageRoute(
                      builder: (_) => const AgencyLoginScreen(),
                    ),
                  );
                } catch (e) {
                  if (!context.mounted) return;
                  messenger.showSnackBar(
                    SnackBar(
                      backgroundColor: AppColors.error,
                      content: Text(
                        'Erreur d’accès à l’espace agence: $e',
                        style: AppTextStyles.bodyMedium
                            .copyWith(color: AppColors.textOnPrimary),
                      ),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textOnPrimary,
                shape: const RoundedRectangleBorder(borderRadius: AppRadius.buttonRadius),
              ),
              child: Text(
                'Espace agence',
                style: AppTextStyles.buttonMedium.copyWith(color: AppColors.textOnPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

