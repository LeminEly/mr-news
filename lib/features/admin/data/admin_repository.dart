import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final adminRepositoryProvider = Provider<AdminRepository>(
  (ref) => AdminRepository(),
);

class AdminRepositoryException implements Exception {
  const AdminRepositoryException({
    required this.code,
    required this.message,
    this.details,
  });

  final String code;
  final String message;
  final Object? details;

  @override
  String toString() =>
      'AdminRepositoryException(code: $code, message: $message)';
}

class AdminRepository {
  AdminRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<List<Map<String, dynamic>>> getPendingAgencies() {
    return _getAgenciesByStatus('pending');
  }

  Future<List<Map<String, dynamic>>> getAgencies({String? status}) async {
    try {
      final rows = status == null
          ? await _client.from('agencies').select().order('created_at')
          : await _client
              .from('agencies')
              .select()
              .eq('status', status)
              .order('created_at');
      return List<Map<String, dynamic>>.from(rows);
    } on PostgrestException catch (error) {
      throw _mapPostgrestError(error);
    }
  }

  Future<Map<String, dynamic>> approveAgency(String agencyId) async {
    return _updateAgencyStatus(
      agencyId: agencyId,
      status: 'approved',
      rejectReason: null,
      validatedAt: DateTime.now(),
    );
  }

  Future<Map<String, dynamic>> rejectAgency({
    required String agencyId,
    required String reason,
  }) async {
    return _updateAgencyStatus(
      agencyId: agencyId,
      status: 'rejected',
      rejectReason: reason.trim(),
      validatedAt: null,
    );
  }

  Future<Map<String, dynamic>> suspendAgency({
    required String agencyId,
    String? reason,
  }) async {
    return _updateAgencyStatus(
      agencyId: agencyId,
      status: 'suspended',
      rejectReason: reason?.trim(),
      validatedAt: null,
    );
  }

  Future<Map<String, dynamic>> getAdminStats() async {
    try {
      final pendingAgencies =
          await _client.from('agencies').select('id').eq('status', 'pending');
      final pendingReports =
          await _client.from('reports').select('id').eq('status', 'pending');
      final activeArticles =
          await _client.from('articles').select('id').eq('is_active', true);
      final categories = await _client.from('categories').select('id');

      return {
        'pending_agencies': pendingAgencies.length,
        'pending_reports': pendingReports.length,
        'active_articles': activeArticles.length,
        'categories': categories.length,
      };
    } on PostgrestException catch (error) {
      throw _mapPostgrestError(error);
    }
  }

  Future<List<Map<String, dynamic>>> _getAgenciesByStatus(String status) async {
    try {
      final rows = await _client
          .from('agencies')
          .select()
          .eq('status', status)
          .order('created_at');
      return List<Map<String, dynamic>>.from(rows);
    } on PostgrestException catch (error) {
      throw _mapPostgrestError(error);
    }
  }

  Future<Map<String, dynamic>> _updateAgencyStatus({
    required String agencyId,
    required String status,
    required String? rejectReason,
    required DateTime? validatedAt,
  }) async {
    try {
      return await _client
          .from('agencies')
          .update({
            'status': status,
            'reject_reason': rejectReason,
            'validated_at': validatedAt?.toUtc().toIso8601String(),
          })
          .eq('id', agencyId)
          .select()
          .single();
    } on PostgrestException catch (error) {
      throw _mapPostgrestError(error);
    }
  }

  AdminRepositoryException _mapPostgrestError(PostgrestException error) {
    if (error.code == 'PGRST116') {
      return const AdminRepositoryException(
        code: 'NOT_FOUND',
        message: 'Agence introuvable.',
      );
    }

    return AdminRepositoryException(
      code: error.code ?? 'DATABASE_ERROR',
      message: error.message,
      details: error,
    );
  }
}
