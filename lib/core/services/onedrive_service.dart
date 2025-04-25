import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:aad_oauth/aad_oauth.dart';
import 'package:aad_oauth/model/config.dart';
import 'package:path/path.dart' as path;
import 'package:flutter/services.dart' show rootBundle;
import '../utils/logger.dart';

class OneDriveService {
  static final OneDriveService _instance = OneDriveService._internal();
  factory OneDriveService() => _instance;
  OneDriveService._internal();

  final _storage = const FlutterSecureStorage();
  late final AadOAuth _oauth;
  final _navigatorKey = GlobalKey<NavigatorState>();

  late final String _clientId;
  late final String _tenantId;
  late final String _redirectUri;
  late final String _scope;
  late final String _baseFolderPath;

  String? _accessToken;

  final _logger = AppLogger('OneDriveService');

  Future<void> initialize() async {
    try {
      _logger.info('Initializing OneDrive service');

      // Load configuration from JSON file
      final configJson = await rootBundle.loadString(
        'lib/data/config/onedrive_config.json',
      );
      final config = json.decode(configJson) as Map<String, dynamic>;

      _clientId = config['clientId'] as String;
      _tenantId = config['tenantId'] as String;
      _redirectUri = config['redirectUri'] as String;
      _scope = config['scope'] as String;
      _baseFolderPath = config['baseFolderPath'] as String;

      _logger.debug(
        'Loaded configuration: clientId=${_clientId.substring(0, 4)}..., tenantId=${_tenantId.substring(0, 4)}...',
      );

      final oauthConfig = Config(
        tenant: _tenantId,
        clientId: _clientId,
        scope: 'offline_access $_scope',
        redirectUri: _redirectUri,
        navigatorKey: _navigatorKey,
      );

      _oauth = AadOAuth(oauthConfig);

      // Try to get stored token
      _accessToken = await _storage.read(key: 'onedrive_access_token');

      if (_accessToken == null) {
        _logger.info('No stored token found, initiating authentication');
        await _authenticate();
      } else {
        _logger.info('Using stored access token');
      }

      _logger.debug(
        'OneDriveService - Initialized with token: ${_accessToken != null}',
      );
    } catch (e) {
      _logger.error('Failed to initialize OneDrive service', e);
      rethrow;
    }
  }

  Future<void> _authenticate() async {
    try {
      _logger.info('Starting authentication process');
      await _oauth.login();
      _accessToken = await _oauth.getAccessToken();

      if (_accessToken != null) {
        _logger.info('Authentication successful, storing token');
        await _storage.write(key: 'onedrive_access_token', value: _accessToken);
      } else {
        _logger.error('Authentication failed: No access token received');
        throw Exception('Failed to get access token');
      }
    } catch (e) {
      _logger.error('Authentication failed', e);
      rethrow;
    }
  }

  Future<void> _ensureAuthenticated() async {
    if (_accessToken == null) {
      _logger.info('No access token, initiating authentication');
      await _authenticate();
    } else {
      // Check if token needs refresh
      try {
        final accessToken = await _oauth.getAccessToken();
        if (accessToken == null || accessToken != _accessToken) {
          _logger.info('Token needs refresh, re-authenticating');
          await _authenticate();
        }
      } catch (e) {
        _logger.warning('Token validation failed, re-authenticating', e);
        await _authenticate();
      }
    }
  }

