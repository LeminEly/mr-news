import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/models/agency_model.dart';

class AgencyAuthService {
  final SupabaseClient _client;
  AgencyAuthService(this._client);

  Future<void> register({
    required String email,
    required String password,
    required String agencyName,
    required String websiteUrl,
    required String mediaType,
    String? logoUrl,
    Uint8List? logoBytes,
    String? logoFileExt,
  }) async {
    try {
      final authResponse = await _client.auth.signUp(
        email: email,
        password: password,
        data: const {'role': 'agency'},
      );
      final user = authResponse.user;
      if (user == null) throw Exception('Échec création compte');

      // IMPORTANT (RLS):
      // La policy `agencies_insert_any_auth` exige un JWT valide (auth.uid()).
      // On s'assure d'être authentifié avant l'insert pour respecter les politiques RLS.
      if (_client.auth.currentSession == null) {
        await _client.auth.signInWithPassword(email: email, password: password);
      }

      String? resolvedLogoUrl = logoUrl;
      if (resolvedLogoUrl == null &&
          logoBytes != null &&
          logoBytes.isNotEmpty) {
        resolvedLogoUrl = await _uploadAgencyLogoBytes(
          userId: user.id,
          bytes: logoBytes,
          fileExt: logoFileExt,
        );
      }

      await _client.from('agencies').insert({
        'auth_user_id': user.id,
        'name': agencyName,
        'email': email,
        'website_url': websiteUrl,
        'media_type': mediaType,
        'logo_url': resolvedLogoUrl,
        'status': 'pending',
      });
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<String> _uploadAgencyLogoBytes({
    required String userId,
    required Uint8List bytes,
    String? fileExt,
  }) async {
    var ext = (fileExt ?? 'jpg').trim().toLowerCase().replaceFirst('.', '');
    if (ext.isEmpty || ext.length > 8) ext = 'jpg';
    final path =
        '$userId/logo_${DateTime.now().millisecondsSinceEpoch}.$ext';
    final contentType = switch (ext) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      'jpg' => 'image/jpeg',
      'jpeg' => 'image/jpeg',
      _ => 'image/jpeg',
    };
    await _client.storage.from('agency-logos').uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: contentType, upsert: true),
        );
    return _client.storage.from('agency-logos').getPublicUrl(path);
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

