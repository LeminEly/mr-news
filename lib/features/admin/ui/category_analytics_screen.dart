import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/theme/app_theme.dart';
import '../../feed/providers/feed_providers.dart';
import 'admin_drawer.dart';

class CategoryAnalyticsScreen extends ConsumerWidget {
  const CategoryAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(categoryAnalyticsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        title: Text(
          'Analytiques des Catégories',
          style: AppTextStyles.headlineSmall.copyWith(color: AppColors.textOnPrimary),
        ),
      ),
      drawer: const AdminDrawer(),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(categoryAnalyticsProvider.future),
        child: analyticsAsync.when(
          data: (data) => SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: AppSpacing.pagePadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section 1: Categories actives aujourd’hui
                _AnalyticsBlock(
                  title: '1. Catégories actives aujourd’hui',
                  subtitle: 'Usage en temps réel basé sur les publications du jour',
                  children: (data['active_today'] as List).isEmpty 
                    ? [const _EmptyAnalyticsTile(message: 'Aucune activité aujourd’hui')]
                    : (data['active_today'] as List).map((cat) {
                        return _CategoryMetricTile(
                          label: cat['name'],
                          value: '${cat['count']} articles',
                          icon: cat['icon'],
                        );
                      }).toList(),
                ),
                const SizedBox(height: AppSpacing.xl),

                // Section 2: Les plus actives catégories
                _AnalyticsBlock(
                  title: '2. Les plus actives catégories',
                  subtitle: 'Basé sur l’engagement global de la plateforme',
                  children: (data['most_active'] as List).isEmpty
                    ? [const _EmptyAnalyticsTile(message: 'Données insuffisantes')]
                    : (data['most_active'] as List).map((cat) {
                        return _CategoryEngagementTile(
                          label: cat['name'],
                          engagement: cat['engagement'],
                          icon: cat['icon'],
                        );
                      }).toList(),
                ),
                const SizedBox(height: AppSpacing.xl),

                // Section 3: Activité des catégories aujourd’hui
                _AnalyticsBlock(
                  title: '3. Activité des catégories aujourd’hui',
                  subtitle: 'Répartition détaillée des interactions par catégorie',
                  children: (data['activity_today'] as List).isEmpty
                    ? [const _EmptyAnalyticsTile(message: 'Pas encore de données pour aujourd’hui')]
                    : (data['activity_today'] as List).map((cat) {
                        return _ActivityRowTile(
                          label: cat['name'],
                          count: cat['count'],
                          icon: cat['icon'],
                        );
                      }).toList(),
                ),
              ],
            ),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(
            child: Text('Erreur: $err', style: const TextStyle(color: AppColors.error)),
          ),
        ),
      ),
    );
  }
}

class _AnalyticsBlock extends StatelessWidget {
  const _AnalyticsBlock({
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.headlineSmall.copyWith(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(subtitle, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: AppSpacing.md),
        ...children,
      ],
    );
  }
}

class _CategoryMetricTile extends StatelessWidget {
  const _CategoryMetricTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final String icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.cardRadius,
        side: const BorderSide(color: AppColors.border),
      ),
      child: ListTile(
        leading: Text(icon, style: const TextStyle(fontSize: 24)),
        title: Text(label, style: AppTextStyles.labelLarge),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(value, style: AppTextStyles.labelSmall.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}

class _CategoryEngagementTile extends StatelessWidget {
  const _CategoryEngagementTile({
    required this.label,
    required this.engagement,
    required this.icon,
  });

  final String label;
  final int engagement;
  final String icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.cardRadius,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.labelLarge),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: engagement / 100,
                    backgroundColor: AppColors.surfaceVariant,
                    color: AppColors.accent,
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text('$engagement%', style: AppTextStyles.labelSmall.copyWith(fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _ActivityRowTile extends StatelessWidget {
  const _ActivityRowTile({
    required this.label,
    required this.count,
    required this.icon,
  });

  final String label;
  final int count;
  final String icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(icon, style: const TextStyle(fontSize: 16)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label, style: AppTextStyles.bodyMedium),
          ),
          Text(
            '$count articles',
            style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _EmptyAnalyticsTile extends StatelessWidget {
  const _EmptyAnalyticsTile({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant.withOpacity(0.3),
        borderRadius: AppRadius.cardRadius,
        border: Border.all(color: AppColors.border.withOpacity(0.5), style: BorderStyle.solid),
      ),
      child: Center(
        child: Text(message, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textTertiary)),
      ),
    );
  }
}
