import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import 'package:gap/gap.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/reader_drawer.dart';
import '../providers/feed_providers.dart';
import 'article_card.dart';
import 'date_banner.dart';
import 'category_filter.dart';
import '../../../main.dart';

class FeedScreen extends ConsumerWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final articlesAsync = ref.watch(feedArticlesProvider);
    final locale = ref.watch(appLocaleProvider);
    final isAr = locale.languageCode == 'ar';
    final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

    return Scaffold(
      key: scaffoldKey,
      backgroundColor: AppColors.background,
      drawer: const ReaderDrawer(),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(feedArticlesProvider),
        child: CustomScrollView(
          slivers: [
            // Custom App Bar
            SliverAppBar(
              floating: true,
              pinned: false,
              centerTitle: false,
              backgroundColor: AppColors.surface,
              leading: IconButton(
                icon: const Icon(Icons.menu_rounded, color: AppColors.primary),
                onPressed: () => scaffoldKey.currentState?.openDrawer(),
              ),
              title: Text(
                isAr ? 'موريتانيا نيوز' : 'Mauritanie News',
                style: AppTextStyles.headlineLarge.copyWith(
                  color: AppColors.primary,
                  letterSpacing: isAr ? 0 : -0.5,
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.search_rounded, color: AppColors.textSecondary),
                  onPressed: () {
                    // TODO: Implement Search
                  },
                ),
                const Gap(AppSpacing.sm),
              ],
            ),

            // Fixed Filters (Date & Category)
            SliverToBoxAdapter(
              child: Column(
                children: [
                  const DateBanner(),
                  const CategoryFilter(),
                  const Gap(AppSpacing.sm),
                ],
              ),
            ),

            // Articles List
            articlesAsync.when(
              data: (articles) {
                if (articles.isEmpty) {
                  return const SliverFillRemaining(
                    child: _EmptyState(),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => ArticleCard(article: articles[index]),
                      childCount: articles.length,
                    ),
                  ),
                );
              },
              loading: () => const SliverFillRemaining(
                child: _LoadingState(),
              ),
              error: (error, stack) => SliverFillRemaining(
                child: _ErrorState(message: error.toString()),
              ),
            ),
            
            // Bottom Padding
            const SliverToBoxAdapter(child: Gap(AppSpacing.huge)),
          ],
        ),
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Shimmer.fromColors(
        baseColor: AppColors.surfaceVariant,
        highlightColor: AppColors.surface,
        child: Column(
          children: List.generate(3, (index) => Container(
            height: 280,
            margin: const EdgeInsets.only(bottom: AppSpacing.lg),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: AppRadius.cardRadius,
            ),
          )),
        ),
      ),
    );
  }
}

class _EmptyState extends ConsumerWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAr = ref.watch(appLocaleProvider).languageCode == 'ar';
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.newspaper, size: 64, color: AppColors.textTertiary),
          const Gap(AppSpacing.lg),
          Text(
            isAr ? 'لا توجد مقالات متاحة' : 'Aucun article disponible',
            style: AppTextStyles.headlineSmall.copyWith(color: AppColors.textSecondary),
          ),
          const Gap(AppSpacing.sm),
          Text(
            isAr ? 'حاول تغيير التاريخ أو الفئة' : 'Essayez une autre date ou catégorie',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textTertiary),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  const _ErrorState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const Gap(AppSpacing.md),
            Text(
              'Oups ! Une erreur est survenue',
              style: AppTextStyles.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const Gap(AppSpacing.sm),
            Text(
              message,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textTertiary),
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }
}
