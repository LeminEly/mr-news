import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/theme/app_theme.dart';
import '../../feed/providers/feed_providers.dart';
import 'admin_drawer.dart';

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
      drawer: const AdminDrawer(),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(pendingAgenciesProvider.future),
        child: pendingAsync.when(
          data: (agencies) {
            if (agencies.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle_outline, color: AppColors.success, size: 64),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Aucune agence en attente',
                      style: AppTextStyles.headlineSmall.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              );
            }

            return ListView.separated(
              padding: AppSpacing.pagePadding,
              itemCount: agencies.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, index) {
                final agency = agencies[index];
                return _AgencyCard(agency: agency);
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

class _AgencyCard extends ConsumerStatefulWidget {
  const _AgencyCard({required this.agency});

  final dynamic agency;

  @override
  ConsumerState<_AgencyCard> createState() => _AgencyCardState();
}

class _AgencyCardState extends ConsumerState<_AgencyCard> {
  bool _isProcessing = false;

  Future<void> _handleAction(bool approve) async {
    final messenger = ScaffoldMessenger.of(context);
    final repo = ref.read(adminRepositoryProvider);
    final agencyId = widget.agency.id;

    String? reason;
    if (!approve) {
      reason = await _showRejectDialog();
      if (reason == null) return;
    }

    setState(() => _isProcessing = true);

    try {
      if (approve) {
        await repo.approveAgency(agencyId);
        messenger.showSnackBar(const SnackBar(content: Text('Agence approuvée')));
      } else {
        await repo.rejectAgency(agencyId: agencyId, reason: reason!);
        messenger.showSnackBar(const SnackBar(content: Text('Agence rejetée')));
      }
      ref.invalidate(pendingAgenciesProvider);
      ref.invalidate(adminStatsProvider);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Erreur: $e'), backgroundColor: AppColors.error));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<String?> _showRejectDialog() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rejeter l’agence'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Raison du rejet',
            hintText: 'Ex: Document invalide',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Rejeter'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final agency = widget.agency;

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
                CircleAvatar(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: const Icon(Icons.business, color: AppColors.primary),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(agency.name, style: AppTextStyles.labelLarge),
                      Text(agency.email, style: AppTextStyles.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: AppSpacing.xl),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isProcessing ? null : () => _handleAction(false),
                  style: TextButton.styleFrom(foregroundColor: AppColors.error),
                  child: const Text('Rejeter'),
                ),
                const SizedBox(width: AppSpacing.sm),
                ElevatedButton(
                  onPressed: _isProcessing ? null : () => _handleAction(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                  ),
                  child: _isProcessing
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Approuver'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
