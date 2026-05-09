import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:go_router/go_router.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/models/article_model.dart';
import '../../../app/router.dart';
import '../../feed/providers/feed_providers.dart';
import 'admin_drawer.dart';

final adminArticlesProvider = FutureProvider.autoDispose<List<ArticleModel>>((ref) async {
  return ref.watch(adminRepositoryProvider).getAllArticles();
});

class ArticlesManagementScreen extends ConsumerStatefulWidget {
  const ArticlesManagementScreen({super.key});

  @override
  ConsumerState<ArticlesManagementScreen> createState() => _ArticlesManagementScreenState();
}

class _ArticlesManagementScreenState extends ConsumerState<ArticlesManagementScreen> {
  @override
  Widget build(BuildContext context) {
    final articlesAsync = ref.watch(adminArticlesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        title: Text(
          'Gestion des Articles',
          style: AppTextStyles.headlineSmall.copyWith(color: AppColors.textOnPrimary),
        ),
      ),
      drawer: const AdminDrawer(),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(adminArticlesProvider.future),
        child: articlesAsync.when(
          data: (articles) {
            if (articles.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.article_outlined, size: 64, color: AppColors.textTertiary),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Aucun article trouvé',
                      style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              );
            }

            return ListView.separated(
              padding: AppSpacing.pagePadding,
              itemCount: articles.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, index) {
                final article = articles[index];
                return _ArticleManagementCard(article: article);
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, __) => Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Text('Erreur: $err', style: const TextStyle(color: AppColors.error), textAlign: TextAlign.center),
            ),
          ),
        ),
      ),
    );
  }
}

class _ArticleManagementCard extends ConsumerWidget {
  final ArticleModel article;
  const _ArticleManagementCard({required this.article});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateStr = DateFormat('d MMM yyyy HH:mm', 'fr_FR').format(article.publishedAt);
    
    return Card(
      elevation: 0,
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.cardRadius,
        side: BorderSide(color: AppColors.border.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            contentPadding: const EdgeInsets.all(AppSpacing.md),
            leading: Container(
              width: 60,
              height: 60,
              decoration: const BoxDecoration(
                borderRadius: AppRadius.imageRadius,
                color: AppColors.surfaceVariant,
              ),
              child: ClipRRect(
                borderRadius: AppRadius.imageRadius,
                child: article.coverImageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: article.coverImageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                        errorWidget: (_, __, ___) => const Icon(Icons.image_not_supported_outlined),
                      )
                    : const Icon(Icons.article_outlined, color: AppColors.textTertiary),
              ),
            ),
            title: Text(
              article.title,
              style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.bold),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text('Publié le $dateStr', style: AppTextStyles.meta),
                Text('Langue: ${article.language.name.toUpperCase()}', style: AppTextStyles.meta),
              ],
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (val) async {
                if (val == 'delete') {
                  final confirmed = await _showDeleteConfirm(context);
                  if (confirmed == true) {
                    await ref.read(adminRepositoryProvider).deleteArticle(article.id);
                    ref.invalidate(adminArticlesProvider);
                    ref.invalidate(adminStatsProvider);
                  }
                } else if (val == 'toggle') {
                  await ref.read(adminRepositoryProvider).toggleArticleStatus(article.id, !article.isActive);
                  ref.invalidate(adminArticlesProvider);
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'toggle',
                  child: Row(
                    children: [
                      Icon(article.isActive ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
                      const SizedBox(width: 8),
                      Text(article.isActive ? 'Masquer' : 'Afficher'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                      SizedBox(width: 8),
                      Text('Supprimer', style: TextStyle(color: AppColors.error)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: AppSpacing.md, right: AppSpacing.md, bottom: AppSpacing.md),
            child: Row(
              children: [
                _StatusChip(isActive: article.isActive),
                const Spacer(),
                TextButton.icon(
                  onPressed: () {
                    context.push(
                      AppRoutes.articleWebView,
                      extra: {
                        'url': article.sourceUrl,
                        'title': article.title,
                      },
                    );
                  },
                  icon: const Icon(Icons.open_in_new, size: 16),
                  label: const Text('Voir l\'article'),
                  style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showDeleteConfirm(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer l\'article ?'),
        content: const Text('Cette action est irréversible. L\'article sera définitivement supprimé.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final bool isActive;
  const _StatusChip({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: (isActive ? AppColors.success : AppColors.error).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        isActive ? 'ACTIF' : 'INACTIF',
        style: AppTextStyles.meta.copyWith(
          color: isActive ? AppColors.success : AppColors.error,
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
      ),
    );
  }
}
