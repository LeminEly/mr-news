import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/errors/app_error.dart';
import '../../../shared/models/article_model.dart';
import '../../../shared/models/category_model.dart';
import 'dart:async';

class FeedRepository {
  FeedRepository(this._supabase);
  final SupabaseClient _supabase;

  // Charger les articles d'une date
  Future<List<ArticleModel>> getArticlesByDate(DateTime date) async {
    try {
      final startOfDay = DateTime.utc(date.year, date.month, date.day);
      final endOfDay = DateTime.utc(date.year, date.month, date.day + 1);

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
      final startOfDay = DateTime.utc(date.year, date.month, date.day);
      final endOfDay = DateTime.utc(date.year, date.month, date.day + 1);

      var query = _supabase
          .from(AppConstants.viewArticlesWithDetails)
          .select()
          .gte('published_at', startOfDay.toIso8601String())
          .lt('published_at', endOfDay.toIso8601String());

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
        final startOfDay = DateTime.utc(date.year, date.month, date.day);
        final endOfDay = DateTime.utc(date.year, date.month, date.day + 1);
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

  // Obtenir les articles les plus récents sans filtre de date
  Future<List<ArticleModel>> getRecentArticles() async {
    try {
      final response = await _supabase
          .from(AppConstants.viewArticlesWithDetails)
          .select()
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
    final startOfDay = DateTime.utc(today.year, today.month, today.day);

    return _supabase
        .from(AppConstants.tableArticles)
        .stream(primaryKey: ['id'])
        .gte('published_at', startOfDay.toIso8601String())
        .order('published_at', ascending: false)
        .map((list) => list.map((e) => ArticleModel.fromJson(e)).toList());
  }

  // Pour le service de notifications : nouveaux articles uniquement
  Stream<ArticleModel> watchNewArticles() {
    final controller = StreamController<ArticleModel>();

    final channel = _supabase.channel('new-articles');

    channel.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'articles',
      callback: (payload) {
        print('INSERT reçu: ${payload.newRecord}');
        try {
          final data = Map<String, dynamic>.from(payload.newRecord);

          // Champs optionnels absents de la table brute
          data['agency_name'] ??= null;
          data['agency_logo_url'] ??= null;
          data['agency_website'] ??= null;
          data['category_name_ar'] ??= null;
          data['category_name_fr'] ??= null;
          data['category_icon'] ??= null;
          data['category_color'] ??= null;
          data['created_at'] ??= data['published_at'];
          data['updated_at'] ??= data['published_at'];
          data['reaction_counts'] ??= <String, dynamic>{};

          controller.add(ArticleModel.fromJson(data));
        } catch (e) {
          print('ERREUR watchNewArticles fromJson: $e');
        }
      },
    );

    channel.subscribe();

    controller.onCancel = () {
      _supabase.removeChannel(channel);
    };

    return controller.stream;
  }
}
