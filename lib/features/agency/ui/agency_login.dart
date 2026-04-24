import 'package:flutter/material.dart';

import 'package:mauritanie_news/shared/theme/app_theme.dart';

class AgencyLoginScreen extends StatelessWidget {
  const AgencyLoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        title: Text(
          'Connexion agence',
          style: AppTextStyles.headlineSmall.copyWith(color: AppColors.textOnPrimary),
        ),
      ),
      body: Padding(
        padding: AppSpacing.pagePadding,
        child: Text(
          'À implémenter.',
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
      ),
    );
  }
}

