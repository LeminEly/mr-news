import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:mauritanie_news/shared/theme/app_theme.dart';
import 'package:mauritanie_news/features/feed/providers/feed_providers.dart';
import 'package:mauritanie_news/shared/models/agency_model.dart';

class AgencyValidationScreen extends ConsumerWidget {
  const AgencyValidationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingAsync = ref.watch(pendingAgenciesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        title: Text(
          'Validation Agences',
          style: AppTextStyles.headlineSmall.copyWith(color: AppColors.textOnPrimary),
        ),
      ),
      body: pendingAsync.when(
        data: (agencies) {
          if (agencies.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle_outline_rounded, size: 64, color: AppColors.success),
                  const Gap(AppSpacing.md),
                  Text(
                    'Aucune agence en attente',
                    style: AppTextStyles.headlineSmall.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(pendingAgenciesProvider),
            child: ListView.builder(
              padding: AppSpacing.pagePadding,
              itemCount: agencies.length,
              itemBuilder: (context, index) {
                return _AgencyValidationCard(agency: agencies[index]);
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(child: Text('Erreur: $e')),
      ),
    );
  }
}

class _AgencyValidationCard extends ConsumerStatefulWidget {
  const _AgencyValidationCard({required this.agency});
  final AgencyModel agency;

  @override
  ConsumerState<_AgencyValidationCard> createState() => _AgencyValidationCardState();
}

class _AgencyValidationCardState extends ConsumerState<_AgencyValidationCard> {
  bool _loading = false;

  Future<void> _approve() async {
    setState(() => _loading = true);
    try {
      await ref.read(adminRepositoryProvider).approveAgency(widget.agency.id);
      ref.invalidate(pendingAgenciesProvider);
      ref.invalidate(adminStatsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Agence approuvée'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _reject() async {
    final reasonController = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rejeter l\'agence'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(hintText: 'Raison du rejet...'),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Rejeter'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _loading = true);
      try {
        await ref.read(adminRepositoryProvider).rejectAgency(
              agencyId: widget.agency.id,
              reason: reasonController.text,
            );
        ref.invalidate(pendingAgenciesProvider);
        ref.invalidate(adminStatsProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Agence rejetée'), backgroundColor: AppColors.error),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: $e'), backgroundColor: AppColors.error),
          );
        }
      } finally {
        if (mounted) setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.cardRadius,
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.surfaceVariant,
                backgroundImage: widget.agency.logoUrl != null
                    ? CachedNetworkImageProvider(widget.agency.logoUrl!)
                    : null,
                child: widget.agency.logoUrl == null
                    ? const Icon(Icons.business_rounded, color: AppColors.textTertiary)
                    : null,
              ),
              const Gap(AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.agency.name, style: AppTextStyles.headlineSmall),
                    Text(widget.agency.email, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
          const Gap(AppSpacing.md),
          Text(
            'Type: ${widget.agency.mediaType.name}',
            style: AppTextStyles.bodySmall,
          ),
          if (widget.agency.websiteUrl != null)
            Text(
              'Site: ${widget.agency.websiteUrl}',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.info),
            ),
          const Gap(AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _loading ? null : _reject,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                  ),
                  child: const Text('Rejeter'),
                ),
              ),
              const Gap(AppSpacing.md),
              Expanded(
                child: ElevatedButton(
                  onPressed: _loading ? null : _approve,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: AppColors.textOnPrimary,
                  ),
                  child: _loading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Approuver'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
