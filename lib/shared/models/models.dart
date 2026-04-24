export 'article_model.dart';
export 'category_model.dart';
export 'agency_model.dart';

enum EmojiType { like, wow, sad, angry, fire }

enum ReportReason { spam, falseInfo, offensive, other }

class ReactionCounts {
  final int likeCount;
  final int wowCount;
  final int sadCount;
  final int angryCount;
  final int fireCount;

  int get total => likeCount + wowCount + sadCount + angryCount + fireCount;

  const ReactionCounts({
    this.likeCount = 0,
    this.wowCount = 0,
    this.sadCount = 0,
    this.angryCount = 0,
    this.fireCount = 0,
  });

  factory ReactionCounts.fromJson(Map<String, dynamic> json) => ReactionCounts(
        likeCount: json['like'] ?? 0,
        wowCount: json['wow'] ?? 0,
        sadCount: json['sad'] ?? 0,
        angryCount: json['angry'] ?? 0,
        fireCount: json['fire'] ?? 0,
      );
}

