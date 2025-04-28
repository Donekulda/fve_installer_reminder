import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_translate/flutter_translate.dart';
import '../../state/app_state.dart';
import '../../core/utils/logger.dart';
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
          final isAdmin = appState.hasRequiredPrivilege('admin');

          return AppBar(
            title: Text(translate('app.title')),
            leading: _buildCloudStatusIndicator(appState),
            actions: [
              // Language selector is always visible
              const LanguageSelector(),
              // Only show these actions if user is logged in
              if (isLoggedIn) ...[
                // Required image models management - only visible for admin users
                if (isAdmin)
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/required-image-managment');
                    },
                    child: Text(translate('required_images.management.title')),
                  ),
                // User management - only visible for admin users
                if (isAdmin)
                  IconButton(
                    icon: const Icon(Icons.people),
                    tooltip: translate('app.userManagement'),
                    onPressed: () {
                      Navigator.pushNamed(context, '/users');
                    },
                  ),
                // Logout - only visible when logged in
                IconButton(
                  icon: const Icon(Icons.logout),
                  tooltip: translate('auth.logout'),
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

  Widget _buildCloudStatusIndicator(AppState appState) {
    Color iconColor;
    Widget icon;

    switch (appState.cloudStatus) {
      case CloudStatus.disconnected:
        iconColor = Colors.red;
        icon = const Icon(Icons.cloud_off);
        break;
      case CloudStatus.connected:
        iconColor = Colors.blue;
        icon = const Icon(Icons.cloud);
        break;
      case CloudStatus.syncing:
        iconColor = Colors.green;
        icon = Stack(
          alignment: Alignment.center,
          children: [
            const Icon(Icons.cloud),
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
              ),
            ),
          ],
        );
        break;
    }

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: IconTheme(data: IconThemeData(color: iconColor), child: icon),
    );
  }
}
