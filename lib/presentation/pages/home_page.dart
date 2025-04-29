import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_translate/flutter_translate.dart';
import '../../state/app_state.dart';
import 'fve_installation_details_page.dart';
import '../widgets/app_top_bar.dart';
import '../../core/utils/logger.dart';
import '../controllers/home_controller.dart';

/// A page that displays a list of FVE installations and allows adding new ones.
/// Uses Provider pattern for state management and handles user authentication.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _logger = AppLogger('HomePage');
  late HomeController _controller;

  @override
  void initState() {
    super.initState();
    _logger.debug('HomePage initialized');
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
    _logger.debug('HomePage disposed');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    try {
      _logger.debug('HomePage building');
      return Scaffold(
        appBar: const AppTopBar(),
        body: Consumer<AppState>(
          builder: (context, appState, child) {
            // Use currentLanguage to force rebuilds
            final currentLanguage = appState.currentLanguage;
            final canEdit = appState.hasRequiredPrivilege('builder');

            _logger.debug(
              'HomePage - Building with user: ${appState.currentUser?.username}, language: $currentLanguage',
            );

            // Show loading indicator while data is being fetched
            if (appState.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            // Show message if no installations are found
            if (appState.installations.isEmpty) {
              return Center(child: Text(translate('common.noInstallations')));
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
        floatingActionButton: Consumer<AppState>(
          builder: (context, appState, child) {
            final canEdit = appState.hasRequiredPrivilege('builder');

            if (!canEdit) {
              return const SizedBox.shrink();
            }

            return FloatingActionButton(
              onPressed: () => _controller.showAddInstallationDialog(),
              child: const Icon(Icons.add),
            );
          },
        ),
      );
    } catch (e, stackTrace) {
      _logger.error('Error building HomePage', e, stackTrace);
      return const Scaffold(
        body: Center(child: Text('Error loading home page')),
      );
    }
  }
}
