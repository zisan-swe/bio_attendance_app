import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/attendance_model.dart';
import '../../models/employee_model.dart';
import '../../providers/attendance_provider.dart';
import '../../services/location_service.dart';
import '../../services/fingerprint_service.dart';
import '../../services/api_service.dart';
import '../../db/database_helper.dart';

class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  String selectedAction = 'Check In';
  String formattedTime = '';
  String formattedDate = '';
  Timer? _timer;
  bool isScanning = false;

  Map<String, bool> fingerScanStatus = {
    'Left Thumb': false,
    'Right Thumb': false,
    'Left Index': false,
    'Right Index': false,
    'Left Middle': false,
    'Right Middle': false,
    'Left Ring': false,
    'Right Ring': false,
    'Left Little': false,
    'Right Little': false,
  };

  @override
  void initState() {
    super.initState();
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTime());
  }

  static final _timeFormat = DateFormat('hh:mm:ss a');
  static final _dateFormat = DateFormat('EEEE, MMMM d');
  static final _timeLogFormat = DateFormat('HH:mm:ss');
  static final _dateLogFormat = DateFormat('yyyy-MM-dd');

  void _updateTime() {
    if (!mounted) return;
    final now = DateTime.now().toUtc().add(const Duration(hours: 6));
    setState(() {
      formattedTime = _timeFormat.format(now);
      formattedDate = _dateFormat.format(now);
    });
  }

  Future<void> _startFingerprintScan() async {
    if (isScanning) return;
    setState(() => isScanning = true);

    final fingerprintService = FingerprintService();
    String? scannedTemplate;

    try {
      scannedTemplate = await fingerprintService.scanFingerprint();
      debugPrint("Scanned Template: $scannedTemplate");
      if (scannedTemplate == null || scannedTemplate.isEmpty) {
        _showSnack("❌ Invalid or empty fingerprint scan.", isError: true);
        setState(() => isScanning = false);
        return;
      }
    } on FingerprintException catch (e) {
      debugPrint("Scan Error: ${e.code} - ${e.message}");
      _showSnack("❌ Finger scan failed: ${e.message}", isError: true);
      setState(() => isScanning = false);
      return;
    } catch (e) {
      debugPrint("Scan Error: $e");
      _showSnack("❌ Finger scan failed: $e", isError: true);
      setState(() => isScanning = false);
      return;
    }

    final attendanceProvider = context.read<AttendanceProvider>();
    EmployeeModel? employee;
    try {
      employee = await attendanceProvider.getEmployeeByFingerprint(scannedTemplate);
      debugPrint("Employee Found: ${employee?.name ?? 'None'}");
      if (employee == null) {
        _showSnack("❌ No matching employee found.", isError: true);
        setState(() => isScanning = false);
        return;
      }
    } catch (e) {
      debugPrint("Match Error: $e");
      _showSnack("❌ Error matching employee: $e", isError: true);
      setState(() => isScanning = false);
      return;
    }

    final selectedFinger = fingerScanStatus.entries.firstWhere(
          (e) => e.value,
      orElse: () => MapEntry('Left Thumb', true),
    ).key;

    final storedTemplate =
        employee.fingerprints[selectedFinger] ?? employee.fingerInfo1;
    debugPrint("Stored Template ($selectedFinger): $storedTemplate");
    if (storedTemplate == null || storedTemplate.isEmpty) {
      _showSnack("❌ No stored template for $selectedFinger.", isError: true);
      setState(() => isScanning = false);
      return;
    }

    await _saveAndRedirect(employee, selectedFinger);
  }

  Future<void> _saveAndRedirect(EmployeeModel employee, String selectedFinger) async {
    final now = DateTime.now().toUtc().add(const Duration(hours: 6));
    final time = _timeLogFormat.format(now);
    final date = _dateLogFormat.format(now);

    final locationService = LocationService();
    final location = await locationService.getCurrentLocation();
    final safeLocation = (location != null && location.isNotEmpty) ? location : 'Unknown';

    final projectId = await DatabaseHelper.instance.getSettingBySlug('project_id');
    final blockId = await DatabaseHelper.instance.getSettingBySlug('block_id');

    final attendance = AttendanceModel(
      // id: null,
      deviceId: 'Device001',
      projectId: int.tryParse(projectId?.value ?? '0') ?? 0,
      blockId: int.tryParse(blockId?.value ?? '0') ?? 0,
      employeeNo: employee.employeeNo,
      workingDate: date,
      attendanceStatus: selectedAction,
      inTime: (selectedAction == 'Check In' || selectedAction == 'Break In') ? time : '',
      outTime: (selectedAction == 'Check Out' || selectedAction == 'Break Out') ? time : '',
      location: safeLocation,
      fingerprint: selectedFinger,
      status: 'Regular',
      remarks: '',
      createAt: now.toIso8601String(),
      updateAt: now.toIso8601String(),
      synced: 0,
    );

    final attendanceProvider = context.read<AttendanceProvider>();

    try {
      final localId = await attendanceProvider.insertAttendance(attendance);
      final message = await ApiService.createAttendance(attendance);
      final synced = message.toLowerCase().contains("success");

      if (synced) {
        await attendanceProvider.updateAttendance(
          attendance.copyWith(id: localId, synced: 1),
        );
        _showSnack("✅ $message", isError: false);
      } else {
        _showSnack("⚠️ $message", isError: true);
      }
    } catch (e) {
      debugPrint("Save Error: $e");
      _showSnack("❌ Failed to log attendance: $e", isError: true);
    } finally {
      setState(() => isScanning = false);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance'),
        backgroundColor: Colors.blueGrey,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 40),
              const Icon(Icons.fingerprint, size: 80, color: Colors.blueGrey),
              const SizedBox(height: 10),
              Text(
                'Fingerprint Attendance',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey[800],
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Quick and secure check-ins',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              const SizedBox(height: 40),
              Text(
                formattedDate,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                width: 180,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.blueGrey,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  formattedTime.isEmpty ? "Loading..." : formattedTime,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 24,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const SizedBox(height: 30),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  _buildRadioButton('Check In'),
                  _buildRadioButton('Check Out'),
                  _buildRadioButton('Break In'),
                  _buildRadioButton('Break Out'),
                ],
              ),
              const SizedBox(height: 30),
              Column(
                children: [
                  _buildFingerRow('Left Thumb', 'Right Thumb'),
                  _buildFingerRow('Left Index', 'Right Index'),
                  _buildFingerRow('Left Middle', 'Right Middle'),
                  _buildFingerRow('Left Ring', 'Right Ring'),
                  _buildFingerRow('Left Little', 'Right Little'),
                ],
              ),
              const SizedBox(height: 30),
              if (isScanning)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRadioButton(String action) {
    final isSelected = selectedAction == action;
    return SizedBox(
      width: 130,
      height: 50,
      child: GestureDetector(
        onTap: () => setState(() => selectedAction = action),
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? Colors.green : Colors.grey[400],
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: isSelected ? Colors.green : Colors.transparent,
              width: 2,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            action,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFinger(String fingerName) {
    final isScanned = fingerScanStatus[fingerName] ?? false;
    final screenWidth = MediaQuery.of(context).size.width;
    final buttonWidth = (screenWidth - 64 - 16) / 2;

    return SizedBox(
      width: buttonWidth,
      height: 50,
      child: ElevatedButton(
        onPressed: isScanning
            ? null
            : () async {
          setState(() {
            fingerScanStatus.updateAll((key, value) => false);
            fingerScanStatus[fingerName] = true;
          });
          await _startFingerprintScan();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: isScanned ? Colors.green : Colors.grey[300],
          foregroundColor: isScanned ? Colors.white : Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 10),
        ),
        child: Text(
          fingerName,
          style: const TextStyle(fontSize: 13),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildFingerRow(String leftFinger, String rightFinger) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildFinger(leftFinger),
          const SizedBox(width: 16),
          _buildFinger(rightFinger),
        ],
      ),
    );
  }
}
