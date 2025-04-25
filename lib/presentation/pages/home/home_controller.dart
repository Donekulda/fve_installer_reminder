import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_translate/flutter_translate.dart';
import '../../../state/app_state.dart';
import '../../../data/models/fve_installation.dart';
import '../../../data/models/user.dart';
import '../../../core/utils/logger.dart';

class HomeController {
  final BuildContext context;
  final AppState appState;
  final _logger = AppLogger('HomeController');

  HomeController(this.context) : appState = context.read<AppState>();

  Future<void> handleLogout() async {
    try {
      _logger.debug('Logout attempt started');
      await appState.logout();
      _logger.info('Logout successful');
    } catch (e, stackTrace) {
      _logger.error('Error during logout', e, stackTrace);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(translate('auth.logoutError')),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> showAddInstallationDialog() async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final regionController = TextEditingController();
    final addressController = TextEditingController();
    User? selectedUser = appState.currentUser;

    if (!context.mounted) return;

    return showDialog(
      context: context,
      builder:
          (BuildContext dialogContext) => AlertDialog(
            title: Text(translate('fve.addInstallation')),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
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
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(translate('common.cancel')),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;

                  final installation = FVEInstallation(
                    id: 0,
                    name: nameController.text,
                    region: regionController.text,
                    address: addressController.text,
                    userId: selectedUser!.id,
                  );

                  await appState.addInstallation(installation);

                  if (!context.mounted) return;
                  Navigator.pop(dialogContext);
                },
                child: Text(translate('common.add')),
              ),
            ],
          ),
    );
  }
}
