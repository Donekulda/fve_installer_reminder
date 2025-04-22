import 'base_repository.dart';
import '../models/saved_image.dart';
import '../services/database_service.dart';

class SavedImageRepository implements BaseRepository<SavedImage> {
  final DatabaseService _databaseService;

  SavedImageRepository(this._databaseService);

  @override
  Future<SavedImage?> getById(int id) async {
    return await _databaseService.getSavedImageById(id);
  }

  @override
  Future<List<SavedImage>> getAll() async {
    // Implementation will be added when needed
    return [];
  }

  Future<List<SavedImage>> getByInstallationId(int installationId) async {
    return await _databaseService.getSavedImagesByInstallationId(
      installationId,
    );
  }

  Future<List<SavedImage>> getByRequiredImageId(int requiredImageId) async {
    return await _databaseService.getSavedImagesByRequiredImageId(
      requiredImageId,
    );
  }

  Future<void> saveImage(SavedImage image) async {
    await _databaseService.saveImage(image);
  }

  @override
  Future<void> create(SavedImage entity) async {
    await saveImage(entity);
  }

  @override
  Future<void> update(SavedImage entity) async {
    await _databaseService.updateSavedImage(entity);
  }

  @override
  Future<void> delete(int id) async {
    // Delete operation not allowed for security reasons
    throw UnimplementedError(
      'Delete operation is not allowed for security reasons',
    );
  }
}
