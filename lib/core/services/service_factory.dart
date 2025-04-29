import 'image_sync_service.dart';
import 'image_storage_service.dart';
import 'local_database_service.dart';
import 'database_service.dart';
import 'onedrive_service.dart';
import '../../state/app_state.dart';
import '../utils/logger.dart';

/// Result of a service initialization attempt
class ServiceInitializationResult<T> {
  final T? service;
  final bool success;
  final String? errorMessage;
  final dynamic error;

  ServiceInitializationResult({
    this.service,
    required this.success,
    this.errorMessage,
    this.error,
  });

  factory ServiceInitializationResult.success(T service) {
    return ServiceInitializationResult(service: service, success: true);
  }

  factory ServiceInitializationResult.failure({
    String? errorMessage,
    dynamic error,
  }) {
    return ServiceInitializationResult(
      success: false,
      errorMessage: errorMessage,
      error: error,
    );
  }
}

/// Factory class that manages singleton instances of services that require
/// constant running and synchronization.
class ServiceFactory {
  static final ServiceFactory _instance = ServiceFactory._internal();
  factory ServiceFactory() => _instance;
  ServiceFactory._internal();

  final _logger = AppLogger('ServiceFactory');

  // Service instances
  ImageSyncService? _imageSyncService;
  ImageStorageService? _imageStorageService;
  LocalDatabaseService? _localDatabaseService;
  DatabaseService? _databaseService;
  OneDriveService? _oneDriveService;

  // Track initialization status
  final Map<String, ServiceInitializationResult> _initializationResults = {};

  // Getters for service instances with null safety
  ImageSyncService? get imageSyncService => _imageSyncService;
  ImageStorageService? get imageStorageService => _imageStorageService;
  LocalDatabaseService? get localDatabaseService => _localDatabaseService;
  DatabaseService? get databaseService => _databaseService;
  OneDriveService? get oneDriveService => _oneDriveService;

  // Service-specific initialization checks
  bool get isDatabaseServiceInitialized =>
      _initializationResults['DatabaseService']?.success ?? false;
  bool get isImageStorageServiceInitialized =>
      _initializationResults['ImageStorageService']?.success ?? false;
  bool get isLocalDatabaseServiceInitialized =>
      _initializationResults['LocalDatabaseService']?.success ?? false;
  bool get isOneDriveServiceInitialized =>
      _initializationResults['OneDriveService']?.success ?? false;
  bool get isImageSyncServiceInitialized =>
      _initializationResults['ImageSyncService']?.success ?? false;

  /// Initializes all services with required dependencies.
  /// Should be called once during app startup.
  Future<void> initialize(AppState appState) async {
    _logger.info('Initializing service factory');

    // Initialize services independently
    await _initializeService<ImageStorageService>(
      'ImageStorageService',
      () async {
        final service = ImageStorageService();
        return ServiceInitializationResult.success(service);
      },
    );

    await _initializeService<LocalDatabaseService>(
      'LocalDatabaseService',
      () async {
        final service = LocalDatabaseService();
        return ServiceInitializationResult.success(service);
      },
    );

    await _initializeService<OneDriveService>('OneDriveService', () async {
      final service = OneDriveService();
      try {
        await service.initialize();
        return ServiceInitializationResult.success(service);
      } catch (e, stackTrace) {
        _logger.warning(
          'OneDrive service initialization failed, but continuing with other services',
        );
        return ServiceInitializationResult.failure(
          errorMessage: 'Failed to initialize OneDrive service',
          error: e,
        );
      }
    });

    // Initialize image sync service only if all required dependencies are available
    // and OneDrive service is successfully initialized
    if (isImageStorageServiceInitialized &&
        isLocalDatabaseServiceInitialized &&
        isOneDriveServiceInitialized &&
        appState.databaseService != null) {
      await _initializeService<ImageSyncService>('ImageSyncService', () async {
        try {
          final service = ImageSyncService(
            imageStorage: _imageStorageService!,
            localDatabase: _localDatabaseService!,
            database: appState.databaseService!, // We know it's not null here
            oneDrive: _oneDriveService!,
            appState: appState,
          );
          return ServiceInitializationResult.success(service);
        } catch (e, stackTrace) {
          _logger.warning(
            'ImageSync service initialization failed, but continuing with other services',
          );
          return ServiceInitializationResult.failure(
            errorMessage: 'Failed to initialize ImageSync service',
            error: e,
          );
        }
      });
    } else {
      _logger.warning(
        'ImageSyncService not initialized due to missing dependencies',
      );
      _initializationResults['ImageSyncService'] =
          ServiceInitializationResult.failure(
            errorMessage: 'Missing required dependencies',
          );
    }

    // Log initialization status
    _logInitializationStatus();
  }

