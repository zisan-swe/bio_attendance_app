import 'package:flutter/material.dart';

import '../../providers/employee_provider1.dart';
import '../../services/fingerprint_service1.dart';

class FingerprintTestPage extends StatefulWidget {
  const FingerprintTestPage({super.key});

  @override
  State<FingerprintTestPage> createState() => _FingerprintTestPageState();
}

class _FingerprintTestPageState extends State<FingerprintTestPage> {
  final _svc = FingerprintService1();
  final _employeeProvider = EmployeeProvider1();
  String log = "Ready";


  Future<void> _scanAndVerify() async {
    try {
      setState(() => log = "🔍 Scanning...");

      // ১) নতুন টেমপ্লেট স্ক্যান
      final newTpl = await _svc.scanFingerprint();
      if (newTpl == null) {
        setState(() => log = "❌ No fingerprint captured!");
        return;
      }

      // ২) Stored templates SQLite থেকে আনা (with employeeId)
      final storedTemplates = await _employeeProvider.getAllTemplatesWithEmployeeId();
      if (storedTemplates.isEmpty) {
        setState(() => log = "⚠️ No stored templates in database.");
        return;
      }

      int bestScore = 0;
      int? matchedEmployeeId;

      // ৩) Verify against each template
      for (var item in storedTemplates) {
        final result = await FingerprintService1.verifyFingerprint(
          scannedTemplate: newTpl,
          storedTemplates: [item.template],
        );

        if (result['matched'] == true && (result['score'] ?? 0) > bestScore) {
          bestScore = result['score'] ?? 0;
          matchedEmployeeId = item.employeeId;
        }
      }

      // ৪) Show result
      setState(() {
        if (matchedEmployeeId != null) {
          log = "✅ Match Found!\nEmployee ID: $matchedEmployeeId\nScore: $bestScore";
        } else {
          log = "❌ No Match.\nBest Score: $bestScore";
        }
      });
    } catch (e) {
      setState(() => log = "⚠️ Error: $e");
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Fingerprint Test")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(log, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _scanAndVerify,
              child: const Text("Scan & Verify"),
            ),
          ],
        ),
      ),
    );
  }
}
