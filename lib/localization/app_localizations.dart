import 'package:flutter/material.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../core/utils/logger.dart';
import '../state/app_state.dart';

class LanguageNotifier extends ChangeNotifier {
  String _currentLanguage = 'cs';

  String get currentLanguage => _currentLanguage;

  static final _logger = AppLogger('LanguageNotifier');

  Future<void> changeLanguage(String languageCode) async {
    _logger.debug('Changing language from $_currentLanguage to $languageCode');
    _currentLanguage = languageCode;
    notifyListeners();
    _logger.debug('Language changed to $_currentLanguage');
  }
}

class AppLocalizations {
  static final _logger = AppLogger('AppLocalizations');
  static const String _languageKey = 'language_code';
  static late LocalizationDelegate _delegate;
  static final LanguageNotifier _languageNotifier = LanguageNotifier();

  static LanguageNotifier get languageNotifier => _languageNotifier;

  static Future<LocalizationDelegate> initialize() async {
    try {
      _logger.debug('AppLocalizations - Initializing localization');
      final prefs = await SharedPreferences.getInstance();
      final savedLanguage = prefs.getString(_languageKey) ?? 'cs';
      _logger.debug('Saved language from preferences: $savedLanguage');

      _delegate = await LocalizationDelegate.create(
        fallbackLocale: 'cs',
        supportedLocales: ['en', 'cs'],
      );

      // Load the saved language
      await _delegate.load(Locale(savedLanguage));
      _logger.debug('Loaded language: $savedLanguage');
      await _languageNotifier.changeLanguage(savedLanguage);

      _logger.debug('Initialized with language: $savedLanguage');

      return _delegate;
    } catch (e) {
      _logger.error('Error initializing localization', e);
      rethrow;
    }
  }

  static LocalizationDelegate get delegate => _delegate;

  static Future<void> changeLanguage(
    BuildContext context,
    String languageCode,
  ) async {
    try {
      _logger.debug('Changing language to: $languageCode');

      // Update shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, languageCode);
      _logger.debug('Saved language to preferences: $languageCode');

      // Update flutter_translate
      await _delegate.load(Locale(languageCode));
      _logger.debug('Loaded new language: $languageCode');

      // Schedule state updates for the next frame
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        // Update LanguageNotifier
        await _languageNotifier.changeLanguage(languageCode);

        // Update AppState
        if (context.mounted) {
          final appState = context.read<AppState>();
          await appState.handleLanguageChange(languageCode);
          _logger.debug('Updated AppState with new language');
        }
      });

      _logger.info('Language change completed successfully');
    } catch (e, stackTrace) {
      _logger.error('Error changing language', e, stackTrace);
      rethrow;
    }
  }

  static String getCurrentLanguage(BuildContext context) {
    try {
      final language = context.read<LanguageNotifier>().currentLanguage;
      _logger.debug('Getting current language: $language');
      return language;
    } catch (e, stackTrace) {
      _logger.error('Error getting current language', e, stackTrace);
      return 'cs'; // Fallback to Czech
    }
  }
}
