import 'package:flutter/material.dart';

import 'package:mauritanie_news/shared/theme/app_theme.dart';

/// Dialogue de confirmation de suppression (mock — pas de backend).
class DeleteConfirmDialog extends StatefulWidget {
  const DeleteConfirmDialog({
    super.key,
    required this.articleTitle,
  });

  final String articleTitle;

  @override
  State<DeleteConfirmDialog> createState() => _DeleteConfirmDialogState();
}

class _DeleteConfirmDialogState extends State<DeleteConfirmDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  bool _loading = false;

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
    // TODO: connect to Supabase — supprimer l’article côté serveur.
    setState(() => _loading = true);
    await Future<void>.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop(true);
    messenger.showSnackBar(
      SnackBar(
        backgroundColor: AppColors.success,
        content: Text(
          'Article supprimé',
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textOnPrimary),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pulseScale = Tween<double>(begin: 1, end: 1.08).animate(
      CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
    );

    return AlertDialog(
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.cardRadius),
      title: Row(
        children: [
          ScaleTransition(
            scale: pulseScale,
            child: const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 28),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Supprimer l’article ?',
              style: AppTextStyles.headlineSmall.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
      content: Text(
        'Cette action est irréversible. L’article «${widget.articleTitle}» sera définitivement supprimé.',
        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.of(context).pop(false),
          child: Text(
            'Annuler',
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
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textOnPrimary),
                )
              : Text(
                  'Supprimer',
                  style: AppTextStyles.buttonMedium.copyWith(color: AppColors.textOnPrimary),
                ),
        ),
      ],
    );
  }
}
