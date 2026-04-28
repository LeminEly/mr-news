import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/theme/app_theme.dart';
import '../../feed/providers/feed_providers.dart';
import '../../../shared/models/agency_model.dart';
import 'admin_drawer.dart';

final allAgenciesProvider =
    FutureProvider.autoDispose<List<AgencyModel>>((ref) async {
  return ref.watch(adminRepositoryProvider).getAgencies();
});

class AgenciesListScreen extends ConsumerWidget {
  const AgenciesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final agenciesAsync = ref.watch(allAgenciesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        title: Text(
          'Toutes les Agences',
          style: AppTextStyles.headlineSmall
              .copyWith(color: AppColors.textOnPrimary),
        ),
      ),
      drawer: const AdminDrawer(),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(allAgenciesProvider.future),
        child: agenciesAsync.when(
          data: (agencies) {
            return ListView.separated(
              padding: AppSpacing.pagePadding,
              itemCount: agencies.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, index) {
                final agency = agencies[index];
                return _AgencyListTile(agency: agency);
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(
            child: Text('Erreur: $err',
                style: const TextStyle(color: AppColors.error)),
          ),
        ),
      ),
    );
  }
}

class _AgencyListTile extends ConsumerWidget {
  const _AgencyListTile({required this.agency});

  final AgencyModel agency;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = agency.status;

    Color statusColor;
    String statusLabel;

    switch (status) {
      case AgencyStatus.approved:
        statusColor = AppColors.success;
        statusLabel = 'Approuvé';
        break;
      case AgencyStatus.pending:
        statusColor = AppColors.warning;
        statusLabel = 'En attente';
        break;
      case AgencyStatus.suspended:
        statusColor = AppColors.error;
        statusLabel = 'Suspendu';
        break;
      case AgencyStatus.rejected:
        statusColor = AppColors.error;
        statusLabel = 'Rejeté';
        break;
    }

    return Card(
      elevation: 0,
      color: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: AppRadius.cardRadius,
        side: BorderSide(color: AppColors.border),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        leading: CircleAvatar(
          backgroundColor: statusColor.withValues(alpha: 0.1),
          child: Icon(Icons.business, color: statusColor),
        ),
        title: Text(agency.name, style: AppTextStyles.labelLarge),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(agency.email, style: AppTextStyles.bodySmall),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                statusLabel,
                style: AppTextStyles.labelSmall
                    .copyWith(color: statusColor, fontSize: 10),
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) async {
            if (value == 'suspend' && status == AgencyStatus.approved) {
              await _suspendAgency(context, ref);
            } else if (value == 'approve' &&
                (status == AgencyStatus.suspended ||
                    status == AgencyStatus.pending)) {
              await _approveAgency(context, ref);
            }
          },
          itemBuilder: (context) => [
            if (status == AgencyStatus.approved)
              const PopupMenuItem(
                value: 'suspend',
                child:
                    Text('Suspendre', style: TextStyle(color: AppColors.error)),
              ),
            if (status == AgencyStatus.suspended ||
                status == AgencyStatus.pending)
              const PopupMenuItem(
                value: 'approve',
                child: Text('Approuver',
                    style: TextStyle(color: AppColors.success)),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _suspendAgency(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Suspendre l’agence'),
        content: const Text(
            'Voulez-vous vraiment suspendre cette agence ? Ses articles ne seront plus visibles.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Suspendre'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref
            .read(adminRepositoryProvider)
            .suspendAgency(agencyId: agency.id);
        ref.invalidate(allAgenciesProvider);
        ref.invalidate(adminStatsProvider);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Erreur: $e'), backgroundColor: AppColors.error));
        }
      }
    }
  }

  Future<void> _approveAgency(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(adminRepositoryProvider).approveAgency(agency.id);
      ref.invalidate(allAgenciesProvider);
      ref.invalidate(adminStatsProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Erreur: $e'), backgroundColor: AppColors.error));
      }
    }
  }
}
