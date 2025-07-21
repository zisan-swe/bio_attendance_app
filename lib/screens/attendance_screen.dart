import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/attendance_provider.dart';
import '../services/fingerprint_service.dart';
import '../services/api_service.dart';

class AttendanceScreen extends StatelessWidget {
  final FingerprintService fingerprintService = FingerprintService();

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AttendanceProvider>(context);

    return Scaffold(
      appBar: AppBar(title: Text('Mark Attendance')),
      body: Center(
        child: provider.isScanning
            ? CircularProgressIndicator()
            : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () async {
                provider.startScan();
                final template = await fingerprintService.scanFingerprint();
                if (template != null) {
                  await ApiService.markAttendance(template);
                  provider.setScanResult("Attendance marked");
                } else {
                  provider.setScanResult("Failed to scan");
                }
              },
              child: Text("Scan Fingerprint"),
            ),
            SizedBox(height: 20),
            Text(
              provider.scanResult,
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
