import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_translate/flutter_translate.dart';
import '../../../state/app_state.dart';
import '../../../data/models/fve_installation.dart';
import '../../../data/models/user.dart';
import '../fve_instalation/installation_details_page.dart';
import '../../widgets/language_selector.dart';
import '../../../core/utils/logger.dart';

/// A page that displays a list of FVE installations and allows adding new ones.
/// Uses Provider pattern for state management and handles user authentication.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
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
  void dispose() {
    AppLogger.debug('HomePage disposed');
    super.dispose();
  }

  Future<void> _handleLogout() async {
    try {
      AppLogger.debug('Logout attempt started');
      await context.read<AppState>().logout();
      AppLogger.info('Logout successful');
    } catch (e, stackTrace) {
      AppLogger.error('Error during logout', e, stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(translate('auth.logoutError')),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
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
              onPressed: _handleLogout,
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
          onPressed: () => _showAddInstallationDialog(context),
          child: const Icon(Icons.add),
        ),
      );
    } catch (e, stackTrace) {
      AppLogger.error('Error building HomePage', e, stackTrace);
      return Scaffold(body: Center(child: Text('Error loading home page: $e')));
    }
  }

  /// Shows a dialog for adding a new FVE installation.
  /// The dialog includes fields for installation details and responsible user selection.
  Future<void> _showAddInstallationDialog(BuildContext context) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final regionController = TextEditingController();
    final addressController = TextEditingController();
    // Initialize selected user with current user, as the creator should by default be responsible for the installation
    User? selectedUser = context.read<AppState>().currentUser;

    return showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(translate('fve.addInstallation')),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Installation name field
                  TextFormField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: translate('fve.installationName'),
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return translate('error.installationNameNull');
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  // Region field of the location of the installation
                  TextFormField(
                    controller: regionController,
                    decoration: InputDecoration(
                      labelText: translate('fve.region'),
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return translate('error.regionNull');
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  // Address field of the location of the installation
                  TextFormField(
                    controller: addressController,
                    decoration: InputDecoration(
                      labelText: translate('fve.address'),
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return translate('error.addressNull');
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  /*
                  // Dropdown for selecting the responsible user for the installation
                  Consumer<AppState>(
                    builder: (context, appState, child) {
                      if (appState.users.isEmpty) {
                        return Text(translate('common.noUsers'));
                      }
                      return DropdownButtonFormField<User>(
                        value: selectedUser,
                        decoration: InputDecoration(
                          labelText: translate('fve.responsibleUser'),
                          border: const OutlineInputBorder(),
                        ),
                        items:
                            appState.users.map((User user) {
                              return DropdownMenuItem<User>(
                                value: user,
                                child: Text(user.fullname ?? user.username),
                              );
                            }).toList(),
                        onChanged: (User? newValue) {
                          selectedUser = newValue;
                        },
                        validator: (value) {
                          if (value == null) {
                            return translate('error.responsibleUserNull');
                          }
                          return null;
                        },
                      );
                    },
                  ),*/
                ],
              ),
            ),
            actions: [
              // Cancel button
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(translate('common.cancel')),
              ),
              // Add button
              ElevatedButton(
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;

                  // Create new installation with form data
                  final installation = FVEInstallation(
                    id: 0,
                    name: nameController.text,
                    region: regionController.text,
                    address: addressController.text,
                    userId: selectedUser!.id,
                  );

                  // Add installation and close dialog
                  await context.read<AppState>().addInstallation(installation);

                  if (!mounted) return;
                  Navigator.pop(context);
                },
                child: Text(translate('common.add')),
              ),
            ],
          ),
    );
  }
}
