import 'dart:io';
import 'dart:async';
import '../../core/services/image_storage_service.dart';
import '../../core/services/local_database_service.dart';
import '../../core/services/database_service.dart';
import '../../core/services/onedrive_service.dart';
import '../../core/utils/logger.dart';
import '../../data/models/saved_image.dart';

/// Service class that coordinates between image storage, local database, cloud database, and OneDrive services.
/// Handles synchronization of images between local storage and cloud storage.
class ImageSyncService {
  final ImageStorageService _imageStorage;
  final LocalDatabaseService _localDatabase;
  final DatabaseService _database;
  final OneDriveService _oneDrive;
  final _logger = AppLogger('ImageSyncService');

  Timer? _syncTimer;
  static const _syncInterval = Duration(minutes: 15); // Check every 15 minutes

  ImageSyncService({
    required ImageStorageService imageStorage,
    required LocalDatabaseService localDatabase,
    required DatabaseService database,
    required OneDriveService oneDrive,
  }) : _imageStorage = imageStorage,
       _localDatabase = localDatabase,
       _database = database,
       _oneDrive = oneDrive {
    _startPeriodicSync();
  }

  /// Starts periodic checking for unuploaded images
  void _startPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(_syncInterval, (_) {
      syncUnuploadedImages();
    });
  }

  /// Stops periodic checking
  void dispose() {
    _syncTimer?.cancel();
    _syncTimer = null;
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

      // 1. Get local image data
      final localImage = await _localDatabase.getImageById(localImageId);
      if (localImage == null) {
        throw Exception('Local image not found');
      }

      final file = File(localImage['local_path'] as String);
      if (!await file.exists()) {
        throw Exception('Local file not found');
      }

      // 2. Upload to OneDrive
      final oneDriveUrl = await _oneDrive.uploadInstallationImage(
        localImage['fve_installation_id'].toString(),
        file,
        description: description,
      );

      // 3. Save to cloud database
      final savedImage = SavedImage(
        id: 0, // Will be set by the database
        fveInstallationId: localImage['fve_installation_id'] as int,
        requiredImageId: localImage['required_image_id'] as int,
        location: oneDriveUrl,
        timeAdded: DateTime.parse(localImage['time_added'] as String),
        name: localImage['name'] as String?,
        userId: localImage['user_id'] as int,
        hash: localImage['hash'] as int,
        active: true,
      );

      await _database.saveImage(savedImage);

      // 4. Update local database with cloud ID
      await _localDatabase.markImageAsUploaded(localImageId, savedImage.id);

      _logger.info('Local image uploaded to cloud successfully');
      return savedImage;
    } catch (e, stackTrace) {
      _logger.error('Error uploading local image to cloud', e, stackTrace);
      return null;
    }
  }

  /// Downloads an image from cloud storage to local storage
  Future<File> downloadImage(SavedImage savedImage) async {
    try {
      _logger.info('Starting image download for image ID: ${savedImage.id}');

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
      return File(localPath);
    } catch (e, stackTrace) {
      _logger.error('Error downloading image', e, stackTrace);
      rethrow;
    }
  }

  /// Syncs all unuploaded images to cloud storage
  Future<void> syncUnuploadedImages() async {
    try {
      _logger.info('Starting sync of unuploaded images');

      final unuploadedImages = await _localDatabase.getUnuploadedImages();
      for (final image in unuploadedImages) {
        try {
          final savedImage = await uploadLocalImageToCloud(
            localImageId: image['id'] as int,
          );

          if (savedImage != null) {
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
    } catch (e, stackTrace) {
      _logger.error('Error syncing unuploaded images', e, stackTrace);
      rethrow;
    }
  }

  /// Deletes an image from all storage locations
  Future<void> deleteImage(SavedImage savedImage) async {
    try {
      _logger.info('Starting image deletion for ID: ${savedImage.id}');

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
    } catch (e, stackTrace) {
      _logger.error('Error deleting image', e, stackTrace);
      rethrow;
    }
  }
}
