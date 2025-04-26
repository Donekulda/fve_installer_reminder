import 'package:flutter/material.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../data/models/fve_installation.dart';
import '../../../data/models/required_image.dart';
import '../../../data/models/saved_image.dart';
import '../../../core/utils/logger.dart';
import '../../../core/services/onedrive_service.dart';
import 'fve_instalation_controller.dart';

/// A page that displays detailed information about an FVE installation.
/// Shows the installation's basic information and allows users to:
/// - View and edit installation details
/// - View required images for the installation
/// - Upload images for each required image type
/// - View uploaded images in a horizontal scrollable list
class InstallationDetailsPage extends StatefulWidget {
  /// The FVE installation to display details for
  final FVEInstallation installation;

  const InstallationDetailsPage({super.key, required this.installation});

  @override
  State<InstallationDetailsPage> createState() =>
      _InstallationDetailsPageState();
}

class _InstallationDetailsPageState extends State<InstallationDetailsPage> {
  final _logger = AppLogger('InstallationDetailsPage');

  /// Controller for managing installation-related operations
  late FVEInstallationController _controller;

  /// List of required image types for the installation
  List<RequiredImage> _requiredImages = [];

  /// Map of required image IDs to their associated saved images
  final Map<int, List<SavedImage>> _savedImages = {};

  /// Flag indicating if the page is currently loading data
  bool _isLoading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller = FVEInstallationController(context, widget.installation);
    _loadRequiredImages();
  }

  /// Loads all required image types and their associated saved images
  Future<void> _loadRequiredImages() async {
    try {
      setState(() => _isLoading = true);
      _requiredImages = await _controller.getRequiredImages();
      await _loadSavedImages();
    } catch (e) {
      _logger.error('Error loading required images', e);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Loads saved images for each required image type
  Future<void> _loadSavedImages() async {
    try {
      for (var requiredImage in _requiredImages) {
        _savedImages[requiredImage.id] = await _controller.getSavedImages(
          requiredImage.id,
        );
      }
    } catch (e) {
      _logger.error('Error loading saved images', e);
    }
  }

  /// Handles the image upload process for a required image type
  ///
  /// [requiredImage] - The required image type to upload an image for
  Future<void> _uploadImage(RequiredImage requiredImage) async {
    try {
      // Show image picker
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image == null) return;

      setState(() => _isLoading = true);

      // Upload image to OneDrive
      final file = File(image.path);
      final oneDriveService = OneDriveService();
      final imageUrl = await oneDriveService.uploadInstallationImage(
        widget.installation.id.toString(),
        file,
        description: requiredImage.name,
      );

      // Create and save the image record
      final savedImage = SavedImage(
        id: 0, // Will be set by database
        fveInstallationId: widget.installation.id,
        requiredImageId: requiredImage.id,
        location: imageUrl,
        timeAdded: DateTime.now(),
        name:
            '${widget.installation.name}_${requiredImage.name}_${DateTime.now().millisecondsSinceEpoch}',
        userId: _controller.currentUser?.id ?? 0,
      );

      await _controller.saveImage(savedImage);
      await _loadSavedImages();
    } catch (e) {
      _logger.error('Error uploading image', e);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    try {
      _logger.debug('InstallationDetailsPage building');
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.installation.name ?? translate('fve.unnamed')),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _controller.showEditInstallationDialog,
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _controller.showDeleteConfirmationDialog,
            ),
          ],
        ),
        body:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Installation details card
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildInfoRow(
                                  title: translate('fve.installationName'),
                                  value:
                                      widget.installation.name ??
                                      translate('fve.unnamed'),
                                ),
                                const Divider(),
                                _buildInfoRow(
                                  title: translate('fve.region'),
                                  value:
                                      widget.installation.region ??
                                      translate('fve.noRegion'),
                                ),
                                const Divider(),
                                _buildInfoRow(
                                  title: translate('fve.address'),
                                  value:
                                      widget.installation.address ??
                                      translate('fve.noAddress'),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Required images section
                        Text(
                          translate('fve.requiredImages'),
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        if (_controller.appState.isPrivileged &&
                            (_controller.currentUser?.privileges ?? 0) >= 3)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: ElevatedButton.icon(
                              onPressed:
                                  () =>
                                      _controller.showAddRequiredImageDialog(),
                              icon: const Icon(Icons.add),
                              label: Text(translate('fve.addRequiredImage')),
                            ),
                          ),
                        ..._requiredImages.map(
                          (requiredImage) =>
                              _buildRequiredImageSection(requiredImage),
                        ),
                      ],
                    ),
                  ),
                ),
      );
    } catch (e, stackTrace) {
      _logger.error('Error building InstallationDetailsPage', e, stackTrace);
      return const Scaffold(
        body: Center(child: Text('Error loading installation details page')),
      );
    }
  }

  /// Builds a section for a required image type, including:
  /// - The required image name
  /// - An upload button
  /// - A horizontal scrollable list of uploaded images
  Widget _buildRequiredImageSection(RequiredImage requiredImage) {
    final savedImages = _savedImages[requiredImage.id] ?? [];

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with name and upload button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  requiredImage.name ?? translate('fve.unnamed'),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                ElevatedButton.icon(
                  onPressed: () => _uploadImage(requiredImage),
                  icon: const Icon(Icons.upload),
                  label: Text(translate('fve.uploadImage')),
                ),
              ],
            ),
            // Horizontal list of uploaded images
            if (savedImages.isNotEmpty) ...[
              const SizedBox(height: 8),
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: savedImages.length,
                  itemBuilder: (context, index) {
                    final image = savedImages[index];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () {
                          // TODO: Implement image preview
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            image.location ?? '',
                            width: 120,
                            height: 120,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 120,
                                height: 120,
                                color: Colors.grey[300],
                                child: const Icon(Icons.error),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Builds a row displaying a title and value pair
  Widget _buildInfoRow({required String title, required String value}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(title, style: Theme.of(context).textTheme.titleMedium),
          ),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodyLarge),
          ),
        ],
      ),
    );
  }
}
