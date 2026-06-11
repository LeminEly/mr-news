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
      final debugToken = token.trim();
      debugPrint('[PasswordReset] verifyCode: email="$email" token="$debugToken"');

      await _client.auth.verifyOTP(
        email: email.trim(),
        token: debugToken,
        type: OtpType.recovery,
      );
    } on AuthApiException catch (e) {
      debugPrint('[PasswordReset] verifyCode AuthApiException: '
          '${e.message} (code=${e.code})');
      throw _mapAuthError(e);
    } catch (e) {
      debugPrint('[PasswordReset] verifyCode error: $e');
      // Si c'est une AuthException, on a le message détaillé
      if (e is AuthException) {
        debugPrint('[PasswordReset] verifyCode AuthException details: '
            'message="${e.message}" statusCode="${e.statusCode}" code="${e.code}"');
        throw _mapAuthError(
          AuthApiException(e.message, code: e.code),
        );
      }
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

  /// Mappe une [AuthApiException] Supabase en message utilisateur en français.
  String _mapAuthError(AuthApiException e) {
    final msg = e.message.toLowerCase();
    final code = e.code;

    debugPrint('[PasswordReset] _mapAuthError: code="$code" message="$msg"');

    // --- Rate limit (doit être vérifié AVANT les erreurs OTP) ---
    if (code == 'over_email_send_rate_limit' ||
        msg.contains('rate limit') ||
        msg.contains('too many requests') ||
        msg.contains('trop de tentatives')) {
      return 'Trop de tentatives. Veuillez patienter 30 secondes avant de réessayer.';
    }

    // --- OTP expiré ---
    if (code == 'otp_expired') {
      return 'Le code a expiré. Veuillez en demander un nouveau.';
    }

    // --- OTP invalide (code erroné) ---
    if (code == 'otp_not_found') {
      return 'Code invalide. Vérifiez le code saisi et réessayez.';
    }

    // --- Erreurs génériques liées au jeton/OTP ---
    if ((code?.contains('otp') ?? false) || (code?.contains('token') ?? false) ||
        msg.contains('otp') || msg.contains('token')) {
      if (msg.contains('expired') || msg.contains('expiré')) {
        return 'Le code a expiré. Veuillez en demander un nouveau.';
      }
      if (msg.contains('invalid') || msg.contains('invalide')) {
        return 'Code invalide. Vérifiez le code reçu par email et réessayez.';
      }
      return 'Code invalide ou expiré. Veuillez en demander un nouveau.';
    }

    // --- Mot de passe trop faible ---
    if (code == 'weak_password' ||
        msg.contains('weak') ||
        msg.contains('at least') ||
        msg.contains('password should')) {
      return 'Mot de passe trop faible (6 caractères minimum).';
    }

    return 'Une erreur est survenue : ${e.message}';
  }
}
