import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final reportsManagementRepositoryProvider =
    Provider<ReportsManagementRepository>(
  (ref) {
    // IMPORTANT: Using the Service Role Key for Admin operations to bypass RLS
    const serviceRoleKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNiZnVsZG1zd2x1end4ZmRpcHd5Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3NjQxOTQ4MCwiZXhwIjoyMDkxOTk1NDgwfQ.BgyB813SUM9wx7GzZUnN7iTb5DEprZVfdxzhyzD1tVo';
    const url = 'https://cbfuldmswluzwxfdipwy.supabase.co';
    
    final adminClient = SupabaseClient(url, serviceRoleKey);
    return ReportsManagementRepository(client: adminClient);
  },
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
          .eq('status', status.toLowerCase())
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
            'status': status.toLowerCase(),
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
