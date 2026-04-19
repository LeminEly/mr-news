import 'package:flutter/material.dart';

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
            'Aucun article publié',
            textAlign: TextAlign.center,
            style: AppTextStyles.headlineSmall.copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Commencez par publier votre premier article',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.xxl),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: widget.onPublishPressed,
              icon: const Icon(Icons.add, color: AppColors.textOnPrimary),
              label: Text(
                '✚ Publier maintenant',
                style: AppTextStyles.buttonLarge.copyWith(color: AppColors.textOnPrimary),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textOnPrimary,
                minimumSize: const Size.fromHeight(52),
                shape: const RoundedRectangleBorder(borderRadius: AppRadius.buttonRadius),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
