import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/errors/app_error.dart';
import '../../../core/utils/device_id.dart';
import '../../../shared/models/models.dart';


class ReportRepository {
  ReportRepository(this._supabase);
  final SupabaseClient _supabase;

  // Signaler un article
  Future<void> reportArticle({
    required String articleId,
    required ReportReason reason,
  }) async {
    try {
      final deviceId = await DeviceIdService.getDeviceId();

      // La contrainte UNIQUE empeche le double signalement par appareil
      await _supabase.from(AppConstants.tableReports).insert({
        'article_id': articleId,
        'device_id': deviceId,
        'reason': reason.name,
      });
    } catch (e) {
      // Code 23505 = violation UNIQUE -> déja signalé
      if (e is PostgrestException && e.code == '23505') {
        throw const AppError(
          message: 'Vous avez déja signalé cet article.',
          code: 'ALREADY_REPORTED',
        );
      }
      throw AppError.fromSupabase(e);
    }
  }

  // ── Vérifier si j'ai déja signalé un article ─────────────
  Future<bool> hasReported(String articleId) async {
    try {
      final deviceId = await DeviceIdService.getDeviceId();

      final response = await _supabase
          .from(AppConstants.tableReports)
          .select('id')
          .eq('article_id', articleId)
          .eq('device_id', deviceId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      return false;
    }
  }
}
