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
import 'core/localization/l10n.dart';

import 'package:intl/date_symbol_data_local.dart';
import 'package:mauritanie_news/features/notifications/notification_listener_provider.dart';
import 'core/services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('fr_FR', null);
  await initializeDateFormatting('ar_SA', null);

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await NotificationService.init();

  try {
    await Supabase.initialize(
      url: Env.appSupabaseUrl,
      anonKey: Env.appSupabaseAnonKey,
      debug: true,
    );
  } catch (e) {
    debugPrint('Supabase init error: $e');
  }

  final supabase = Supabase.instance.client;

  final channel = supabase.channel('test');

  channel.onPostgresChanges(
    event: PostgresChangeEvent.insert,
    schema: 'public',
    table: 'articles',
    callback: (payload) {
      print('INSERT DETECTE');
      print(payload.newRecord);
    },
  );

  channel.subscribe(
    (status, error) {
      print('REALTIME STATUS: $status');

      if (error != null) {
        print('REALTIME ERROR: $error');
      }
    },
  );

  debugPrint('CHANNEL SUBSCRIBED');

  final prefs = await SharedPreferences.getInstance();

  final savedLang = prefs.getString(AppConstants.keyAppLanguage);

  final onboardingDone = prefs.getBool(AppConstants.keyOnboardingDone) ?? false;

  runApp(
    ProviderScope(
      overrides: [
        initialLocaleProvider.overrideWithValue(
          savedLang != null ? Locale(savedLang) : null,
        ),
        initialOnboardingDoneProvider.overrideWithValue(
          onboardingDone,
        ),
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
    ref.watch(notificationListenerProvider);

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
      supportedLocales: const [Locale('fr'), Locale('en'), Locale('ar')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
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
