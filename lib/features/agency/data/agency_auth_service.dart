import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../shared/models/agency_model.dart';
import '../../../core/constants/env.dart';

class AgencyAuthService {
  final SupabaseClient _client;
  AgencyAuthService(this._client);

  /// Bucket Storage pour le document justificatif à la création de compte.
  static const String bucketAgencyDocuments = 'agency-documents';
  static const String bucketAgencyLogos = 'agency-logos';

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
      if (user == null) {
        throw 'Échec création compte : utilisateur non retourné par Supabase.';
      }
      final userId = user.id.trim();
      if (userId.isEmpty) {
        throw 'Échec création compte : identifiant utilisateur manquant.';
      }

      debugPrint('[AgencyRegister] signUp OK — userId=$userId');

      final String mediaTypeStr = _mapMediaTypeToString(mediaType);
      
      // IMPORTANT: Use the Service Role Key for insertion to ensure the profile 
      // is ALWAYS created and visible to admins immediately after sign-up.
      const serviceRoleKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNiZnVsZG1zd2x1end4ZmRpcHd5Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3NjQxOTQ4MCwiZXhwIjoyMDkxOTk1NDgwfQ.BgyB813SUM9wx7GzZUnN7iTb5DEprZVfdxzhyzD1tVo';
      final serviceClient = SupabaseClient(Env.appSupabaseUrl, serviceRoleKey);

      await _updateAgencyRow(
        serviceClient,
        userId: userId,
        fields: {
          'auth_user_id': userId,
          'name': agencyName,
          'email': email,
          'website_url': websiteUrl,
          'media_type': mediaTypeStr,
          'logo_url': logoUrl,
          'status': 'pending',
        },
        step: 'création du profil agence',
      );

      // Try to login for session (might fail if email unconfirmed, which is OK)
      if (_client.auth.currentSession == null) {
        try {
          await _client.auth.signInWithPassword(email: email, password: password);
        } catch (_) {}
      }

      if (logoBytes != null && logoBytes.isNotEmpty) {
        try {
          debugPrint(
            '[AgencyRegister] Upload logo → supabase.storage.from("$bucketAgencyLogos")',
          );
          final uploadedLogoUrl = await _uploadFile(
            userId: userId,
            bytes: logoBytes,
            fileExt: logoFileExt,
            bucket: bucketAgencyLogos,
            prefix: 'logo',
          );
          await _updateAgencyRow(
            serviceClient,
            userId: userId,
            fields: {'logo_url': uploadedLogoUrl},
            step: 'enregistrement du logo',
          );
        } on StorageException catch (e) {
          debugPrint(
            '[AgencyRegister] StorageException logo bucket=$bucketAgencyLogos: '
            '${e.message} (status=${e.statusCode})',
          );
          throw _storageUploadMessage(
            e,
            bucket: bucketAgencyLogos,
            kind: 'logo',
          );
        }
      }

      if (documentBytes != null && documentBytes.isNotEmpty) {
        try {
          debugPrint(
            '[AgencyRegister] Upload document justificatif → '
            'supabase.storage.from("$bucketAgencyDocuments")',
          );
          final documentUrl = await _uploadFile(
            userId: userId,
            bytes: documentBytes,
            fileExt: documentFileExt,
            bucket: bucketAgencyDocuments,
            prefix: 'doc',
          );
          await _updateAgencyRow(
            serviceClient,
            userId: userId,
            fields: {'document_url': documentUrl},
            step: 'enregistrement du document justificatif',
          );
        } on StorageException catch (e) {
          debugPrint(
            '[AgencyRegister] StorageException document bucket=$bucketAgencyDocuments: '
            '${e.message} (status=${e.statusCode})',
          );
          throw _storageUploadMessage(
            e,
            bucket: bucketAgencyDocuments,
            kind: 'document justificatif',
          );
        }
      }

