import 'package:flutter/material.dart';

class AuthProvider with ChangeNotifier {
  bool _isAuthenticated = false;

  bool get isAuthenticated => _isAuthenticated;

  // Static login (email: admin@example.com, password: 123456)
  Future<bool> login(String email, String password) async {
    if (email == 'admin@gmail.com' && password == '123456') {
      _isAuthenticated = true;
      notifyListeners();
      return true;
    } else {
      return false;
    }
  }

  void logout() {
    _isAuthenticated = false;
    notifyListeners();
  }
}
