// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'article_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ArticleModelImpl _$$ArticleModelImplFromJson(Map<String, dynamic> json) =>
    _$ArticleModelImpl(
      id: json['id'] as String,
      agencyId: json['agency_id'] as String,
      categoryId: json['category_id'] as String?,
      title: json['title'] as String,
      sourceUrl: json['source_url'] as String,
      coverImageUrl: json['cover_image_url'] as String?,
      language: $enumDecode(_$ArticleLanguageEnumMap, json['language']),
      isActive: json['is_active'] as bool,
      publishedAt: DateTime.parse(json['published_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$$ArticleModelImplToJson(_$ArticleModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'agency_id': instance.agencyId,
      'category_id': instance.categoryId,
      'title': instance.title,
      'source_url': instance.sourceUrl,
      'cover_image_url': instance.coverImageUrl,
      'language': _$ArticleLanguageEnumMap[instance.language]!,
      'is_active': instance.isActive,
      'published_at': instance.publishedAt.toIso8601String(),
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };

const _$ArticleLanguageEnumMap = {
  ArticleLanguage.ar: 'ar',
  ArticleLanguage.fr: 'fr',
};
