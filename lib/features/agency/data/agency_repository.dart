import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final agencyRepositoryProvider = Provider<AgencyRepository>(
  (ref) => AgencyRepository(),
);

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
  AgencyRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

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
}
