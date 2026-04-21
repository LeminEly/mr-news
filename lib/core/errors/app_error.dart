import 'package:supabase_flutter/supabase_flutter.dart';

/// Erreurs métier unifiées de l'application
class AppError implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  const AppError({
    required this.message,
    this.code,
    this.originalError,
  });

  /// Convertit une erreur Supabase en AppError lisible
  factory AppError.fromSupabase(dynamic error) {
    if (error is AuthException) {
      return AppError(
        message: _translateAuthError(error.message),
        code: error.statusCode,
        originalError: error,
      );
    }
    if (error is PostgrestException) {
      return AppError(
        message: _translatePostgrestError(error),
        code: error.code,
        originalError: error,
      );
    }
    return AppError(
      message: 'Une erreur inattendue s\'est produite.',
      originalError: error,
    );
  }

  static String _translateAuthError(String message) {
    if (message.contains('Invalid login')) return 'Email ou mot de passe incorrect.';
    if (message.contains('Email not confirmed')) return 'Veuillez confirmer votre email.';
    if (message.contains('User already registered')) return 'Cet email est déja utilisé.';
    if (message.contains('Password should be')) return 'Mot de passe trop faible.';
    if (message.contains('rate limit')) return 'Trop de tentatives. Réessayez plus tard.';
    return 'Erreur d\'authentification.';
  }

  static String _translatePostgrestError(PostgrestException error) {
    if (error.code == '23505') return 'Cette entrée existe déja.'; // unique violation
    if (error.code == '23503') return 'Référence invalide.';       // FK violation
    if (error.code == '42501') return 'Permission refusée.';       // RLS violation
    return 'Erreur de base de données.';
  }

  @override
  String toString() => 'AppError(code: $code, message: $message)';
}

/// Résultat unifié — succès ou erreur
class Result<T> {
  final T? data;
  final AppError? error;

  const Result.success(this.data) : error = null;
  const Result.failure(this.error) : data = null;

  bool get isSuccess => error == null;
  bool get isFailure => error != null;
}