import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_translate/flutter_translate.dart';
import '../../state/app_state.dart';
import '../../core/utils/logger.dart';
import '../../localization/app_localizations.dart';
import 'language_selector.dart';

/// A custom app bar widget that provides the main navigation and actions for the application.
/// It includes language selection, user management (for admin users), and logout functionality.
class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  const AppTopBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final logger = AppLogger('AppTopBar');
    try {
      // Use Consumer to rebuild only when app state changes
      return Consumer<AppState>(
        builder: (context, appState, child) {
          // Get current user state
          final isLoggedIn = appState.isLoggedIn;
          final userPrivileges = appState.currentUserPrivileges;

          return AppBar(
            title: Text(translate('app.title')),
            actions: [
              // Language selector is always visible
              const LanguageSelector(),
              // Only show these actions if user is logged in
              if (isLoggedIn) ...[
                // User management - only visible for admin users (privilege level 3)
                if (userPrivileges >= 3)
                  IconButton(
                    icon: const Icon(Icons.people),
                    onPressed: () {
                      Navigator.pushNamed(context, '/users');
                    },
                  ),
                // Logout - only visible when logged in
                IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: () {
                    // Show confirmation dialog before logout
                    showDialog(
                      context: context,
                      builder:
                          (context) => AlertDialog(
                            title: Text(translate('logout.confirm')),
                            content: Text(translate('logout.message')),
                            actions: [
                              // Cancel button
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text(translate('common.cancel')),
                              ),
                              // Confirm button
                              TextButton(
                                onPressed: () {
                                  // Perform logout and close dialog
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
