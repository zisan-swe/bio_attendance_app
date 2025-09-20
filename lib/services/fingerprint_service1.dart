import 'dart:convert';
import 'dart:developer' as dev;

class FingerprintService1 {
  /// 👉 Scan fingerprint - Dummy version (for testing)
  Future<String?> scanFingerprint() async {
    await Future.delayed(Duration(seconds: 2)); // simulate scan delay

    // Dummy fingerprint template (Base64 string)
    final fakeFingerprintBytes = List<int>.generate(256, (i) => i % 256);
    final base64Template = base64Encode(fakeFingerprintBytes);

    dev.log("📸 Fake fingerprint scanned", name: "FingerprintService");
    return base64Template;
  }

  /// Verify scanned fingerprint against stored templates
  static Future<Map<String, dynamic>> verifyFingerprint({
    required String scannedTemplate, // Base64 string
    required List<String> storedTemplates, // Base64 list
  }) async {
    try {
      final scannedBytes = base64Decode(scannedTemplate);

      for (String stored in storedTemplates) {
        try {
          final storedBytes = base64Decode(stored);

          final score = _fakeMatch(scannedBytes, storedBytes);

          if (score > 60) {
            return {
              'matched': true,
              'score': score,
            };
          }
        } catch (e) {
          dev.log("❌ Error decoding stored template: $e", name: "FingerprintService");
          continue;
        }
      }

      return {
        'matched': false,
        'score': 0,
      };
    } catch (e) {
      dev.log("❌ verifyFingerprint error: $e", name: "FingerprintService");
      return {
        'matched': false,
        'score': 0,
        'error': e.toString(),
      };
    }
  }

  /// Fake matcher
  static int _fakeMatch(List<int> a, List<int> b) {
    if (a.length == b.length) {
      return 75;
    }
    return 30;
  }
}
