import 'dart:typed_data';
import 'package:flutter/services.dart';

class FingerprintService {
  static const _channel = MethodChannel('com.legendit.zkteco');

  Future<Map<String, dynamic>> diagnoseUsb() async {
    final res = await _channel.invokeMapMethod<String, dynamic>('diagnoseUsb');
    return (res ?? <String, dynamic>{});
  }

  /// Starts native capture. Returns Base64 template on success.
  /// Throws PlatformException(code, message) on failure.
  Future<String> scanFingerprint() async {
    final tpl = await _channel.invokeMethod<String>('scanFingerprint');
    if (tpl == null || tpl.isEmpty) {
      throw PlatformException(
        code: 'EMPTY_TEMPLATE',
        message: 'No template returned from native layer.',
      );
    }
    return tpl;
  }
}
