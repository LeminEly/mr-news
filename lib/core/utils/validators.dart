class Validators {
  Validators._();

  // EMAIL
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email requis';
    final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,}$');
    if (!regex.hasMatch(value.trim())) return 'Email invalide';
    return null;
  }

  // PASSWORD
  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Mot de passe requis';
    if (value.length < 8) return 'Au moins 8 caractères';
    return null;
  }

  // AGENCY NAME
  static String? agencyName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Nom requis';
    if (value.trim().length < 2) return 'Au moins 2 caractères';
    return null;
  }

  // WEBSITE URL
  static String? websiteUrl(String? value) {
    if (value == null || value.trim().isEmpty) return 'URL requise';
    final regex = RegExp(r'^https?://');
    if (!regex.hasMatch(value.trim())) return 'URL doit commencer par https://';
    return null;
  }

  // ARTICLE TITLE
  static String? articleTitle(String? value) {
    if (value == null || value.trim().isEmpty) return 'Titre requis';
    if (value.trim().length < 3) return 'Titre trop court';
    return null;
  }

  // ARTICLE URL
  static String? articleUrl(String? value) {
    if (value == null || value.trim().isEmpty) return 'Lien requis';
    final regex = RegExp(r'^https?://');
    if (!regex.hasMatch(value.trim())) return 'Lien invalide (doit commencer par https://)';
    return null;
  }

  // REQUIRED
  static String? required(String? value, {String message = 'Champ requis'}) {
    if (value == null || value.trim().isEmpty) return message;
    return null;
  }
}