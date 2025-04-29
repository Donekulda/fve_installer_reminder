import 'package:flutter/material.dart';
import '../data/models/user.dart';
import '../data/models/fve_installation.dart';
import '../core/services/database_service.dart';
import '../core/services/image_sync_service.dart';
import '../core/services/image_storage_service.dart';
import '../core/services/local_database_service.dart';
import '../core/services/onedrive_service.dart';
import '../core/services/service_factory.dart';
import '../core/utils/logger.dart';
import '../core/config/config.dart';

// Cloud status enum
enum CloudStatus { disconnected, connected, syncing }

/// Main application state management class that handles all global state
/// and provides methods for state manipulation and data operations.
class AppState extends ChangeNotifier {
  // Service and utility instances
  final _logger = AppLogger('AppState');
  final _serviceFactory = ServiceFactory();

  // Direct database connection for testing
  DatabaseService? _directDatabaseService;
  bool _isDirectDatabaseConnected = false;

  // State variables
  User? _currentUser;
  List<FVEInstallation> _installations = [];
  List<User> _users = [];
  bool _isLoading = false;
  final int _refreshCounter = 0;
  String _currentLanguage = 'cs';
  CloudStatus _cloudStatus = CloudStatus.disconnected;
  bool _isSyncing = false;

  // Getters for state access
  User? get currentUser => _currentUser;
  List<FVEInstallation> get installations => _installations;
  List<User> get users => _users;
  bool get isLoading => _isLoading;
  // Is the user logged in?
  bool get isLoggedIn => _currentUser != null;
  // Is this user not visitor? -> is  the user employee?
  bool get isPrivileged => _currentUser?.isPrivileged ?? false;
  // What is the user privilege level? -> 0 is visitor, 1 is builder, 2 is installer, 3 is admin
  int get currentUserPrivileges => _currentUser?.privileges ?? 0;

  // Service accessors with null safety
  DatabaseService? get databaseService {
    if (!Config.enableDatabaseService) {
      return null;
    }
    return Config.useDirectDatabaseConnection
        ? _directDatabaseService
        : _serviceFactory.databaseService;
  }

  ImageStorageService? get imageStorageService =>
      _serviceFactory.imageStorageService;
  LocalDatabaseService? get localDatabaseService =>
      _serviceFactory.localDatabaseService;
  OneDriveService? get oneDriveService => _serviceFactory.oneDriveService;
  ImageSyncService? get imageSyncService => _serviceFactory.imageSyncService;
  ServiceFactory get serviceFactory => _serviceFactory;

  // Service initialization status
  bool get isDatabaseServiceInitialized {
    if (!Config.enableDatabaseService) {
      return false;
    }
    return Config.useDirectDatabaseConnection
        ? _isDirectDatabaseConnected
        : _serviceFactory.isDatabaseServiceInitialized;
  }

  bool get isImageStorageServiceInitialized =>
      _serviceFactory.isImageStorageServiceInitialized;
  bool get isLocalDatabaseServiceInitialized =>
      _serviceFactory.isLocalDatabaseServiceInitialized;
  bool get isOneDriveServiceInitialized =>
      _serviceFactory.isOneDriveServiceInitialized;
  bool get isImageSyncServiceInitialized =>
      _serviceFactory.isImageSyncServiceInitialized;

  int get refreshCounter => _refreshCounter;
  String get currentLanguage => _currentLanguage;
  CloudStatus get cloudStatus => _cloudStatus;
  bool get isSyncing => _isSyncing;

