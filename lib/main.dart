import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/constants/app_constants.dart';
import 'shared/theme/app_theme.dart';
import 'app/router.dart';
import 'core/constants/env.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Orientation portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Init Supabase 
  try {
    await Supabase.initialize(
      url: Env.appSupabaseUrl,
      anonKey: Env.appSupabaseAnonKey,
      debug: true, // true en développement
    );
  } catch (e) {
    debugPrint('Supabase init error: $e');
  }

  debugPrint(
    '=== IMPORTANT: Exécuter lib/supabase/rls_policies.sql dans Supabase Dashboard ===',
  );

  // Lire la langue sauvegardée
  final prefs = await SharedPreferences.getInstance();
  final savedLang = prefs.getString(AppConstants.keyAppLanguage);
  final onboardingDone = prefs.getBool(AppConstants.keyOnboardingDone) ?? false;

  runApp(
    ProviderScope(
      overrides: [
        initialLocaleProvider.overrideWithValue(
          savedLang != null ? Locale(savedLang) : null,
        ),
        initialOnboardingDoneProvider.overrideWithValue(onboardingDone),
      ],
      child: const MauritanieNewsApp(),
    ),
  );
}

// Providers d'initialisation 
final initialLocaleProvider = Provider<Locale?>((ref) => null);
final initialOnboardingDoneProvider = Provider<bool>((ref) => false);

// App locale
final appLocaleProvider = StateProvider<Locale>((ref) {
  return ref.watch(initialLocaleProvider) ?? const Locale('fr');
});

// 
// ROOT APP WIDGET
// 

class MauritanieNewsApp extends ConsumerWidget {
  const MauritanieNewsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final locale = ref.watch(appLocaleProvider);
    final fontFamily = locale.languageCode == 'ar'
        ? AppTextStyles.fontAr
        : AppTextStyles.fontFr;

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,

      // Thème 
      theme: AppTheme.light(fontFamily: fontFamily),
      darkTheme: AppTheme.dark(fontFamily: fontFamily),
      themeMode: ThemeMode.system,

      // Localisation
      locale: locale,
      supportedLocales: const [Locale('ar'), Locale('fr')],
      localizationsDelegates: const [
        // AppLocalizations.delegate, // ajouter avec flutter gen-l10n
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      // RTL auto selon la locale
      builder: (context, child) {
        return Directionality(
          textDirection: locale.languageCode == 'ar'
              ? TextDirection.rtl
              : TextDirection.ltr,
          child: child!,
        );
      },

      // Navigation
      routerConfig: router,
    );
  }
}