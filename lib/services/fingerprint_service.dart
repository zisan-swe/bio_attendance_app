import 'package:flutter/services.dart';

class FingerprintService {
  static const _channel = MethodChannel("com.legendit.zkteco");

  /// 🔹 USB ডিভাইস ডায়াগনসিস
  Future<Map<String, dynamic>> diagnoseUsb() async {
    final m = await _channel.invokeMethod<Map>('diagnoseUsb');
    if (m == null) return {};
    return Map<String, dynamic>.from(m);
  }

  /// 🔹 ফিঙ্গারপ্রিন্ট স্ক্যান → সরাসরি Base64 template string return করবে
  Future<String> scanFingerprint() async {
    try {
      final String base64Template =
          await _channel.invokeMethod<String>('scanFingerprint') ?? '';
      print("Template: $base64Template");
      return base64Template;
    } on PlatformException catch (e) {
      throw Exception("Scan failed: ${e.code} - ${e.message}");
    }
  }

  /// 🔹 LED ON
  Future<void> ledOn() async {
    await _channel.invokeMethod('ledOn');
  }

  /// 🔹 LED OFF
  Future<void> ledOff() async {
    await _channel.invokeMethod('ledOff');
  }

  /// 🔹 Debug dump
  Future<String> dumpSdk() async {
    final s = await _channel.invokeMethod<String>('dumpSdk');
    return s ?? '';
  }
}
