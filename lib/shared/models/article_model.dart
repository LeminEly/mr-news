import 'package:freezed_annotation/freezed_annotation.dart';

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
  }) = _ArticleModel;

  factory ArticleModel.fromJson(Map<String, dynamic> json) =>
      _$ArticleModelFromJson(json);
}

// Helpers

extension ArticleModelX on ArticleModel {
  bool get isRtl => language == ArticleLanguage.ar;

  String categoryName(String locale) => '';
}