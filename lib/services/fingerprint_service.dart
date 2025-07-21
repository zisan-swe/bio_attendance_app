import 'package:flutter/services.dart';

class FingerprintService {
  static const platform = MethodChannel('com.yourcompany.fingerprint');

  Future<String?> scanFingerprint() async {
    try {
      final result = await platform.invokeMethod<String>('scanFingerprint');
      return result;
    } catch (e) {
      print('Error scanning fingerprint: $e');
      return null;
    }
  }
}
