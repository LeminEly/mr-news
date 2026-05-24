import 'package:flutter/material.dart';

import 'package:mauritanie_news/features/agency/localization/agency_l10n.dart';
import 'package:mauritanie_news/shared/theme/app_theme.dart';

/// État vide lorsqu’aucun article n’est affiché (animation Flutter pure).
class EmptyStateWidget extends StatefulWidget {
  const EmptyStateWidget({
    super.key,
    required this.onPublishPressed,
  });

  final VoidCallback onPublishPressed;

  @override
  State<EmptyStateWidget> createState() => _EmptyStateWidgetState();
}

class _EmptyStateWidgetState extends State<EmptyStateWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
        duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.agencyL10n;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxxl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          RotationTransition(
            turns: Tween<double>(begin: -0.02, end: 0.02).animate(
              CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
            ),
            child: const Icon(
              Icons.newspaper_outlined,
              size: 64,
              color: AppColors.primaryLight,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            l10n.t('empty_published'),
            textAlign: TextAlign.center,
            style: AppTextStyles.headlineSmall
                .copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.t('empty_publish_hint'),
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium
                .copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.xxl),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: widget.onPublishPressed,
              icon: const Icon(Icons.add, color: AppColors.textOnPrimary),
              label: Text(
                l10n.t('publish_now'),
                style: AppTextStyles.buttonLarge
                    .copyWith(color: AppColors.textOnPrimary),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textOnPrimary,
                minimumSize: const Size.fromHeight(52),
                shape: const RoundedRectangleBorder(
                    borderRadius: AppRadius.buttonRadius),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