  // Update cloud status
  void updateCloudStatus(CloudStatus status) {
    _cloudStatus = status;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  // Update sync status
  void updateSyncStatus(bool isSyncing) {
    _isSyncing = isSyncing;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  /// Initializes the database connection based on configuration
  Future<bool> initializeDatabase() async {
    try {
      _logger.debug('Initializing database connection');

      if (!Config.enableDatabaseService) {
        _logger.info('Database service is disabled in configuration');
        return false;
      }

      if (Config.useDirectDatabaseConnection) {
        _logger.debug('Initializing direct database connection');
        _directDatabaseService = DatabaseService();
        try {
          await _directDatabaseService!.connect();
          _isDirectDatabaseConnected = true;
          _logger.info('Direct database connection established');
          return true;
        } catch (e, stackTrace) {
          _logger.error(
            'Failed to establish direct database connection',
            e,
            stackTrace,
          );
          return false;
        }
      } else {
        _logger.debug('Using service factory database connection');
        if (!_serviceFactory.isDatabaseServiceInitialized) {
          _logger.error('Database service not initialized');
          return false;
        }
        return true;
      }
    } catch (e, stackTrace) {
      _logger.error('Error initializing database', e, stackTrace);
      return false;
    }
  }

  /// Cleans up database connections
  Future<void> cleanupDatabase() async {
    try {
      _logger.debug('Cleaning up database connections');

      if (Config.useDirectDatabaseConnection && _isDirectDatabaseConnected) {
        await _directDatabaseService?.disconnect();
        _directDatabaseService = null;
        _isDirectDatabaseConnected = false;
        _logger.info('Direct database connection closed');
      }
    } catch (e, stackTrace) {
      _logger.error('Error cleaning up database connections', e, stackTrace);
    }
  }

  /// Authenticates a user with the provided credentials and loads initial data
  ///
  /// [username] - The username to authenticate
  /// [password] - The password for authentication
  /// Returns true if authentication is successful, false otherwise
  Future<bool> login(String username, String password) async {
    try {
      _logger.debug('Attempting login for user: $username');
      _logger.debug('Password length: ${password.length}');
      _isLoading = true;
      // Schedule the state update for the next frame to avoid build phase errors
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });

      // Connect to the database and attempt authentication
      _logger.debug('Attempting to connect to database');
      final dbService = databaseService;
      if (dbService == null) {
        _logger.error('Database service is null');
        return false;
      }

      final user = await dbService.authenticateUser(username, password);

      if (user != null) {
        _currentUser = user;
        _logger.info('User logged in successfully: ${user.username}');
        await _loadInitialData(user);
        return true;
      }
      _logger.warning('Login failed for user: $username - Invalid credentials');
      return false;
    } catch (e, stackTrace) {
      _logger.error('Login error for user: $username', e, stackTrace);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Loads initial data after successful login
  Future<void> _loadInitialData(User user) async {
    try {
      _logger.debug('Loading initial data for user: ${user.username}');
      await loadInstallations();
      if (user.isPrivileged) {
        await loadUsers();
      }
      _logger.info(
        'Initial data loaded successfully for user: ${user.username}',
      );
    } catch (e, stackTrace) {
      _logger.error(
        'Error loading initial data for user: ${user.username}',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  /// Logs out the current user and cleans up the application state
  Future<void> logout() async {
    try {
      _logger.debug('Logging out user: ${_currentUser?.username}');
      // Schedule the state update for the next frame
      _isLoading = true;
      notifyListeners();

      // Clean up database connections
      //await cleanupDatabase();

      // Dispose services
      await _serviceFactory.dispose();

      _currentUser = null;
      _installations = [];
      _users = [];

      _logger.info('User logged out successfully');
    } catch (e, stackTrace) {
      _logger.error('Error during logout', e, stackTrace);
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Loads all FVE installations from the database
  Future<void> loadInstallations() async {
    try {
      _logger.debug('Loading installations');
      _isLoading = true;
      // Schedule the state update for the next frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });

      // Fetch installations from the database
      final dbService = databaseService;
      if (dbService == null) {
        _logger.error('Database service is null');
        throw Exception('Database service not initialized');
      }

      _installations = await dbService.getAllInstallations();
      _logger.info(
        'Successfully loaded ${_installations.length} installations',
      );

      // Schedule the final state update for the next frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _isLoading = false;
        notifyListeners();
      });
    } catch (e, stackTrace) {
      _logger.error('Error loading installations', e, stackTrace);
      // Schedule the error state update for the next frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _isLoading = false;
        notifyListeners();
      });
      rethrow;
    }
  }

  /// Loads all users from the database
  Future<void> loadUsers() async {
    try {
      _logger.debug('Loading users');
      _isLoading = true;
      // Schedule the state update for the next frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });

      // Fetch users from the database
      final dbService = databaseService;
      if (dbService == null) {
        _logger.error('Database service is null');
        throw Exception('Database service not initialized');
      }

      _users = await dbService.getAllUsers();
      _logger.info('Successfully loaded ${_users.length} users');

      // Schedule the final state update for the next frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _isLoading = false;
        notifyListeners();
      });
    } catch (e, stackTrace) {
      _logger.error('Error loading users', e, stackTrace);
      // Schedule the error state update for the next frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _isLoading = false;
        notifyListeners();
      });
      rethrow;
    }
  }

  /// Adds a new FVE installation to the database
  ///
  /// [installation] - The installation to add
  Future<void> addInstallation(FVEInstallation installation) async {
    try {
      _logger.debug('Adding new installation: ${installation.id}');
      _isLoading = true;
      // Schedule the state update for the next frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });

      // Add the installation to the database and reload the list
      final dbService = databaseService;
      if (dbService == null) {
        _logger.error('Database service is null');
        throw Exception('Database service not initialized');
      }

      await dbService.addFVEInstallation(installation);
      await loadInstallations();
      _logger.info('Successfully added installation: ${installation.id}');

      // Schedule the final state update for the next frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _isLoading = false;
        notifyListeners();
      });
    } catch (e, stackTrace) {
      _logger.error(
        'Error adding installation: ${installation.id}',
        e,
        stackTrace,
      );
      // Schedule the error state update for the next frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _isLoading = false;
        notifyListeners();
      });
      rethrow;
    }
  }

  /// Updates an existing FVE installation in the database
  ///
  /// [installation] - The installation to update
  Future<void> updateInstallation(FVEInstallation installation) async {
    try {
      _logger.debug('Updating installation: ${installation.id}');
      _isLoading = true;
      // Schedule the state update for the next frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });

      // Update the installation in the database and reload the list
      final dbService = databaseService;
      if (dbService == null) {
        _logger.error('Database service is null');
        throw Exception('Database service not initialized');
      }

      await dbService.updateFVEInstallation(installation);
      await loadInstallations();
      _logger.info('Successfully updated installation: ${installation.id}');

      // Schedule the final state update for the next frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _isLoading = false;
        notifyListeners();
      });
    } catch (e, stackTrace) {
      _logger.error(
        'Error updating installation: ${installation.id}',
        e,
        stackTrace,
      );
      // Schedule the error state update for the next frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _isLoading = false;
        notifyListeners();
      });
      rethrow;
    }
  }

  /// Adds a new user to the database
  ///
  /// [user] - The user to add
  Future<void> addUser(User user) async {
    try {
      _logger.debug('Adding new user: ${user.username}');
      _isLoading = true;
      // Schedule the state update for the next frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });

      // Add the user to the database and reload the list
      final dbService = databaseService;
      if (dbService == null) {
        _logger.error('Database service is null');
        throw Exception('Database service not initialized');
      }

      await dbService.addUser(user);
      await loadUsers();
      _logger.info('Successfully added user: ${user.username}');

      // Schedule the final state update for the next frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _isLoading = false;
        notifyListeners();
      });
    } catch (e, stackTrace) {
      _logger.error('Error adding user: ${user.username}', e, stackTrace);
      // Schedule the error state update for the next frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _isLoading = false;
        notifyListeners();
      });
      rethrow;
    }
  }

  /// Updates an existing user in the database
  ///
  /// [user] - The user to update
  Future<void> updateUser(User user) async {
    try {
      _logger.debug('Updating user: ${user.username}');
      _isLoading = true;
      // Schedule the state update for the next frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });

      // Update the user in the database and reload the list
      final dbService = databaseService;
      if (dbService == null) {
        _logger.error('Database service is null');
        throw Exception('Database service not initialized');
      }

      await dbService.updateUser(user);
      await loadUsers();
      _logger.info('Successfully updated user: ${user.username}');

      // Schedule the final state update for the next frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _isLoading = false;
        notifyListeners();
      });
    } catch (e, stackTrace) {
      _logger.error('Error updating user: ${user.username}', e, stackTrace);
      // Schedule the error state update for the next frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _isLoading = false;
        notifyListeners();
      });
      rethrow;
    }
  }

  /// Deactivates a user in the database
  ///
  /// [userId] - The ID of the user to deactivate
  Future<void> deactivateUser(int userId) async {
    try {
      _logger.debug('Deactivating user with ID: $userId');
      _isLoading = true;
      // Schedule the state update for the next frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });

      // Deactivate the user in the database and reload the list
      final dbService = databaseService;
      if (dbService == null) {
        _logger.error('Database service is null');
        throw Exception('Database service not initialized');
      }

      await dbService.deactivateUser(userId);
      await loadUsers();
      _logger.info('Successfully deactivated user with ID: $userId');

      // Schedule the final state update for the next frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _isLoading = false;
        notifyListeners();
      });
    } catch (e, stackTrace) {
      _logger.error('Error deactivating user with ID: $userId', e, stackTrace);
      // Schedule the error state update for the next frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _isLoading = false;
        notifyListeners();
      });
      rethrow;
    }
  }

  /// Activates a previously deactivated user in the database
  ///
  /// [userId] - The ID of the user to activate
  Future<void> activateUser(int userId) async {
    try {
      _logger.debug('Activating user with ID: $userId');
      _isLoading = true;
      // Schedule the state update for the next frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });

      // Activate the user in the database and reload the list
      final dbService = databaseService;
      if (dbService == null) {
        _logger.error('Database service is null');
        throw Exception('Database service not initialized');
      }

      await dbService.activateUser(userId);
      await loadUsers();
      _logger.info('Successfully activated user with ID: $userId');

      // Schedule the final state update for the next frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _isLoading = false;
        notifyListeners();
      });
    } catch (e, stackTrace) {
      _logger.error('Error activating user with ID: $userId', e, stackTrace);
      // Schedule the error state update for the next frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _isLoading = false;
        notifyListeners();
      });
      rethrow;
    }
  }

  /// Forces a complete rebuild of the entire app scaffold
  Future<void> forceRebuild() async {
    try {
      _logger.debug('Forcing complete app rebuild');
      notifyListeners();
      _logger.info('App rebuild triggered successfully');
    } catch (e, stackTrace) {
      _logger.error('Error forcing app rebuild', e, stackTrace);
      rethrow;
    }
  }

  /// Handles language change and forces a complete rebuild
  ///
  /// [languageCode] - The new language code to set
  Future<void> handleLanguageChange(String languageCode) async {
    try {
      _logger.debug('AppState - Handling language change to: $languageCode');
      // Schedule the state update for the next frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _currentLanguage = languageCode;
        notifyListeners();
        _logger.info(
          'Language changed to $languageCode and listeners notified successfully',
        );
      });
    } catch (e, stackTrace) {
      _logger.error('Error handling language change', e, stackTrace);
      rethrow;
    }
  }

  /// Checks if the current user has sufficient privileges for a required privilege level
  ///
  /// [requiredPrivilege] The name of the required privilege level ('visitor', 'builder', 'installer', 'admin')
  /// Returns true if the user has sufficient privileges - equal or higher, false otherwise
  bool hasRequiredPrivilege(String requiredPrivilege) {
    try {
      _logger.debug('Checking privileges for: $requiredPrivilege');
      final hasPrivilege = Config.hasRequiredPrivilege(
        currentUserPrivileges,
        requiredPrivilege,
      );
      _logger.info('Privilege check result: $hasPrivilege');
      return hasPrivilege;
    } catch (e, stackTrace) {
      _logger.error('Error checking privileges', e, stackTrace);
      return false;
    }
  }

  /// Gets the name of the current user's privilege level
  String get currentUserPrivilegeName {
    try {
      final privilegeName = Config.getPrivilegeName(currentUserPrivileges);
      _logger.debug('Current user privilege name: $privilegeName');
      return privilegeName;
    } catch (e, stackTrace) {
      _logger.error('Error getting privilege name', e, stackTrace);
      return 'unknown';
    }
  }

  @override
  void dispose() {
    _logger.debug('Disposing AppState');
    cleanupDatabase();
    super.dispose();
  }
}
