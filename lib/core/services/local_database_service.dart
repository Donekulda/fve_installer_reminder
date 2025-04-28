import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/utils/logger.dart';

/// Service class for handling local SQLite database operations.
/// Manages local storage of images and related data for offline use.
class LocalDatabaseService {
  static const String _databaseName = 'fve_installer_local.db';
  static const int _databaseVersion = 1;

  /// Database instance
  Database? _database;

  /// Logger instance
  final _logger = AppLogger('LocalDatabaseService');

  /// Gets the database instance, creating it if it doesn't exist
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Initializes the database and creates necessary tables
  Future<Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Creates the database tables
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE local_images (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        cloud_id INTEGER,  -- ID in the cloud database
        fve_installation_id INTEGER,  -- ID of the FVE installation
        required_image_id INTEGER,  -- ID of the required image type
        local_path TEXT NOT NULL,  -- Local file path
        name TEXT,  -- Display name
        time_added TEXT,  -- ISO 8601 timestamp
        user_id INTEGER,  -- ID of the user who added the image
        hash INTEGER,  -- SHA-256 hash of the image
        is_uploaded INTEGER DEFAULT 0,  -- Whether the image has been uploaded to cloud
        is_active INTEGER DEFAULT 1  -- Whether the image is active
      )
    ''');

    await db.execute('''
      CREATE TABLE image_metadata (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        image_id INTEGER,  -- Reference to local_images.id
        key TEXT NOT NULL,  -- Metadata key
        value TEXT,  -- Metadata value
        FOREIGN KEY (image_id) REFERENCES local_images (id) ON DELETE CASCADE
      )
    ''');
  }

  /// Handles database upgrades
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle future database upgrades here
  }

  /// Saves a new image to the local database
  Future<int> saveImage({
    required int fveInstallationId,
    required int requiredImageId,
    required String localPath,
    String? name,
    DateTime? timeAdded,
    required int userId,
    required int hash,
    int? cloudId,
    bool isUploaded = false,
    bool isActive = true,
  }) async {
    try {
      final db = await database;
      return await db.insert('local_images', {
        'cloud_id': cloudId,
        'fve_installation_id': fveInstallationId,
        'required_image_id': requiredImageId,
        'local_path': localPath,
        'name': name,
        'time_added': timeAdded?.toIso8601String(),
        'user_id': userId,
        'hash': hash,
        'is_uploaded': isUploaded ? 1 : 0,
        'is_active': isActive ? 1 : 0,
      });
    } catch (e, stackTrace) {
      _logger.error('Error saving image to local database', e, stackTrace);
      rethrow;
    }
  }

  /// Gets all images for a specific FVE installation
  Future<List<Map<String, dynamic>>> getImagesByInstallationId(
    int installationId,
  ) async {
    try {
      final db = await database;
      return await db.query(
        'local_images',
        where: 'fve_installation_id = ?',
        whereArgs: [installationId],
      );
    } catch (e, stackTrace) {
      _logger.error('Error getting images by installation ID', e, stackTrace);
      rethrow;
    }
  }

  /// Gets all images of a specific required image type
  Future<List<Map<String, dynamic>>> getImagesByRequiredImageId(
    int requiredImageId,
  ) async {
    try {
      final db = await database;
      return await db.query(
        'local_images',
        where: 'required_image_id = ?',
        whereArgs: [requiredImageId],
      );
    } catch (e, stackTrace) {
      _logger.error('Error getting images by required image ID', e, stackTrace);
      rethrow;
    }
  }

  /// Gets all images that haven't been uploaded to the cloud
  Future<List<Map<String, dynamic>>> getUnuploadedImages() async {
    try {
      final db = await database;
      return await db.query(
        'local_images',
        where: 'is_uploaded = ?',
        whereArgs: [0],
      );
    } catch (e, stackTrace) {
      _logger.error('Error getting unuploaded images', e, stackTrace);
      rethrow;
    }
  }

  /// Updates an image's upload status
  Future<void> markImageAsUploaded(int imageId, int cloudId) async {
    try {
      final db = await database;
      await db.update(
        'local_images',
        {'is_uploaded': 1, 'cloud_id': cloudId},
        where: 'id = ?',
        whereArgs: [imageId],
      );
    } catch (e, stackTrace) {
      _logger.error('Error marking image as uploaded', e, stackTrace);
      rethrow;
    }
  }

  /// Deactivates an image
  Future<void> deactivateImage(int imageId) async {
    try {
      final db = await database;
      await db.update(
        'local_images',
        {'is_active': 0},
        where: 'id = ?',
        whereArgs: [imageId],
      );
    } catch (e, stackTrace) {
      _logger.error('Error deactivating image', e, stackTrace);
      rethrow;
    }
  }

  /// Adds metadata to an image
  Future<void> addImageMetadata(int imageId, String key, String value) async {
    try {
      final db = await database;
      await db.insert('image_metadata', {
        'image_id': imageId,
        'key': key,
        'value': value,
      });
    } catch (e, stackTrace) {
      _logger.error('Error adding image metadata', e, stackTrace);
      rethrow;
    }
  }

  /// Gets metadata for an image
  Future<List<Map<String, dynamic>>> getImageMetadata(int imageId) async {
    try {
      final db = await database;
      return await db.query(
        'image_metadata',
        where: 'image_id = ?',
        whereArgs: [imageId],
      );
    } catch (e, stackTrace) {
      _logger.error('Error getting image metadata', e, stackTrace);
      rethrow;
    }
  }

  /// Closes the database connection
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
