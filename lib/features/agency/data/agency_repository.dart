import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/models/article_model.dart';
import '../../../shared/models/agency_model.dart';
import '../../../shared/models/category_model.dart';

class AgencyRepositoryException implements Exception {
  const AgencyRepositoryException({
    required this.code,
    required this.message,
    this.details,
  });

  final String code;
  final String message;
  final Object? details;

  @override
  String toString() =>
      'AgencyRepositoryException(code: $code, message: $message)';
}

class AgencyRepository {
  AgencyRepository({required SupabaseClient client}) : _client = client;

  final SupabaseClient _client;

  User? get currentUser => _client.auth.currentUser;

  Future<Map<String, dynamic>> signUpAgency({
    required String email,
    required String password,
    required String name,
    required String websiteUrl,
    String mediaType = 'news_agency',
    Uint8List? logoBytes,
    String? logoFileExt,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: const {'role': 'agency'},
      );

      final user = response.user;
      if (user == null) {
        throw const AgencyRepositoryException(
          code: 'SIGN_UP_FAILED',
          message: 'Impossible de creer le compte agence.',
        );
      }

      String? logoUrl;
      if (logoBytes != null) {
        logoUrl = await uploadAgencyLogo(
          userId: user.id,
          bytes: logoBytes,
          fileExt: logoFileExt,
        );
      }

      final inserted = await _client
          .from('agencies')
          .insert({
            'auth_user_id': user.id,
            'name': name.trim(),
            'email': email.trim().toLowerCase(),
            'logo_url': logoUrl,
            'website_url': websiteUrl.trim(),
            'media_type': mediaType,
          })
          .select()
          .single();

      return inserted;
    } on AuthException catch (error) {
      throw AgencyRepositoryException(
          code: error.statusCode ?? 'AUTH_ERROR',
          message: error.message,
          details: error);
    } on StorageException catch (error) {
      throw AgencyRepositoryException(
          code: 'STORAGE_ERROR', message: error.message, details: error);
    } on PostgrestException catch (error) {
      throw _mapPostgrestError(error);
    }
  }

  Future<Map<String, dynamic>> signInAgency({
    required String email,
    required String password,
  }) async {
    try {
      await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return getCurrentAgency();
    } on AuthException catch (error) {
      throw AgencyRepositoryException(
          code: error.statusCode ?? 'AUTH_ERROR',
          message: error.message,
          details: error);
    } on PostgrestException catch (error) {
      throw _mapPostgrestError(error);
    }
  }

  Future<void> signOut() => _client.auth.signOut();

  Future<Map<String, dynamic>> getCurrentAgency() async {
    final user = currentUser;
    if (user == null) {
      throw const AgencyRepositoryException(
        code: 'UNAUTHENTICATED',
        message: 'Aucune session active.',
      );
    }

    try {
      return await _client
          .from('agencies')
          .select()
          .eq('auth_user_id', user.id)
          .single();
    } on PostgrestException catch (error) {
      throw _mapPostgrestError(error);
    }
  }

  Future<Map<String, dynamic>> updateAgencyProfile({
    required String agencyId,
    String? name,
    String? websiteUrl,
    String? mediaType,
    Uint8List? logoBytes,
    String? logoFileExt,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name.trim();
      if (websiteUrl != null) updates['website_url'] = websiteUrl.trim();
      if (mediaType != null) updates['media_type'] = mediaType;

      if (logoBytes != null) {
        updates['logo_url'] = await uploadAgencyLogo(
          agencyId: agencyId,
          bytes: logoBytes,
          fileExt: logoFileExt,
        );
      }

      if (updates.isEmpty) {
        return _client.from('agencies').select().eq('id', agencyId).single();
      }

      return await _client
          .from('agencies')
          .update(updates)
          .eq('id', agencyId)
          .select()
          .single();
    } on StorageException catch (error) {
      throw AgencyRepositoryException(
          code: 'STORAGE_ERROR', message: error.message, details: error);
    } on PostgrestException catch (error) {
      throw _mapPostgrestError(error);
    }
  }

  Future<String> uploadAgencyLogo({
    String? agencyId,
    String? userId,
    required Uint8List bytes,
    String? fileExt,
  }) async {
    final ownerId = agencyId ?? userId ?? currentUser?.id;
    if (ownerId == null) {
      throw const AgencyRepositoryException(
        code: 'UNAUTHENTICATED',
        message: 'Connexion requise pour uploader un logo.',
      );
    }

    final ext = _normalizeFileExt(fileExt);
    final path = '$ownerId/logo_${DateTime.now().millisecondsSinceEpoch}.$ext';

    await _client.storage.from('agency-logos').uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
              contentType: _contentTypeForExtension(ext), upsert: true),
        );

    return _client.storage.from('agency-logos').getPublicUrl(path);
  }

  /// Couverture article (bucket `article-covers`, chemin `agencyId/timestamp.ext`).
  Future<String> uploadArticleCover({
    required String agencyId,
    required Uint8List bytes,
    String? fileExt,
  }) async {
    if (agencyId.isEmpty) {
      throw const AgencyRepositoryException(
        code: 'INVALID',
        message: 'agency_id requis pour l\'upload de couverture.',
      );
    }
    final ext = _normalizeFileExt(fileExt);
    final path = '$agencyId/${DateTime.now().millisecondsSinceEpoch}.$ext';
    try {
      await _client.storage.from('article-covers').uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(
              contentType: _contentTypeForExtension(ext),
              upsert: false,
            ),
          );
      return _client.storage.from('article-covers').getPublicUrl(path);
    } on StorageException catch (error) {
      throw AgencyRepositoryException(
        code: 'STORAGE_ERROR',
        message: error.message,
        details: error,
      );
    }
  }

  String _normalizeFileExt(String? fileExt) {
    final trimmed =
        (fileExt ?? 'jpg').trim().toLowerCase().replaceFirst('.', '');
    if (trimmed.isEmpty) return 'jpg';
    return trimmed;
  }

  String _contentTypeForExtension(String extension) {
    switch (extension) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'jpg':
      case 'jpeg':
      default:
        return 'image/jpeg';
    }
  }

  AgencyRepositoryException _mapPostgrestError(PostgrestException error) {
    if (error.code == 'PGRST116') {
      return const AgencyRepositoryException(
        code: 'NOT_FOUND',
        message: 'Ressource introuvable.',
      );
    }

    if (error.code == '23505') {
      return const AgencyRepositoryException(
        code: 'DUPLICATE',
        message: 'Cette ressource existe deja.',
      );
    }

    return AgencyRepositoryException(
      code: error.code ?? 'DATABASE_ERROR',
      message: error.message,
      details: error,
    );
  }

  // ────────────────────────────────────────────────────────────────────────────
  // CRUD articles + catégories + profil agence (Supabase réel)
  // ────────────────────────────────────────────────────────────────────────────

  Future<List<ArticleModel>> getMyArticles(String agencyId) async {
    try {
      final response = await _client
          .from('articles')
          .select()
          .eq('agency_id', agencyId)
          .order('published_at', ascending: false);

      return (response as List)
          .map((e) => ArticleModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (error) {
      throw _mapPostgrestError(error);
    }
  }

  Future<void> publishArticle({
    required String agencyId,
    required String title,
    required String sourceUrl,
    String? coverImageUrl,
    required String categoryId,
    required String language,
  }) async {
    debugPrint('=== PUBLISH START ===');
    debugPrint('agencyId: "$agencyId"');
    debugPrint('title: "$title"');
    debugPrint('sourceUrl: "$sourceUrl"');
    debugPrint('categoryId: "$categoryId"');
    debugPrint('language: "$language"');
    debugPrint('coverImageUrl: "$coverImageUrl"');
    debugPrint('currentUser: "${_client.auth.currentUser?.id}"');

    if (_client.auth.currentUser == null) {
      throw Exception('Utilisateur non connecté');
    }

    if (agencyId.isEmpty) throw Exception('agency_id est vide');
    if (categoryId.isEmpty) throw Exception('category_id est vide');
    if (title.isEmpty) throw Exception('title est vide');
    if (sourceUrl.isEmpty) throw Exception('source_url est vide');

    final Map<String, dynamic> data = {
      'agency_id': agencyId,
      'title': title,
      'source_url': sourceUrl,
      'category_id': categoryId,
      'language': language,
      'is_active': true,
      'published_at': DateTime.now().toUtc().toIso8601String(),
    };

    if (coverImageUrl != null && coverImageUrl.isNotEmpty) {
      data['cover_image_url'] = coverImageUrl;
    }

    debugPrint('Data envoyée: $data');

    try {
      final result = await _client.from('articles').insert(data).select();
      debugPrint('=== PUBLISH SUCCESS === $result');
    } on PostgrestException catch (e) {
      debugPrint('=== POSTGREST ERROR ===');
      debugPrint('message: ${e.message}');
      debugPrint('code: ${e.code}');
      debugPrint('details: ${e.details}');
      debugPrint('hint: ${e.hint}');
      rethrow;
    } catch (e) {
      debugPrint('=== UNKNOWN ERROR === $e');
      rethrow;
    }
  }

  Future<void> updateArticle({
    required String articleId,
    required String title,
    required String sourceUrl,
    String? coverImageUrl,
    required String categoryId,
    required ArticleLanguage language,
  }) async {
    try {
      final rows = await _client.from('articles').update({
        'title': title,
        'source_url': sourceUrl,
        'cover_image_url': coverImageUrl,
        'category_id': categoryId,
        'language': language.name,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', articleId).select('id');
      final list = List<dynamic>.from(rows as List? ?? const []);
      if (list.isEmpty) {
        throw const AgencyRepositoryException(
          code: 'UPDATE_FAILED',
          message:
              'Aucune ligne mise a jour. Verifiez vos droits (RLS) ou reessayez.',
        );
      }
    } on PostgrestException catch (error) {
      throw _mapPostgrestError(error);
    }
  }

  Future<void> deleteArticle(String articleId) async {
    try {
      final rows =
          await _client.from('articles').delete().eq('id', articleId).select('id');
      final list = List<dynamic>.from(rows as List? ?? const []);
      if (list.isEmpty) {
        throw const AgencyRepositoryException(
          code: 'DELETE_FAILED',
          message:
              'Aucune ligne supprimee. Verifiez vos droits (RLS) ou reessayez.',
        );
      }
    } on PostgrestException catch (error) {
      throw _mapPostgrestError(error);
    }
  }

  Future<List<CategoryModel>> getCategories() async {
    try {
      final response = await _client
          .from('categories')
          .select()
          .eq('is_active', true)
          .order('display_order');

      return (response as List)
          .map((e) => CategoryModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (error) {
      throw _mapPostgrestError(error);
    }
  }

  Future<AgencyModel?> getMyAgency(String authUserId) async {
    try {
      final response = await _client
          .from('agencies')
          .select()
          .eq('auth_user_id', authUserId)
          .maybeSingle();
      if (response == null) return null;
      return AgencyModel.fromJson(response);
    } on PostgrestException catch (error) {
      throw _mapPostgrestError(error);
    }
  }
}
