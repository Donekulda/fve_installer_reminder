import 'package:mysql1/mysql1.dart';
import '../models/user.dart';
import '../models/fve_installation.dart';
import 'config_service.dart';

class DatabaseService {
  late MySqlConnection _connection;
  bool _isConnected = false;

  Future<void> connect() async {
    try {
      final credentials = await ConfigService.getDatabaseCredentials();
      final settings = ConnectionSettings(
        host: credentials.host,
        port: credentials.port,
        user: credentials.user,
        password: credentials.password,
        db: credentials.database,
      );
      _connection = await MySqlConnection.connect(settings);
      _isConnected = true;
    } catch (e) {
      _isConnected = false;
      rethrow;
    }
  }

  Future<User?> authenticateUser(String username, String password) async {
    if (!_isConnected) throw Exception('Database not connected');

    final results = await _connection.query(
      'SELECT * FROM users WHERE username = ? AND password = ?',
      [username, password],
    );

    if (results.isEmpty) return null;
    final row = results.first;
    return User.fromMap({
      'id': row['id'],
      'username': row['username'],
      'password': row['password'],
      'is_privileged': row['is_privileged'] == 1,
    });
  }

  Future<List<FVEInstallation>> getFVEInstallations() async {
    if (!_isConnected) throw Exception('Database not connected');

    final results = await _connection.query('SELECT * FROM fve_installations');
    return results.map((row) => FVEInstallation.fromMap({
      'id': row['id'],
      'name': row['name'],
      'address': row['address'],
      'installation_date': row['installation_date'].toString(),
      'required_photos': row['required_photos'],
    })).toList();
  }

  Future<void> addFVEInstallation(FVEInstallation installation) async {
    if (!_isConnected) throw Exception('Database not connected');

    await _connection.query(
      'INSERT INTO fve_installations (name, address, installation_date, required_photos) VALUES (?, ?, ?, ?)',
      [
        installation.name,
        installation.address,
        installation.installationDate.toIso8601String(),
        installation.requiredPhotos.join(','),
      ],
    );
  }

  Future<List<User>> getUsers() async {
    if (!_isConnected) throw Exception('Database not connected');

    final results = await _connection.query('SELECT * FROM users');
    return results.map((row) => User.fromMap({
      'id': row['id'],
      'username': row['username'],
      'password': row['password'],
      'is_privileged': row['is_privileged'] == 1,
    })).toList();
  }

  Future<void> updateUser(User user) async {
    if (!_isConnected) throw Exception('Database not connected');

    await _connection.query(
      'UPDATE users SET username = ?, password = ?, is_privileged = ? WHERE id = ?',
      [
        user.username,
        user.password,
        user.isPrivileged ? 1 : 0,
        user.id,
      ],
    );
  }

  Future<void> addUser(User user) async {
    if (!_isConnected) throw Exception('Database not connected');

    await _connection.query(
      'INSERT INTO users (username, password, is_privileged) VALUES (?, ?, ?)',
      [
        user.username,
        user.password,
        user.isPrivileged ? 1 : 0,
      ],
    );
  }

  Future<void> deleteUser(int userId) async {
    if (!_isConnected) throw Exception('Database not connected');

    await _connection.query(
      'DELETE FROM users WHERE id = ?',
      [userId],
    );
  }

  Future<void> disconnect() async {
    if (_isConnected) {
      await _connection.close();
      _isConnected = false;
    }
  }
} 