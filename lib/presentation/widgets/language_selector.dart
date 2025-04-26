import 'package:flutter/material.dart';
import '../../localization/app_localizations.dart';
import 'package:provider/provider.dart';
import '../../core/utils/logger.dart';
import 'package:flutter_translate/flutter_translate.dart';
import '../../state/app_state.dart';

/// A widget that provides language selection functionality through a popup menu.
/// It allows users to switch between different languages in the application.
class LanguageSelector extends StatefulWidget {
  const LanguageSelector({super.key});

  @override
  State<LanguageSelector> createState() => _LanguageSelectorState();
}

class _LanguageSelectorState extends State<LanguageSelector> {
  final _logger = AppLogger('LanguageSelector');

  @override
  Widget build(BuildContext context) {
    try {
      // Use Consumer to rebuild only when language changes
      return Consumer<LanguageNotifier>(
        builder: (context, languageNotifier, child) {
          _logger.debug(
            'LanguageSelector - Current language: ${languageNotifier.currentLanguage}',
          );
          // Create a popup menu button for language selection
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

  /// Builds the list of language options for the popup menu
  ///
  /// [currentLanguage] - The currently selected language code
  /// Returns a list of PopupMenuEntry widgets for each available language
  List<PopupMenuEntry<String>> _buildLanguageMenuItems(String currentLanguage) {
    try {
      return [
        PopupMenuItem<String>(
          value: 'en',
          enabled: currentLanguage != 'en',
          child: const Text('English'),
        ),
        PopupMenuItem<String>(
          value: 'cs',
          enabled: currentLanguage != 'cs',
          child: const Text('Čeština'),
        ),
      ];
    } catch (e, stackTrace) {
      _logger.error('Error building language menu items', e, stackTrace);
      return [];
    }
  }

  /// Handles the language change when a new language is selected
  ///
  /// [context] - The build context
  /// [languageCode] - The code of the selected language
  /// [languageNotifier] - The language notifier for state management
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

      // Check if context is still valid after async operation
      if (!context.mounted) {
        _logger.warning(
          'LanguageSelector - Context not mounted after language change',
        );
        return;
      }

      // Update the language in AppState
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

  /// Shows an error message to the user using a SnackBar
  ///
  /// [context] - The build context
  /// [message] - The error message to display
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
