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
  @override
  Widget build(BuildContext context) {
    try {
      return Consumer<LanguageNotifier>(
        builder: (context, languageNotifier, child) {
          AppLogger.debug(
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
      AppLogger.error('Error building LanguageSelector', e, stackTrace);
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
      AppLogger.error('Error building language menu items', e, stackTrace);
      return [];
    }
  }

  Future<void> _handleLanguageChange(
    BuildContext context,
    String languageCode,
    LanguageNotifier languageNotifier,
  ) async {
    try {
      AppLogger.debug('LanguageSelector - Language selected: $languageCode');

      // First update the language in AppLocalizations
      await AppLocalizations.changeLanguage(context, languageCode);
      AppLogger.info(
        'LanguageSelector - Language changed to: ${languageNotifier.currentLanguage}',
      );

      if (!context.mounted) {
        AppLogger.warning(
          'LanguageSelector - Context not mounted after language change',
        );
        return;
      }

      // Then handle the language change in AppState
      try {
        await context.read<AppState>().handleLanguageChange(languageCode);
        AppLogger.debug(
          'LanguageSelector - App state updated with new language',
        );

        // Force a rebuild of the current widget
        setState(() {});
      } catch (e, stackTrace) {
        AppLogger.error(
          'Error updating app state with new language',
          e,
          stackTrace,
        );
        // Show error to user
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error updating app with new language: $e'),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        'LanguageSelector - Failed to change language',
        e,
        stackTrace,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error changing language: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}
