import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../app/router.dart';
import '../../../core/localization/l10n.dart';

class AuthHomeScreen extends StatelessWidget {
  const AuthHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.xxl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Align(
                alignment: Alignment.topLeft,
                child: LanguageSwitcher(),
              ),
              const SizedBox(height: AppSpacing.md),
              const Icon(Icons.newspaper, color: AppColors.primary, size: 80),
              const SizedBox(height: AppSpacing.lg),
              Text(
                context.l10n.translate('app_title'),
                textAlign: TextAlign.center,
                style: AppTextStyles.displayMedium.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                context.l10n.translate('management_portal'),
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.xxxl),

              // Agency Card
              _RoleCard(
                title: context.l10n.translate('agency_space'),
                icon: Icons.business_outlined,
                description: context.l10n.translate('agency_desc'),
                actions: [
                  ElevatedButton(
                    onPressed: () => context.push(AppRoutes.agencyRegister),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.textOnPrimary,
                    ),
                    child: Text(context.l10n.translate('signup')),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  OutlinedButton(
                    onPressed: () => context.push(AppRoutes.agencyLogin),
                    child: Text(context.l10n.translate('signin')),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.xl),

              // Admin Card
              _RoleCard(
                title: context.l10n.translate('admin'),
                icon: Icons.admin_panel_settings_outlined,
                description: context.l10n.translate('admin_desc'),
                actions: [
                  ElevatedButton(
                    onPressed: () => context.push(AppRoutes.adminLogin),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.textPrimary,
                      foregroundColor: AppColors.surface,
                    ),
                    child: Text(context.l10n.translate('sign_admin')),
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

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.title,
    required this.icon,
    required this.description,
    required this.actions,
  });

  final String title;
  final IconData icon;
  final String description;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: AppRadius.cardRadius,
        side: BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 32),
                ),
                const SizedBox(width: AppSpacing.md),
                Text(title, style: AppTextStyles.headlineSmall),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              description,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.xl),
            ...actions,
          ],
        ),
      ),
    );
  }
}
