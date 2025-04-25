import 'package:flutter/material.dart';
import '../data/models/user.dart';
import '../data/models/fve_installation.dart';
import '../core/services/database_service.dart';
import '../core/utils/logger.dart';
import '../localization/app_localizations.dart';

class AppState extends ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  User? _currentUser;
  List<FVEInstallation> _installations = [];
  List<User> _users = [];
  bool _isLoading = false;
  int _refreshCounter = 0;
  String _currentLanguage = 'cs';

  User? get currentUser => _currentUser;
  List<FVEInstallation> get installations => _installations;
  List<User> get users => _users;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _currentUser != null;
  bool get isPrivileged => _currentUser?.isPrivileged ?? false;
  DatabaseService get databaseService => _databaseService;
  int get refreshCounter => _refreshCounter;
  String get currentLanguage => _currentLanguage;

  Future<bool> login(String username, String password) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _databaseService.connect();

      final user = await _databaseService.authenticateUser(username, password);
      if (user != null) {
        _currentUser = user;
        await loadInstallations();
        if (user.isPrivileged) {
          await loadUsers();
        }
        return true;
      }
      return false;
    } catch (e) {
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _currentUser = null;
    _installations = [];
    _users = [];
    await _databaseService.disconnect();
    notifyListeners();
  }

  Future<void> loadInstallations() async {
    try {
      _isLoading = true;
      notifyListeners();

      _installations = await _databaseService.getAllInstallations();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadUsers() async {
    try {
      _isLoading = true;
      notifyListeners();

      _users = await _databaseService.getAllUsers();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addInstallation(FVEInstallation installation) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _databaseService.addFVEInstallation(installation);
      await loadInstallations();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addUser(User user) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _databaseService.addUser(user);
      await loadUsers();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateUser(User user) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _databaseService.updateUser(user);
      await loadUsers();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deactivateUser(int userId) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _databaseService.deactivateUser(userId);
      await loadUsers();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> activateUser(int userId) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _databaseService.activateUser(userId);
      await loadUsers();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Forces a complete rebuild of the entire app scaffold
  Future<void> forceRebuild() async {
    try {
      AppLogger.debug('Forcing complete app rebuild');
      _refreshCounter++;
      notifyListeners();
      AppLogger.info('App rebuild triggered');
    } catch (e) {
      AppLogger.error('Error forcing app rebuild', e);
      rethrow;
    }
  }

  /// Handles language change and forces a complete rebuild
  Future<void> handleLanguageChange(String languageCode) async {
    try {
      AppLogger.debug('AppState - Handling language change to: $languageCode');
      _currentLanguage = languageCode;
      _refreshCounter++;
      notifyListeners();
      AppLogger.info(
        'AppState - Language change handled and rebuild triggered',
      );
    } catch (e) {
      AppLogger.error('Error handling language change', e);
      rethrow;
    }
  }
}
