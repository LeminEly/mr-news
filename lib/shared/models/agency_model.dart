import 'package:freezed_annotation/freezed_annotation.dart';

part 'agency_model.freezed.dart';
part 'agency_model.g.dart';

enum AgencyStatus { pending, approved, rejected, suspended }
enum MediaType {
  @JsonValue('news_agency')
  newsAgency,
  @JsonValue('newspaper')
  newspaper,
  @JsonValue('blog')
  blog,
  @JsonValue('tv_channel')
  tvChannel,
  @JsonValue('radio')
  radio,
  @JsonValue('other')
  other,
}

@freezed
class AgencyModel with _$AgencyModel {
  const factory AgencyModel({
    required String id,
    required String authUserId,
    required String name,
    required String email,
    String? logoUrl,
    String? websiteUrl,
    required MediaType mediaType,
    required AgencyStatus status,
    String? rejectReason,
    required DateTime createdAt,
    DateTime? validatedAt,
  }) = _AgencyModel;

  factory AgencyModel.fromJson(Map<String, dynamic> json) =>
      _$AgencyModelFromJson(json);

  /// Parsing robuste pour les maps Supabase (snake_case + enums Postgres).
  /// Permet d'éviter une dépendance stricte à la génération quand l'énum côté DB
  /// diffère du naming Dart (ex: `news_agency` vs `newsAgency`).
  factory AgencyModel.fromSupabase(Map<String, dynamic> row) {
    MediaType parseMediaType(String v) {
      switch (v) {
        case 'news_agency':
          return MediaType.newsAgency;
        case 'newspaper':
          return MediaType.newspaper;
        case 'blog':
          return MediaType.blog;
        case 'tv_channel':
          return MediaType.tvChannel;
        case 'radio':
          return MediaType.radio;
        case 'other':
        default:
          return MediaType.other;
      }
    }

    AgencyStatus parseStatus(String v) {
      switch (v) {
        case 'approved':
          return AgencyStatus.approved;
        case 'rejected':
          return AgencyStatus.rejected;
        case 'suspended':
          return AgencyStatus.suspended;
        case 'pending':
        default:
          return AgencyStatus.pending;
      }
    }

    final mediaRaw = (row['media_type'] ?? 'other').toString();
    final statusRaw = (row['status'] ?? 'pending').toString();

    return AgencyModel(
      id: row['id'].toString(),
      authUserId: row['auth_user_id'].toString(),
      name: (row['name'] ?? '').toString(),
      email: (row['email'] ?? '').toString(),
      logoUrl: row['logo_url']?.toString(),
      websiteUrl: row['website_url']?.toString(),
      mediaType: parseMediaType(mediaRaw),
      status: parseStatus(statusRaw),
      rejectReason: row['reject_reason']?.toString(),
      createdAt: DateTime.parse(row['created_at'].toString()),
      validatedAt: row['validated_at'] == null
          ? null
          : DateTime.parse(row['validated_at'].toString()),
    );
  }
}

// Helpers

extension AgencyStatusX on AgencyStatus {
  String get label {
    switch (this) {
      case AgencyStatus.pending:   return 'En attente';
      case AgencyStatus.approved:  return 'Approuvée';
      case AgencyStatus.rejected:  return 'Rejetée';
      case AgencyStatus.suspended: return 'Suspendue';
    }
  }

  bool get canPublish => this == AgencyStatus.approved;
}