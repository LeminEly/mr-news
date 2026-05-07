import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'models.dart';

part 'article_model.freezed.dart';
part 'article_model.g.dart';

enum ArticleLanguage { ar, fr }

@freezed
class ArticleModel with _$ArticleModel {
  const factory ArticleModel({
    required String id,
    required String agencyId,
    String? categoryId,
    required String title,
    required String sourceUrl,
    String? coverImageUrl,
    required ArticleLanguage language,
    required bool isActive,
    required DateTime publishedAt,
    required DateTime createdAt,
    required DateTime updatedAt,
    
    // Joined fields
    String? agencyName,
    String? agencyLogoUrl,
    String? categoryNameAr,
    String? categoryNameFr,
    String? categoryIcon,
    String? categoryColor,
    @Default(ReactionCounts()) ReactionCounts reactionCounts,
  }) = _ArticleModel;

  factory ArticleModel.fromJson(Map<String, dynamic> json) =>
      _$ArticleModelFromJson(json);
}

// Helpers

extension ArticleModelX on ArticleModel {
  bool get isRtl => language == ArticleLanguage.ar;

  String? categoryName(Locale locale) {
    return locale.languageCode == 'ar' ? categoryNameAr : categoryNameFr;
  }
}