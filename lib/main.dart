import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:mauritanie_news/features/agency/ui/agency_dashboard_screen.dart';
import 'package:mauritanie_news/shared/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR', null);
  runApp(const MauritanieNewsApp());
}

class MauritanieNewsApp extends StatelessWidget {
  const MauritanieNewsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mauritanie News',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      locale: const Locale('fr'),
      supportedLocales: const [
        Locale('fr'),
        Locale('ar'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const AgencyDashboardScreen(),
    );
  }
}
