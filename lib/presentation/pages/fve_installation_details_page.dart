import 'package:flutter/material.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../data/models/fve_installation.dart';
import '../../data/models/required_image.dart';
import '../../data/models/saved_image.dart';
import '../../core/utils/logger.dart';
import '../controllers/fve_installation_controller.dart';
import 'package:provider/provider.dart';
import '../../state/app_state.dart';

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

      // Save image locally first
      final file = File(image.path);
      final imageSyncService = _controller.appState.imageSyncService;

      // Save image locally and get local image ID
      final localImageId = await imageSyncService.saveImageLocally(
        installationId: widget.installation.id,
        requiredImageId: requiredImage.id,
        sourceFile: file,
        userId: _controller.currentUser?.id ?? 0,
        name:
            '${widget.installation.name}_${requiredImage.name}_${DateTime.now().millisecondsSinceEpoch}',
      );

      // Upload to cloud
      final savedImage = await imageSyncService.uploadLocalImageToCloud(
        localImageId: localImageId,
        description: requiredImage.name,
      );

      if (savedImage != null) {
        await _loadSavedImages();
      } else {
        _logger.warning('Failed to upload image to cloud');
      }
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
            // Edit button - only for builders and above
            Consumer<AppState>(
              builder: (context, appState, child) {
                final canEdit = appState.hasRequiredPrivilege('builder');

                if (!canEdit) {
                  return const SizedBox.shrink();
                }

                return IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _showEditDialog(context),
                );
              },
            ),
          ],
        ),
        body:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildContent(),
      );
    } catch (e, stackTrace) {
      _logger.error('Error building InstallationDetailsPage', e, stackTrace);
      return Scaffold(
        body: Center(child: Text('Error loading installation details: $e')),
      );
    }
  }

  Widget _buildContent() {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        final canEdit = appState.hasRequiredPrivilege('builder');
        final canManageImages = appState.hasRequiredPrivilege('installer');

        return ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Installation details
            _buildInstallationDetails(),
            const SizedBox(height: 24),
            // Required images section
            Text(
              translate('fve.requiredImages'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            // List of required images
            ..._requiredImages.map((requiredImage) {
              return _buildRequiredImageSection(requiredImage, canManageImages);
            }),
          ],
        );
      },
    );
  }

  Widget _buildInstallationDetails() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              translate('fve.details'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildDetailRow('fve.name', widget.installation.name),
            _buildDetailRow('fve.address', widget.installation.address),
            _buildDetailRow('fve.region', widget.installation.region),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String labelKey, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              translate(labelKey),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value ?? translate('common.notSpecified'))),
        ],
      ),
    );
  }

  Widget _buildRequiredImageSection(
    RequiredImage requiredImage,
    bool canUpload,
  ) {
    final savedImages = _savedImages[requiredImage.id] ?? [];
    final activeImages = savedImages.where((image) => image.active).length;
    final isComplete = activeImages >= requiredImage.minImages;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    requiredImage.name ?? translate('fve.unnamed'),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Text(
                  '$activeImages/${requiredImage.minImages}',
                  style: TextStyle(
                    color: isComplete ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Upload button - only for installers and above
            if (canUpload)
              ElevatedButton.icon(
                onPressed: () => _uploadImage(requiredImage),
                icon: const Icon(Icons.upload),
                label: Text(translate('fve.uploadImage')),
              ),
            const SizedBox(height: 8),
            // Display saved images
            if (savedImages.isNotEmpty)
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: savedImages.length,
                  itemBuilder: (context, index) {
                    final image = savedImages[index];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: GestureDetector(
                        onTap: () => _showImageDialog(image),
                        child: FutureBuilder<String?>(
                          future: _controller.appState.imageStorageService
                              .getLocalImagePath(
                                installationId: widget.installation.id,
                                requiredImageId: requiredImage.id,
                                imageName: image.name ?? '',
                              ),
                          builder: (context, snapshot) {
                            final bool hasLocalFile =
                                snapshot.hasData && snapshot.data != null;
                            final bool isUploading = image.location == null;
                            final bool isSynced =
                                image.location != null && hasLocalFile;

                            return Stack(
                              children: [
                                // Main image
                                if (hasLocalFile)
                                  Image.file(
                                    File(snapshot.data!),
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                  )
                                else
                                  Image.network(
                                    image.location ?? '',
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                    color:
                                        !hasLocalFile ? Colors.black54 : null,
                                    colorBlendMode:
                                        !hasLocalFile ? BlendMode.darken : null,
                                  ),
                                // Inactive overlay
                                if (!image.active)
                                  Container(
                                    width: 100,
                                    height: 100,
                                    color: Colors.black.withAlpha(128),
                                    child: const Center(
                                      child: Icon(
                                        Icons.block,
                                        color: Colors.white,
                                        size: 32,
                                      ),
                                    ),
                                  ),
                                // Status indicator
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withAlpha(51),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: Icon(
                                        isUploading
                                            ? Icons.upload
                                            : isSynced
                                            ? Icons.cloud_done
                                            : Icons.cloud_off,
                                        size: 16,
                                        color:
                                            isUploading
                                                ? Colors.blue
                                                : isSynced
                                                ? Colors.green
                                                : Colors.orange,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context) async {
    await _controller.showEditInstallationDialog();
    // Refresh the page to show updated data
    if (mounted) {
      setState(() {
        // Trigger rebuild to show updated data
      });
    }
  }

  void _showImageDialog(SavedImage image) {
    // Implementation of _showImageDialog method
  }
}
