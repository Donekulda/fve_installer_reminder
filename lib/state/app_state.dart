import 'package:flutter/material.dart';

class AppState extends ChangeNotifier {
  // Example global state variables
  bool _isLoggedIn = false;
  String _userName = '';

  // Getter for isLoggedIn
  bool get isLoggedIn => _isLoggedIn;

  // Setter for isLoggedIn
  void setLoggedIn(bool value) {
    _isLoggedIn = value;
    notifyListeners();
  }

  // Getter for userName
  String get userName => _userName;

  // Setter for userName
  void setUserName(String value) {
    _userName = value;
    notifyListeners();
  }

  // Add other global states and methods as needed
}