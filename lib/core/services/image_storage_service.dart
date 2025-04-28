import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';
import '../../core/utils/logger.dart';
import '../../core/config/image_storage_config.dart';

/// Service class for managing image file storage.
/// Handles platform-specific storage locations and file operations.
class ImageStorageService {
  /// Logger instance
  final _logger = AppLogger('ImageStorageService');

  /// Base directory for storing images
  Directory? _baseDirectory;

  /// Gets the base directory for storing images
  Future<Directory> get baseDirectory async {
    if (_baseDirectory != null) return _baseDirectory!;
    _baseDirectory = await _initBaseDirectory();
    return _baseDirectory!;
  }

  /// Calculates a SHA-256 hash for a file
  Future<int> calculateFileHash(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final hash = sha256.convert(bytes);
      return hash.toString().hashCode;
    } catch (e, stackTrace) {
      _logger.error('Error calculating file hash', e, stackTrace);
      rethrow;
    }
  }

  /// Initializes the base directory for storing images
  Future<Directory> _initBaseDirectory() async {
    try {
      Directory appDir;
      final platformSettings = ImageStorageConfig.getPlatformSettings();

      if (Platform.isAndroid &&
          platformSettings['useExternalStorage'] == true) {
        appDir =
            await getExternalStorageDirectory() ??
            await getApplicationDocumentsDirectory();
      } else {
        appDir = await getApplicationDocumentsDirectory();
      }

      // Create the images directory
      final imagesDir = Directory(
        path.join(appDir.path, ImageStorageConfig.baseImagesDir),
      );
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }

      return imagesDir;
    } catch (e, stackTrace) {
      _logger.error('Error initializing base directory', e, stackTrace);
      rethrow;
    }
  }

  /// Gets the directory for a specific FVE installation
  Future<Directory> getInstallationDirectory(int installationId) async {
    try {
      final baseDir = await baseDirectory;
      final installationDir = Directory(
        path.join(
          baseDir.path,
          '${ImageStorageConfig.installationDirPrefix}$installationId',
        ),
      );
      if (!await installationDir.exists()) {
        await installationDir.create(recursive: true);
      }
      return installationDir;
    } catch (e, stackTrace) {
      _logger.error(
        'Error getting installation directory for ID: $installationId',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  /// Gets the directory for a specific required image type
  Future<Directory> getRequiredImageDirectory(
    int installationId,
    int requiredImageId,
  ) async {
    try {
      final installationDir = await getInstallationDirectory(installationId);
      final requiredImageDir = Directory(
        path.join(
          installationDir.path,
          '${ImageStorageConfig.requiredImageDirPrefix}$requiredImageId',
        ),
      );
      if (!await requiredImageDir.exists()) {
        await requiredImageDir.create(recursive: true);
      }
      return requiredImageDir;
    } catch (e, stackTrace) {
      _logger.error(
        'Error getting required image directory for installation: $installationId, required: $requiredImageId',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  /// Validates an image file before saving
  Future<void> _validateImage(File file) async {
    // Check file size
    final fileSize = await file.length();
    if (fileSize > ImageStorageConfig.maxImageSize) {
      throw Exception(ImageStorageConfig.errorMaxSizeExceeded);
    }

    // Check file extension
    final extension = path.extension(file.path).toLowerCase();
    if (!ImageStorageConfig.allowedExtensions.contains(extension)) {
      throw Exception(ImageStorageConfig.errorInvalidExtension);
    }

    // TODO: Add image dimension validation when image processing is implemented
  }

  /// Saves an image file to the appropriate directory
  Future<String> saveImage({
    required int installationId,
    required int requiredImageId,
    required File sourceFile,
    String? customFileName,
  }) async {
    try {
      // Validate the image before saving
      await _validateImage(sourceFile);

      // Check if we've reached the maximum number of images for this type
      final existingImages = await getImagesForRequiredType(
        installationId,
        requiredImageId,
      );
      if (existingImages.length >= ImageStorageConfig.maxImagesPerType) {
        throw Exception(ImageStorageConfig.errorMaxImagesExceeded);
      }

      // Check if we've reached the maximum storage size for this installation
      final currentSize = await getInstallationStorageSize(installationId);
      if (currentSize + await sourceFile.length() >
          ImageStorageConfig.maxStoragePerInstallation) {
        throw Exception(ImageStorageConfig.errorMaxStorageExceeded);
      }

      final targetDir = await getRequiredImageDirectory(
        installationId,
        requiredImageId,
      );

      // Generate a unique filename if not provided
      final fileName =
          customFileName ??
          '${DateTime.now().millisecondsSinceEpoch}_${path.basename(sourceFile.path)}';
      final targetPath = path.join(targetDir.path, fileName);

      // Copy the file to the target location
      await sourceFile.copy(targetPath);
      return targetPath;
    } catch (e, stackTrace) {
      _logger.error(
        'Error saving image for installation: $installationId, required: $requiredImageId',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  /// Gets all image files for a specific required image type
  Future<List<File>> getImagesForRequiredType(
    int installationId,
    int requiredImageId,
  ) async {
    try {
      final targetDir = await getRequiredImageDirectory(
        installationId,
        requiredImageId,
      );
      final files = await targetDir.list().toList();
      return files
          .whereType<File>()
          .where((file) => _isImageFile(file.path))
          .toList();
    } catch (e, stackTrace) {
      _logger.error(
        'Error getting images for installation: $installationId, required: $requiredImageId',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  /// Deletes an image file
  Future<void> deleteImage(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e, stackTrace) {
      _logger.error('Error deleting image: $filePath', e, stackTrace);
      rethrow;
    }
  }

  /// Checks if a file is an image based on its extension
  bool _isImageFile(String filePath) {
    final extension = path.extension(filePath).toLowerCase();
    return ImageStorageConfig.allowedExtensions.contains(extension);
  }

  /// Gets the total size of all images for a specific installation
  Future<int> getInstallationStorageSize(int installationId) async {
    try {
      final installationDir = await getInstallationDirectory(installationId);
      int totalSize = 0;
      await for (final entity in installationDir.list(recursive: true)) {
        if (entity is File && _isImageFile(entity.path)) {
          totalSize += await entity.length();
        }
      }
      return totalSize;
    } catch (e, stackTrace) {
      _logger.error(
        'Error getting storage size for installation: $installationId',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  /// Cleans up old or unused images
  Future<void> cleanupImages({
    required int installationId,
    required int requiredImageId,
    required List<String> activeImagePaths,
  }) async {
    if (!ImageStorageConfig.autoCleanupEnabled) return;

    try {
      final targetDir = await getRequiredImageDirectory(
        installationId,
        requiredImageId,
      );
      final files = await targetDir.list().toList();

      for (final entity in files) {
        if (entity is File && _isImageFile(entity.path)) {
          if (!activeImagePaths.contains(entity.path)) {
            await entity.delete();
          }
        }
      }
    } catch (e, stackTrace) {
      _logger.error(
        'Error cleaning up images for installation: $installationId, required: $requiredImageId',
        e,
        stackTrace,
      );
      rethrow;
    }
  }
}
