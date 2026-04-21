import 'package:freezed_annotation/freezed_annotation.dart';

part 'report_model.freezed.dart';
part 'report_model.g.dart';

enum ReportReason { fakeNews, inappropriate, brokenLink, duplicate, other }
enum ReportStatus { pending, resolved, dismissed }

@freezed
class ReportModel with _$ReportModel {
  const factory ReportModel({
    required String id,
    required String articleId,
    required String deviceId,
    required ReportReason reason,
    required ReportStatus status,
    required DateTime createdAt,
    DateTime? resolvedAt,
  }) = _ReportModel;

  factory ReportModel.fromJson(Map<String, dynamic> json) =>
      _$ReportModelFromJson(json);
}

extension ReportReasonX on ReportReason {
  String get labelFr {
    switch (this) {
      case ReportReason.fakeNews:      return 'Fausse information';
      case ReportReason.inappropriate: return 'Contenu inapproprié';
      case ReportReason.brokenLink:    return 'Lien cassé';
      case ReportReason.duplicate:     return 'Article dupliqué';
      case ReportReason.other:         return 'Autre';
    }
  }

  String get labelAr {
    switch (this) {
      case ReportReason.fakeNews:      return 'معلومة مزيفة';
      case ReportReason.inappropriate: return 'محتوى غير لائق';
      case ReportReason.brokenLink:    return 'رابط معطل';
      case ReportReason.duplicate:     return 'مقال مكرر';
      case ReportReason.other:         return 'أخرى';
    }
  }
}