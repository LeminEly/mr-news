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

