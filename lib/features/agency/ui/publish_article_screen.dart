import 'package:flutter/material.dart';

import 'package:mauritanie_news/shared/theme/app_theme.dart';

import 'package:mauritanie_news/features/agency/ui/agency_article_form.dart';
import 'package:mauritanie_news/features/agency/ui/mock_article.dart';

/// Écran publication d’article (mock — pas de backend).
class PublishArticleScreen extends StatefulWidget {
  const PublishArticleScreen({super.key});

  @override
  State<PublishArticleScreen> createState() => _PublishArticleScreenState();
}

class _PublishArticleScreenState extends State<PublishArticleScreen>
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

  void _onSuccess(MockArticle article) {
    // TODO: connect to Supabase — insérer l’article puis invalider le cache.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.success,
        content: Text(
          'Article publié avec succès !',
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textOnPrimary),
        ),
      ),
    );
    Navigator.of(context).pop<MockArticle>(article);
  }

  @override
  Widget build(BuildContext context) {
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
              title: Text(
                'Publier un article',
                style: AppTextStyles.headlineMedium.copyWith(color: AppColors.textOnPrimary),
              ),
            );
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.pagePadding,
          child: AgencyArticleForm(
            mode: AgencyFormMode.publish,
            onPrimarySuccess: _onSuccess,
          ),
        ),
      ),
    );
  }
}
