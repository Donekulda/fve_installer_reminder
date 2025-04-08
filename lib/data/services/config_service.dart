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

class ConfigService {
  static DatabaseCredentials? _databaseCredentials;

  static Future<DatabaseCredentials> getDatabaseCredentials() async {
    if (_databaseCredentials != null) {
      return _databaseCredentials!;
    }

    try {
      final String jsonString = await rootBundle.loadString('lib/data/config/credentials.json');
      final Map<String, dynamic> json = jsonDecode(jsonString);
      _databaseCredentials = DatabaseCredentials.fromJson(json['database']);
      return _databaseCredentials!;
    } catch (e) {
      throw Exception('Failed to load database credentials: $e');
    }
  }
} 