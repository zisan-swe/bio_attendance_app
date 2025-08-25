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
    setState(() { _log = 'Scanning...'; _template = null; });
    try {
      final tpl = await _svc.scanFingerprint();
      setState(() { _template = tpl; _append('Scan OK (len=${tpl.length})'); });
    } on PlatformException catch (e) {
      setState(() => _log = 'Error: ${e.code} - ${e.message}');
    } catch (e) {
      setState(() => _log = 'Error: $e');
    }
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
