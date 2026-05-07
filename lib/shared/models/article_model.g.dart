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
      agencyName: json['agency_name'] as String?,
      agencyLogoUrl: json['agency_logo_url'] as String?,
      categoryNameAr: json['category_name_ar'] as String?,
      categoryNameFr: json['category_name_fr'] as String?,
      categoryIcon: json['category_icon'] as String?,
      categoryColor: json['category_color'] as String?,
      reactionCounts: json['reaction_counts'] == null
          ? const ReactionCounts()
          : ReactionCounts.fromJson(
              json['reaction_counts'] as Map<String, dynamic>),
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
      'agency_name': instance.agencyName,
      'agency_logo_url': instance.agencyLogoUrl,
      'category_name_ar': instance.categoryNameAr,
      'category_name_fr': instance.categoryNameFr,
      'category_icon': instance.categoryIcon,
      'category_color': instance.categoryColor,
      'reaction_counts': instance.reactionCounts,
    };

const _$ArticleLanguageEnumMap = {
  ArticleLanguage.ar: 'ar',
  ArticleLanguage.fr: 'fr',
};
