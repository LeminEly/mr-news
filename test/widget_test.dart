// Smoke test : l'application démarre et construit un MaterialApp sans planter.
//
// Le provider d'articles est surchargé pour renvoyer une liste vide : on évite
// tout appel réseau réel (et donc les Timers en attente qui feraient échouer le
// test via l'assertion `!timersPending`).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:mauritanie_news/main.dart';
import 'package:mauritanie_news/features/feed/providers/feed_providers.dart';
import 'package:mauritanie_news/features/notifications/notification_listener_provider.dart';
import 'package:mauritanie_news/shared/models/models.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      anonKey: 'test-anon-key',
    );
  });

  testWidgets('App boots without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // Pas de réseau : feed vide → état "aucun article".
          feedArticlesProvider.overrideWith((ref) async => <ArticleModel>[]),
          // Coupe l'abonnement realtime (websocket) au démarrage → pas de Timer pendant.
          notificationListenerProvider.overrideWith((ref) {}),
        ],
        child: const MauritanieNewsApp(),
      ),
    );
    await tester.pump();

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
