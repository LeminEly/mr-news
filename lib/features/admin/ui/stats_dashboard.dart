import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import 'package:mauritanie_news/shared/theme/app_theme.dart';
import 'package:mauritanie_news/features/feed/providers/feed_providers.dart';
import 'package:mauritanie_news/app/router.dart';
import 'package:mauritanie_news/shared/widgets/agency/stats_card.dart';

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
          'Administration',
          style: AppTextStyles.headlineSmall.copyWith(color: AppColors.textOnPrimary),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(adminStatsProvider),
          ),
        ],
      ),
      body: statsAsync.when(
        data: (stats) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(adminStatsProvider),
          child: SingleChildScrollView(
            padding: AppSpacing.pagePadding,
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Vue d\'ensemble',
                  style: AppTextStyles.displayMedium.copyWith(color: AppColors.textPrimary),
                ),
                const Gap(AppSpacing.sm),
                Text(
                  'Statistiques globales de la plateforme',
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                ),
                const Gap(AppSpacing.xxl),
                
                // Stats Grid
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: AppSpacing.md,
                  crossAxisSpacing: AppSpacing.md,
                  childAspectRatio: 1.1,
                  children: [
                    StatsCard(
                      title: 'Agences en attente',
                      value: stats['pending_agencies'].toString(),
                      icon: Icons.business_rounded,
                      accentColor: AppColors.warning,
                      onTap: () => context.push(AppRoutes.adminValidation),
                    ),
                    StatsCard(
                      title: 'Signalements',
                      value: stats['pending_reports'].toString(),
                      icon: Icons.report_problem_rounded,
                      accentColor: AppColors.error,
                      onTap: () => context.push(AppRoutes.adminReports),
                    ),
                    StatsCard(
                      title: 'Articles actifs',
                      value: stats['active_articles'].toString(),
                      icon: Icons.article_rounded,
                      accentColor: AppColors.primary,
                    ),
                    StatsCard(
                      title: 'Catégories',
                      value: stats['categories'].toString(),
                      icon: Icons.category_rounded,
                      accentColor: AppColors.secondary,
                      onTap: () => context.push(AppRoutes.adminCategories),
                    ),
                  ],
                ),
                
                const Gap(AppSpacing.xxxl),
                Text(
                  'Actions rapides',
                  style: AppTextStyles.headlineMedium.copyWith(color: AppColors.textPrimary),
                ),
                const Gap(AppSpacing.md),
                
                _AdminActionTile(
                  title: 'Validation des agences',
                  subtitle: 'Approuver ou rejeter les nouvelles inscriptions',
                  icon: Icons.verified_user_rounded,
                  color: AppColors.warning,
                  onTap: () => context.push(AppRoutes.adminValidation),
                ),
                _AdminActionTile(
                  title: 'Gestion des signalements',
                  subtitle: 'Modérer le contenu signalé par les lecteurs',
                  icon: Icons.gavel_rounded,
                  color: AppColors.error,
                  onTap: () => context.push(AppRoutes.adminReports),
                ),
                _AdminActionTile(
                  title: 'Liste des agences',
                  subtitle: 'Gérer les comptes et les accès agence',
                  icon: Icons.business_center_rounded,
                  color: AppColors.primary,
                  onTap: () => context.push(AppRoutes.adminAgencies),
                ),
                _AdminActionTile(
                  title: 'Catégories d\'articles',
                  subtitle: 'Configurer les thématiques et couleurs',
                  icon: Icons.settings_suggest_rounded,
                  color: AppColors.secondary,
                  onTap: () => context.push(AppRoutes.adminCategories),
                ),
              ],
            ),
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const Gap(AppSpacing.md),
              Text('Erreur: $e', textAlign: TextAlign.center),
              TextButton(
                onPressed: () => ref.invalidate(adminStatsProvider),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminActionTile extends StatelessWidget {
  const _AdminActionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.cardRadius,
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: AppRadius.buttonRadius,
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: AppTextStyles.headlineSmall),
        subtitle: Text(subtitle, style: AppTextStyles.bodySmall),
        trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary),
      ),
    );
  }
}
