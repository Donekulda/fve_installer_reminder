import 'dart:io';
import 'dart:async';
import 'package:path/path.dart' as path;
import '../../core/services/image_storage_service.dart';
import '../../core/services/local_database_service.dart';
import '../../core/services/database_service.dart';
import '../../core/services/onedrive_service.dart';
import '../../core/utils/logger.dart';
import '../../core/config/image_sync_config.dart';
import '../../data/models/saved_image.dart';
import '../../state/app_state.dart';
import 'package:collection/collection.dart';

/// Service class that coordinates between image storage, local database, cloud database, and OneDrive services.
/// Handles synchronization of images between local storage and cloud storage.
class ImageSyncService {
  final ImageStorageService _imageStorage;
  final LocalDatabaseService _localDatabase;
  final DatabaseService _database;
  final OneDriveService _oneDrive;
  final AppState _appState;
  final _logger = AppLogger('ImageSyncService');

  Timer? _syncTimer;
  int _activeUploads = 0;

  ImageSyncService({
    required ImageStorageService imageStorage,
    required LocalDatabaseService localDatabase,
    required DatabaseService database,
    required OneDriveService oneDrive,
    required AppState appState,
  }) : _imageStorage = imageStorage,
       _localDatabase = localDatabase,
       _database = database,
       _oneDrive = oneDrive,
       _appState = appState {
    _startPeriodicSync();
  }

