import 'package:flutter/material.dart';
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

  // Getters for service instances
  ImageSyncService get imageSyncService => _imageSyncService!;
  ImageStorageService get imageStorageService => _imageStorageService!;
  LocalDatabaseService get localDatabaseService => _localDatabaseService!;
  DatabaseService get databaseService => _databaseService!;
  OneDriveService get oneDriveService => _oneDriveService!;

  /// Initializes all services with required dependencies.
  /// Should be called once during app startup.
  Future<void> initialize(AppState appState) async {
    _logger.info('Initializing service factory');

    // Initialize services in correct order
    _databaseService = DatabaseService();
    _imageStorageService = ImageStorageService();
    _localDatabaseService = LocalDatabaseService();
    _oneDriveService = OneDriveService();

    // Initialize OneDrive service
    await _oneDriveService!.initialize();

    // Initialize image sync service last as it depends on all others
    _imageSyncService = ImageSyncService(
      imageStorage: _imageStorageService!,
      localDatabase: _localDatabaseService!,
      database: _databaseService!,
      oneDrive: _oneDriveService!,
      appState: appState,
    );

    _logger.info('Service factory initialized successfully');
  }

  /// Disposes all services and cleans up resources.
  /// Should be called when the app is shutting down.
  Future<void> dispose() async {
    _logger.info('Disposing service factory');

    // Dispose services in reverse order of initialization
    _imageSyncService?.dispose();

    // Clear references
    _imageSyncService = null;
    _oneDriveService = null;
    _localDatabaseService = null;
    _imageStorageService = null;
    _databaseService = null;

    _logger.info('Service factory disposed successfully');
  }

  /// Checks if all services are properly initialized
  bool get isInitialized {
    return _imageSyncService != null &&
        _imageStorageService != null &&
        _localDatabaseService != null &&
        _databaseService != null &&
        _oneDriveService != null;
  }
}
