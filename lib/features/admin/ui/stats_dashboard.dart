import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/theme/app_theme.dart';
import '../../feed/providers/feed_providers.dart';
import '../../../app/router.dart';
import 'admin_drawer.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(adminStatsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        title: Text(
          'Tableau de bord',
          style: AppTextStyles.headlineSmall.copyWith(color: AppColors.textOnPrimary),
        ),
      ),
      drawer: const AdminDrawer(),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(adminStatsProvider.future),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: AppSpacing.pagePadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Résumé de l’activité',
                style: AppTextStyles.headlineSmall.copyWith(color: AppColors.textPrimary),
              ),
              const SizedBox(height: AppSpacing.lg),
              statsAsync.when(
                data: (stats) => GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: AppSpacing.md,
                  crossAxisSpacing: AppSpacing.md,
                  childAspectRatio: 1.5,
                  children: [
                    _StatCard(
                      label: 'Agences en attente',
                      value: stats['pending_agencies'].toString(),
                      icon: Icons.business_outlined,
                      color: AppColors.warning,
                      onTap: () => context.go(AppRoutes.adminValidation),
                    ),
                    _StatCard(
                      label: 'Signalements',
                      value: stats['pending_reports'].toString(),
                      icon: Icons.report_problem_outlined,
                      color: AppColors.error,
                      onTap: () => context.go(AppRoutes.adminReports),
                    ),
                    _StatCard(
                      label: 'Articles actifs',
                      value: stats['active_articles'].toString(),
                      icon: Icons.article_outlined,
                      color: AppColors.success,
                      onTap: () => context.go(AppRoutes.adminAgencies),
                    ),
                    _StatCard(
                      label: 'Catégories',
                      value: stats['categories'].toString(),
                      icon: Icons.category_outlined,
                      color: AppColors.primary,
                      onTap: () => context.go(AppRoutes.adminCategories),
                    ),
                  ],
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(
                  child: Text('Erreur: $err', style: const TextStyle(color: AppColors.error)),
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              Text(
                'Actions rapides',
                style: AppTextStyles.headlineSmall.copyWith(color: AppColors.textPrimary),
              ),
              const SizedBox(height: AppSpacing.md),
              _QuickActionTile(
                title: 'Valider les nouvelles agences',
                subtitle: 'Gérer les demandes d’inscription',
                icon: Icons.verified_user_outlined,
                onTap: () => context.go(AppRoutes.adminValidation),
              ),
              _QuickActionTile(
                title: 'Gérer les catégories',
                subtitle: 'Ajouter ou modifier des catégories d’articles',
                icon: Icons.category_outlined,
                onTap: () => context.go(AppRoutes.adminCategories),
              ),
              _QuickActionTile(
                title: 'Liste complète des agences',
                subtitle: 'Voir et suspendre des comptes',
                icon: Icons.business_outlined,
                onTap: () => context.go(AppRoutes.adminAgencies),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.cardRadius,
      child: Container(
        padding: AppSpacing.cardPadding,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.cardRadius,
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: color, size: 28),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: AppTextStyles.headlineMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  label,
                  style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.cardRadius),
      elevation: 0,
      color: AppColors.surfaceVariant,
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.primary),
        ),
        title: Text(title, style: AppTextStyles.labelLarge),
        subtitle: Text(subtitle, style: AppTextStyles.bodySmall),
        trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
        onTap: onTap,
      ),
    );
  }
}
