import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/attendance_provider.dart';
import '../services/fingerprint_service.dart';
import '../services/api_service.dart';

class EnrollScreen extends StatelessWidget {
  final FingerprintService fingerprintService = FingerprintService();

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AttendanceProvider>(context);

    return Scaffold(
      appBar: AppBar(title: Text('Enroll Worker')),
      body: Center(
        child: provider.isScanning
            ? CircularProgressIndicator()
            : ElevatedButton(
          onPressed: () async {
            provider.startScan();
            final template = await fingerprintService.scanFingerprint();
            if (template != null) {
              await ApiService.enrollWorker("WORKER_ID", template);
              provider.setScanResult("Enrollment Successful");
            } else {
              provider.setScanResult("Failed to scan");
            }
          },
          child: Text("Scan Fingerprint"),
        ),
      ),
    );
  }
}
