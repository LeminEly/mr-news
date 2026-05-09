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
                data: (stats) => Column(
                  children: [
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: AppSpacing.md,
                      crossAxisSpacing: AppSpacing.md,
                      childAspectRatio: 1.5,
                      children: [
                        _StatCard(
                          label: 'Agences inscrites',
                          value: stats['total_agencies'].toString(),
                          icon: Icons.business,
                          color: AppColors.primary,
                        ),
                        _StatCard(
                          label: 'Agences en attente',
                          value: stats['pending_agencies'].toString(),
                          icon: Icons.pending_actions,
                          color: AppColors.warning,
                        ),
                        _StatCard(
                          label: 'Agences validées',
                          value: stats['validated_agencies'].toString(),
                          icon: Icons.check_circle_outline,
                          color: AppColors.success,
                        ),
                        _StatCard(
                          label: 'Signalements',
                          value: stats['pending_reports'].toString(),
                          icon: Icons.report_problem_outlined,
                          color: AppColors.error,
                        ),
                        _StatCard(
                          label: 'Articles actifs',
                          value: stats['active_articles'].toString(),
                          icon: Icons.article_outlined,
                          color: AppColors.success,
                        ),
                        _StatCard(
                          label: 'Catégories',
                          value: stats['categories'].toString(),
                          icon: Icons.category_outlined,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _SplitValidationCard(
                      validated: stats['validated_agencies'] ?? 0,
                      rejected: stats['rejected_agencies'] ?? 0,
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
                'Analytiques & Gestion',
                style: AppTextStyles.headlineSmall.copyWith(color: AppColors.textPrimary),
              ),
              const SizedBox(height: AppSpacing.md),
              _QuickActionTile(
                title: 'Activités des agences par date',
                subtitle: 'Historique des validations et rejets',
                icon: Icons.calendar_today_outlined,
                onTap: () {
                  // Show activity bottom sheet or navigate
                  _showAgencyActivity(context, ref);
                },
              ),
              _QuickActionTile(
                title: 'Gérer les catégories',
                subtitle: 'Statistiques et interactions par catégorie',
                icon: Icons.analytics_outlined,
                onTap: () => context.go(AppRoutes.adminCategoryAnalytics),
              ),
              _QuickActionTile(
                title: 'Liste complète des agences',
                subtitle: 'Gestion centralisée, filtres et décisions',
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
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.cardRadius,
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 24),
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
                style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary, fontSize: 10),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SplitValidationCard extends StatelessWidget {
  const _SplitValidationCard({
    required this.validated,
    required this.rejected,
  });

  final int validated;
  final int rejected;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.cardRadius,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SplitSection(
              label: 'Agences Validées',
              value: validated.toString(),
              icon: Icons.check_circle_outline,
              color: AppColors.success,
            ),
          ),
          Container(width: 1, color: AppColors.border),
          Expanded(
            child: _SplitSection(
              label: 'Agences Refusées',
              value: rejected.toString(),
              icon: Icons.cancel_outlined,
              color: AppColors.error,
            ),
          ),
        ],
      ),
    );
  }
}

class _SplitSection extends StatelessWidget {
  const _SplitSection({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                value,
                style: AppTextStyles.headlineSmall.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

void _showAgencyActivity(BuildContext context, WidgetRef ref) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      minChildSize: 0.5,
      expand: false,
      builder: (context, scrollController) => Column(
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Activités des agences',
                  style: AppTextStyles.headlineSmall,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: Consumer(
              builder: (context, ref, child) {
                final activityAsync = ref.watch(agencyActivityProvider);
                return activityAsync.when(
                  data: (activities) {
                    if (activities.isEmpty) {
                      return const Center(child: Text('Aucune activité récente'));
                    }
                    
                    // Simple grouping by date for the prototype
                    return ListView.builder(
                      controller: scrollController,
                      padding: AppSpacing.pagePadding,
                      itemCount: activities.length,
                      itemBuilder: (context, index) {
                        final act = activities[index];
                        final isApproved = act['status'] == 'approved';
                        final date = act['validated_at'] != null 
                            ? DateTime.parse(act['validated_at'])
                            : DateTime.parse(act['created_at']);
                        
                        return ListTile(
                          leading: Icon(
                            isApproved ? Icons.check_circle : Icons.cancel,
                            color: isApproved ? AppColors.success : AppColors.error,
                          ),
                          title: Text(act['name'] ?? 'Inconnu', style: AppTextStyles.labelLarge),
                          subtitle: Text(
                            '${isApproved ? "Accepté" : "Refusé"} le ${date.day}/${date.month}/${date.year}',
                            style: AppTextStyles.bodySmall,
                          ),
                          trailing: const Icon(Icons.history, size: 16, color: AppColors.textTertiary),
                        );
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, _) => Center(child: Text('Erreur: $err')),
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
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
            color: AppColors.primary.withOpacity(0.1),
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
