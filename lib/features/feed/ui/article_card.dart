import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/models/article_model.dart';
import '../providers/feed_providers.dart';
import '../../../app/router.dart';
import '../../../main.dart';

class ArticleCard extends ConsumerWidget {
  final ArticleModel article;

  const ArticleCard({
    super.key,
    required this.article,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(appLocaleProvider);
    final isRtl = article.language == ArticleLanguage.ar;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: AppRadius.cardRadius,
        boxShadow: AppShadows.card,
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
      ),
      child: ClipRRect(
        borderRadius: AppRadius.cardRadius,
        child: InkWell(
          onTap: () => context.push(
            AppRoutes.articleWebView,
            extra: {
              'url': article.sourceUrl,
              'title': article.title,
              'articleId': article.id,
            },
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Cover Image
              if (article.coverImageUrl != null)
                Hero(
                  tag: 'article_image_${article.id}',
                  child: CachedNetworkImage(
                    imageUrl: article.coverImageUrl!,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      height: 200,
                      color: AppColors.surfaceVariant,
                      child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      height: 200,
                      color: AppColors.surfaceVariant,
                      child: const Icon(Icons.broken_image_outlined,
                          color: AppColors.textTertiary),
                    ),
                  ),
                ),

              Padding(
                padding: AppSpacing.cardPadding,
                child: Column(
                  crossAxisAlignment: isRtl ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    // Meta: Category & Date
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _CategoryBadge(
                          label: article.categoryName(locale) ?? '',
                          colorHex: article.categoryColor ?? '#64748B',
                          icon: article.categoryIcon,
                        ),
                        Text(
                          _formatDate(article.publishedAt, locale.languageCode),
                          style: AppTextStyles.meta,
                        ),
                      ],
                    ),
                    const Gap(AppSpacing.md),

                    // Title
                    Text(
                      article.title,
                      style: isRtl
                          ? AppTextStyles.articleTitleAr
                          : AppTextStyles.articleTitle,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      textAlign: isRtl ? TextAlign.right : TextAlign.left,
                    ),
                    const Gap(AppSpacing.md),

                    // Source & Actions
                    Row(
                      children: [
                        // Agency Info
                        if (article.agencyLogoUrl != null)
                          CircleAvatar(
                            radius: 12,
                            backgroundImage: CachedNetworkImageProvider(article.agencyLogoUrl!),
                          )
                        else
                          const CircleAvatar(
                            radius: 12,
                            backgroundColor: AppColors.primarySurface,
                            child: Icon(Icons.business, size: 14, color: AppColors.primary),
                          ),
                        const Gap(AppSpacing.sm),
                        Expanded(
                          child: Text(
                            article.agencyName ?? 'Source inconnue',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),

                        // Reactions Summary
                        _ReactionsSummary(article: article),

                        // Share Action
                        IconButton(
                          onPressed: () => Share.share('${article.title}\n\n${article.sourceUrl}'),
                          icon: const Icon(Icons.share_outlined, size: 20),
                          color: AppColors.textSecondary,
                          visualDensity: VisualDensity.compact,
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
  }

  String _formatDate(DateTime date, String lang) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 60) {
      return lang == 'ar' ? 'منذ ${difference.inMinutes} د' : 'Il y a ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return lang == 'ar' ? 'منذ ${difference.inHours} س' : 'Il y a ${difference.inHours} h';
    } else {
      return DateFormat.MMMd(lang).format(date);
    }
  }
}

class _CategoryBadge extends StatelessWidget {
  final String label;
  final String colorHex;
  final String? icon;

  const _CategoryBadge({
    required this.label,
    required this.colorHex,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final color = Color(int.parse(colorHex.replaceAll('#', '0xFF')));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: AppRadius.chipRadius,
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Text(icon!, style: const TextStyle(fontSize: 12)),
            const Gap(4),
          ],
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _ReactionsSummary extends StatelessWidget {
  final ArticleModel article;

  const _ReactionsSummary({required this.article});

  @override
  Widget build(BuildContext context) {
    final total = article.reactionCounts.total;
    if (total == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      margin: const EdgeInsets.only(right: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: AppRadius.chipRadius,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.auto_awesome, size: 12, color: AppColors.accent),
          const Gap(4),
          Text(
            '$total',
            style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
