import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/errors/app_error.dart';
import '../../../shared/models/article_model.dart';
import '../../../shared/models/category_model.dart';

class FeedRepository {
  FeedRepository(this._supabase);
  final SupabaseClient _supabase;

  // Charger les articles d'une date
  Future<List<ArticleModel>> getArticlesByDate(DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay   = startOfDay.add(const Duration(days: 1));

      final response = await _supabase
          .from(AppConstants.viewArticlesWithDetails)
          .select()
          .gte('published_at', startOfDay.toIso8601String())
          .lt('published_at', endOfDay.toIso8601String())
          .order('published_at', ascending: false)
          .limit(AppConstants.feedPageSize);

      return (response as List)
          .map((e) => ArticleModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw AppError.fromSupabase(e);
    }
  }

  // Pagination par curseur
  Future<List<ArticleModel>> getArticlesByDatePaginated({
    required DateTime date,
    DateTime? lastPublishedAt,
    String? lastId,
  }) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay   = startOfDay.add(const Duration(days: 1));

      var query = _supabase
          .from(AppConstants.viewArticlesWithDetails)
          .select()
          .gte('published_at', startOfDay.toIso8601String())
          .lt('published_at', endOfDay.toIso8601String());

      // Curseur pour la pagination
      if (lastPublishedAt != null) {
        query = query.lt('published_at', lastPublishedAt.toIso8601String());
      }

      final response = await query
          .order('published_at', ascending: false)
          .limit(AppConstants.feedPageSize);

      return (response as List)
          .map((e) => ArticleModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw AppError.fromSupabase(e);
    }
  }

  // Filtrer par catégorie
  Future<List<ArticleModel>> getArticlesByCategory({
    required String categoryId,
    DateTime? date,
  }) async {
    try {
      var query = _supabase
          .from(AppConstants.viewArticlesWithDetails)
          .select()
          .eq('category_id', categoryId);

      if (date != null) {
        final startOfDay = DateTime(date.year, date.month, date.day);
        final endOfDay   = startOfDay.add(const Duration(days: 1));
        query = query
            .gte('published_at', startOfDay.toIso8601String())
            .lt('published_at', endOfDay.toIso8601String());
      }

      final response = await query
          .order('published_at', ascending: false)
          .limit(AppConstants.feedPageSize);

      return (response as List)
          .map((e) => ArticleModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw AppError.fromSupabase(e);
    }
  }

  // Charger les catégories actives
  Future<List<CategoryModel>> getCategories() async {
    try {
      final response = await _supabase
          .from(AppConstants.tableCategories)
          .select()
          .eq('is_active', true)
          .order('display_order');

      return (response as List)
          .map((e) => CategoryModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw AppError.fromSupabase(e);
    }
  }

  // Stream Realtime pour le feed
  Stream<List<ArticleModel>> watchTodayArticles() {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);

    return _supabase
        .from(AppConstants.tableArticles)
        .stream(primaryKey: ['id'])
        .gte('published_at', startOfDay.toIso8601String())
        .order('published_at', ascending: false)
        .map((list) => list
            .map((e) => ArticleModel.fromJson(e))
            .toList());
  }
}