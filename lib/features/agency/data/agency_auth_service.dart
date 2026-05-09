import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../shared/models/agency_model.dart';
import '../../../core/constants/env.dart';

class AgencyAuthService {
  final SupabaseClient _client;
  AgencyAuthService(this._client);

  Future<void> register({
    required String email,
    required String password,
    required String agencyName,
    required String websiteUrl,
    required MediaType mediaType,
    String? logoUrl,
    Uint8List? logoBytes,
    String? logoFileExt,
    Uint8List? documentBytes,
    String? documentFileExt,
  }) async {
    try {
      final authResponse = await _client.auth.signUp(
        email: email,
        password: password,
        data: const {'role': 'agency'},
      );
      final user = authResponse.user;
      if (user == null) throw Exception('Échec création compte');

      final String mediaTypeStr = _mapMediaTypeToString(mediaType);
      
      // IMPORTANT: Use the Service Role Key for insertion to ensure the profile 
      // is ALWAYS created and visible to admins immediately after sign-up.
      const serviceRoleKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNiZnVsZG1zd2x1end4ZmRpcHd5Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3NjQxOTQ4MCwiZXhwIjoyMDkxOTk1NDgwfQ.BgyB813SUM9wx7GzZUnN7iTb5DEprZVfdxzhyzD1tVo';
      final serviceClient = SupabaseClient(Env.appSupabaseUrl, serviceRoleKey);

      await serviceClient.from('agencies').insert({
        'auth_user_id': user.id,
        'name': agencyName,
        'email': email,
        'website_url': websiteUrl,
        'media_type': mediaTypeStr,
        'logo_url': logoUrl,
        'status': 'pending',
      });

      // Try to login for session (might fail if email unconfirmed, which is OK)
      if (_client.auth.currentSession == null) {
        try {
          await _client.auth.signInWithPassword(email: email, password: password);
        } catch (_) {}
      }

      if (logoBytes != null && logoBytes.isNotEmpty) {
        final uploadedLogoUrl = await _uploadFile(
          userId: user.id,
          bytes: logoBytes,
          fileExt: logoFileExt,
          bucket: 'agency-logos',
          prefix: 'logo',
        );
        await serviceClient.from('agencies').update({'logo_url': uploadedLogoUrl}).eq('auth_user_id', user.id);
      }

      if (documentBytes != null && documentBytes.isNotEmpty) {
        final documentUrl = await _uploadFile(
          userId: user.id,
          bytes: documentBytes,
          fileExt: documentFileExt,
          bucket: 'agency-documents',
          prefix: 'doc',
        );
        await serviceClient.from('agencies').update({'document_url': documentUrl}).eq('auth_user_id', user.id);
      }
      
    } on AuthApiException catch (e) {
      if (e.message.contains('already registered') || e.code == 'user_already_exists') {
        throw 'Cet email est déjà utilisé par une autre agence.';
      }
      rethrow;
    } on PostgrestException catch (e) {
      debugPrint('Supabase insertion error: ${e.message}');
      throw 'Erreur lors de la création du profil: ${e.message}';
    } catch (e) {
      debugPrint('Unexpected registration error: $e');
      throw 'Une erreur inattendue est survenue lors de l\'inscription.';
    }
  }

  String _mapMediaTypeToString(MediaType type) {
    switch (type) {
      case MediaType.newsAgency: return 'news_agency';
      case MediaType.newspaper: return 'newspaper';
      case MediaType.blog: return 'blog';
      case MediaType.tvChannel: return 'tv_channel';
      case MediaType.radio: return 'radio';
      case MediaType.other: return 'other';
    }
  }

  Future<String> _uploadFile({
    required String userId,
    required Uint8List bytes,
    String? fileExt,
    required String bucket,
    required String prefix,
  }) async {
    var ext = (fileExt ?? 'jpg').trim().toLowerCase().replaceFirst('.', '');
    if (ext.isEmpty || ext.length > 8) ext = 'jpg';
    final path =
        '$userId/${prefix}_${DateTime.now().millisecondsSinceEpoch}.$ext';
    
    final contentType = switch (ext) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      'pdf' => 'application/pdf',
      'jpg' || 'jpeg' => 'image/jpeg',
      _ => 'application/octet-stream',
    };

    await _client.storage.from(bucket).uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: contentType, upsert: true),
        );
    return _client.storage.from(bucket).getPublicUrl(path);
  }

  Future<AgencyModel?> login({
    required String email,
    required String password,
  }) async {
    final authResponse = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    final user = authResponse.user;
    if (user == null) {
      throw Exception('Email ou mot de passe incorrect');
    }

    final response = await _client
        .from('agencies')
        .select()
        .eq('auth_user_id', user.id)
        .maybeSingle();

    if (response == null) throw Exception('Profil agence introuvable');
    return AgencyModel.fromSupabase(response);
  }

  Future<void> logout() async {
    await _client.auth.signOut();
  }

  Future<AgencyModel?> getCurrentAgency() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    final response = await _client
        .from('agencies')
        .select()
        .eq('auth_user_id', user.id)
        .maybeSingle();

    if (response == null) return null;
    return AgencyModel.fromSupabase(response);
  }
}

