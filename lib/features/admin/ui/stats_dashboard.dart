import 'package:flutter/material.dart';
import 'package:mauritanie_news/shared/theme/app_theme.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
      body: Center(
        child: Text(
          'Dashboard Admin\nÀ implémenter',
          textAlign: TextAlign.center,
          style: AppTextStyles.headlineMedium.copyWith(color: AppColors.textSecondary),
        ),
      ),
    );
  }
}
