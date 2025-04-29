import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_translate/flutter_translate.dart';
import '../../state/app_state.dart';
import '../../data/models/fve_installation.dart';
import '../../data/models/required_image.dart';
import '../../data/models/saved_image.dart';
import '../../data/models/user.dart';
import '../../core/utils/logger.dart';

/// Controller class for managing FVE installation details and related operations.
/// Handles all business logic for the installation details page, including:
/// - Loading and displaying installation information
/// - Managing required images and their uploads
/// - Handling user interactions with the installation
class FVEInstallationController {
  /// The build context used for showing dialogs and accessing theme
  final BuildContext context;

  /// The app state instance for accessing global state and services
  final AppState appState;

  /// The FVE installation being managed
  final FVEInstallation installation;

  final _logger = AppLogger('FVEInstallationController');

  /// Creates a new FVEInstallationController instance.
  ///
  /// [context] - The build context for the page
  /// [installation] - The FVE installation to manage
  FVEInstallationController(this.context, this.installation)
    : appState = context.read<AppState>();

  /// Gets the current logged-in user
  User? get currentUser => appState.currentUser;

  /// Retrieves all required image types from the database.
  /// These are the types of images that need to be uploaded for an installation.
  Future<List<RequiredImage>> getRequiredImages() async {
    try {
      final dbService = appState.databaseService;
      if (dbService == null) {
        _logger.error('Database service is null');
        throw Exception('Database service not initialized');
      }
      return await dbService.getAllRequiredImages();
    } catch (e) {
      _logger.error('Error getting required images', e);
      return [];
    }
  }

  /// Retrieves all saved images for a specific required image type.
  ///
  /// [requiredImageId] - The ID of the required image type to get saved images for
  Future<List<SavedImage>> getSavedImages(int requiredImageId) async {
    try {
      final dbService = appState.databaseService;
      if (dbService == null) {
        _logger.error('Database service is null');
        throw Exception('Database service not initialized');
      }
      return await dbService.getSavedImagesByRequiredImageId(requiredImageId);
    } catch (e) {
      _logger.error('Error getting saved images', e);
      return [];
    }
  }

  /// Saves a new image to the database.
  ///
  /// [image] - The saved image to store in the database
  Future<void> saveImage(SavedImage image) async {
    try {
      final dbService = appState.databaseService;
      if (dbService == null) {
        _logger.error('Database service is null');
        throw Exception('Database service not initialized');
      }
      await dbService.saveImage(image);
    } catch (e) {
      _logger.error('Error saving image', e);
      rethrow;
    }
  }

  /// Shows a dialog for editing the installation details.
  /// Allows users to modify the installation's name, region, and address.
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

  /// Shows a confirmation dialog for deleting the installation.
  /// Currently, deletion is not allowed for security reasons.
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

  /// Shows a dialog for adding a new required image type.
  /// Only available to users with admin privileges (level 3 or higher).
  Future<void> showAddRequiredImageDialog() async {
    if (!appState.isPrivileged || (appState.currentUser?.privileges ?? 0) < 3) {
      return;
    }

    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final minImagesController = TextEditingController(text: '1');

    if (!context.mounted) return;

    return showDialog(
      context: context,
      builder:
          (BuildContext dialogContext) => AlertDialog(
            title: Text(translate('fve.addRequiredImage')),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: translate('fve.requiredImageName'),
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return translate('error.requiredImageNameNull');
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: minImagesController,
                    decoration: InputDecoration(
                      labelText: translate('fve.minImages'),
                      border: const OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return translate('error.minImagesNull');
                      }
                      final number = int.tryParse(value);
                      if (number == null || number < 1) {
                        return translate('error.minImagesInvalid');
                      }
                      return null;
                    },
                  ),
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

                  final newRequiredImage = RequiredImage(
                    id: 0, // Will be set by database
                    name: nameController.text,
                    minImages: int.parse(minImagesController.text),
                  );

                  final dbService = appState.databaseService;
                  if (dbService == null) {
                    _logger.error('Database service is null');
                    throw Exception('Database service not initialized');
                  }

                  await dbService.addRequiredImage(newRequiredImage);

                  if (!context.mounted) return;
                  Navigator.pop(dialogContext);
                },
                child: Text(translate('common.save')),
              ),
            ],
          ),
    );
  }
}
