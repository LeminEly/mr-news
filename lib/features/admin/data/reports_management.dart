import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final reportsManagementRepositoryProvider =
    Provider<ReportsManagementRepository>(
  (ref) => ReportsManagementRepository(),
);

class ReportsManagementException implements Exception {
  const ReportsManagementException({
    required this.code,
    required this.message,
    this.details,
  });

  final String code;
  final String message;
  final Object? details;

  @override
  String toString() =>
      'ReportsManagementException(code: $code, message: $message)';
}

class ReportsManagementRepository {
  ReportsManagementRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<List<Map<String, dynamic>>> getReports({
    String status = 'pending',
  }) async {
    try {
      final rows = await _client
          .from('reports')
          .select('*, articles(id, title, source_url, language, agency_id)')
          .eq('status', status)
          .order('created_at');
      return List<Map<String, dynamic>>.from(rows);
    } on PostgrestException catch (error) {
      throw _mapPostgrestError(error);
    }
  }

  Future<Map<String, dynamic>> resolveReport(String reportId) {
    return _updateReportStatus(reportId: reportId, status: 'resolved');
  }

  Future<Map<String, dynamic>> dismissReport(String reportId) {
    return _updateReportStatus(reportId: reportId, status: 'dismissed');
  }

  Future<Map<String, dynamic>> _updateReportStatus({
    required String reportId,
    required String status,
  }) async {
    try {
      return await _client
          .from('reports')
          .update({
            'status': status,
            'resolved_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', reportId)
          .select()
          .single();
    } on PostgrestException catch (error) {
      throw _mapPostgrestError(error);
    }
  }

  ReportsManagementException _mapPostgrestError(PostgrestException error) {
    if (error.code == 'PGRST116') {
      return const ReportsManagementException(
        code: 'NOT_FOUND',
        message: 'Signalement introuvable.',
      );
    }

    return ReportsManagementException(
      code: error.code ?? 'DATABASE_ERROR',
      message: error.message,
      details: error,
    );
  }
}