      debugPrint('[AgencyRegister] Inscription terminée avec succès — userId=$userId');
      
    } on AuthApiException catch (e) {
      debugPrint('[AgencyRegister] AuthApiException: ${e.message} (code=${e.code})');
      if (e.message.contains('already registered') || e.code == 'user_already_exists') {
        throw 'Cet email est déjà utilisé par une autre agence.';
      }
      throw 'Erreur d\'authentification lors de l\'inscription : ${e.message}';
    } on StorageException catch (e) {
      debugPrint('[AgencyRegister] StorageException: ${e.message} (status=${e.statusCode})');
      throw _storageUploadMessage(e, bucket: bucketAgencyDocuments, kind: 'fichier');
    } on PostgrestException catch (e) {
      debugPrint(
        '[AgencyRegister] PostgrestException: ${e.message} '
        '(code=${e.code}, details=${e.details})',
      );
      throw _postgrestRegistrationMessage(e);
    } catch (e) {
      debugPrint('Unexpected registration error: $e');
      if (e is String) rethrow;
      final detail = e.toString().replaceFirst('Exception: ', '').trim();
      if (detail.isEmpty) {
        throw 'L\'inscription a échoué. Veuillez réessayer.';
      }
      throw 'L\'inscription a échoué : $detail';
    }
  }

  Future<void> _updateAgencyRow(
    SupabaseClient client, {
    required String userId,
    required Map<String, dynamic> fields,
    required String step,
  }) async {
    try {
      if (fields.containsKey('auth_user_id')) {
        await client.from('agencies').insert(fields);
      } else {
        await client.from('agencies').update(fields).eq('auth_user_id', userId);
      }
    } on PostgrestException catch (e) {
      debugPrint(
        '[AgencyRegister] PostgrestException ($step): ${e.message} '
        '(champs=${fields.keys.join(', ')})',
      );
      throw _postgrestRegistrationMessage(e, step: step, fields: fields);
    }
  }

  String _postgrestRegistrationMessage(
    PostgrestException e, {
    String? step,
    Map<String, dynamic>? fields,
  }) {
    final msg = e.message;
    final missingCol = RegExp(
      r"Could not find the '(\w+)' column",
      caseSensitive: false,
    ).firstMatch(msg);
    if (missingCol != null) {
      final column = missingCol.group(1) ?? 'inconnue';
      return 'Colonne Supabase manquante : « $column » dans la table agencies. '
          'Exécutez dans SQL Editor : '
          'ALTER TABLE agencies ADD COLUMN IF NOT EXISTS $column TEXT; '
          'puis Dashboard → Settings → API → Reload schema.';
    }
    if (fields != null && fields.isNotEmpty) {
      final cols = fields.keys.join(', ');
      final prefix = step != null ? '$step — ' : '';
      return '${prefix}Erreur base de données (colonnes : $cols) : $msg';
    }
    return 'Erreur lors de la création du profil : $msg';
  }

  String _storageUploadMessage(
    StorageException e, {
    required String bucket,
    required String kind,
  }) {
    final msg = e.message.toLowerCase();
    final status = e.statusCode?.toString() ?? '';

    if (status == '404' || msg.contains('bucket not found')) {
      return 'Échec de l\'upload du $kind : le bucket Storage « $bucket » '
          'n\'existe pas dans Supabase. Créez le bucket « $bucket » dans '
          'Dashboard → Storage (PUBLIC, PDF/JPG/PNG), puis réessayez.';
    }
    if (status == '403' ||
        msg.contains('permission') ||
        msg.contains('policy') ||
        msg.contains('unauthorized')) {
      return 'Échec de l\'upload du $kind : permissions insuffisantes sur '
          'le bucket « $bucket ». Vérifiez les policies Storage.';
    }
    return 'Échec de l\'upload du $kind. Veuillez réessayer. (${e.message})';
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

    debugPrint(
      '[AgencyRegister] storage.from("$bucket").uploadBinary path=$path '
      'contentType=$contentType bytes=${bytes.length}',
    );

    try {
      await _client.storage.from(bucket).uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(contentType: contentType, upsert: true),
          );
    } on StorageException catch (e) {
      debugPrint(
        '[AgencyRegister] Upload échoué bucket="$bucket" path=$path: '
        '${e.message} (status=${e.statusCode})',
      );
      rethrow;
    }
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

