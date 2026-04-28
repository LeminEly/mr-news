import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/theme/app_theme.dart';
import '../../feed/providers/feed_providers.dart';
import 'admin_drawer.dart';

class ReportsManagementScreen extends ConsumerWidget {
  const ReportsManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportsAsync = ref.watch(pendingReportsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        title: Text(
          'Signalements',
          style: AppTextStyles.headlineSmall.copyWith(color: AppColors.textOnPrimary),
        ),
      ),
      drawer: const AdminDrawer(),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(pendingReportsProvider.future),
        child: reportsAsync.when(
          data: (reports) {
            if (reports.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle_outline, color: AppColors.success, size: 64),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Aucun signalement en attente',
                      style: AppTextStyles.headlineSmall.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              );
            }

            return ListView.separated(
              padding: AppSpacing.pagePadding,
              itemCount: reports.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, index) {
                final report = reports[index];
                return _ReportCard(report: report);
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(
            child: Text('Erreur: $err', style: const TextStyle(color: AppColors.error)),
          ),
        ),
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({required this.report});

  final dynamic report;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.cardRadius),
      elevation: 0,
      color: AppColors.surface,
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: AppColors.error),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Signalement #${report['id'].toString().substring(0, 8)}',
                  style: AppTextStyles.labelLarge.copyWith(color: AppColors.error),
                ),
                const Spacer(),
                Text(
                  report['created_at'].toString().split('T')[0],
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
            const Divider(height: AppSpacing.xl),
            Text(
              'Raison:',
              style: AppTextStyles.labelSmall.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(report['reason'] ?? 'Non spécifiée', style: AppTextStyles.bodyMedium),
            const SizedBox(height: AppSpacing.md),
            if (report['comment'] != null) ...[
              Text(
                'Commentaire:',
                style: AppTextStyles.labelSmall.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(report['comment'], style: AppTextStyles.bodySmall),
              const SizedBox(height: AppSpacing.md),
            ],
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () {
                    // Logic to resolve report could be added here
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Fonctionnalité en cours de développement')),
                    );
                  },
                  child: const Text('Ignorer'),
                ),
                const SizedBox(width: AppSpacing.sm),
                ElevatedButton(
                  onPressed: () {
                    // Logic to take action (e.g. suspend article)
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Fonctionnalité en cours de développement')),
                    );
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                  child: const Text('Prendre des mesures'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