  /// Starts periodic checking for unuploaded images and cloud images
  void _startPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(
      Duration(minutes: ImageSyncConfig.syncIntervalMinutes),
      (_) async {
        await syncUnuploadedImages();
        await syncCloudImages();
      },
    );
  }

  /// Stops periodic checking
  void dispose() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }

  /// Validates a file before processing
  Future<void> _validateFile(File file) async {
    // Check file size
    final fileSize = await file.length();
    if (fileSize > ImageSyncConfig.maxUploadSizeBytes) {
      throw Exception(ImageSyncConfig.errorMaxSizeExceeded);
    }

    // Check file extension
    final extension = path.extension(file.path).toLowerCase();
    if (!ImageSyncConfig.allowedExtensions.contains(extension)) {
      throw Exception(ImageSyncConfig.errorInvalidExtension);
    }
  }

  /// Saves a new image to the local database
  Future<int> saveImageLocally({
    required int installationId,
    required int requiredImageId,
    required File sourceFile,
    required int userId,
    String? name,
  }) async {
    try {
      _logger.info(
        'Saving image locally for installation: $installationId, required: $requiredImageId',
      );

      // Validate file
      await _validateFile(sourceFile);

      // 1. Save to local storage
      final localPath = await _imageStorage.saveImage(
        installationId: installationId,
        requiredImageId: requiredImageId,
        sourceFile: sourceFile,
        customFileName: name,
      );

      // 2. Save to local database
      final localImageId = await _localDatabase.saveImage(
        fveInstallationId: installationId,
        requiredImageId: requiredImageId,
        localPath: localPath,
        name: name,
        timeAdded: DateTime.now(),
        userId: userId,
        hash: await _imageStorage.calculateFileHash(sourceFile),
      );

      _logger.info('Image saved locally successfully');
      return localImageId;
    } catch (e, stackTrace) {
      _logger.error('Error saving image locally', e, stackTrace);
      rethrow;
    }
  }

  /// Attempts to upload a locally saved image to cloud storage
  Future<SavedImage?> uploadLocalImageToCloud({
    required int localImageId,
    String? description,
  }) async {
    try {
      _logger.info(
        'Attempting to upload local image ID: $localImageId to cloud',
      );

      // Check concurrent uploads limit
      if (_activeUploads >= ImageSyncConfig.maxConcurrentUploads) {
        _logger.warning('Maximum concurrent uploads reached, queuing upload');
        return null;
      }

      _activeUploads++;
      _appState.updateCloudStatus(CloudStatus.syncing);

      try {
        // 1. Get local image data
        final localImage = await _localDatabase.getImageById(localImageId);
        if (localImage == null) {
          throw Exception('Local image not found');
        }

        final file = File(localImage['local_path'] as String);
        if (!await file.exists()) {
          throw Exception('Local file not found');
        }

        // Validate file
        await _validateFile(file);

        // Check for existing image with same hash
        final existingImages = await _database.getActiveImages();
        final fileHash = await _imageStorage.calculateFileHash(file);
        final existingImage = existingImages.firstWhereOrNull(
          (img) => img.hash == fileHash,
        );

        if (existingImage != null) {
          _logger.info('Found existing image with same hash, binding to it');
          // Update local database to point to existing cloud image
          await _localDatabase.markImageAsUploaded(
            localImageId,
            existingImage.id,
          );
          return existingImage;
        }

        // 2. Upload to OneDrive with retries
        String? oneDriveUrl;
        int retryCount = 0;
        while (retryCount < ImageSyncConfig.maxUploadRetries) {
          try {
            oneDriveUrl = await _oneDrive.uploadInstallationImage(
              localImage['fve_installation_id'].toString(),
              file,
              description: description,
            );
            break;
          } catch (e) {
            retryCount++;
            if (retryCount >= ImageSyncConfig.maxUploadRetries) {
              throw Exception(ImageSyncConfig.errorUploadFailed);
            }
            await Future.delayed(
              Duration(seconds: ImageSyncConfig.retryDelaySeconds),
            );
          }
        }

        if (oneDriveUrl == null) {
          throw Exception(ImageSyncConfig.errorUploadFailed);
        }

        // 3. Save to cloud database
        final savedImage = SavedImage(
          id: 0, // Will be set by the database
          fveInstallationId: localImage['fve_installation_id'] as int,
          requiredImageId: localImage['required_image_id'] as int,
          location: oneDriveUrl,
          timeAdded: DateTime.parse(localImage['time_added'] as String),
          name: localImage['name'] as String?,
          userId: localImage['user_id'] as int,
          hash: fileHash,
          active: true,
        );

        await _database.saveImage(savedImage);

        // 4. Update local database with cloud ID
        await _localDatabase.markImageAsUploaded(localImageId, savedImage.id);

        _logger.info('Local image uploaded to cloud successfully');
        return savedImage;
      } finally {
        _activeUploads--;
        if (_activeUploads == 0) {
          _appState.updateCloudStatus(CloudStatus.connected);
        }
      }
    } catch (e, stackTrace) {
      _logger.error('Error uploading local image to cloud', e, stackTrace);
      _appState.updateCloudStatus(CloudStatus.connected);
      return null;
    }
  }

  /// Downloads an image from cloud storage to local storage
  Future<File> downloadImage(SavedImage savedImage) async {
    try {
      _logger.info('Starting image download for image ID: ${savedImage.id}');
      _appState.updateCloudStatus(CloudStatus.syncing);

      // Check if image already exists locally with same hash
      final localImages = await _localDatabase.getImagesByInstallationId(
        savedImage.fveInstallationId,
      );

      final existingLocalImage = localImages.firstWhere(
        (img) => img['hash'] == savedImage.hash,
        orElse: () => <String, dynamic>{},
      );

      if (existingLocalImage.isNotEmpty) {
        _logger.info(
          'Found existing local image with same hash, skipping download',
        );
        return File(existingLocalImage['local_path'] as String);
      }

      // 1. Download from OneDrive
      final response = await _oneDrive.getInstallationImages(
        savedImage.fveInstallationId.toString(),
      );

      final imageData = response.firstWhere(
        (img) => img['webUrl'] == savedImage.location,
        orElse: () => throw Exception('Image not found in OneDrive'),
      );

      // 2. Save to local storage
      final localPath = await _imageStorage.saveImage(
        installationId: savedImage.fveInstallationId,
        requiredImageId: savedImage.requiredImageId,
        sourceFile: File(imageData['downloadUrl']),
        customFileName: savedImage.name,
      );

      // 3. Save to local database
      await _localDatabase.saveImage(
        fveInstallationId: savedImage.fveInstallationId,
        requiredImageId: savedImage.requiredImageId,
        localPath: localPath,
        name: savedImage.name,
        timeAdded: savedImage.timeAdded,
        userId: savedImage.userId,
        hash: savedImage.hash,
        cloudId: savedImage.id,
        isUploaded: true,
      );

      _logger.info('Image download completed successfully');
      _appState.updateCloudStatus(CloudStatus.connected);
      return File(localPath);
    } catch (e, stackTrace) {
      _logger.error('Error downloading image', e, stackTrace);
      _appState.updateCloudStatus(CloudStatus.connected);
      rethrow;
    }
  }

  /// Syncs all unuploaded images to cloud storage
  Future<void> syncUnuploadedImages() async {
    try {
      _logger.info('Starting sync of unuploaded images');
      _appState.updateCloudStatus(CloudStatus.syncing);

      final unuploadedImages = await _localDatabase.getUnuploadedImages();
      final processedHashes = <int>{};

      for (final image in unuploadedImages) {
        try {
          // Skip if we've already processed an image with this hash
          if (processedHashes.contains(image['hash'] as int)) {
            _logger.info(
              'Skipping duplicate image with hash: ${image['hash']}',
            );
            continue;
          }

          final savedImage = await uploadLocalImageToCloud(
            localImageId: image['id'] as int,
          );

          if (savedImage != null) {
            processedHashes.add(savedImage.hash);
            _logger.info(
              'Successfully synced image: ${image['id']} to cloud storage',
            );
          } else {
            _logger.warning(
              'Failed to sync image: ${image['id']} to cloud storage',
            );
          }
        } catch (e) {
          _logger.error('Error syncing individual image: ${image['id']}', e);
          // Continue with next image
        }
      }

      _logger.info('Completed sync of unuploaded images');
      _appState.updateCloudStatus(CloudStatus.connected);
    } catch (e, stackTrace) {
      _logger.error('Error syncing unuploaded images', e, stackTrace);
      _appState.updateCloudStatus(CloudStatus.connected);
      rethrow;
    }
  }

  /// Syncs cloud images to local storage
  Future<void> syncCloudImages() async {
    try {
      _logger.info('Starting sync of cloud images to local storage');
      _appState.updateCloudStatus(CloudStatus.syncing);

      // Get all active images from cloud database
      final cloudImages = await _database.getActiveImages();
      final processedHashes = <int>{};

      for (final cloudImage in cloudImages) {
        try {
          // Skip if we've already processed an image with this hash
          if (processedHashes.contains(cloudImage.hash)) {
            _logger.info(
              'Skipping duplicate image with hash: ${cloudImage.hash}',
            );
            continue;
          }

          // Check if image already exists locally
          final localImages = await _localDatabase.getImagesByInstallationId(
            cloudImage.fveInstallationId,
          );

          final existsLocally = localImages.any(
            (img) =>
                img['cloud_id'] == cloudImage.id ||
                img['hash'] == cloudImage.hash,
          );

          if (!existsLocally) {
            await downloadImage(cloudImage);
            processedHashes.add(cloudImage.hash);
            _logger.info(
              'Successfully downloaded cloud image: ${cloudImage.id} to local storage',
            );
          }
        } catch (e) {
          _logger.error(
            'Error syncing individual cloud image: ${cloudImage.id}',
            e,
          );
          // Continue with next image
        }
      }

      _logger.info('Completed sync of cloud images to local storage');
      _appState.updateCloudStatus(CloudStatus.connected);
    } catch (e, stackTrace) {
      _logger.error('Error syncing cloud images', e, stackTrace);
      _appState.updateCloudStatus(CloudStatus.connected);
      rethrow;
    }
  }

  /// Deletes an image from all storage locations
  Future<void> deleteImage(SavedImage savedImage) async {
    try {
      _logger.info('Starting image deletion for ID: ${savedImage.id}');
      _appState.updateCloudStatus(CloudStatus.syncing);

      // 1. Delete from OneDrive
      final response = await _oneDrive.getInstallationImages(
        savedImage.fveInstallationId.toString(),
      );

      final imageData = response.firstWhere(
        (img) => img['webUrl'] == savedImage.location,
        orElse: () => throw Exception('Image not found in OneDrive'),
      );

      await _oneDrive.deleteInstallationImage(
        savedImage.fveInstallationId.toString(),
        imageData['id'],
      );

      // 2. Delete from local storage
      final localImages = await _localDatabase.getImagesByInstallationId(
        savedImage.fveInstallationId,
      );

      for (final localImage in localImages) {
        if (localImage['cloud_id'] == savedImage.id) {
          await _imageStorage.deleteImage(localImage['local_path'] as String);
          break;
        }
      }

      // 3. Mark as inactive in cloud database
      final updatedImage = SavedImage(
        id: savedImage.id,
        fveInstallationId: savedImage.fveInstallationId,
        requiredImageId: savedImage.requiredImageId,
        location: savedImage.location,
        timeAdded: savedImage.timeAdded,
        name: savedImage.name,
        userId: savedImage.userId,
        hash: savedImage.hash,
        active: false,
      );

      await _database.updateSavedImage(updatedImage);

      _logger.info('Image deletion completed successfully');
      _appState.updateCloudStatus(CloudStatus.connected);
    } catch (e, stackTrace) {
      _logger.error('Error deleting image', e, stackTrace);
      _appState.updateCloudStatus(CloudStatus.connected);
      rethrow;
    }
  }
}
