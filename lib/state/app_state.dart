import 'package:flutter/material.dart';
import '../data/models/user.dart';
import '../data/models/fve_installation.dart';
import '../data/services/database_service.dart';

class AppState extends ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  User? _currentUser;
  List<FVEInstallation> _installations = [];
  List<User> _users = [];
  bool _isLoading = false;

  User? get currentUser => _currentUser;
  List<FVEInstallation> get installations => _installations;
  List<User> get users => _users;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _currentUser != null;
  bool get isPrivileged => _currentUser?.isPrivileged ?? false;

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

      _installations = await _databaseService.getFVEInstallations();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadUsers() async {
    try {
      _isLoading = true;
      notifyListeners();

      _users = await _databaseService.getUsers();
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

  Future<void> deleteUser(int userId) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _databaseService.deleteUser(userId);
      await loadUsers();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}