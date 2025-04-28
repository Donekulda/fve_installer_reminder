import 'dart:io';

/// Configuration class for image synchronization settings.
/// Contains constants and settings for image sync operations.
class ImageSyncConfig {
  /// Sync interval for checking unuploaded images (15 minutes)
  static const syncIntervalMinutes = 15;

  /// Maximum number of retry attempts for failed uploads
  static const maxUploadRetries = 3;

  /// Delay between retry attempts (in seconds)
  static const retryDelaySeconds = 30;

  /// Maximum number of concurrent uploads
  static const maxConcurrentUploads = 3;

  /// Maximum file size for upload (32MB)
  static const maxUploadSizeBytes = 32 * 1024 * 1024;

  /// Allowed image file extensions
  static const List<String> allowedExtensions = [
    '.jpg',
    '.jpeg',
    '.png',
    '.gif',
    '.bmp',
    '.webp',
  ];

  /// Error messages
  static const String errorMaxSizeExceeded =
      'Image size exceeds maximum allowed size';
  static const String errorInvalidExtension = 'Invalid image file extension';
  static const String errorUploadFailed =
      'Failed to upload image after retries';
  static const String errorDownloadFailed = 'Failed to download image';
  static const String errorDeleteFailed = 'Failed to delete image';
  static const String errorSyncFailed = 'Failed to sync images';

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
