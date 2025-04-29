import '../../core/utils/logger.dart';
import '../../state/app_state.dart';
import '../../data/models/required_image.dart';
import '../../data/repositories/required_image_repository.dart';

/// Controller for managing required image models in the application.
/// This controller handles the business logic for defining what types of images
/// are required for FVE installations, with database integration.
class RequiredImageModelController {
  final AppState _appState;
  final _logger = AppLogger('RequiredImageModelController');
  late final RequiredImageRepository _repository;

  RequiredImageModelController(this._appState) {
    final dbService = _appState.databaseService;
    if (dbService == null) {
      _logger.error('Database service is null');
      throw Exception('Database service not initialized');
    }
    _repository = RequiredImageRepository(dbService);
  }

  /// Checks if the current user has admin privileges
  bool get isAdmin => _appState.hasRequiredPrivilege('admin');

  /// Loads all required image models from the database
  Future<List<RequiredImage>> loadRequiredImageModels() async {
    try {
      _logger.debug('Loading required image models');
      return await _repository.getAll();
    } catch (e, stackTrace) {
      _logger.error('Error loading required image models', e, stackTrace);
      rethrow;
    }
  }

  /// Adds a new required image model to the database
  Future<void> addRequiredImageModel(
    String name,
    int minImages,
    String description,
  ) async {
    try {
      _logger.debug('Adding new required image model: $name');
      final model = RequiredImage(
        id: 0, // ID will be assigned by the database
        name: name,
        minImages: minImages,
        description: description,
      );
      await _repository.create(model);
    } catch (e, stackTrace) {
      _logger.error('Error adding required image model: $name', e, stackTrace);
      rethrow;
    }
  }

  /// Updates an existing required image model in the database
  Future<void> updateRequiredImageModel(
    int id,
    String name,
    int minImages,
    String description,
  ) async {
    try {
      _logger.debug('Updating required image model: $id');
      final model = RequiredImage(
        id: id,
        name: name,
        minImages: minImages,
        description: description,
      );
      await _repository.update(model);
    } catch (e, stackTrace) {
      _logger.error('Error updating required image model: $id', e, stackTrace);
      rethrow;
    }
  }

  /// Deletes a required image model from the database
  Future<void> deleteRequiredImageModel(int id) async {
    try {
      _logger.debug('Deleting required image model: $id');
      await _repository.delete(id);
    } catch (e, stackTrace) {
      _logger.error('Error deleting required image model: $id', e, stackTrace);
      rethrow;
    }
  }

  /// Gets a required image model by its ID
  Future<RequiredImage?> getRequiredImageModelById(int id) async {
    try {
      _logger.debug('Getting required image model by ID: $id');
      return await _repository.getById(id);
    } catch (e, stackTrace) {
      _logger.error(
        'Error getting required image model by ID: $id',
        e,
        stackTrace,
      );
      rethrow;
    }
  }
}
