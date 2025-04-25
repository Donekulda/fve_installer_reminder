import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_translate/flutter_translate.dart';
import '../../../state/app_state.dart';
import '../../../data/models/fve_installation.dart';
import '../../../core/utils/logger.dart';

class FVEInstallationController {
  final BuildContext context;
  final AppState appState;
  final FVEInstallation installation;

  FVEInstallationController(this.context, this.installation)
    : appState = context.read<AppState>();

  Future<void> showEditInstallationDialog() async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: installation.name);
    final regionController = TextEditingController(text: installation.region);
    final addressController = TextEditingController(text: installation.address);

    if (!context.mounted) return;

    return showDialog(
      context: context,
      builder:
          (BuildContext dialogContext) => AlertDialog(
            title: Text(translate('fve.editInstallation')),
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

                  final updatedInstallation = FVEInstallation(
                    id: installation.id,
                    name: nameController.text,
                    region: regionController.text,
                    address: addressController.text,
                    userId: installation.userId,
                  );

                  await appState.updateInstallation(updatedInstallation);

                  if (!context.mounted) return;
                  Navigator.pop(dialogContext);
                },
                child: Text(translate('common.save')),
              ),
            ],
          ),
    );
  }

  Future<void> showDeleteConfirmationDialog() async {
    if (!context.mounted) return;

    return showDialog(
      context: context,
      builder:
          (BuildContext dialogContext) => AlertDialog(
            title: Text(translate('fve.deleteInstallation')),
            content: Text(translate('fve.deleteNotAllowed')),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(translate('common.ok')),
              ),
            ],
          ),
    );
  }
}
