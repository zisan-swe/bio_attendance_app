import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:biometric_attendance/services/fingerprint_service.dart';


class FingerPage extends StatefulWidget {
  const FingerPage({Key? key}) : super(key: key);
  @override
  State<FingerPage> createState() => _FingerPageState();
}

class _FingerPageState extends State<FingerPage> {
  final _svc = FingerprintService();
  String _fingerprintData = 'No data yet';

  Future<void> _onScan() async {
    setState(() => _fingerprintData = 'Scanning...');
    try {
      final tpl = await _svc.scanFingerprint();
      setState(() => _fingerprintData = tpl);         // Base64 template
    } on PlatformException catch (e) {
      setState(() => _fingerprintData = 'Error: ${e.code} - ${e.message}');
    } catch (e) {
      setState(() => _fingerprintData = 'Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SLK20R Fingerprint')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(onPressed: _onScan, child: const Text('Scan Finger')),
              const SizedBox(height: 20),
              const Text('Result:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              SelectableText(_fingerprintData),
            ],
          ),
        ),
      ),
    );
  }
}
