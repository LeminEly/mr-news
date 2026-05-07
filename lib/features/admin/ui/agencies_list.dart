import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:mauritanie_news/shared/theme/app_theme.dart';
import 'package:mauritanie_news/features/feed/providers/feed_providers.dart';
import 'package:mauritanie_news/shared/models/agency_model.dart';

class AgenciesListScreen extends ConsumerStatefulWidget {
  const AgenciesListScreen({super.key});

  @override
  ConsumerState<AgenciesListScreen> createState() => _AgenciesListScreenState();
}

class _AgenciesListScreenState extends ConsumerState<AgenciesListScreen> {
  String? _filterStatus;

  @override
  Widget build(BuildContext context) {
    final adminRepo = ref.watch(adminRepositoryProvider);
    final agenciesFuture = adminRepo.getAgencies(status: _filterStatus);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        title: Text(
          'Gestion des Agences',
          style: AppTextStyles.headlineSmall.copyWith(color: AppColors.textOnPrimary),
        ),
      ),
      body: Column(
        children: [
          // Filter Chips
          Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _FilterChip(
                  label: 'Toutes',
                  isSelected: _filterStatus == null,
                  onTap: () => setState(() => _filterStatus = null),
                ),
                _FilterChip(
                  label: 'Approuvées',
                  isSelected: _filterStatus == 'approved',
                  onTap: () => setState(() => _filterStatus = 'approved'),
                ),
                _FilterChip(
                  label: 'Suspendues',
                  isSelected: _filterStatus == 'suspended',
                  onTap: () => setState(() => _filterStatus = 'suspended'),
                ),
                _FilterChip(
                  label: 'Rejetées',
                  isSelected: _filterStatus == 'rejected',
                  onTap: () => setState(() => _filterStatus = 'rejected'),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: agenciesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Erreur: ${snapshot.error}'));
                }
                
                final agencies = snapshot.data ?? [];
                if (agencies.isEmpty) {
                  return const Center(child: Text('Aucune agence trouvée'));
                }

                return ListView.builder(
                  padding: AppSpacing.pagePadding,
                  itemCount: agencies.length,
                  itemBuilder: (context, index) {
                    final data = agencies[index];
                    final agency = AgencyModel.fromJson(data);
                    return _AgencyTile(agency: agency);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onTap(),
        selectedColor: AppColors.primary.withOpacity(0.2),
        checkmarkColor: AppColors.primary,
        labelStyle: AppTextStyles.labelMedium.copyWith(
          color: isSelected ? AppColors.primary : AppColors.textSecondary,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}

class _AgencyTile extends ConsumerWidget {
  const _AgencyTile({required this.agency});
  final AgencyModel agency;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.cardRadius,
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.surfaceVariant,
          backgroundImage: agency.logoUrl != null ? CachedNetworkImageProvider(agency.logoUrl!) : null,
          child: agency.logoUrl == null ? const Icon(Icons.business_rounded) : null,
        ),
        title: Text(agency.name, style: AppTextStyles.headlineSmall),
        subtitle: Text(agency.email, style: AppTextStyles.bodySmall),
        trailing: _StatusBadge(status: agency.status),
        onTap: () {
          // TODO: Open detail view or actions
        },
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final AgencyStatus status;

  @override
  Widget build(BuildContext context) {
    final color = () {
      switch (status) {
        case AgencyStatus.approved: return AppColors.success;
        case AgencyStatus.pending: return AppColors.warning;
        case AgencyStatus.rejected: return AppColors.error;
        case AgencyStatus.suspended: return AppColors.textTertiary;
      }
    }();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: AppRadius.chipRadius,
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        status.name.toUpperCase(),
        style: AppTextStyles.labelSmall.copyWith(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }
}
