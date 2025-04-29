import 'package:flutter_test/flutter_test.dart';
import 'package:fve_installer_reminder/core/services/service_factory.dart';
import 'package:fve_installer_reminder/state/app_state.dart';
import 'package:fve_installer_reminder/core/services/database_service.dart';
import 'package:fve_installer_reminder/core/services/image_storage_service.dart';
import 'package:fve_installer_reminder/core/services/local_database_service.dart';
import 'package:fve_installer_reminder/core/services/onedrive_service.dart';
import 'package:fve_installer_reminder/core/services/image_sync_service.dart';

/// A mock AppState class for testing that allows simulating initialization failures
class MockAppState extends AppState {
  bool _shouldFail = false;

  void setShouldFail(bool value) {
    _shouldFail = value;
  }

  @override
  Future<void> forceRebuild() async {
    if (_shouldFail) {
      throw Exception('Initialization failed');
    }
    await super.forceRebuild();
  }
}

void main() {
  late ServiceFactory serviceFactory;
  late MockAppState mockAppState;

  setUp(() {
    serviceFactory = ServiceFactory();
    mockAppState = MockAppState();
  });

  tearDown(() async {
    await serviceFactory.dispose();
  });

  group('ServiceFactory Tests', () {
    test('should be a singleton', () {
      final instance1 = ServiceFactory();
      final instance2 = ServiceFactory();
      expect(instance1, same(instance2));
    });

    test('should not be initialized by default', () {
      expect(serviceFactory.isInitialized, false);
      expect(serviceFactory.isDatabaseServiceInitialized, false);
      expect(serviceFactory.isImageStorageServiceInitialized, false);
      expect(serviceFactory.isLocalDatabaseServiceInitialized, false);
      expect(serviceFactory.isOneDriveServiceInitialized, false);
      expect(serviceFactory.isImageSyncServiceInitialized, false);
    });

    test('should initialize all services successfully', () async {
      await serviceFactory.initialize(mockAppState);

      expect(serviceFactory.isInitialized, true);
      expect(serviceFactory.isDatabaseServiceInitialized, true);
      expect(serviceFactory.isImageStorageServiceInitialized, true);
      expect(serviceFactory.isLocalDatabaseServiceInitialized, true);
      expect(serviceFactory.isOneDriveServiceInitialized, true);
      expect(serviceFactory.isImageSyncServiceInitialized, true);
    });

    test('should provide access to initialized services', () async {
      await serviceFactory.initialize(mockAppState);

      expect(serviceFactory.databaseService, isA<DatabaseService>());
      expect(serviceFactory.imageStorageService, isA<ImageStorageService>());
      expect(serviceFactory.localDatabaseService, isA<LocalDatabaseService>());
      expect(serviceFactory.oneDriveService, isA<OneDriveService>());
      expect(serviceFactory.imageSyncService, isA<ImageSyncService>());
    });

    test('should handle service initialization failures gracefully', () async {
      mockAppState.setShouldFail(true);

      await serviceFactory.initialize(mockAppState);

      expect(serviceFactory.isInitialized, false);
      expect(serviceFactory.isDatabaseServiceInitialized, false);
      expect(serviceFactory.isImageStorageServiceInitialized, false);
      expect(serviceFactory.isLocalDatabaseServiceInitialized, false);
      expect(serviceFactory.isOneDriveServiceInitialized, false);
      expect(serviceFactory.isImageSyncServiceInitialized, false);
    });

    test('should dispose all services properly', () async {
      await serviceFactory.initialize(mockAppState);
      await serviceFactory.dispose();

      expect(serviceFactory.isInitialized, false);
      expect(serviceFactory.isDatabaseServiceInitialized, false);
      expect(serviceFactory.isImageStorageServiceInitialized, false);
      expect(serviceFactory.isLocalDatabaseServiceInitialized, false);
      expect(serviceFactory.isOneDriveServiceInitialized, false);
      expect(serviceFactory.isImageSyncServiceInitialized, false);
    });

    test('should check service initialization status correctly', () async {
      await serviceFactory.initialize(mockAppState);

      expect(serviceFactory.isServiceInitialized('DatabaseService'), true);
      expect(serviceFactory.isServiceInitialized('ImageStorageService'), true);
      expect(serviceFactory.isServiceInitialized('LocalDatabaseService'), true);
      expect(serviceFactory.isServiceInitialized('OneDriveService'), true);
      expect(serviceFactory.isServiceInitialized('ImageSyncService'), true);
      expect(serviceFactory.isServiceInitialized('NonExistentService'), false);
    });

    test('should handle multiple initialize calls gracefully', () async {
      await serviceFactory.initialize(mockAppState);
      await serviceFactory.initialize(mockAppState); // Second call

      expect(serviceFactory.isInitialized, true);
      expect(serviceFactory.isDatabaseServiceInitialized, true);
      expect(serviceFactory.isImageStorageServiceInitialized, true);
      expect(serviceFactory.isLocalDatabaseServiceInitialized, true);
      expect(serviceFactory.isOneDriveServiceInitialized, true);
      expect(serviceFactory.isImageSyncServiceInitialized, true);
    });

    test('should handle multiple dispose calls gracefully', () async {
      await serviceFactory.initialize(mockAppState);
      await serviceFactory.dispose();
      await serviceFactory.dispose(); // Second call

      expect(serviceFactory.isInitialized, false);
      expect(serviceFactory.isDatabaseServiceInitialized, false);
      expect(serviceFactory.isImageStorageServiceInitialized, false);
      expect(serviceFactory.isLocalDatabaseServiceInitialized, false);
      expect(serviceFactory.isOneDriveServiceInitialized, false);
      expect(serviceFactory.isImageSyncServiceInitialized, false);
    });
  });
}
