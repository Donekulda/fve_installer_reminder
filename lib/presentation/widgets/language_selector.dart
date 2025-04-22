import 'package:flutter/material.dart';
import 'package:flutter_translate/flutter_translate.dart';
import '../../localization/app_localizations.dart';

class LanguageSelector extends StatelessWidget {
  const LanguageSelector({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.language),
      onSelected: (String languageCode) {
        AppLocalizations.changeLanguage(context, languageCode);
      },
      itemBuilder:
          (BuildContext context) => <PopupMenuEntry<String>>[
            const PopupMenuItem<String>(value: 'en', child: Text('English')),
            const PopupMenuItem<String>(value: 'cs', child: Text('Čeština')),
          ],
    );
  }
}
