import 'dart:io';

/// Configuration class for image storage settings.
/// Contains constants and settings for image storage operations.
class ImageStorageConfig {
  /// Maximum allowed image size in bytes (10MB)
  static const int maxImageSize = 10 * 1024 * 1024;

  /// Maximum number of images per required image type
  static const int maxImagesPerType = 10;

  /// Maximum total storage size per installation in bytes (100MB)
  static const int maxStoragePerInstallation = 100 * 1024 * 1024;

  /// Allowed image file extensions
  static const List<String> allowedExtensions = [
    '.jpg',
    '.jpeg',
    '.png',
    '.gif',
    '.bmp',
    '.webp',
  ];

  /// Default image quality for compression (0-100)
  static const int defaultImageQuality = 85;

  /// Maximum image dimensions
  static const int maxImageWidth = 1920;
  static const int maxImageHeight = 1080;

  /// Directory names
  static const String baseImagesDir = 'images';
  static const String installationDirPrefix = 'installation_';
  static const String requiredImageDirPrefix = 'required_';

  /// File naming patterns
  static const String timestampFormat = 'yyyyMMdd_HHmmss';
  static const String defaultFileNamePattern = '{timestamp}_{originalName}';

  /// Cleanup settings
  static const int cleanupIntervalDays =
      30; // Days after which unused images are cleaned up
  static const bool autoCleanupEnabled = true;

  /// Error messages
  static const String errorMaxSizeExceeded =
      'Image size exceeds maximum allowed size';
  static const String errorMaxImagesExceeded =
      'Maximum number of images reached for this type';
  static const String errorMaxStorageExceeded =
      'Maximum storage size reached for this installation';
  static const String errorInvalidExtension = 'Invalid image file extension';
  static const String errorInvalidDimensions =
      'Image dimensions exceed maximum allowed size';

  /// Platform-specific settings
  static const Map<String, dynamic> platformSettings = {
    'android': {
      'useExternalStorage': true,
      'requirePermissions': true,
      'permissions': ['android.permission.WRITE_EXTERNAL_STORAGE'],
    },
    'ios': {
      'useExternalStorage': false,
      'requirePermissions': true,
      'permissions': ['NSPhotoLibraryUsageDescription'],
    },
    'windows': {'useExternalStorage': false, 'requirePermissions': false},
    'macos': {
      'useExternalStorage': false,
      'requirePermissions': true,
      'permissions': ['NSPhotoLibraryUsageDescription'],
    },
    'linux': {'useExternalStorage': false, 'requirePermissions': false},
  };

  /// Gets platform-specific settings for the current platform
  static Map<String, dynamic> getPlatformSettings() {
    if (Platform.isAndroid) {
      return platformSettings['android'] as Map<String, dynamic>;
    } else if (Platform.isIOS) {
      return platformSettings['ios'] as Map<String, dynamic>;
    } else if (Platform.isWindows) {
      return platformSettings['windows'] as Map<String, dynamic>;
    } else if (Platform.isMacOS) {
      return platformSettings['macos'] as Map<String, dynamic>;
    } else if (Platform.isLinux) {
      return platformSettings['linux'] as Map<String, dynamic>;
    }
    return {};
  }

  /// Checks if the current platform requires storage permissions
  static bool requiresStoragePermissions() {
    final settings = getPlatformSettings();
    return settings['requirePermissions'] as bool? ?? false;
  }

  /// Gets the required permissions for the current platform
  static List<String> getRequiredPermissions() {
    final settings = getPlatformSettings();
    return (settings['permissions'] as List<dynamic>?)?.cast<String>() ?? [];
  }
}
