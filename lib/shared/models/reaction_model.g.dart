// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reaction_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ReactionModelImpl _$$ReactionModelImplFromJson(Map<String, dynamic> json) =>
    _$ReactionModelImpl(
      id: json['id'] as String,
      articleId: json['article_id'] as String,
      deviceId: json['device_id'] as String,
      emojiType: $enumDecode(_$EmojiTypeEnumMap, json['emoji_type']),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$$ReactionModelImplToJson(_$ReactionModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'article_id': instance.articleId,
      'device_id': instance.deviceId,
      'emoji_type': _$EmojiTypeEnumMap[instance.emojiType]!,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };

const _$EmojiTypeEnumMap = {
  EmojiType.like: 'like',
  EmojiType.wow: 'wow',
  EmojiType.sad: 'sad',
  EmojiType.angry: 'angry',
  EmojiType.fire: 'fire',
};
