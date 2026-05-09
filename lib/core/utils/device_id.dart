import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../constants/app_constants.dart';

class DeviceIdService {
  DeviceIdService._();

  static String? _cachedId;

  /// Retourne le Device ID unique de cet appareil.
  /// Génere un UUID v4 au premier lancement et le persiste.
  static Future<String> getDeviceId() async {
    if (_cachedId != null) return _cachedId!;

    final prefs = await SharedPreferences.getInstance();
    String? storedId = prefs.getString(AppConstants.keyDeviceId);

    if (storedId == null || storedId.isEmpty) {
      storedId = const Uuid().v4();
      await prefs.setString(AppConstants.keyDeviceId, storedId);
    }

    _cachedId = storedId;
    return _cachedId!; 
  }

  /// Pour les tests uniquement
  static void clearCache() => _cachedId = null;
}
