import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../main.dart';
import '../constants/app_constants.dart';

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier();
});

class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier() : super(const Locale('fr')) {
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final langCode = prefs.getString('language_code');
    if (langCode != null) {
      state = Locale(langCode);
    }
  }

  Future<void> setLocale(Locale locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', locale.languageCode);
    state = locale;
  }
}

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static final Map<String, Map<String, String>> _localizedValues = {
    'fr': {
      'app_title': 'Mr-News',
      'management_portal': 'Portail de Gestion',
      'agency_space': 'Espace Agence',
      'agency_desc': 'Inscrivez votre agence de presse ou connectez-vous pour publier vos articles.',
      'signup': "S'inscrire",
      'signin': 'Se connecter',
      'admin': 'Administration',
      'admin_desc': 'Accès réservé aux administrateurs pour la modération et la gestion du système.',
      'sign_admin': 'Connexion Admin',
      'admin_login_title': 'Connexion Administrateur',
      'email': 'Adresse email',
      'password': 'Mot de passe',
      'connect': 'Se connecter',
      'agency_signup_title': 'Inscription Agence',
      'agency_name': "Nom de l'agence",
      'required_field': 'Champ requis',
      'no_account': "Pas de compte ? S'inscrire",
      'already_account': 'Déjà un compte ? Se connecter',
      'portal_desc': 'Accès Administration & Agences',
      'admin_tab': 'Admin',
      'agency_tab': 'Agence',
      'pending_msg': "Votre compte est en attente de validation",
      'rejected_msg': "Votre compte a été refusé",
      'unknown_status': 'Statut du compte inconnu',
      'admin_space': 'Espace Administrateur',
    },
    'en': {
      'app_title': 'Mr-News',
      'management_portal': 'Management Portal',
      'agency_space': 'Agency Space',
      'agency_desc': 'Register your press agency or log in to publish your articles.',
      'signup': 'Sign Up',
      'signin': 'Sign In',
      'admin': 'Administration',
      'admin_desc': 'Access reserved for administrators for moderation and system management.',
      'sign_admin': 'Admin Login',
      'admin_login_title': 'Administrator Login',
      'email': 'Email Address',
      'password': 'Password',
      'connect': 'Connect',
      'agency_signup_title': 'Agency Registration',
      'agency_name': 'Agency Name',
      'required_field': 'Required field',
      'no_account': "Don't have an account? Sign up",
      'already_account': 'Already have an account? Sign in',
      'portal_desc': 'Administration & Agencies Access',
      'admin_tab': 'Admin',
      'agency_tab': 'Agency',
      'pending_msg': "Your account is pending validation",
      'rejected_msg': "Your account has been rejected",
      'unknown_status': 'Unknown account status',
      'admin_space': 'Administrator Space',
    },
    'ar': {
      'app_title': 'السيد نيوز',
      'management_portal': 'بوابة الإدارة',
      'agency_space': 'مساحة الوكالة',
      'agency_desc': 'قم بتسجيل وكالة الأنباء الخاصة بك أو تسجيل الدخول لنشر مقالاتك.',
      'signup': 'التسجيل',
      'signin': 'تسجيل الدخول',
      'admin': 'الإدارة',
      'admin_desc': 'الوصول محجوز للمسؤولين للإشراف وإدارة النظام.',
      'sign_admin': 'دخول المسؤول',
      'admin_login_title': 'تسجيل دخول المسؤول',
      'email': 'البريد الإلكتروني',
      'password': 'كلمة المرور',
      'connect': 'اتصال',
      'agency_signup_title': 'تسجيل الوكالة',
      'agency_name': 'اسم الوكالة',
      'required_field': 'حقل مطلوب',
      'no_account': 'ليس لديك حساب؟ تسجيل',
      'already_account': 'لديك حساب بالفعل؟ تسجيل الدخول',
      'portal_desc': 'وصول الإدارة والوكالات',
      'admin_tab': 'المسؤول',
      'agency_tab': 'الوكالة',
      'pending_msg': "حسابك قيد الانتظار للتحقق",
      'rejected_msg': "لقد تم رفض حسابك",
      'unknown_status': 'حالة الحساب غير معروفة',
      'admin_space': 'مساحة المسؤول',
    },
  };

  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? _localizedValues['fr']![key] ?? key;
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['fr', 'en', 'ar'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

extension AppLocalizationsExtension on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

class LanguageSwitcher extends ConsumerWidget {
  const LanguageSwitcher({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(appLocaleProvider);
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: locale.languageCode,
          icon: const Icon(Icons.language, color: Colors.blue),
          dropdownColor: Colors.white,
          onChanged: (String? newValue) async {
            if (newValue != null) {
              ref.read(appLocaleProvider.notifier).state = Locale(newValue);
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString(AppConstants.keyAppLanguage, newValue);
            }
          },
          items: const [
            DropdownMenuItem(value: 'fr', child: Text('FR', style: TextStyle(color: Colors.black))),
            DropdownMenuItem(value: 'en', child: Text('EN', style: TextStyle(color: Colors.black))),
            DropdownMenuItem(value: 'ar', child: Text('AR', style: TextStyle(color: Colors.black))),
          ],
        ),
      ),
    );
  }
}
