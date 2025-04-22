import 'package:flutter/material.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppLocalizations {
  static const String _languageKey = 'language_code';

  static Future<void> changeLanguage(
    BuildContext context,
    String languageCode,
  ) async {
    var localizedApp = LocalizedApp.of(context);
    await localizedApp.delegate.load(Locale(languageCode));

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, languageCode);
  }

  static Future<String> getCurrentLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_languageKey) ?? 'en';
  }
}
