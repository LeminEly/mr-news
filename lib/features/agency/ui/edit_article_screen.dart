import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import 'package:mauritanie_news/shared/theme/app_theme.dart';

import 'package:mauritanie_news/features/agency/ui/agency_article_form.dart';
import 'package:mauritanie_news/features/feed/providers/feed_providers.dart';
import 'package:mauritanie_news/shared/models/article_model.dart';
import 'package:mauritanie_news/shared/models/category_model.dart';

/// Écran modification d’article (Supabase).
class EditArticleScreen extends ConsumerStatefulWidget {
  const EditArticleScreen({
    super.key,
    required this.article,
    required this.categories,
  });

  final ArticleModel article;
  final List<CategoryModel> categories;

  @override
  ConsumerState<EditArticleScreen> createState() => _EditArticleScreenState();
}

class _EditArticleScreenState extends ConsumerState<EditArticleScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _gradientCtrl;

  @override
  void initState() {
    super.initState();
    _gradientCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _gradientCtrl.dispose();
    super.dispose();
  }

  String _formatDate(DateTime d) {
    return DateFormat("d MMM yyyy 'à' HH:mm", 'fr_FR').format(d);
  }

  @override
  Widget build(BuildContext context) {
    final last = widget.article.updatedAt;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: AnimatedBuilder(
          animation: _gradientCtrl,
          builder: (context, _) {
            final t = CurvedAnimation(parent: _gradientCtrl, curve: Curves.easeInOut).value;
            return AppBar(
              iconTheme: const IconThemeData(color: AppColors.textOnPrimary),
              flexibleSpace: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color.lerp(AppColors.primary, AppColors.secondary, t)!,
                      Color.lerp(AppColors.secondary, AppColors.primary, t)!,
                    ],
                  ),
                ),
              ),
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Modifier l’article',
                      style: AppTextStyles.headlineMedium.copyWith(color: AppColors.textOnPrimary),
                    ),
                  ),
                  Container(
                    padding: AppSpacing.chipPadding,
                    decoration: const BoxDecoration(
                      color: AppColors.warningLight,
                      borderRadius: AppRadius.chipRadius,
                    ),
                    child: Text(
                      'Modifié',
                      style: AppTextStyles.labelMedium.copyWith(color: AppColors.warning),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.pagePadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: AppSpacing.cardPadding,
                decoration: BoxDecoration(
                  color: AppColors.warningLight,
                  borderRadius: AppRadius.cardRadius,
                  border: Border.all(color: AppColors.warning.withOpacity(0.35)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.schedule, color: AppColors.warning, size: 20),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'Dernière modification : ${_formatDate(last)}',
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textPrimary),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              AgencyArticleForm(
                mode: AgencyFormMode.edit,
                initial: widget.article,
                categories: widget.categories,
                uploadPickedCover: (XFile file) async {
                  final bytes = await file.readAsBytes();
                  var ext = file.path.split('.').last.toLowerCase();
                  if (ext.isEmpty || ext.length > 8) ext = 'jpg';
                  ext = ext.replaceFirst(RegExp(r'^\.'), '');
                  return ref.read(agencyRepositoryProvider).uploadArticleCover(
                        agencyId: widget.article.agencyId,
                        bytes: bytes,
                        fileExt: ext,
                      );
                },
                onSubmit: ({
                  required String title,
                  required String sourceUrl,
                  String? coverImageUrl,
                  required String categoryId,
                  required ArticleLanguage language,
                }) async {
                  final messenger = ScaffoldMessenger.of(context);
                  final navigator = Navigator.of(context);
                  try {
                    await ref.read(agencyRepositoryProvider).updateArticle(
                          articleId: widget.article.id,
                          title: title,
                          sourceUrl: sourceUrl,
                          coverImageUrl: coverImageUrl,
                          categoryId: categoryId,
                          language: language,
                        );
                    if (!mounted) return true;
                    messenger.showSnackBar(
                      SnackBar(
                        backgroundColor: AppColors.success,
                        content: Text(
                          'Modifications enregistrées',
                          style: AppTextStyles.bodyMedium
                              .copyWith(color: AppColors.textOnPrimary),
                        ),
                      ),
                    );
                    navigator.pop(true);
                    return true;
                  } catch (_) {
                    if (!mounted) return false;
                    messenger.showSnackBar(
                      SnackBar(
                        backgroundColor: AppColors.error,
                        content: Text(
                          'Erreur lors de la mise à jour',
                          style: AppTextStyles.bodyMedium
                              .copyWith(color: AppColors.textOnPrimary),
                        ),
                      ),
                    );
                    return false;
                  }
                },
                onCancel: () => Navigator.of(context).maybePop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
