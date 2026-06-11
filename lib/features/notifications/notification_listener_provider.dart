// lib/features/notifications/notification_listener_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/notification_service.dart';
import '../feed/providers/feed_providers.dart'; // ← import correct

final notificationListenerProvider = Provider<void>((ref) {
  print('>>> NOTIFICATION LISTENER DÉMARRÉ');

  final repo = ref.read(feedRepositoryProvider);

  final sub = repo.watchNewArticles().listen((article) {
    print('NOUVEL ARTICLE: ${article.title}');
    NotificationService.showArticleNotification(
      title: '📰 Nouvel article',
      body: article.title,
      articleId: article.id,
    );
  });

  ref.onDispose(() => sub.cancel());
});
