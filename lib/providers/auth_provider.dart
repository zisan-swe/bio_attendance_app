import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AuthProvider with ChangeNotifier {
  bool _isAuthenticated = false;
  String? _token;
  Map<String, dynamic>? _userData;

  bool get isAuthenticated => _isAuthenticated;
  Map<String, dynamic>? get userData => _userData;
  String? get token => _token;

  static const String baseUrl = "https://bats.kisanbotanix.com/api/v1";

  /// Login with email/password
  Future<bool> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/login"), // replace with your real login endpoint
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "password": password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _token = data['token'];       // Save the received token
        _userData = data['user'];     // Save user info
        _isAuthenticated = true;
        notifyListeners();
        print("✅ Login successful: $_userData");
        return true;
      } else {
        print("❌ Login failed: ${response.body}");
        return false;
      }
    } catch (e) {
      print("❌ Exception during login: $e");
      return false;
    }
  }

  /// Fetch /me with the saved token
  Future<void> fetchUserProfile() async {
    if (_token == null) return;

    try {
      final response = await http.get(
        Uri.parse("$baseUrl/me"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $_token",
        },
      );

      if (response.statusCode == 200) {
        _userData = jsonDecode(response.body)['data'];
        notifyListeners();
        print("✅ User profile fetched: $_userData");
      } else {
        print("❌ Failed to fetch profile: ${response.body}");
      }
    } catch (e) {
      print("❌ Exception while fetching profile: $e");
    }
  }


  Future<bool> logoutApi() async {
    if (_token == null) return false;

    try {
      final response = await http.post(
        Uri.parse("$baseUrl/logout"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $_token",
        },
      );

      if (response.statusCode == 200) {
        print("✅ Logged out from server successfully");
        // Clear local auth data
        logout();
        return true;
      } else {
        print("❌ Failed to logout: ${response.body}");
        return false;
      }
    } catch (e) {
      print("❌ Exception during logout: $e");
      return false;
    }
  }


  void logout() {
    _isAuthenticated = false;
    _token = null;
    _userData = null;
    notifyListeners();
  }
}
