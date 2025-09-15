import 'package:flutter/services.dart';

class FingerprintService {
  static const _channel = MethodChannel("com.legendit.zkteco");

  /// 🔹 USB ডিভাইস ডায়াগনসিস
  Future<Map<String, dynamic>> diagnoseUsb() async {
    try {
      final Map<dynamic, dynamic>? result =
      await _channel.invokeMethod('diagnoseUsb');
      if (result == null) return {};
      return Map<String, dynamic>.from(result);
    } on PlatformException catch (e) {
      throw Exception("USB Diagnose failed: ${e.code} - ${e.message}");
    }
  }

  /// 🔹 ফিঙ্গারপ্রিন্ট স্ক্যান → সরাসরি Base64 template string return করবে
  Future<String> scanFingerprint() async {
    try {
      final String? base64Template =
      await _channel.invokeMethod<String>('scanFingerprint');
      if (base64Template == null || base64Template.isEmpty) {
        throw Exception("No fingerprint template received");
      }
      print("✅ Fingerprint Template Captured: $base64Template");
      return base64Template;
    } on PlatformException catch (e) {
      throw Exception("Scan failed: ${e.code} - ${e.message}");
    }
  }

  /// 🔹 LED ON
  Future<void> ledOn() async {
    try {
      await _channel.invokeMethod('ledOn');
      print("✅ LED turned ON");
    } on PlatformException catch (e) {
      throw Exception("LED ON failed: ${e.code} - ${e.message}");
    }
  }

  /// 🔹 LED OFF
  Future<void> ledOff() async {
    try {
      await _channel.invokeMethod('ledOff');
      print("✅ LED turned OFF");
    } on PlatformException catch (e) {
      throw Exception("LED OFF failed: ${e.code} - ${e.message}");
    }
  }

  /// 🔹 Debug dump (SDK Info)
  Future<String> dumpSdk() async {
    try {
      final String? info = await _channel.invokeMethod<String>('dumpSdk');
      return info ?? "No SDK info available";
    } on PlatformException catch (e) {
      throw Exception("Dump SDK failed: ${e.code} - ${e.message}");
    }
  }
}
