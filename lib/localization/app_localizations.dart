import 'package:flutter/material.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../core/utils/logger.dart';
import '../state/app_state.dart';

class LanguageNotifier extends ChangeNotifier {
  String _currentLanguage = 'cs';

  String get currentLanguage => _currentLanguage;

  Future<void> changeLanguage(String languageCode) async {
    AppLogger.debug(
      'LanguageNotifier - Changing language from $_currentLanguage to $languageCode',
    );
    _currentLanguage = languageCode;
    notifyListeners();
    AppLogger.debug('LanguageNotifier - Language changed to $_currentLanguage');
  }
}

class AppLocalizations {
  static const String _languageKey = 'language_code';
  static late LocalizationDelegate _delegate;
  static final LanguageNotifier _languageNotifier = LanguageNotifier();

  static LanguageNotifier get languageNotifier => _languageNotifier;

  static Future<LocalizationDelegate> initialize() async {
    AppLogger.debug('AppLocalizations - Initializing localization');
    final prefs = await SharedPreferences.getInstance();
    final savedLanguage = prefs.getString(_languageKey) ?? 'cs';
    AppLogger.debug(
      'AppLocalizations - Saved language from preferences: $savedLanguage',
    );

    _delegate = await LocalizationDelegate.create(
      fallbackLocale: 'cs',
      supportedLocales: ['en', 'cs'],
    );

    // Load the saved language
    await _delegate.load(Locale(savedLanguage));
    AppLogger.debug('AppLocalizations - Loaded language: $savedLanguage');
    await _languageNotifier.changeLanguage(savedLanguage);

    return _delegate;
  }

  static LocalizationDelegate get delegate => _delegate;

  static Future<void> changeLanguage(
    BuildContext context,
    String languageCode,
  ) async {
    try {
      AppLogger.debug('AppLocalizations - Changing language to: $languageCode');

      // Update shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, languageCode);
      AppLogger.debug(
        'AppLocalizations - Saved language to preferences: $languageCode',
      );

      // Update flutter_translate
      await _delegate.load(Locale(languageCode));
      AppLogger.debug('AppLocalizations - Loaded new language: $languageCode');

      // Update LanguageNotifier
      await _languageNotifier.changeLanguage(languageCode);

      // Update AppState
      if (context.mounted) {
        final appState = context.read<AppState>();
        await appState.handleLanguageChange(languageCode);
        AppLogger.debug(
          'AppLocalizations - Updated AppState with new language',
        );
      }

      AppLogger.info('Language change completed successfully');
    } catch (e, stackTrace) {
      AppLogger.error('Error changing language', e, stackTrace);
      rethrow;
    }
  }

  static Future<String> getCurrentLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final language = prefs.getString(_languageKey) ?? 'cs';
      AppLogger.debug('AppLocalizations - Getting current language: $language');
      return language;
    } catch (e, stackTrace) {
      AppLogger.error('Error getting current language', e, stackTrace);
      return 'cs'; // Fallback to Czech
    }
  }
}
