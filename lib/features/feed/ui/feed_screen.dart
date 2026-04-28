import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mauritanie_news/app/router.dart';

import 'package:mauritanie_news/shared/theme/app_theme.dart';

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
              onPressed: () => context.push(AppRoutes.agencyDashboard),
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
            const SizedBox(height: AppSpacing.md),
            ElevatedButton(
              onPressed: () => context.push(AppRoutes.adminDashboard),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.surfaceVariant,
                foregroundColor: AppColors.textPrimary,
                shape: const RoundedRectangleBorder(
                  borderRadius: AppRadius.buttonRadius,
                  side: BorderSide(color: AppColors.border),
                ),
              ),
              child: Text(
                'Espace administration',
                style: AppTextStyles.buttonMedium.copyWith(color: AppColors.textPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

