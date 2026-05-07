import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

import 'package:mauritanie_news/shared/theme/app_theme.dart';

import 'package:mauritanie_news/shared/widgets/agency/delete_confirm_dialog.dart';
import 'package:mauritanie_news/shared/models/article_model.dart';
import 'package:mauritanie_news/shared/models/category_model.dart';
import 'package:mauritanie_news/features/webview/ui/article_webview_screen.dart';

/// Carte article pour la liste agence (liste + actions modifier / supprimer).
class ArticleCardAgency extends StatelessWidget {
  const ArticleCardAgency({
    super.key,
    required this.article,
    required this.category,
    this.animation,
    required this.onDeleted,
    required this.onEdit,
  });

  final ArticleModel article;
  final CategoryModel? category;
  final Animation<double>? animation;
  final VoidCallback onDeleted;
  final VoidCallback onEdit;

  String _formatDate(DateTime d) {
    return DateFormat("d MMM yyyy 'à' HH:mm", 'fr_FR').format(d);
  }

  String _shortUrl(String url) {
    if (url.length <= 42) return url;
    return '${url.substring(0, 39)}…';
  }

  Color _categoryColorFromHexOrDefault(String? colorHex) {
    final v = (colorHex ?? '').trim().toLowerCase();
    switch (v) {
      case '#ef4444':
        return AppColors.catPolitique;
      case '#f59e0b':
        return AppColors.catEconomie;
      case '#10b981':
        return AppColors.catSport;
      case '#3b82f6':
        return AppColors.catTechno;
      case '#8b5cf6':
        return AppColors.catSociete;
      case '#ec4899':
        return AppColors.catSante;
      case '#f97316':
        return AppColors.catCulture;
      case '#06b6d4':
        return AppColors.catInternational;
      default:
        return AppColors.primary;
    }
  }

  void _openWebView(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ArticleWebViewScreen(
          url: article.sourceUrl,
          title: article.title,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cover = article.coverImageUrl;

    final categoryLocale = Locale(article.language.name);
    final categoryLabel = category?.name(categoryLocale) ?? '';
    final categoryIcon = category?.icon ?? '';
    final catColor = _categoryColorFromHexOrDefault(category?.colorHex);

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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openWebView(context),
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
                        child: cover == null || cover.trim().isEmpty
                            ? Container(
                                color: AppColors.surfaceVariant,
                                alignment: Alignment.center,
                                child: const Icon(
                                  Icons.image_not_supported_outlined,
                                  color: AppColors.textTertiary,
                                ),
                              )
                            : CachedNetworkImage(
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
                                  child: const Icon(
                                    Icons.image_not_supported_outlined,
                                    color: AppColors.textTertiary,
                                  ),
                                ),
                              ),
                      ),
                    ),
                  ),
                  if (categoryLabel.isNotEmpty)
                    Positioned(
                      top: AppSpacing.sm,
                      left: AppSpacing.sm,
                      child: _CategoryBadge(
                        label: '$categoryIcon $categoryLabel'.trim(),
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
                    InkWell(
                      onTap: () => _openWebView(context),
                      child: Text(
                        _shortUrl(article.sourceUrl),
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.info,
                          decoration: TextDecoration.underline,
                          decorationColor: AppColors.info,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                      child: Divider(height: 1, color: AppColors.divider),
                    ),
                    Row(
                      children: [
                        TextButton.icon(
                          onPressed: onEdit,
                          icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.primary),
                          label: Text(
                            'Modifier',
                            style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary),
                          ),
                        ),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: () async {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (_) => DeleteConfirmDialog(
                                articleId: article.id,
                                articleTitle: article.title,
                              ),
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
        ),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: AppRadius.chipRadius,
      ),
      child: Text(
        label,
        style: AppTextStyles.labelMedium.copyWith(color: AppColors.textOnPrimary, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _LangBadge extends StatelessWidget {
  const _LangBadge({required this.language});

  final ArticleLanguage language;

  @override
  Widget build(BuildContext context) {
    final isFr = language == ArticleLanguage.fr;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.92),
        borderRadius: AppRadius.chipRadius,
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        isFr ? 'FR' : 'AR',
        style: AppTextStyles.labelMedium.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
      ),
    );
  }
}
