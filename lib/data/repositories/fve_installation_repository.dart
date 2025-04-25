import 'base_repository.dart';
import '../models/fve_installation.dart';
import '../../core/services/database_service.dart';

class FVEInstallationRepository implements BaseRepository<FVEInstallation> {
  final DatabaseService _databaseService;

  FVEInstallationRepository(this._databaseService);

  @override
  Future<FVEInstallation?> getById(int id) async {
    return await _databaseService.getFVEInstallationById(id);
  }

  @override
  Future<List<FVEInstallation>> getAll() async {
    return await _databaseService.getAllInstallations();
  }

  Future<List<FVEInstallation>> getByUserId(int userId) async {
    return await _databaseService.getInstallationsByUserId(userId);
  }

  @override
  Future<void> create(FVEInstallation entity) async {
    await _databaseService.addFVEInstallation(entity);
  }

  @override
  Future<void> update(FVEInstallation entity) async {
    await _databaseService.updateFVEInstallation(entity);
  }

  @override
  Future<void> delete(int id) async {
    // Delete operation not allowed for security reasons
    throw UnimplementedError(
      'Delete operation is not allowed for security reasons',
    );
  }
}
