import 'package:flutter/material.dart';

class AttendanceProvider with ChangeNotifier {
  bool isScanning = false;
  String scanResult = '';

  void startScan() {
    isScanning = true;
    notifyListeners();
  }

  void setScanResult(String result) {
    isScanning = false;
    scanResult = result;
    notifyListeners();
  }

  void reset() {
    isScanning = false;
    scanResult = '';
    notifyListeners();
  }
}
