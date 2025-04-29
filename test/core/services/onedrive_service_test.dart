//import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:fve_installer_reminder/core/services/onedrive_service.dart';
import 'package:fve_installer_reminder/state/app_state.dart';
//import 'package:fve_installer_reminder/core/config/config_service.dart';
import 'dart:io';

// Generate mocks
@GenerateMocks([http.Client, AppState])
import 'onedrive_service_test.mocks.dart';

void main() {
  late OneDriveService oneDriveService;
  late MockClient mockHttpClient;
  late MockAppState mockAppState;

  setUp(() {
    mockHttpClient = MockClient();
    mockAppState = MockAppState();

    // Create instance of OneDriveService
    oneDriveService = OneDriveService();
    oneDriveService.setAppState(mockAppState);
  });

  tearDown(() {
    mockHttpClient.close();
  });

  group('OneDriveService File Operations Tests', () {
    test('should upload file successfully', () async {
      // Mock HTTP client to return success response
      when(
        mockHttpClient.put(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        ),
      ).thenAnswer(
        (_) async => http.Response(
          '{"id": "test_file_id", "webUrl": "https://test.com/file"}',
          201,
        ),
      );

      final testFile = File('test_file.txt');
      await testFile.writeAsString('test content');

      final result = await oneDriveService.uploadInstallationImage(
        'test_installation_id',
        testFile,
        description: 'test description',
      );

      expect(result, isNotNull);
      expect(result, 'https://test.com/file');
      verify(
        mockHttpClient.put(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        ),
      ).called(1);
    });

    test('should handle file upload errors gracefully', () async {
      // Mock HTTP client to return error response
      when(
        mockHttpClient.put(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        ),
      ).thenAnswer((_) async => http.Response('Error', 500));

      final testFile = File('test_file.txt');
      await testFile.writeAsString('test content');

      expect(
        () => oneDriveService.uploadInstallationImage(
          'test_installation_id',
          testFile,
        ),
        throwsException,
      );
    });

    test('should get installation images successfully', () async {
      // Mock HTTP client to return success response
      when(mockHttpClient.get(any, headers: anyNamed('headers'))).thenAnswer(
        (_) async => http.Response('''{
            "value": [
              {
                "id": "test_file_id",
                "name": "test_file.jpg",
                "description": "test description",
                "webUrl": "https://test.com/file",
                "@microsoft.graph.downloadUrl": "https://test.com/download",
                "createdDateTime": "2024-01-01T00:00:00Z"
              }
            ]
          }''', 200),
      );

      final result = await oneDriveService.getInstallationImages(
        'test_installation_id',
      );

      expect(result, isNotEmpty);
      expect(result.length, 1);
      expect(result[0]['id'], 'test_file_id');
      expect(result[0]['name'], 'test_file.jpg');
      expect(result[0]['description'], 'test description');
      expect(result[0]['webUrl'], 'https://test.com/file');
      expect(result[0]['downloadUrl'], 'https://test.com/download');
      expect(result[0]['createdDateTime'], '2024-01-01T00:00:00Z');

      verify(mockHttpClient.get(any, headers: anyNamed('headers'))).called(1);
    });

    test('should handle get images errors gracefully', () async {
      // Mock HTTP client to return error response
      when(
        mockHttpClient.get(any, headers: anyNamed('headers')),
      ).thenAnswer((_) async => http.Response('Error', 500));

      expect(
        () => oneDriveService.getInstallationImages('test_installation_id'),
        throwsException,
      );
    });

    test('should delete file successfully', () async {
      // Mock HTTP client to return success response
      when(
        mockHttpClient.delete(any, headers: anyNamed('headers')),
      ).thenAnswer((_) async => http.Response('', 204));

      await oneDriveService.deleteInstallationImage(
        'test_installation_id',
        'test_file_id',
      );

      verify(
        mockHttpClient.delete(any, headers: anyNamed('headers')),
      ).called(1);
    });

    test('should handle delete file errors gracefully', () async {
      // Mock HTTP client to return error response
      when(
        mockHttpClient.delete(any, headers: anyNamed('headers')),
      ).thenAnswer((_) async => http.Response('Error', 500));

      expect(
        () => oneDriveService.deleteInstallationImage(
          'test_installation_id',
          'test_file_id',
        ),
        throwsException,
      );
    });
  });
}
