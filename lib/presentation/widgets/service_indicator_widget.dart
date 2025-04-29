import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_translate/flutter_translate.dart';
import '../../state/app_state.dart';

/// A widget that displays the connection status of cloud and database services
class ServiceIndicatorWidget extends StatelessWidget {
  const ServiceIndicatorWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildCloudStatusIndicator(appState),
            const SizedBox(width: 8),
            _buildDatabaseStatusIndicator(appState),
          ],
        );
      },
    );
  }

  Widget _buildCloudStatusIndicator(AppState appState) {
    Color iconColor;
    Widget icon;
    String tooltip;

    switch (appState.cloudStatus) {
      case CloudStatus.disconnected:
        iconColor = Colors.red;
        icon = const Icon(Icons.cloud_off);
        tooltip = translate('services.cloud.disconnected');
        break;
      case CloudStatus.connected:
        iconColor = Colors.blue;
        icon = const Icon(Icons.cloud);
        tooltip = translate('services.cloud.connected');
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
        tooltip = translate('services.cloud.syncing');
        break;
    }

    return Tooltip(
      message: tooltip,
      child: IconTheme(data: IconThemeData(color: iconColor), child: icon),
    );
  }

  Widget _buildDatabaseStatusIndicator(AppState appState) {
    final isConnected = appState.isDatabaseServiceInitialized;
    final iconColor = isConnected ? Colors.blue : Colors.red;
    final icon =
        isConnected
            ? const Icon(Icons.storage)
            : const Icon(Icons.error_outline);
    final tooltip =
        isConnected
            ? translate('services.database.connected')
            : translate('services.database.disconnected');

    return Tooltip(
      message: tooltip,
      child: IconTheme(data: IconThemeData(color: iconColor), child: icon),
    );
  }
}
