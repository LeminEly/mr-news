import 'package:flutter/material.dart';

import 'package:mauritanie_news/shared/theme/app_theme.dart';

class AgencyPendingScreen extends StatelessWidget {
  const AgencyPendingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        title: Text(
          'Validation en cours',
          style: AppTextStyles.headlineSmall.copyWith(color: AppColors.textOnPrimary),
        ),
      ),
      body: Padding(
        padding: AppSpacing.pagePadding,
        child: Text(
          'Votre compte agence est en attente de validation.',
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
      ),
    );
  }
}

