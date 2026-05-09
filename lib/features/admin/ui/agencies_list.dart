import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/theme/app_theme.dart';
import '../../feed/providers/feed_providers.dart';
import '../../../shared/models/agency_model.dart';
import 'admin_drawer.dart';

import 'package:go_router/go_router.dart';
import '../../../app/router.dart';

enum AgencyFilter { all, validated, pending, rejected }

final agencyFilterProvider = StateProvider<AgencyFilter>((ref) => AgencyFilter.all);

final filteredAgenciesProvider = Provider.autoDispose<AsyncValue<List<AgencyModel>>>((ref) {
  final agenciesAsync = ref.watch(allAgenciesProvider);
  final filter = ref.watch(agencyFilterProvider);

  return agenciesAsync.whenData((agencies) {
    switch (filter) {
      case AgencyFilter.all:
        return agencies;
      case AgencyFilter.validated:
        return agencies.where((a) => a.status == AgencyStatus.accepted).toList();
      case AgencyFilter.pending:
        return agencies.where((a) => a.status == AgencyStatus.pending).toList();
      case AgencyFilter.rejected:
        return agencies.where((a) => a.status == AgencyStatus.rejected).toList();
    }
  });
});

class AgenciesListScreen extends ConsumerWidget {
  const AgenciesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textOnPrimary,
          title: Text(
            'Gestion des Agences',
            style: AppTextStyles.headlineSmall.copyWith(color: AppColors.textOnPrimary),
          ),
          bottom: TabBar(
            isScrollable: true,
            labelColor: AppColors.textOnPrimary,
            unselectedLabelColor: AppColors.textOnPrimary.withValues(alpha: 0.7),
            indicatorColor: AppColors.textOnPrimary,
            tabs: const [
              Tab(text: 'Toutes'),
              Tab(text: 'En attente'),
              Tab(text: 'Acceptées'),
              Tab(text: 'Refusées'),
            ],
            onTap: (index) {
              final filter = [
                AgencyFilter.all,
                AgencyFilter.pending,
                AgencyFilter.validated,
                AgencyFilter.rejected,
              ][index];
              ref.read(agencyFilterProvider.notifier).state = filter;
            },
          ),
        ),
        drawer: const AdminDrawer(),
        body: TabBarView(
          physics: const NeverScrollableScrollPhysics(), // Managed by our provider
          children: List.generate(4, (index) => const _AgenciesListContent()),
        ),
      ),
    );
  }
}

class _AgenciesListContent extends ConsumerWidget {
  const _AgenciesListContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filteredAgenciesAsync = ref.watch(filteredAgenciesProvider);

    return RefreshIndicator(
      onRefresh: () => ref.refresh(allAgenciesProvider.future),
      child: filteredAgenciesAsync.when(
        data: (agencies) {
          if (agencies.isEmpty) {
            return const Center(child: Text('Aucune agence trouvée'));
          }
          return ListView.separated(
            padding: AppSpacing.pagePadding,
            itemCount: agencies.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (context, index) {
              final agency = agencies[index];
              return _AgencyListTile(agency: agency);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Text('Erreur: $err', style: const TextStyle(color: AppColors.error)),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.color,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final activeColor = color ?? AppColors.primary;
    
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onTap(),
        selectedColor: activeColor.withValues(alpha: 0.2),
        labelStyle: AppTextStyles.labelMedium.copyWith(
          color: isSelected ? activeColor : AppColors.textSecondary,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        side: BorderSide(
          color: isSelected ? activeColor : AppColors.border,
          width: isSelected ? 1.5 : 1,
        ),
        showCheckmark: false,
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
      case AgencyStatus.accepted:
        statusColor = AppColors.statusApproved;
        statusLabel = 'Validé';
        break;
      case AgencyStatus.pending:
        statusColor = AppColors.statusPending;
        statusLabel = 'En attente';
        break;
      case AgencyStatus.rejected:
        statusColor = AppColors.statusRejected;
        statusLabel = 'Rejeté';
        break;
      case AgencyStatus.suspended:
        statusColor = AppColors.statusSuspended;
        statusLabel = 'Suspendu';
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
          child: Icon(
            status == AgencyStatus.accepted
                ? Icons.business
                : Icons.lock_outline,
            color: statusColor,
          ),
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
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.picture_as_pdf, color: AppColors.primary),
              onPressed: () =>
                  context.push(AppRoutes.adminAgencyDetails, extra: agency),
            ),
            PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'suspend' && status == AgencyStatus.accepted) {
                  await _suspendAgency(context, ref);
                } else if (value == 'approve' &&
                    (status == AgencyStatus.suspended ||
                        status == AgencyStatus.pending)) {
                  await _approveAgency(context, ref);
                } else if (value == 'reject' &&
                    (status == AgencyStatus.pending ||
                        status == AgencyStatus.suspended)) {
                  await _rejectAgency(context, ref);
                }
              },
              itemBuilder: (context) => [
                if (status == AgencyStatus.accepted)
                  const PopupMenuItem(
                    value: 'suspend',
                    child: Text('Suspendre',
                        style: TextStyle(color: AppColors.error)),
                  ),
                if (status == AgencyStatus.suspended ||
                    status == AgencyStatus.pending)
                  const PopupMenuItem(
                    value: 'approve',
                    child: Text('Approuver',
                        style: TextStyle(color: AppColors.success)),
                  ),
                if (status == AgencyStatus.pending ||
                    status == AgencyStatus.suspended)
                  const PopupMenuItem(
                    value: 'reject',
                    child: Text('Rejeter',
                        style: TextStyle(color: AppColors.error)),
                  ),
              ],
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

  Future<void> _rejectAgency(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(adminRepositoryProvider).rejectAgency(
          agencyId: agency.id, reason: 'Rejeté par l\'administrateur');
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
