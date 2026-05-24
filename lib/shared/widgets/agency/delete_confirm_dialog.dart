import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mauritanie_news/features/agency/localization/agency_l10n.dart';
import 'package:mauritanie_news/shared/theme/app_theme.dart';
import 'package:mauritanie_news/features/feed/providers/feed_providers.dart';

/// Dialogue de confirmation de suppression (Supabase).
class DeleteConfirmDialog extends ConsumerStatefulWidget {
  const DeleteConfirmDialog({
    super.key,
    required this.articleId,
    required this.articleTitle,
  });

  final String articleId;
  final String articleTitle;

  @override
  ConsumerState<DeleteConfirmDialog> createState() =>
      _DeleteConfirmDialogState();
}

class _DeleteConfirmDialogState extends ConsumerState<DeleteConfirmDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  bool _loading = false;

  /// Le [showDialog] n'hérite pas toujours de [AgencyLocalizations].
  AgencyLocalizations _l10n(BuildContext context) {
    return Localizations.of<AgencyLocalizations>(context, AgencyLocalizations) ??
        AgencyLocalizations(const Locale('fr'));
  }

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  Future<void> _onDelete() async {
    if (!mounted) return;
    final l10n = _l10n(context);
    if (widget.articleId.isEmpty) return;

    setState(() => _loading = true);
    try {
      await ref.read(agencyRepositoryProvider).deleteArticle(widget.articleId);
      if (!mounted) return;
      final messenger = ScaffoldMessenger.maybeOf(context);
      Navigator.of(context).pop(true);
      messenger?.showSnackBar(
        SnackBar(
          backgroundColor: AppColors.success,
          content: Text(
            l10n.t('delete_success'),
            style: AppTextStyles.bodyMedium
                .copyWith(color: AppColors.textOnPrimary),
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      final messenger = ScaffoldMessenger.maybeOf(context);
      messenger?.showSnackBar(
        SnackBar(
          backgroundColor: AppColors.error,
          content: Text(
            l10n.t('delete_error'),
            style: AppTextStyles.bodyMedium
                .copyWith(color: AppColors.textOnPrimary),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = _l10n(context);
    final pulseScale = Tween<double>(begin: 1, end: 1.08).animate(
      CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
    );

    return AlertDialog(
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.cardRadius),
      title: Row(
        children: [
          ScaleTransition(
            scale: pulseScale,
            child: const Icon(Icons.warning_amber_rounded,
                color: AppColors.error, size: 28),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              l10n.t('delete_article_title'),
              style: AppTextStyles.headlineSmall.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
      content: Text(
        l10n.tf('delete_article_body', params: {'title': widget.articleTitle}),
        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.of(context).pop(false),
          child: Text(
            l10n.t('cancel'),
            style: AppTextStyles.buttonMedium.copyWith(color: AppColors.textSecondary),
          ),
        ),
        ElevatedButton(
          onPressed: _loading ? null : _onDelete,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.error,
            foregroundColor: AppColors.textOnPrimary,
            shape: const RoundedRectangleBorder(borderRadius: AppRadius.buttonRadius),
          ),
          child: _loading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppColors.textOnPrimary),
                )
              : Text(
                  l10n.t('delete'),
                  style: AppTextStyles.buttonMedium
                      .copyWith(color: AppColors.textOnPrimary),
                ),
        ),
      ],
    );
  }
}
