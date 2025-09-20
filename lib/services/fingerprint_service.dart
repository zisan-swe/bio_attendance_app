import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:developer' as dev; // For dev.log

class FingerprintException implements Exception {
  final String code;
  final String message;
  FingerprintException(this.code, this.message);

  @override
  String toString() => 'FingerprintException: $code - $message';
}

class FingerprintService {
  static const MethodChannel _methodChannel = MethodChannel('com.legendit.zkteco');

  /// 🔹 USB ডিভাইস ডায়াগনসিস
  Future<Map<String, dynamic>> diagnoseUsb() async {
    try {
      final Map<dynamic, dynamic>? result = await _methodChannel.invokeMethod('diagnoseUsb');
      if (result == null) {
        dev.log('Warning: diagnoseUsb returned null', name: 'FingerprintService');
        throw FingerprintException('DIAGNOSE_NULL', 'USB diagnosis returned no data');
      }
      return result.cast<String, dynamic>(); // Safely cast to Map<String, dynamic>
    } on PlatformException catch (e) {
      dev.log('USB Diagnose Error: ${e.code} - ${e.message}', name: 'FingerprintService');
      throw FingerprintException(e.code, 'USB Diagnose failed: ${e.message}');
    }
  }

  /// 🔹 ফিঙ্গারপ্রিন্ট স্ক্যান → সরাসরি Base64 template string return করবে
  Future<String> scanFingerprint() async {
    try {
      final String? base64Template = await _methodChannel.invokeMethod<String>('scanFingerprint');
      if (base64Template == null || base64Template.isEmpty) {
        dev.log('Error: No fingerprint template received', name: 'FingerprintService');
        throw FingerprintException('CAPTURE_EMPTY', 'No fingerprint template received');
      }
      dev.log('✅ Fingerprint Template Captured: $base64Template (length: ${base64Template.length})', name: 'FingerprintService');
      return base64Template;
    } on PlatformException catch (e) {
      dev.log('Scan Error: ${e.code} - ${e.message}', name: 'FingerprintService');
      throw FingerprintException(e.code, 'Scan failed: ${e.message}');
    }
  }

  /// 🔹 LED ON
  Future<void> ledOn() async {
    try {
      await _methodChannel.invokeMethod('ledOn');
      dev.log('✅ LED turned ON', name: 'FingerprintService');
    } on PlatformException catch (e) {
      dev.log('LED ON Error: ${e.code} - ${e.message}', name: 'FingerprintService');
      throw FingerprintException(e.code, 'LED ON failed: ${e.message}');
    }
  }

  /// 🔹 LED OFF
  Future<void> ledOff() async {
    try {
      await _methodChannel.invokeMethod('ledOff');
      dev.log('✅ LED turned OFF', name: 'FingerprintService');
    } on PlatformException catch (e) {
      dev.log('LED OFF Error: ${e.code} - ${e.message}', name: 'FingerprintService');
      throw FingerprintException(e.code, 'LED OFF failed: ${e.message}');
    }
  }

  /// 🔹 Debug dump (SDK Info)
  Future<String> dumpSdk() async {
    try {
      final String? info = await _methodChannel.invokeMethod<String>('dumpSdk');
      if (info == null) {
        dev.log('Warning: dumpSdk returned null', name: 'FingerprintService');
        throw FingerprintException('DUMP_NULL', 'No SDK info available');
      }
      return info;
    } on PlatformException catch (e) {
      dev.log('Dump SDK Error: ${e.code} - ${e.message}', name: 'FingerprintService');
      throw FingerprintException(e.code, 'Dump SDK failed: ${e.message}');
    }
  }

  /// 🔹 ফিঙ্গারপ্রিন্ট ভেরিফিকেশন
  static Future<Map<String, dynamic>> verifyFingerprint({
    required String scannedTemplate,
    required List<String> storedTemplates, // Accept multiple templates
  }) async {
    try {
      final result = await _methodChannel.invokeMethod('verifyFingerprint', {
        'template': scannedTemplate,
        'stored': storedTemplates, // Pass list of stored templates
      });
      if (result == null) {
        dev.log('Warning: verifyFingerprint returned null', name: 'FingerprintService');
        throw FingerprintException('VERIFY_NULL', 'Verification returned no result');
      }
      return {
        'matched': result['matched'] as bool,
        'score': (result['score'] as num?)?.toDouble() ?? 0.0, // Safely convert to double
        'matchedEmployeeId': result['matchedEmployeeId'] as int?, // Add employee ID if matched
      };
    } on PlatformException catch (e) {
      dev.log('Verification Error: ${e.code} - ${e.message}', name: 'FingerprintService');
      throw FingerprintException(e.code, 'Verification failed: ${e.message}');
    } catch (e) {
      dev.log('Unexpected Verification Error: $e', name: 'FingerprintService');
      rethrow;
    }
  }
}