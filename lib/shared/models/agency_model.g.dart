// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'agency_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AgencyModelImpl _$$AgencyModelImplFromJson(Map<String, dynamic> json) =>
    _$AgencyModelImpl(
      id: json['id'] as String,
      authUserId: json['auth_user_id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      logoUrl: json['logo_url'] as String?,
      websiteUrl: json['website_url'] as String?,
      documentUrl: json['document_url'] as String?,
      mediaType: $enumDecode(_$MediaTypeEnumMap, json['media_type']),
      status: $enumDecode(_$AgencyStatusEnumMap, json['status']),
      rejectReason: json['reject_reason'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      validatedAt: json['validated_at'] == null
          ? null
          : DateTime.parse(json['validated_at'] as String),
    );

Map<String, dynamic> _$$AgencyModelImplToJson(_$AgencyModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'auth_user_id': instance.authUserId,
      'name': instance.name,
      'email': instance.email,
      'logo_url': instance.logoUrl,
      'website_url': instance.websiteUrl,
      'document_url': instance.documentUrl,
      'media_type': _$MediaTypeEnumMap[instance.mediaType]!,
      'status': _$AgencyStatusEnumMap[instance.status]!,
      'reject_reason': instance.rejectReason,
      'created_at': instance.createdAt.toIso8601String(),
      'validated_at': instance.validatedAt?.toIso8601String(),
    };

const _$MediaTypeEnumMap = {
  MediaType.newsAgency: 'news_agency',
  MediaType.newspaper: 'newspaper',
  MediaType.blog: 'blog',
  MediaType.tvChannel: 'tv_channel',
  MediaType.radio: 'radio',
  MediaType.other: 'other',
};

const _$AgencyStatusEnumMap = {
  AgencyStatus.pending: 'pending',
  AgencyStatus.accepted: 'accepted',
  AgencyStatus.rejected: 'rejected',
  AgencyStatus.suspended: 'suspended',
};
