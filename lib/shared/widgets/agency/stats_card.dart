import 'package:flutter/material.dart';

import 'package:mauritanie_news/shared/theme/app_theme.dart';

/// Carte statistique pour les tableaux de bord (Agence ou Admin).
class StatsCard extends StatelessWidget {
  const StatsCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.accentColor,
    this.animation,
    this.onTap,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color accentColor;
  final Animation<double>? animation;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final child = Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.cardRadius,
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.cardRadius,
          child: Padding(
            padding: AppSpacing.cardPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.12),
                        borderRadius: AppRadius.buttonRadius,
                      ),
                      child: Icon(icon, color: accentColor, size: 22),
                    ),
                    if (onTap != null) ...[
                      const Spacer(),
                      Icon(Icons.arrow_forward_rounded, size: 14, color: AppColors.textTertiary.withOpacity(0.5)),
                    ],
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  value,
                  style: AppTextStyles.displayMedium.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.labelMedium.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (animation == null) return child;

    return FadeTransition(
      opacity: animation!,
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.85, end: 1).animate(
          CurvedAnimation(parent: animation!, curve: Curves.easeOutCubic),
        ),
        child: child,
      ),
    );
  }
}
