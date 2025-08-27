import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:biometric_attendance/services/fingerprint_service.dart';

class FingerprintTestPage extends StatefulWidget {
  const FingerprintTestPage({super.key});

  @override
  State<FingerprintTestPage> createState() => _FingerprintTestPageState();
}

class _FingerprintTestPageState extends State<FingerprintTestPage> {
  final _svc = FingerprintService();
  String _log = 'Ready';
  String? _template;

  void _append(String line) {
    setState(() => _log = '$_log\n$line');
  }

  Future<void> _diagnose() async {
    setState(() { _log = 'Diagnosing...'; _template = null; });
    try {
      final m = await _svc.diagnoseUsb();
      _append('USB Devices: ${m['devices']}');
      _append('HasPermission: ${m['hasPermission']}');
      _append('SDK Present: ${m['sdkPresent']}');
      if (m['note'] != null) _append('Note: ${m['note']}');
    } on PlatformException catch (e) {
      setState(() => _log = 'Error: ${e.code} - ${e.message}');
    } catch (e) {
      setState(() => _log = 'Error: $e');
    }
  }

  Future<void> _scan() async {
    setState(() {
      _log = '🟢 READY - Place finger on scanner NOW!\n\n' +
          '• Press FIRMLY on the center\n' +
          '• Cover the entire sensor surface\n' +
          '• Keep finger STILL for 2 seconds\n' +
          '• Wait for beep/light feedback\n\n' +
          'Scanning in 2 seconds...';
      _template = null;
    });

    await Future.delayed(Duration(seconds: 2));

    for (int attempt = 1; attempt <= 3; attempt++) {
      try {
        _append('\n=== Attempt $attempt ===');
        _append('Scanning... (keep finger pressed)');

        final tpl = await _svc.scanFingerprint();

        setState(() {
          _template = tpl;
          _append('✅ SUCCESS! Template captured (${tpl.length} bytes)');
        });
        return;

      } on PlatformException catch (e) {
        if (e.code == 'CAPTURE_EMPTY') {
          _append('❌ No fingerprint detected. Please:');
          _append('   • Press HARDER and center finger');
          _append('   • Try a DIFFERENT finger');
          _append('   • Ensure finger is CLEAN and DRY');
          await Future.delayed(Duration(seconds: 2));
        } else {
          _append('❌ Error: ${e.code} - ${e.message}');
          break;
        }
      }
    }

    _append('\n💡 TIPS: Clean sensor, use thumb/index, firm pressure');
    _append('🔧 Check USB connection and try again');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SLK20R Test')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Wrap(spacing: 12, children: [
              ElevatedButton(onPressed: _diagnose, child: const Text('Diagnose USB')),
              ElevatedButton(onPressed: _scan, child: const Text('Scan Finger')),
            ]),
            const SizedBox(height: 12),
            const Align(alignment: Alignment.centerLeft, child: Text('Log:', style: TextStyle(fontWeight: FontWeight.bold))),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(child: Text(_log)),
              ),
            ),
            if (_template != null) ...[
              const SizedBox(height: 8),
              const Align(alignment: Alignment.centerLeft, child: Text('Template (Base64):', style: TextStyle(fontWeight: FontWeight.bold))),
              const SizedBox(height: 6),
              Expanded(
                child: SelectableText(
                  _template!,
                  maxLines: 6,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
