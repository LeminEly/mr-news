import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

import 'package:mauritanie_news/shared/theme/app_theme.dart';

import 'package:mauritanie_news/features/agency/ui/mock_article.dart';
import 'package:mauritanie_news/features/agency/ui/widgets/delete_confirm_dialog.dart';
import 'package:mauritanie_news/features/agency/ui/edit_article_screen.dart';

/// Carte article pour la liste agence (liste + actions modifier / supprimer).
class ArticleCardAgency extends StatelessWidget {
  const ArticleCardAgency({
    super.key,
    required this.article,
    this.animation,
    required this.onDeleted,
    required this.onUpdated,
  });

  final MockArticle article;
  final Animation<double>? animation;
  final VoidCallback onDeleted;
  final ValueChanged<MockArticle> onUpdated;

  String _formatDate(DateTime d) {
    return DateFormat("d MMM yyyy 'à' HH:mm", 'fr_FR').format(d);
  }

  String _shortUrl(String url) {
    if (url.length <= 42) return url;
    return '${url.substring(0, 39)}…';
  }

  @override
  Widget build(BuildContext context) {
    final cover = article.coverImageUrl ??
        'https://picsum.photos/seed/${article.id}/400/200';

    final categoryLabel = article.language == 'ar'
        ? (article.categoryNameAr ?? '')
        : (article.categoryNameFr ?? '');
    final catColor = article.categoryDisplayColor;

    final titleWidget = Directionality(
      textDirection: article.isRtl ? ui.TextDirection.rtl : ui.TextDirection.ltr,
      child: Text(
        article.title,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        style: (article.isRtl ? AppTextStyles.articleTitleAr : AppTextStyles.articleTitle)
            .copyWith(color: AppColors.textPrimary),
      ),
    );

    final card = Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.cardRadius,
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Stack(
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Hero(
                  tag: 'cover_image_${article.id}',
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppRadius.md - 1),
                    ),
                    child: CachedNetworkImage(
                      imageUrl: cover,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      placeholder: (_, __) => Shimmer.fromColors(
                        baseColor: AppColors.surfaceVariant,
                        highlightColor: AppColors.surface,
                        child: Container(color: AppColors.surfaceVariant),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        color: AppColors.surfaceVariant,
                        child: const Icon(Icons.image_not_supported_outlined, color: AppColors.textTertiary),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: AppSpacing.sm,
                left: AppSpacing.sm,
                child: _CategoryBadge(
                  label: '${article.categoryIcon ?? ''} $categoryLabel'.trim(),
                  background: catColor,
                ),
              ),
              Positioned(
                top: AppSpacing.sm,
                right: AppSpacing.sm,
                child: _LangBadge(language: article.language),
              ),
            ],
          ),
          Padding(
            padding: AppSpacing.cardPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                titleWidget,
                const SizedBox(height: AppSpacing.sm),
                Text(
                  _formatDate(article.publishedAt),
                  style: AppTextStyles.meta.copyWith(color: AppColors.textTertiary),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  _shortUrl(article.sourceUrl),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.info,
                    decoration: TextDecoration.underline,
                    decorationColor: AppColors.info,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                  child: Divider(height: 1, color: AppColors.divider),
                ),
                Row(
                  children: [
                    const Icon(Icons.visibility_outlined, size: 16, color: AppColors.textTertiary),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      '${article.views} vues',
                      style: AppTextStyles.meta.copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    const Icon(Icons.favorite_border, size: 16, color: AppColors.textTertiary),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      '${article.reactions} réactions',
                      style: AppTextStyles.meta.copyWith(color: AppColors.textSecondary),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () async {
                        final updated = await Navigator.of(context).push<MockArticle>(
                          MaterialPageRoute<MockArticle>(
                            builder: (_) => EditArticleScreen(article: article),
                          ),
                        );
                        if (updated != null) onUpdated(updated);
                      },
                      icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.primary),
                      label: Text(
                        'Modifier',
                        style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (_) => DeleteConfirmDialog(articleTitle: article.title),
                        );
                        if (confirmed == true) onDeleted();
                      },
                      icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                      label: Text(
                        'Supprimer',
                        style: AppTextStyles.labelLarge.copyWith(color: AppColors.error),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (animation == null) return card;

    return FadeTransition(
      opacity: animation!,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(parent: animation!, curve: Curves.easeOutCubic),
        ),
        child: card,
      ),
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  const _CategoryBadge({required this.label, required this.background});

  final String label;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSpacing.chipPadding,
      decoration: BoxDecoration(
        color: background,
        borderRadius: AppRadius.chipRadius,
      ),
      child: Text(
        label,
        style: AppTextStyles.labelMedium.copyWith(color: AppColors.textOnPrimary),
      ),
    );
  }
}

class _LangBadge extends StatelessWidget {
  const _LangBadge({required this.language});

  final String language;

  @override
  Widget build(BuildContext context) {
    final isFr = language == 'fr';
    return Container(
      padding: AppSpacing.chipPadding,
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.92),
        borderRadius: AppRadius.chipRadius,
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        isFr ? '🇫🇷 FR' : '🇲🇷 AR',
        style: AppTextStyles.labelMedium.copyWith(color: AppColors.textPrimary),
      ),
    );
  }
}
