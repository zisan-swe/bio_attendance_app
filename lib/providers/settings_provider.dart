import 'package:flutter/foundation.dart';

class SettingsProvider with ChangeNotifier {
  List<Map<String, dynamic>> _settings = [];

  List<Map<String, dynamic>> get settings => _settings;

  void setSettings(List<Map<String, dynamic>> newSettings) {
    _settings = newSettings;
    notifyListeners();
  }
}
