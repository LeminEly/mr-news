// lib/core/services/notification_service.dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );

    // Créer le canal Android explicitement
    const androidChannel = AndroidNotificationChannel(
      'new_articles',
      'Nouveaux articles',
      description: 'Notifications pour les nouveaux articles publiés',
      importance: Importance.high,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  static Future<void> showArticleNotification({
    required String title,
    required String body,
    String? articleId,
  }) async {
    print('>>> NOTIF DEBUT: $title');

    try {
      const androidDetails = AndroidNotificationDetails(
        'new_articles',
        'Nouveaux articles',
        channelDescription: 'Notifications pour les nouveaux articles publiés',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );

      await _plugin.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        const NotificationDetails(android: androidDetails),
        payload: articleId,
      );

      print('>>> NOTIF ENVOYÉE OK');
    } catch (e) {
      print('>>> NOTIF ERREUR: $e');
    }
  }
}
