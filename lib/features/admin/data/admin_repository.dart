import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;

import '../../../shared/models/agency_model.dart';
import '../../../shared/models/article_model.dart';
import '../../../core/constants/env.dart';

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
  AdminRepository({required SupabaseClient client}) : _client = client;

  final SupabaseClient _client;
  final String _apiBaseUrl = 'http://10.0.2.2:8080/api/admin/agencies'; // Adjusted for Android Emulator

  Future<Map<String, dynamic>> getGlobalStats() async {
    try {
      final user = _client.auth.currentUser;
      debugPrint('AdminRepository: Current User Role = ${user?.userMetadata?['role']}');

      // Fetch pending agencies
      debugPrint('AdminRepository: Fetching pending agencies from ${Env.appSupabaseUrl}...');
      final pendingAgenciesRes = await _client
          .from('agencies')
          .select('id, name, status')
          .eq('status', 'pending');
      debugPrint('AdminRepository: Found ${pendingAgenciesRes.length} pending agencies');
      
      // Fetch pending reports
      final pendingReportsRes = await _client
          .from('reports')
          .select('id, status')
          .eq('status', 'pending');
      
      // Fetch active articles
      final activeArticlesRes = await _client
          .from('articles')
          .select('id')
          .eq('is_active', true);
      
      // Fetch categories
      final categoriesRes = await _client
          .from('categories')
          .select('id');
      
      // Fetch total agencies
      final allAgenciesRes = await _client
          .from('agencies')
          .select('id, name, status');

      // Fetch validated agencies
      final validatedAgenciesRes = await _client
          .from('agencies')
          .select('id')
          .eq('status', 'approved');

      // Fetch rejected agencies
      final rejectedAgenciesRes = await _client
          .from('agencies')
          .select('id')
          .eq('status', 'rejected');

      debugPrint('AdminStats Results: Pending=${pendingAgenciesRes.length}, Total=${allAgenciesRes.length}, Reports=${pendingReportsRes.length}');

      return {
        'pending_agencies': pendingAgenciesRes.length,
        'pending_reports': pendingReportsRes.length,
        'active_articles': activeArticlesRes.length,
        'categories': categoriesRes.length,
        'total_agencies': allAgenciesRes.length,
        'validated_agencies': validatedAgenciesRes.length,
        'rejected_agencies': rejectedAgenciesRes.length,
      };
    } catch (e, stack) {
      debugPrint('Unexpected error in getGlobalStats: $e\n$stack');
      rethrow;
    }
  }

  Future<List<AgencyModel>> getAgenciesByStatus(AgencyStatus status) async {
    // Map AgencyStatus enum to DB string
    String statusStr;
    switch (status) {
      case AgencyStatus.accepted:
        statusStr = 'approved';
        break;
      case AgencyStatus.pending:
        statusStr = 'pending';
        break;
      case AgencyStatus.rejected:
        statusStr = 'rejected';
        break;
      case AgencyStatus.suspended:
        statusStr = 'suspended';
        break;
    }
    return getAgencies(status: statusStr);
  }

  Future<List<dynamic>> getPendingReports() async {
    try {
      final rows = await _client
          .from('reports')
          .select('*, articles(title)')
          .eq('status', 'pending')
          .order('created_at');
      return rows as List<dynamic>;
    } on PostgrestException catch (error) {
      throw _mapPostgrestError(error);
    }
  }

  Future<List<Map<String, dynamic>>> getPendingAgencies() {
    return _getAgenciesByStatus('pending');
  }

  Future<List<AgencyModel>> getAgencies({String? status}) async {
    try {
      var query = _client.from('agencies').select();
      
      if (status != null && status.isNotEmpty) {
        query = query.eq('status', status.toLowerCase().trim());
      }
      
      final rows = await query.order('created_at', ascending: false);
      debugPrint('getAgencies result: ${rows.length} agencies found (status filter: $status)');


      return (rows as List)
          .map((e) => AgencyModel.fromSupabase(e as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      debugPrint('PostgrestError in getAgencies: ${e.message}');
      throw AdminRepositoryException(
        code: e.code ?? 'FETCH_ERROR',
        message: 'Erreur lors de la récupération des agences: ${e.message}',
      );
    } catch (e) {
      debugPrint('Unknown error in getAgencies: $e');
      throw AdminRepositoryException(
        code: 'UNKNOWN_ERROR',
        message: 'Une erreur inattendue est survenue: $e',
      );
    }
  }

  Future<void> approveAgency(String agencyId) async {
    try {
      // Try calling backend API if available
      try {
        final response = await http.put(Uri.parse('$_apiBaseUrl/$agencyId/approve'))
            .timeout(const Duration(seconds: 3));
        if (response.statusCode != 200 && response.statusCode != 204) {
           debugPrint('Backend API approve failed: ${response.statusCode}');
        }
      } catch (e) {
        debugPrint('Backend API unreachable: $e');
      }
      
      await _updateAgencyStatus(
        agencyId: agencyId,
        status: 'approved',
        rejectReason: null,
        validatedAt: DateTime.now(),
      );
    } catch (e) {
      debugPrint('Error in approveAgency: $e');
      rethrow;
    }
  }

  Future<void> rejectAgency({
    required String agencyId,
    required String reason,
  }) async {
    try {
      try {
        final response = await http.put(Uri.parse('$_apiBaseUrl/$agencyId/reject'))
            .timeout(const Duration(seconds: 3));
        if (response.statusCode != 200 && response.statusCode != 204) {
           debugPrint('Backend API reject failed: ${response.statusCode}');
        }
      } catch (e) {
        debugPrint('Backend API unreachable: $e');
      }

      await _updateAgencyStatus(
        agencyId: agencyId,
        status: 'rejected',
        rejectReason: reason.trim(),
        validatedAt: null,
      );
    } catch (e) {
      debugPrint('Error in rejectAgency: $e');
      rethrow;
    }
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
    return getGlobalStats();
  }

  Future<List<Map<String, dynamic>>> _getAgenciesByStatus(String status) async {
    try {
      final rows = await _client
          .from('agencies')
          .select()
          .eq('status', status.toLowerCase())
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
      final Map<String, dynamic> data = {
        'status': status.toLowerCase(),
        'reject_reason': rejectReason,
      };

      if (status.toLowerCase() == 'approved' || status.toLowerCase() == 'accepted') {
        data['status'] = 'approved'; // Ensure it's 'approved' for the DB
        data['validated_at'] = validatedAt?.toUtc().toIso8601String();
      }

      return await _client
          .from('agencies')
          .update(data)
          .eq('id', agencyId)
          .select()
          .single();
    } on PostgrestException catch (error) {
      debugPrint('Error updating agency status: ${error.message}');
      throw _mapPostgrestError(error);
    }
  }

  Future<List<ArticleModel>> getAllArticles() async {
    try {
      final rows = await _client
          .from('articles')
          .select('*, agencies(name)')
          .order('published_at', ascending: false);
      
      return (rows as List).map((row) {
        final data = Map<String, dynamic>.from(row);
        return ArticleModel.fromJson(data);
      }).toList();
    } on PostgrestException catch (error) {
      throw _mapPostgrestError(error);
    }
  }

  Future<void> toggleArticleStatus(String articleId, bool isActive) async {
    try {
      await _client
          .from('articles')
          .update({'is_active': isActive})
          .eq('id', articleId);
    } on PostgrestException catch (error) {
      throw _mapPostgrestError(error);
    }
  }

  Future<void> deleteArticle(String articleId) async {
    try {
      await _client.from('articles').delete().eq('id', articleId);
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

  Future<List<Map<String, dynamic>>> getAgencyActivityByDate() async {
    try {
      // Fetch agencies that have been validated or rejected
      // In a real app, we would use a dedicated 'activity_log' table
      // Here we use validated_at and created_at as proxies
      final rows = await _client
          .from('agencies')
          .select('id, name, status, created_at, validated_at')
          .not('status', 'eq', 'pending')
          .order('validated_at', ascending: false);
      
      return List<Map<String, dynamic>>.from(rows);
    } catch (e) {
      debugPrint('Error in getAgencyActivityByDate: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getAllCategories() async {
    try {
      final rows = await _client
          .from('categories')
          .select()
          .order('name_fr');
      return List<Map<String, dynamic>>.from(rows);
    } catch (e) {
      debugPrint('Error in getAllCategories: $e');
      return [];
    }
  }


  Future<Map<String, dynamic>> getCategoryAnalytics() async {
    try {
      // 1. Categories Active Today
      final today = DateTime.now().toUtc().toIso8601String().split('T')[0];
      final articlesToday = await _client
          .from('articles')
          .select('category_id, categories(name_fr, name_ar, icon)')
          .gte('published_at', '${today}T00:00:00Z');
      
      final activeToday = <String, Map<String, dynamic>>{};
      for (var art in (articlesToday as List)) {
        final catId = art['category_id'] as String?;
        if (catId == null) continue;
        final catData = art['categories'] as Map<String, dynamic>?;
        if (catData == null) continue;
        
        if (!activeToday.containsKey(catId)) {
          activeToday[catId] = {
            'id': catId,
            'name': catData['name_fr'],
            'count': 0,
            'icon': catData['icon'],
          };
        }
        activeToday[catId]!['count'] = (activeToday[catId]!['count'] as int) + 1;
      }

      // 2. Most Active Categories
      final allCategories = await _client.from('categories').select('id, name_fr, icon');
      final mostActive = (allCategories as List).map((cat) {
        return {
          'id': cat['id'],
          'name': cat['name_fr'],
          'icon': cat['icon'],
          'engagement': (cat['name_fr'].length * 15) % 100, // Mock engagement score
        };
      }).toList();
      mostActive.sort((a, b) => (b['engagement'] as int).compareTo(a['engagement'] as int));

      // 3. Activity Today (Detailed breakdown)
      // Already partially in activeToday, but we ensure it matches the user request format
      final activityToday = activeToday.values.toList();

      return {
        'active_today': activeToday.values.toList(),
        'most_active': mostActive.take(5).toList(),
        'activity_today': activityToday,
      };
    } catch (e) {
      debugPrint('Error in getCategoryAnalytics: $e');
      return {
        'active_today': [],
        'most_active': [],
        'activity_today': [],
      };
    }
  }
}
