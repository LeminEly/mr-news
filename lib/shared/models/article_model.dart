import 'package:freezed_annotation/freezed_annotation.dart';
import 'category_model.dart';

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
    DateTime? updatedAt,
    // Champs joints (depuis articles_with_details view)
    String? agencyName,
    String? agencyLogoUrl,
    String? agencyWebsite,
    String? categoryNameAr,
    String? categoryNameFr,
    String? categoryIcon,
    String? categoryColor,
    // Réactions
    @Default(ReactionCounts()) ReactionCounts reactionCounts,
  }) = _ArticleModel;

  factory ArticleModel.fromJson(Map<String, dynamic> json) =>
      _$ArticleModelFromJson(json);
}

// Reaction Counts

@freezed
class ReactionCounts with _$ReactionCounts {
  const factory ReactionCounts({
    @Default(0) int likeCount,
    @Default(0) int wowCount,
    @Default(0) int sadCount,
    @Default(0) int angryCount,
    @Default(0) int fireCount,
  }) = _ReactionCounts;

  factory ReactionCounts.fromJson(Map<String, dynamic> json) =>
      _$ReactionCountsFromJson(json);
}

extension ReactionCountsX on ReactionCounts {
  int get total => likeCount + wowCount + sadCount + angryCount + fireCount;
}

// Helpers

extension ArticleModelX on ArticleModel {
  bool get isRtl => language == ArticleLanguage.ar;

  String categoryName(String locale) =>
      locale == 'ar' ? (categoryNameAr ?? '') : (categoryNameFr ?? '');
}