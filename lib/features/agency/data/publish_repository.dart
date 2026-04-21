import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final publishRepositoryProvider = Provider<PublishRepository>(
  (ref) => PublishRepository(),
);

class PublishRepositoryException implements Exception {
  const PublishRepositoryException({
    required this.code,
    required this.message,
    this.details,
  });

  final String code;
  final String message;
  final Object? details;

  @override
  String toString() =>
      'PublishRepositoryException(code: $code, message: $message)';
}

class PublishRepository {
  PublishRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<List<Map<String, dynamic>>> getMyArticles({
    required String agencyId,
    bool includeInactive = true,
  }) async {
    try {
      final rows = includeInactive
          ? await _client
              .from('articles')
              .select('*, categories(id, name_ar, name_fr, icon, color_hex)')
              .eq('agency_id', agencyId)
              .order('published_at', ascending: false)
          : await _client
              .from('articles')
              .select('*, categories(id, name_ar, name_fr, icon, color_hex)')
              .eq('agency_id', agencyId)
              .eq('is_active', true)
              .order('published_at', ascending: false);

      return List<Map<String, dynamic>>.from(rows);
    } on PostgrestException catch (error) {
      throw _mapPostgrestError(error);
    }
  }

  Future<Map<String, dynamic>> publishArticle({
    required String agencyId,
    required String title,
    required String sourceUrl,
    required String language,
    String? categoryId,
    String? coverImageUrl,
    Uint8List? coverBytes,
    String? coverFileExt,
    DateTime? publishedAt,
  }) async {
    try {
      final resolvedCoverUrl = coverBytes != null
          ? await uploadArticleCover(
              agencyId: agencyId,
              bytes: coverBytes,
              fileExt: coverFileExt,
            )
          : coverImageUrl;

      return await _client
          .from('articles')
          .insert({
            'agency_id': agencyId,
            'category_id': categoryId,
            'title': title.trim(),
            'source_url': sourceUrl.trim(),
            'cover_image_url': resolvedCoverUrl,
            'language': language,
            'published_at':
                (publishedAt ?? DateTime.now()).toUtc().toIso8601String(),
          })
          .select()
          .single();
    } on StorageException catch (error) {
      throw PublishRepositoryException(
          code: 'STORAGE_ERROR', message: error.message, details: error);
    } on PostgrestException catch (error) {
      throw _mapPostgrestError(error);
    }
  }

  Future<Map<String, dynamic>> updateArticle({
    required String articleId,
    String? title,
    String? sourceUrl,
    String? language,
    String? categoryId,
    bool clearCategory = false,
    String? coverImageUrl,
    Uint8List? coverBytes,
    String? coverFileExt,
    bool clearCover = false,
    bool? isActive,
    DateTime? publishedAt,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (title != null) updates['title'] = title.trim();
      if (sourceUrl != null) updates['source_url'] = sourceUrl.trim();
      if (language != null) updates['language'] = language;
      if (clearCategory) {
        updates['category_id'] = null;
      } else if (categoryId != null) {
        updates['category_id'] = categoryId;
      }
      if (clearCover) {
        updates['cover_image_url'] = null;
      } else if (coverBytes != null) {
        final article = await getArticle(articleId);
        updates['cover_image_url'] = await uploadArticleCover(
          agencyId: article['agency_id'] as String,
          bytes: coverBytes,
          fileExt: coverFileExt,
        );
      } else if (coverImageUrl != null) {
        updates['cover_image_url'] = coverImageUrl.trim();
      }
      if (isActive != null) updates['is_active'] = isActive;
      if (publishedAt != null) {
        updates['published_at'] = publishedAt.toUtc().toIso8601String();
      }

      if (updates.isEmpty) return getArticle(articleId);

      return await _client
          .from('articles')
          .update(updates)
          .eq('id', articleId)
          .select()
          .single();
    } on StorageException catch (error) {
      throw PublishRepositoryException(
          code: 'STORAGE_ERROR', message: error.message, details: error);
    } on PostgrestException catch (error) {
      throw _mapPostgrestError(error);
    }
  }

  Future<Map<String, dynamic>> getArticle(String articleId) async {
    try {
      return await _client
          .from('articles')
          .select()
          .eq('id', articleId)
          .single();
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

  Future<String> uploadArticleCover({
    required String agencyId,
    required Uint8List bytes,
    String? fileExt,
  }) async {
    final ext = _normalizeFileExt(fileExt);
    final path = '$agencyId/${DateTime.now().millisecondsSinceEpoch}.$ext';

    await _client.storage.from('article-covers').uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
              contentType: _contentTypeForExtension(ext), upsert: true),
        );

    return _client.storage.from('article-covers').getPublicUrl(path);
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

  PublishRepositoryException _mapPostgrestError(PostgrestException error) {
    if (error.code == 'PGRST116') {
      return const PublishRepositoryException(
        code: 'NOT_FOUND',
        message: 'Article introuvable.',
      );
    }

    return PublishRepositoryException(
      code: error.code ?? 'DATABASE_ERROR',
      message: error.message,
      details: error,
    );
  }
}
