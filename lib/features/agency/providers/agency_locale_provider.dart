import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_constants.dart';

final agencyLocaleProvider =
    StateNotifierProvider<AgencyLocaleNotifier, Locale>((ref) {
  return AgencyLocaleNotifier();
});

class AgencyLocaleNotifier extends StateNotifier<Locale> {
  AgencyLocaleNotifier() : super(const Locale('fr')) {
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(AppConstants.keyAgencyLanguage);
    if (code == 'ar' || code == 'fr') {
      state = Locale(code!);
    }
  }

  Future<void> setLocale(String languageCode) async {
    if (languageCode != 'fr' && languageCode != 'ar') return;
    state = Locale(languageCode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyAgencyLanguage, languageCode);
  }

  bool get isArabic => state.languageCode == 'ar';
}
