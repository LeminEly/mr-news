// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'report_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ReportModelImpl _$$ReportModelImplFromJson(Map<String, dynamic> json) =>
    _$ReportModelImpl(
      id: json['id'] as String,
      articleId: json['article_id'] as String,
      deviceId: json['device_id'] as String,
      reason: $enumDecode(_$ReportReasonEnumMap, json['reason']),
      status: $enumDecode(_$ReportStatusEnumMap, json['status']),
      createdAt: DateTime.parse(json['created_at'] as String),
      resolvedAt: json['resolved_at'] == null
          ? null
          : DateTime.parse(json['resolved_at'] as String),
    );

Map<String, dynamic> _$$ReportModelImplToJson(_$ReportModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'article_id': instance.articleId,
      'device_id': instance.deviceId,
      'reason': _$ReportReasonEnumMap[instance.reason]!,
      'status': _$ReportStatusEnumMap[instance.status]!,
      'created_at': instance.createdAt.toIso8601String(),
      'resolved_at': instance.resolvedAt?.toIso8601String(),
    };

const _$ReportReasonEnumMap = {
  ReportReason.spam: 'spam',
  ReportReason.falseInfo: 'falseInfo',
  ReportReason.offensive: 'offensive',
  ReportReason.other: 'other',
};

const _$ReportStatusEnumMap = {
  ReportStatus.pending: 'pending',
  ReportStatus.resolved: 'resolved',
  ReportStatus.dismissed: 'dismissed',
};