  Future<void> _initializeService<T>(
    String serviceName,
    Future<ServiceInitializationResult<T>> Function() initFunction,
  ) async {
    try {
      final result = await initFunction();
      _initializationResults[serviceName] = result;

      if (result.success && result.service != null) {
        switch (serviceName) {
          case 'DatabaseService':
            _databaseService = result.service as DatabaseService;
            break;
          case 'ImageStorageService':
            _imageStorageService = result.service as ImageStorageService;
            break;
          case 'LocalDatabaseService':
            _localDatabaseService = result.service as LocalDatabaseService;
            break;
          case 'OneDriveService':
            _oneDriveService = result.service as OneDriveService;
            break;
          case 'ImageSyncService':
            _imageSyncService = result.service as ImageSyncService;
            break;
        }
        _logger.info('$serviceName initialized successfully');
      } else {
        _logger.error(
          'Failed to initialize $serviceName: ${result.errorMessage}',
          result.error,
        );
        await _cleanup(serviceName);
      }
    } catch (e, stackTrace) {
      _logger.error('Error during $serviceName initialization', e, stackTrace);
      _initializationResults[serviceName] = ServiceInitializationResult.failure(
        errorMessage: 'Unexpected error during initialization',
        error: e,
      );
      await _cleanup(serviceName);
    }
  }

  void _logInitializationStatus() {
    _logger.info('Service initialization status:');
    _initializationResults.forEach((service, result) {
      _logger.info(
        '$service: ${result.success ? "Initialized" : "Failed"}${result.errorMessage != null ? " - ${result.errorMessage}" : ""}',
      );
    });
  }

  /// Cleans up any partially initialized services
  Future<void> _cleanup(String serviceName) async {
    _logger.info('Cleaning up $serviceName');
    try {
      switch (serviceName) {
        case 'ImageSyncService':
          _imageSyncService?.dispose();
          _imageSyncService = null;
          break;
        case 'OneDriveService':
          _oneDriveService = null;
          break;
        case 'LocalDatabaseService':
          _localDatabaseService = null;
          break;
        case 'ImageStorageService':
          _imageStorageService = null;
          break;
        case 'DatabaseService':
          _databaseService = null;
          break;
      }
    } catch (e, stackTrace) {
      _logger.error('Error during $serviceName cleanup', e, stackTrace);
    }
  }

  /// Disposes all services and cleans up resources.
  /// Should be called when the app is shutting down.
  Future<void> dispose() async {
    _logger.info('Disposing service factory');

    try {
      // Dispose services in reverse order of initialization
      _imageSyncService?.dispose();

      // Clear references
      _imageSyncService = null;
      _oneDriveService = null;
      _localDatabaseService = null;
      _imageStorageService = null;
      _databaseService = null;
      _initializationResults.clear();

      _logger.info('Service factory disposed successfully');
    } catch (e, stackTrace) {
      _logger.error('Error disposing service factory', e, stackTrace);
      rethrow;
    }
  }

  /// Checks if all services are properly initialized
  bool get isInitialized {
    return _initializationResults.values.every((result) => result.success);
  }

  /// Gets the initialization status of a specific service
  bool isServiceInitialized(String serviceName) {
    return _initializationResults[serviceName]?.success ?? false;
  }

  /// Gets the initialization result for a specific service
  ServiceInitializationResult? getServiceInitializationResult(
    String serviceName,
  ) {
    return _initializationResults[serviceName];
  }
}
