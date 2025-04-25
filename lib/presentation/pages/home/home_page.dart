import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_translate/flutter_translate.dart';
import '../../../state/app_state.dart';
import '../../../data/models/fve_installation.dart';
import '../fve_instalation/fve_installation_details_page.dart';
import '../../widgets/language_selector.dart';
import '../../../core/utils/logger.dart';
import 'home_controller.dart';

/// A page that displays a list of FVE installations and allows adding new ones.
/// Uses Provider pattern for state management and handles user authentication.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late HomeController _controller;

  @override
  void initState() {
    super.initState();
    AppLogger.debug('HomePage initialized');
    // Load installations after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().loadInstallations();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller = HomeController(context);
  }

  @override
  void dispose() {
    AppLogger.debug('HomePage disposed');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    try {
      AppLogger.debug('HomePage building');
      return Scaffold(
        appBar: AppBar(
          title: Text(translate('home.dashboard')),
          actions: [
            const LanguageSelector(),
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: _controller.handleLogout,
            ),
          ],
        ),
        body: Consumer<AppState>(
          builder: (context, appState, child) {
            // Use currentLanguage to force rebuilds
            final currentLanguage = appState.currentLanguage;

            AppLogger.debug(
              'HomePage - Building with user: ${appState.currentUser?.username}, language: $currentLanguage',
            );

            // Show loading indicator while data is being fetched
            if (appState.isLoading) {
              return Center(child: Text(translate('common.loading')));
            }

            // Show message if no installations are found
            if (appState.installations.isEmpty) {
              return Center(child: Text(translate('common.noData')));
            }

            // Build list of existing FVE installations
            return ListView.builder(
              itemCount: appState.installations.length,
              itemBuilder: (context, index) {
                final installation = appState.installations[index];
                return ListTile(
                  title: Text(installation.name ?? translate('fve.unnamed')),
                  subtitle: Text(
                    installation.address ?? translate('fve.noAddress'),
                  ),
                  onTap: () {
                    // Navigate to installation details page when tapped
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => InstallationDetailsPage(
                              installation: installation,
                            ),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
        // Floating action button to add new installation
        floatingActionButton: FloatingActionButton(
          onPressed: _controller.showAddInstallationDialog,
          child: const Icon(Icons.add),
        ),
      );
    } catch (e, stackTrace) {
      AppLogger.error('Error building HomePage', e, stackTrace);
      return Scaffold(body: Center(child: Text('Error loading home page: $e')));
    }
  }
}
