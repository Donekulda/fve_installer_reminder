import 'package:flutter/material.dart';
import '../../localization/app_localizations.dart';
import 'package:provider/provider.dart';
import '../../core/utils/logger.dart';
import 'package:flutter_translate/flutter_translate.dart';
import '../../state/app_state.dart';

class LanguageSelector extends StatefulWidget {
  const LanguageSelector({Key? key}) : super(key: key);

  @override
  State<LanguageSelector> createState() => _LanguageSelectorState();
}

class _LanguageSelectorState extends State<LanguageSelector> {
  final _logger = AppLogger('LanguageSelector');
  @override
  Widget build(BuildContext context) {
    try {
      return Consumer<LanguageNotifier>(
        builder: (context, languageNotifier, child) {
          _logger.debug(
            'LanguageSelector - Current language: ${languageNotifier.currentLanguage}',
          );
          return PopupMenuButton<String>(
            icon: const Icon(Icons.language),
            tooltip: translate('app.language'),
            onSelected:
                (String languageCode) => _handleLanguageChange(
                  context,
                  languageCode,
                  languageNotifier,
                ),
            itemBuilder:
                (BuildContext context) =>
                    _buildLanguageMenuItems(languageNotifier.currentLanguage),
          );
        },
      );
    } catch (e, stackTrace) {
      _logger.error('Error building LanguageSelector', e, stackTrace);
      return const Icon(Icons.error);
    }
  }

  List<PopupMenuEntry<String>> _buildLanguageMenuItems(String currentLanguage) {
    try {
      return [
        PopupMenuItem<String>(
          value: 'en',
          child: const Text('English'),
          enabled: currentLanguage != 'en',
        ),
        PopupMenuItem<String>(
          value: 'cs',
          child: const Text('Čeština'),
          enabled: currentLanguage != 'cs',
        ),
      ];
    } catch (e, stackTrace) {
      _logger.error('Error building language menu items', e, stackTrace);
      return [];
    }
  }

  Future<void> _handleLanguageChange(
    BuildContext context,
    String languageCode,
    LanguageNotifier languageNotifier,
  ) async {
    try {
      _logger.debug('LanguageSelector - Language selected: $languageCode');

      // First update the language in AppLocalizations
      AppLocalizations.changeLanguage(context, languageCode);
      _logger.info(
        'LanguageSelector - Language changed to: ${context.read<LanguageNotifier>().currentLanguage}',
      );

      if (!context.mounted) {
        _logger.warning(
          'LanguageSelector - Context not mounted after language change',
        );
        return;
      }

      // Then handle the language change in AppState
      try {
        context.read<AppState>().handleLanguageChange(languageCode);
        _logger.debug('LanguageSelector - App state updated with new language');

        // Force a rebuild of the current widget
        context.read<LanguageNotifier>().changeLanguage(languageCode);
      } catch (e, stackTrace) {
        _logger.error(
          'Error updating app state with new language',
          e,
          stackTrace,
        );
        // Show error to user
        _showErrorSnackBar(context, 'Error updating app with new language: $e');
      }
    } catch (e, stackTrace) {
      _logger.error(
        'LanguageSelector - Failed to change language',
        e,
        stackTrace,
      );
      _showErrorSnackBar(context, 'Error changing language: $e');
    }
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    try {
      _logger.debug('LanguageSelector - Showing error snackbar: $message');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (e, stackTrace) {
      _logger.error(
        'LanguageSelector - Error showing error snackbar',
        e,
        stackTrace,
      );
    }
  }
}
