import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Gère la réinitialisation du mot de passe via un code OTP envoyé par email.
///
/// Flux :
///   1. [sendResetCode] — Supabase envoie un code à 6 chiffres par email.
///   2. [verifyCode] — vérifie le code et ouvre une session de récupération.
///   3. [updatePassword] — applique le nouveau mot de passe.
///
/// Fonctionne pour les comptes admin et agence (l'opération porte sur
/// l'utilisateur auth, indépendamment du rôle).
class PasswordResetService {
  final SupabaseClient _client;
  PasswordResetService(this._client);

  /// Envoie un code de réinitialisation à l'adresse email.
  ///
  /// Pour des raisons de sécurité, Supabase ne révèle pas si l'email existe :
  /// l'appel réussit silencieusement même si aucun compte n'est associé.
  Future<void> sendResetCode(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(email.trim());
    } on AuthApiException catch (e) {
      debugPrint('[PasswordReset] sendResetCode AuthApiException: '
          '${e.message} (code=${e.code})');
      throw _mapAuthError(e);
    } catch (e) {
      debugPrint('[PasswordReset] sendResetCode error: $e');
      throw "L'envoi du code a échoué. Veuillez réessayer.";
    }
  }

  /// Vérifie le code OTP reçu par email et ouvre une session de récupération.
  Future<void> verifyCode({
    required String email,
    required String token,
  }) async {
    try {
      await _client.auth.verifyOTP(
        email: email.trim(),
        token: token.trim(),
        type: OtpType.recovery,
      );
    } on AuthApiException catch (e) {
      debugPrint('[PasswordReset] verifyCode AuthApiException: '
          '${e.message} (code=${e.code})');
      throw _mapAuthError(e);
    } catch (e) {
      debugPrint('[PasswordReset] verifyCode error: $e');
      throw 'Code invalide ou expiré. Veuillez réessayer.';
    }
  }

  /// Applique le nouveau mot de passe (nécessite une session de récupération).
  Future<void> updatePassword(String newPassword) async {
    try {
      await _client.auth.updateUser(
        UserAttributes(password: newPassword),
      );
    } on AuthApiException catch (e) {
      debugPrint('[PasswordReset] updatePassword AuthApiException: '
          '${e.message} (code=${e.code})');
      throw _mapAuthError(e);
    } catch (e) {
      debugPrint('[PasswordReset] updatePassword error: $e');
      throw 'La mise à jour du mot de passe a échoué. Veuillez réessayer.';
    }
  }

  String _mapAuthError(AuthApiException e) {
    final msg = e.message.toLowerCase();
    if (e.code == 'otp_expired' ||
        msg.contains('expired') ||
        msg.contains('invalid') && msg.contains('token') ||
        msg.contains('otp')) {
      return 'Code invalide ou expiré. Veuillez en demander un nouveau.';
    }
    if (e.code == 'weak_password' ||
        msg.contains('weak') ||
        msg.contains('at least') ||
        msg.contains('password should')) {
      return 'Mot de passe trop faible (6 caractères minimum).';
    }
    if (e.code == 'over_email_send_rate_limit' ||
        msg.contains('rate limit') ||
        msg.contains('too many')) {
      return 'Trop de tentatives. Veuillez patienter avant de réessayer.';
    }
    return 'Une erreur est survenue : ${e.message}';
  }
}
