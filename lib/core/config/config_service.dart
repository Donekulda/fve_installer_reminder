import 'dart:convert';
//import 'dart:io';
import 'package:flutter/services.dart';

class DatabaseCredentials {
  final String host;
  final int port;
  final String user;
  final String password;
  final String database;

  DatabaseCredentials({
    required this.host,
    required this.port,
    required this.user,
    required this.password,
    required this.database,
  });

  factory DatabaseCredentials.fromJson(Map<String, dynamic> json) {
    return DatabaseCredentials(
      host: json['host'],
      port: json['port'],
      user: json['user'],
      password: json['password'],
      database: json['database'],
    );
  }
}

class OneDriveCredentials {
  final String clientId;
  final String tenantId;
  final String redirectUri;
  final String scope;
  final String baseFolderPath;

  OneDriveCredentials({
    required this.clientId,
    required this.tenantId,
    required this.redirectUri,
    required this.scope,
    required this.baseFolderPath,
  });

  factory OneDriveCredentials.fromJson(Map<String, dynamic> json) {
    return OneDriveCredentials(
      clientId: json['clientId'],
      tenantId: json['tenantId'],
      redirectUri: json['redirectUri'],
      scope: json['scope'],
      baseFolderPath: json['baseFolderPath'],
    );
  }
}

class ConfigService {
  static DatabaseCredentials? _databaseCredentials;
  static OneDriveCredentials? _oneDriveCredentials;

  static Future<DatabaseCredentials> getDatabaseCredentials() async {
    if (_databaseCredentials != null) {
      return _databaseCredentials!;
    }

    try {
      final String jsonString = await rootBundle.loadString(
        'lib/data/config/credentials.json',
      );
      final Map<String, dynamic> json = jsonDecode(jsonString);
      _databaseCredentials = DatabaseCredentials.fromJson(json['database']);
      return _databaseCredentials!;
    } catch (e) {
      throw Exception('Failed to load database credentials: $e');
    }
  }

  static Future<OneDriveCredentials> getOneDriveCredentials() async {
    if (_oneDriveCredentials != null) {
      return _oneDriveCredentials!;
    }

    try {
      final String jsonString = await rootBundle.loadString(
        'lib/data/config/credentials.json',
      );
      final Map<String, dynamic> json = jsonDecode(jsonString);
      _oneDriveCredentials = OneDriveCredentials.fromJson(json['onedrive']);
      return _oneDriveCredentials!;
    } catch (e) {
      throw Exception('Failed to load OneDrive credentials: $e');
    }
  }
}
