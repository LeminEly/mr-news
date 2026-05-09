import 'package:freezed_annotation/freezed_annotation.dart';
import 'models.dart';

part 'report_model.freezed.dart';
part 'report_model.g.dart';

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
      case ReportReason.spam:
        return 'Spam';
      case ReportReason.falseInfo:
        return 'Fausse information';
      case ReportReason.offensive:
        return 'Contenu offensant';
      case ReportReason.other:
        return 'Autre';
    }
  }

  String get labelAr {
    switch (this) {
      case ReportReason.spam:
        return 'رسائل مزعجة';
      case ReportReason.falseInfo:
        return 'معلومة مزيفة';
      case ReportReason.offensive:
        return 'محتوى مسيء';
      case ReportReason.other:
        return 'أخرى';
    }
  }
}
