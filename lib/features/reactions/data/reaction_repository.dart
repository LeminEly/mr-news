import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/errors/app_error.dart';
import '../../../core/utils/device_id.dart';
import '../../../shared/models/models.dart';

class ReactionRepository {
  ReactionRepository(this._supabase);
  final SupabaseClient _supabase;

  // Obtenir ma réaction pour un article
  Future<EmojiType?> getMyReaction(String articleId) async {
    try {
      final deviceId = await DeviceIdService.getDeviceId();

      final response = await _supabase
          .from(AppConstants.tableReactions)
          .select('emoji_type')
          .eq('article_id', articleId)
          .eq('device_id', deviceId)
          .maybeSingle();

      if (response == null) return null;

      final emojiStr = response['emoji_type'] as String;
      return EmojiType.values.firstWhere((e) => e.name == emojiStr);
    } catch (e) {
      throw AppError.fromSupabase(e);
    }
  }

  // Réagir / changer sa réaction
  Future<void> react({
    required String articleId,
    required EmojiType emoji,
  }) async {
    try {
      final deviceId = await DeviceIdService.getDeviceId();

      // Upsert: crée ou met a jour la réaction
      await _supabase.from(AppConstants.tableReactions).upsert(
        {
          'article_id': articleId,
          'device_id': deviceId,
          'emoji_type': emoji.name,
          'updated_at': DateTime.now().toIso8601String(),
        },
        onConflict: 'article_id,device_id',
      );
    } catch (e) {
      throw AppError.fromSupabase(e);
    }
  }

  // Supprimer sa réaction
  Future<void> removeReaction(String articleId) async {
    try {
      final deviceId = await DeviceIdService.getDeviceId();

      await _supabase
          .from(AppConstants.tableReactions)
          .delete()
          .eq('article_id', articleId)
          .eq('device_id', deviceId);
    } catch (e) {
      throw AppError.fromSupabase(e);
    }
  }

  // Charger les comptages pour un article
  Future<ReactionCounts> getReactionCounts(String articleId) async {
    try {
      final response = await _supabase
          .from(AppConstants.viewArticleReactionCounts)
          .select()
          .eq('article_id', articleId)
          .maybeSingle();

      if (response == null) return const ReactionCounts();
      return ReactionCounts.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw AppError.fromSupabase(e);
    }
  }
}
