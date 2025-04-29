import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:fve_installer_reminder/core/services/local_database_service.dart';
//import 'package:path/path.dart' as path;
//import 'dart:io';

void main() {
  late LocalDatabaseService databaseService;

  setUpAll(() {
    // Initialize Flutter bindings
    TestWidgetsFlutterBinding.ensureInitialized();
    // Initialize FFI for testing
    sqfliteFfiInit();
    // Set the database factory to use FFI
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    // Create a new instance of LocalDatabaseService for each test
    // Use an in-memory database for testing
    databaseService = LocalDatabaseService(databasePath: inMemoryDatabasePath);
  });

  tearDown(() async {
    // Close the database after each test
    await databaseService.close();
  });

  group('LocalDatabaseService Tests', () {
    test('should save and retrieve image', () async {
      // Arrange
      final testImage = {
        'fveInstallationId': 1,
        'requiredImageId': 2,
        'localPath': '/test/path/image.jpg',
        'name': 'Test Image',
        'timeAdded': DateTime.now(),
        'userId': 1,
        'hash': 123456,
        'cloudId': null,
        'isUploaded': false,
        'isActive': true,
      };

      // Act
      final imageId = await databaseService.saveImage(
        fveInstallationId: testImage['fveInstallationId'] as int,
        requiredImageId: testImage['requiredImageId'] as int,
        localPath: testImage['localPath'] as String,
        name: testImage['name'] as String,
        timeAdded: testImage['timeAdded'] as DateTime,
        userId: testImage['userId'] as int,
        hash: testImage['hash'] as int,
      );

      // Assert
      expect(imageId, isNotNull);
      expect(imageId, isPositive);

      final retrievedImage = await databaseService.getImageById(imageId);
      expect(retrievedImage, isNotNull);
      expect(
        retrievedImage!['fve_installation_id'],
        testImage['fveInstallationId'],
      );
      expect(retrievedImage['required_image_id'], testImage['requiredImageId']);
      expect(retrievedImage['local_path'], testImage['localPath']);
      expect(retrievedImage['name'], testImage['name']);
      expect(retrievedImage['user_id'], testImage['userId']);
      expect(retrievedImage['hash'], testImage['hash']);
      expect(retrievedImage['is_uploaded'], 0);
      expect(retrievedImage['is_active'], 1);
    });

    test('should get images by installation ID', () async {
      // Arrange
      final installationId = 1;
      await databaseService.saveImage(
        fveInstallationId: installationId,
        requiredImageId: 1,
        localPath: '/test/path/image1.jpg',
        userId: 1,
        hash: 123456,
      );
      await databaseService.saveImage(
        fveInstallationId: installationId,
        requiredImageId: 2,
        localPath: '/test/path/image2.jpg',
        userId: 1,
        hash: 789012,
      );

      // Act
      final images = await databaseService.getImagesByInstallationId(
        installationId,
      );

      // Assert
      expect(images.length, 2);
      expect(
        images.every((img) => img['fve_installation_id'] == installationId),
        true,
      );
    });

    test('should get images by required image ID', () async {
      // Arrange
      final requiredImageId = 1;
      await databaseService.saveImage(
        fveInstallationId: 1,
        requiredImageId: requiredImageId,
        localPath: '/test/path/image1.jpg',
        userId: 1,
        hash: 123456,
      );
      await databaseService.saveImage(
        fveInstallationId: 2,
        requiredImageId: requiredImageId,
        localPath: '/test/path/image2.jpg',
        userId: 1,
        hash: 789012,
      );

      // Act
      final images = await databaseService.getImagesByRequiredImageId(
        requiredImageId,
      );

      // Assert
      expect(images.length, 2);
      expect(
        images.every((img) => img['required_image_id'] == requiredImageId),
        true,
      );
    });

    test('should get unuploaded images', () async {
      // Arrange
      await databaseService.saveImage(
        fveInstallationId: 1,
        requiredImageId: 1,
        localPath: '/test/path/image1.jpg',
        userId: 1,
        hash: 123456,
      );
      final uploadedImageId = await databaseService.saveImage(
        fveInstallationId: 1,
        requiredImageId: 2,
        localPath: '/test/path/image2.jpg',
        userId: 1,
        hash: 789012,
      );
      await databaseService.markImageAsUploaded(uploadedImageId, 999);

      // Act
      final unuploadedImages = await databaseService.getUnuploadedImages();

      // Assert
      expect(unuploadedImages.length, 1);
      expect(unuploadedImages.first['is_uploaded'], 0);
    });

    test('should mark image as uploaded', () async {
      // Arrange
      final imageId = await databaseService.saveImage(
        fveInstallationId: 1,
        requiredImageId: 1,
        localPath: '/test/path/image.jpg',
        userId: 1,
        hash: 123456,
      );
      final cloudId = 999;

      // Act
      await databaseService.markImageAsUploaded(imageId, cloudId);

      // Assert
      final image = await databaseService.getImageById(imageId);
      expect(image!['is_uploaded'], 1);
      expect(image['cloud_id'], cloudId);
    });

    test('should deactivate image', () async {
      // Arrange
      final imageId = await databaseService.saveImage(
        fveInstallationId: 1,
        requiredImageId: 1,
        localPath: '/test/path/image.jpg',
        userId: 1,
        hash: 123456,
      );

      // Act
      await databaseService.deactivateImage(imageId);

      // Assert
      final image = await databaseService.getImageById(imageId);
      expect(image!['is_active'], 0);
    });

    test('should add and retrieve image metadata', () async {
      // Arrange
      final imageId = await databaseService.saveImage(
        fveInstallationId: 1,
        requiredImageId: 1,
        localPath: '/test/path/image.jpg',
        userId: 1,
        hash: 123456,
      );

      // Act
      await databaseService.addImageMetadata(imageId, 'test_key', 'test_value');

      // Assert
      final metadata = await databaseService.getImageMetadata(imageId);
      expect(metadata.length, 1);
      expect(metadata.first['key'], 'test_key');
      expect(metadata.first['value'], 'test_value');
    });

    test('should handle multiple metadata entries for an image', () async {
      // Arrange
      final imageId = await databaseService.saveImage(
        fveInstallationId: 1,
        requiredImageId: 1,
        localPath: '/test/path/image.jpg',
        userId: 1,
        hash: 123456,
      );

      // Act
      await databaseService.addImageMetadata(imageId, 'key1', 'value1');
      await databaseService.addImageMetadata(imageId, 'key2', 'value2');

      // Assert
      final metadata = await databaseService.getImageMetadata(imageId);
      expect(metadata.length, 2);
      expect(
        metadata.any((m) => m['key'] == 'key1' && m['value'] == 'value1'),
        true,
      );
      expect(
        metadata.any((m) => m['key'] == 'key2' && m['value'] == 'value2'),
        true,
      );
    });
  });
}
