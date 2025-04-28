import 'image_sync_service.dart';
import 'image_storage_service.dart';
import 'local_database_service.dart';
import 'database_service.dart';
import 'onedrive_service.dart';
import '../../state/app_state.dart';
import '../utils/logger.dart';

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
  final Map<String, bool> _initializationStatus = {};

  // Getters for service instances
  ImageSyncService get imageSyncService => _imageSyncService!;
  ImageStorageService get imageStorageService => _imageStorageService!;
  LocalDatabaseService get localDatabaseService => _localDatabaseService!;
  DatabaseService get databaseService => _databaseService!;
  OneDriveService get oneDriveService => _oneDriveService!;

  // Service-specific initialization checks
  bool get isDatabaseServiceInitialized => _databaseService != null;
  bool get isImageStorageServiceInitialized => _imageStorageService != null;
  bool get isLocalDatabaseServiceInitialized => _localDatabaseService != null;
  bool get isOneDriveServiceInitialized => _oneDriveService != null;
  bool get isImageSyncServiceInitialized => _imageSyncService != null;

  /// Initializes all services with required dependencies.
  /// Should be called once during app startup.
  Future<void> initialize(AppState appState) async {
    _logger.info('Initializing service factory');

    // Initialize services independently
    await _initializeService('DatabaseService', () async {
      _databaseService = DatabaseService();
    });

    await _initializeService('ImageStorageService', () async {
      _imageStorageService = ImageStorageService();
    });

    await _initializeService('LocalDatabaseService', () async {
      _localDatabaseService = LocalDatabaseService();
    });

    await _initializeService('OneDriveService', () async {
      _oneDriveService = OneDriveService();
      await _oneDriveService!.initialize();
    });

    // Initialize image sync service if all required dependencies are available
    if (_imageStorageService != null &&
        _localDatabaseService != null &&
        _databaseService != null &&
        _oneDriveService != null) {
      await _initializeService('ImageSyncService', () async {
        _imageSyncService = ImageSyncService(
          imageStorage: _imageStorageService!,
          localDatabase: _localDatabaseService!,
          database: _databaseService!,
          oneDrive: _oneDriveService!,
          appState: appState,
        );
      });
    } else {
      _logger.warning(
        'ImageSyncService not initialized due to missing dependencies',
      );
      _initializationStatus['ImageSyncService'] = false;
    }

    // Log initialization status
    _logInitializationStatus();
  }

  Future<void> _initializeService(
    String serviceName,
    Future<void> Function() initFunction,
  ) async {
    try {
      await initFunction();
      _initializationStatus[serviceName] = true;
      _logger.info('$serviceName initialized successfully');
    } catch (e, stackTrace) {
      _logger.error('Failed to initialize $serviceName', e, stackTrace);
      _initializationStatus[serviceName] = false;
      await _cleanup(serviceName);
    }
  }

  void _logInitializationStatus() {
    _logger.info('Service initialization status:');
    _initializationStatus.forEach((service, status) {
      _logger.info('$service: ${status ? "Initialized" : "Failed"}');
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
      _initializationStatus.clear();

      _logger.info('Service factory disposed successfully');
    } catch (e, stackTrace) {
      _logger.error('Error disposing service factory', e, stackTrace);
      rethrow;
    }
  }

  /// Checks if all services are properly initialized
  bool get isInitialized {
    return _initializationStatus.values.every((status) => status);
  }

  /// Gets the initialization status of a specific service
  bool isServiceInitialized(String serviceName) {
    return _initializationStatus[serviceName] ?? false;
  }
}
