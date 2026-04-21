
import 'package:freezed_annotation/freezed_annotation.dart';

part 'reaction_model.freezed.dart';
part 'reaction_model.g.dart';

enum EmojiType { like, wow, sad, angry, fire }

@freezed
class ReactionModel with _$ReactionModel {
  const factory ReactionModel({
    required String id,
    required String articleId,
    required String deviceId,
    required EmojiType emojiType,
    required DateTime createdAt,
    DateTime? updatedAt,
  }) = _ReactionModel;

  factory ReactionModel.fromJson(Map<String, dynamic> json) =>
      _$ReactionModelFromJson(json);
}

extension EmojiTypeX on EmojiType {
  String get emoji {
    switch (this) {
      case EmojiType.like:  return '👍';
      case EmojiType.wow:   return '😮';
      case EmojiType.sad:   return '😢';
      case EmojiType.angry: return '😡';
      case EmojiType.fire:  return '🔥';
    }
  }

  String get label {
    switch (this) {
      case EmojiType.like:  return 'J\'aime';
      case EmojiType.wow:   return 'Surpris';
      case EmojiType.sad:   return 'Triste';
      case EmojiType.angry: return 'Faché';
      case EmojiType.fire:  return 'Chaud';
    }
  }
}
