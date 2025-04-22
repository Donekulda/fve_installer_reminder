import 'base_repository.dart';
import '../models/required_image.dart';
import '../services/database_service.dart';

class RequiredImageRepository implements BaseRepository<RequiredImage> {
  final DatabaseService _databaseService;

  RequiredImageRepository(this._databaseService);

  @override
  Future<RequiredImage?> getById(int id) async {
    return await _databaseService.getRequiredImageById(id);
  }

  @override
  Future<List<RequiredImage>> getAll() async {
    return await _databaseService.getAllRequiredImages();
  }

  @override
  Future<void> create(RequiredImage entity) async {
    await _databaseService.addRequiredImage(entity);
  }

  @override
  Future<void> update(RequiredImage entity) async {
    await _databaseService.updateRequiredImage(entity);
  }

  @override
  Future<void> delete(int id) async {
    // Delete operation not allowed for security reasons
    throw UnimplementedError(
      'Delete operation is not allowed for security reasons',
    );
  }
}
