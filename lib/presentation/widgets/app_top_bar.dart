// lib/widgets/app_top_bar.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_translate/flutter_translate.dart';
import '../../state/app_state.dart';
import '../../core/utils/logger.dart';
import 'language_selector.dart';
import 'service_indicator_widget.dart';

class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  const AppTopBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final logger = AppLogger('AppTopBar');
    try {
      return Consumer<AppState>(
        builder: (context, appState, child) {
          final isLoggedIn = appState.isLoggedIn;
          final isAdmin = appState.hasRequiredPrivilege('admin');

          return AppBar(
            leading: const ServiceIndicatorWidget(),
            title: const SizedBox(), // Placeholder to keep space
            centerTitle: true,
            flexibleSpace: Stack(
              alignment: Alignment.center,
              children: [
                if (isLoggedIn)
                  Align(
                    alignment: Alignment.center,
                    child: IconButton(
                      icon: const Icon(Icons.home),
                      tooltip: translate('app.home'),
                      onPressed: () {
                        Navigator.pushNamed(context, '/');
                      },
                    ),
                  ),
              ],
            ),
            actions: [
              const LanguageSelector(),
              if (isLoggedIn) ...[
                if (isAdmin)
                  IconButton(
                    icon: const Icon(Icons.format_list_bulleted),
                    tooltip: translate('required_images.management.title'),
                    onPressed: () {
                      Navigator.pushNamed(context, '/required-image-managment');
                    },
                  ),
                if (isAdmin)
                  IconButton(
                    icon: const Icon(Icons.people),
                    tooltip: translate('app.userManagement'),
                    onPressed: () {
                      Navigator.pushNamed(context, '/users');
                    },
                  ),
                IconButton(
                  icon: const Icon(Icons.logout),
                  tooltip: translate('auth.logout'),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder:
                          (context) => AlertDialog(
                            title: Text(translate('logout.confirm')),
                            content: Text(translate('logout.message')),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text(translate('common.cancel')),
                              ),
                              TextButton(
                                onPressed: () {
                                  context.read<AppState>().logout();
                                  Navigator.pop(context);
                                },
                                child: Text(translate('common.confirm')),
                              ),
                            ],
                          ),
                    );
                  },
                ),
              ],
            ],
          );
        },
      );
    } catch (e, stackTrace) {
      logger.error('Error building AppTopBar', e, stackTrace);
      return AppBar(title: const Text('Error'));
    }
  }
}
