import 'base_repository.dart';
import '../models/user.dart';
import '../../core/services/database_service.dart';

class UserRepository implements BaseRepository<User> {
  final DatabaseService _databaseService;

  UserRepository(this._databaseService);

  @override
  Future<User?> getById(int id) async {
    return await _databaseService.getUserById(id);
  }

  @override
  Future<List<User>> getAll() async {
    return await _databaseService.getAllUsers();
  }

  Future<User?> authenticate(String nick, String pass) async {
    return await _databaseService.authenticateUser(nick, pass);
  }

  Future<void> deactivateUser(int userId) async {
    await _databaseService.deactivateUser(userId);
  }

  Future<void> activateUser(int userId) async {
    await _databaseService.activateUser(userId);
  }

  @override
  Future<void> create(User entity) async {
    await _databaseService.addUser(entity);
  }

  @override
  Future<void> update(User entity) async {
    await _databaseService.updateUser(entity);
  }

  @override
  Future<void> delete(int id) async {
    // Delete operation not allowed for security reasons
    throw UnimplementedError(
      'Delete operation is not allowed for security reasons',
    );
  }
}
