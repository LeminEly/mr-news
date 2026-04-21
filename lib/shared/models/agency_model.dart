import 'package:freezed_annotation/freezed_annotation.dart';

part 'agency_model.freezed.dart';
part 'agency_model.g.dart';

enum AgencyStatus { pending, approved, rejected, suspended }
enum MediaType { newsAgency, newspaper, blog, tvChannel, radio, other }

@freezed
class AgencyModel with _$AgencyModel {
  const factory AgencyModel({
    required String id,
    required String authUserId,
    required String name,
    required String email,
    String? logoUrl,
    required String websiteUrl,
    required MediaType mediaType,
    required AgencyStatus status,
    String? rejectReason,
    required DateTime createdAt,
    DateTime? validatedAt,
  }) = _AgencyModel;

  factory AgencyModel.fromJson(Map<String, dynamic> json) =>
      _$AgencyModelFromJson(json);
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