  Future<String> _ensureInstallationFolder(String installationId) async {
    final folderPath = '$_baseFolderPath/$installationId';

    try {
      _logger.debug('Ensuring installation folder exists: $folderPath');
      await _ensureAuthenticated();

      // Check if folder exists
      final response = await http.get(
        Uri.parse('https://graph.microsoft.com/v1.0/me/drive/root:$folderPath'),
        headers: {'Authorization': 'Bearer $_accessToken'},
      );

      if (response.statusCode == 404) {
        _logger.info('Creating installation folder: $folderPath');
        // Create folder if it doesn't exist
        await http.post(
          Uri.parse('https://graph.microsoft.com/v1.0/me/drive/root/children'),
          headers: {
            'Authorization': 'Bearer $_accessToken',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'name': installationId,
            'folder': {},
            '@microsoft.graph.conflictBehavior': 'fail',
          }),
        );
      } else if (response.statusCode != 200) {
        _logger.error(
          'Failed to check installation folder: ${response.statusCode}',
        );
        throw Exception(
          'Failed to check installation folder: ${response.statusCode}',
        );
      }

      return folderPath;
    } catch (e) {
      _logger.error('Failed to ensure installation folder exists', e);
      rethrow;
    }
  }

  Future<String> uploadInstallationImage(
    String installationId,
    File imageFile, {
    String? description,
  }) async {
    try {
      _logger.info('Uploading image for installation: $installationId');
      final folderPath = await _ensureInstallationFolder(installationId);
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${path.basename(imageFile.path)}';
      final endpoint =
          'https://graph.microsoft.com/v1.0/me/drive/root:$folderPath/$fileName:/content';

      _logger.debug('Uploading file: $fileName to $folderPath');

      final response = await http.put(
        Uri.parse(endpoint),
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Content-Type': 'image/jpeg',
        },
        body: await imageFile.readAsBytes(),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final responseData = json.decode(response.body);

        // If description is provided, update file metadata
        if (description != null) {
          _logger.debug('Updating file description');
          await _updateFileDescription(responseData['id'], description);
        }

        _logger.info('Image upload successful');
        return responseData['webUrl'];
      } else {
        _logger.error('Failed to upload image: ${response.statusCode}');
        throw Exception('Failed to upload image: ${response.statusCode}');
      }
    } catch (e) {
      _logger.error('Failed to upload installation image', e);
      rethrow;
    }
  }

  Future<void> _updateFileDescription(String fileId, String description) async {
    try {
      final endpoint =
          'https://graph.microsoft.com/v1.0/me/drive/items/$fileId';

      await http.patch(
        Uri.parse(endpoint),
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'description': description}),
      );
    } catch (e) {
      _logger.warning('Failed to update file description', e);
      // Don't rethrow as this is not critical
    }
  }

  Future<List<Map<String, dynamic>>> getInstallationImages(
    String installationId,
  ) async {
    try {
      _logger.info('Getting images for installation: $installationId');
      final folderPath = await _ensureInstallationFolder(installationId);

      final response = await http.get(
        Uri.parse(
          'https://graph.microsoft.com/v1.0/me/drive/root:$folderPath:/children',
        ),
        headers: {'Authorization': 'Bearer $_accessToken'},
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final List<Map<String, dynamic>> images = [];

        for (var item in responseData['value']) {
          if (item['file'] != null) {
            images.add({
              'id': item['id'],
              'name': item['name'],
              'description': item['description'] ?? '',
              'webUrl': item['webUrl'],
              'downloadUrl': item['@microsoft.graph.downloadUrl'],
              'thumbnailUrl': await _getThumbnailUrl(item['id']),
              'createdDateTime': item['createdDateTime'],
            });
          }
        }

        // Sort by creation date, newest first
        images.sort(
          (a, b) => DateTime.parse(
            b['createdDateTime'],
          ).compareTo(DateTime.parse(a['createdDateTime'])),
        );

        _logger.info('Found ${images.length} images');
        return images;
      } else {
        _logger.error(
          'Failed to list installation images: ${response.statusCode}',
        );
        throw Exception(
          'Failed to list installation images: ${response.statusCode}',
        );
      }
    } catch (e) {
      _logger.error('Failed to get installation images', e);
      rethrow;
    }
  }

  Future<String?> _getThumbnailUrl(String fileId) async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://graph.microsoft.com/v1.0/me/drive/items/$fileId/thumbnails/0/medium',
        ),
        headers: {'Authorization': 'Bearer $_accessToken'},
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return responseData['url'];
      }
    } catch (e) {
      _logger.warning('Failed to get thumbnail URL', e);
    }
    return null;
  }

  Future<void> deleteInstallationImage(
    String installationId,
    String fileId,
  ) async {
    try {
      _logger.info(
        'Deleting image: $fileId from installation: $installationId',
      );
      await _ensureAuthenticated();

      final response = await http.delete(
        Uri.parse('https://graph.microsoft.com/v1.0/me/drive/items/$fileId'),
        headers: {'Authorization': 'Bearer $_accessToken'},
      );

      if (response.statusCode != 204) {
        _logger.error('Failed to delete image: ${response.statusCode}');
        throw Exception('Failed to delete image: ${response.statusCode}');
      }

      _logger.info('Image deleted successfully');
    } catch (e) {
      _logger.error('Failed to delete installation image', e);
      rethrow;
    }
  }
}
