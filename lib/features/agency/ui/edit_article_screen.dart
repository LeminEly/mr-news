import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:mauritanie_news/shared/theme/app_theme.dart';

import 'package:mauritanie_news/features/agency/ui/agency_article_form.dart';
import 'package:mauritanie_news/features/agency/ui/mock_article.dart';

/// Écran modification d’article (mock — pas de backend).
class EditArticleScreen extends StatefulWidget {
  const EditArticleScreen({super.key, required this.article});

  final MockArticle article;

  @override
  State<EditArticleScreen> createState() => _EditArticleScreenState();
}

class _EditArticleScreenState extends State<EditArticleScreen>
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

  void _onSaved(MockArticle article) {
    // TODO: connect to Supabase — mettre à jour l’article (upsert).
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.success,
        content: Text(
          'Modifications enregistrées (mock)',
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textOnPrimary),
        ),
      ),
    );
    Navigator.of(context).pop<MockArticle>(article);
  }

  @override
  Widget build(BuildContext context) {
    final last = widget.article.lastModifiedAt ?? widget.article.publishedAt;

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
                  border: Border.all(color: AppColors.warning.withValues(alpha: 0.35)),
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
                onPrimarySuccess: _onSaved,
                onCancel: () => Navigator.of(context).maybePop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
