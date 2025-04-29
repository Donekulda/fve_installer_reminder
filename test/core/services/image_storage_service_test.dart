import 'package:flutter_test/flutter_test.dart';
import 'package:fve_installer_reminder/core/services/image_storage_service.dart';
import 'package:path/path.dart' as path;
import 'dart:io';
//import 'package:flutter/widgets.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
//import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockPathProviderPlatform extends PathProviderPlatform {
  @override
  Future<String?> getApplicationDocumentsPath() async {
    return '/mock/documents/path';
  }

  @override
  Future<String?> getExternalStoragePath() async {
    return '/mock/external/path';
  }

  @override
  Future<String?> getApplicationCachePath() async {
    return '/mock/cache/path';
  }

  @override
  Future<String?> getApplicationSupportPath() async {
    return '/mock/support/path';
  }

  @override
  Future<String?> getDownloadsPath() async {
    return '/mock/downloads/path';
  }

  @override
  Future<List<String>?> getExternalCachePaths() async {
    return ['/mock/external/cache/path'];
  }

  @override
  Future<List<String>?> getExternalStoragePaths({
    StorageDirectory? type,
  }) async {
    return ['/mock/external/storage/path'];
  }

  @override
  Future<String?> getLibraryPath() async {
    return '/mock/library/path';
  }

  @override
  Future<String?> getTemporaryPath() async {
    return '/mock/temp/path';
  }
}

void main() {
  late ImageStorageService imageStorageService;
  late Directory testDir;

  setUpAll(() {
    // Initialize Flutter bindings
    TestWidgetsFlutterBinding.ensureInitialized();
    // Set up mock path provider
    PathProviderPlatform.instance = MockPathProviderPlatform();
  });

  setUp(() async {
    // Create a temporary directory for testing
    testDir = await Directory.systemTemp.createTemp('image_storage_test_');
    imageStorageService = ImageStorageService();
  });

  tearDown(() async {
    // Clean up test directory
    if (await testDir.exists()) {
      await testDir.delete(recursive: true);
    }
  });

  group('ImageStorageService Tests', () {
    test('should initialize base directory', () async {
      // Act
      final baseDir = await imageStorageService.baseDirectory;

      // Assert
      expect(baseDir, isNotNull);
      expect(await baseDir.exists(), true);
    });

    test('should calculate file hash', () async {
      // Arrange
      final testFile = File(path.join(testDir.path, 'test.txt'));
      await testFile.writeAsString('test content');

      // Act
      final hash = await imageStorageService.calculateFileHash(testFile);

      // Assert
      expect(hash, isNotNull);
      expect(hash, isA<int>());
    });

    test('should get installation directory', () async {
      // Arrange
      const installationId = 1;

      // Act
      final installationDir = await imageStorageService
          .getInstallationDirectory(installationId);

      // Assert
      expect(installationDir, isNotNull);
      expect(await installationDir.exists(), true);
      expect(path.basename(installationDir.path), 'installation_1');
    });

    test('should get required image directory', () async {
      // Arrange
      const installationId = 1;
      const requiredImageId = 2;

      // Act
      final requiredImageDir = await imageStorageService
          .getRequiredImageDirectory(installationId, requiredImageId);

      // Assert
      expect(requiredImageDir, isNotNull);
      expect(await requiredImageDir.exists(), true);
      expect(path.basename(requiredImageDir.path), 'required_2');
    });

    test('should validate image file size', () async {
      // Arrange
      final largeFile = File(path.join(testDir.path, 'large.jpg'));
      await largeFile.writeAsBytes(List.filled(11 * 1024 * 1024, 0)); // 11MB

      // Act & Assert
      expect(
        () => imageStorageService.saveImage(
          installationId: 1,
          requiredImageId: 1,
          sourceFile: largeFile,
        ),
        throwsException,
      );
    });

    test('should validate image file extension', () async {
      // Arrange
      final invalidFile = File(path.join(testDir.path, 'test.invalid'));
      await invalidFile.writeAsString('test content');

      // Act & Assert
      expect(
        () => imageStorageService.saveImage(
          installationId: 1,
          requiredImageId: 1,
          sourceFile: invalidFile,
        ),
        throwsException,
      );
    });

    test('should save and retrieve image', () async {
      // Arrange
      final testImage = File(path.join(testDir.path, 'test.jpg'));
      await testImage.writeAsString('test image content');

      // Act
      final savedPath = await imageStorageService.saveImage(
        installationId: 1,
        requiredImageId: 1,
        sourceFile: testImage,
      );

      // Assert
      expect(savedPath, isNotNull);
      expect(await File(savedPath).exists(), true);
    });

    test('should get images for required type', () async {
      // Arrange
      final testImage1 = File(path.join(testDir.path, 'test1.jpg'));
      final testImage2 = File(path.join(testDir.path, 'test2.jpg'));
      await testImage1.writeAsString('test image 1');
      await testImage2.writeAsString('test image 2');

      await imageStorageService.saveImage(
        installationId: 1,
        requiredImageId: 1,
        sourceFile: testImage1,
      );
      await imageStorageService.saveImage(
        installationId: 1,
        requiredImageId: 1,
        sourceFile: testImage2,
      );

      // Act
      final images = await imageStorageService.getImagesForRequiredType(1, 1);

      // Assert
      expect(images.length, 2);
    });

    test('should delete image', () async {
      // Arrange
      final testImage = File(path.join(testDir.path, 'test.jpg'));
      await testImage.writeAsString('test image content');
      final savedPath = await imageStorageService.saveImage(
        installationId: 1,
        requiredImageId: 1,
        sourceFile: testImage,
      );

      // Act
      await imageStorageService.deleteImage(savedPath);

      // Assert
      expect(await File(savedPath).exists(), false);
    });

    test('should get installation storage size', () async {
      // Arrange
      final testImage = File(path.join(testDir.path, 'test.jpg'));
      await testImage.writeAsString('test image content');
      await imageStorageService.saveImage(
        installationId: 1,
        requiredImageId: 1,
        sourceFile: testImage,
      );

      // Act
      final size = await imageStorageService.getInstallationStorageSize(1);

      // Assert
      expect(size, isPositive);
    });

    test('should cleanup unused images', () async {
      // Arrange
      final testImage1 = File(path.join(testDir.path, 'test1.jpg'));
      final testImage2 = File(path.join(testDir.path, 'test2.jpg'));
      await testImage1.writeAsString('test image 1');
      await testImage2.writeAsString('test image 2');

      final savedPath1 = await imageStorageService.saveImage(
        installationId: 1,
        requiredImageId: 1,
        sourceFile: testImage1,
      );
      await imageStorageService.saveImage(
        installationId: 1,
        requiredImageId: 1,
        sourceFile: testImage2,
      );

      // Act
      await imageStorageService.cleanupImages(
        installationId: 1,
        requiredImageId: 1,
        activeImagePaths: [savedPath1],
      );

      // Assert
      final images = await imageStorageService.getImagesForRequiredType(1, 1);
      expect(images.length, 1);
      expect(images.first.path, savedPath1);
    });

    test('should get local image path', () async {
      // Arrange
      final testImage = File(path.join(testDir.path, 'test.jpg'));
      await testImage.writeAsString('test image content');
      final savedPath = await imageStorageService.saveImage(
        installationId: 1,
        requiredImageId: 1,
        sourceFile: testImage,
      );
      final imageName = path.basename(savedPath);

      // Act
      final retrievedPath = await imageStorageService.getLocalImagePath(
        installationId: 1,
        requiredImageId: 1,
        imageName: imageName,
      );

      // Assert
      expect(retrievedPath, savedPath);
    });
  });
}
