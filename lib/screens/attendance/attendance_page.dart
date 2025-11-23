// E:\Android\bio_attendance_app\lib\screens\attendance\attendance_page.dart
import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
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

  // Connectivity & syncing
  StreamSubscription<List<ConnectivityResult>>? _connSub;
  int _pending = 0;
  DateTime _nextAutoSyncAllowed = DateTime.fromMillisecondsSinceEpoch(0);

  // Formats
  static final _timeFormat = DateFormat('hh:mm:ss a');
  static final _dateFormat = DateFormat('EEEE, MMMM d');
  static final _timeLogFormat = DateFormat('HH:mm:ss');
  static final _dateLogFormat = DateFormat('yyyy-MM-dd');

  @override
  void initState() {
    super.initState();
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTime());
    _refreshPending();
    _listenConnectivity();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _connSub?.cancel();
    super.dispose();
  }

  void _updateTime() {
    if (!mounted) return;
    final now = DateTime.now().toUtc().add(const Duration(hours: 6));
    setState(() {
      formattedTime = _timeFormat.format(now);
      formattedDate = _dateFormat.format(now);
    });
  }

  Future<void> _refreshPending() async {
    final n = await context.read<AttendanceProvider>().countPendingUnsynced();
    if (mounted) setState(() => _pending = n);
  }

  void _listenConnectivity() {
    _connSub = Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> results) async {
      final online = results.any(
            (r) => r == ConnectivityResult.mobile || r == ConnectivityResult.wifi,
      );
      if (!online) return;

      // throttle auto-sync attempts
      if (DateTime.now().isBefore(_nextAutoSyncAllowed)) return;
      _nextAutoSyncAllowed = DateTime.now().add(const Duration(seconds: 10));

      final synced =
      await context.read<AttendanceProvider>().syncPendingAttendance();
      if (!mounted) return;
      await _refreshPending();
      if (synced > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ Auto-synced $synced record(s)')),
        );
      }
    });
  }

  Future<String> _detectFingerLabel({
    required String employeeNo,
    required String scannedTemplate,
  }) async {
    // 1) ঐ এমপ্লয়ির সব এনরোল করা ফিঙ্গার টেমপ্লেট নাও
    final attendanceProvider = context.read<AttendanceProvider>();
    final enrolled = await attendanceProvider.getEnrolledFingerprints(
      employeeNo: employeeNo,
    ); // Map<String, List<String>>

    // 2) ফ্ল্যাটেন: ফিঙ্গার লেবেল ও টেমপ্লেট লিস্ট আলাদা করা
    final List<String> labels = [];
    final List<String> templates = [];
    enrolled.forEach((finger, list) {
      for (final t in list) {
        if (t.isNotEmpty) {
          labels.add(finger);
          templates.add(t);
        }
      }
    });

    if (templates.isEmpty) return 'Fingerprint'; // fallback

    // 3) নেটিভ verifyFingerprint কল — (MainActivity.kt এ ইতোমধ্যে হয়েছে)
    final res = await FingerprintService.verifyFingerprint(
      scannedTemplate: scannedTemplate,
      storedTemplates: templates,
    );

    final matched = (res['matched'] as bool?) ?? false;
    final idx = res['matchedEmployeeId'] as int?;

    if (matched && idx != null && idx >= 0 && idx < labels.length) {
      return labels[idx]; // যেমন 'Left Thumb'
    }

    return 'Fingerprint'; // fallback
  }


  Future<void> _startFingerprintScanAndSave() async {
    if (isScanning) return;
    setState(() => isScanning = true);

    final fingerprintService = FingerprintService();
    String? scannedTemplate;

    try {
      scannedTemplate = await fingerprintService.scanFingerprint();
      if (scannedTemplate == null || scannedTemplate.isEmpty) {
        _showSnack('❌ Invalid or empty fingerprint scan.', isError: true);
        setState(() => isScanning = false);
        return;
      }
    } catch (e) {
      _showSnack('❌ Finger scan failed: $e', isError: true);
      setState(() => isScanning = false);
      return;
    }

    // Identify employee from DB by scanned template
    final attendanceProvider = context.read<AttendanceProvider>();
    EmployeeModel? employee;
    try {
      employee =
      await attendanceProvider.getEmployeeByFingerprint(scannedTemplate);
      if (employee == null) {
        _showSnack('❌ No matching employee found.', isError: true);
        setState(() => isScanning = false);
        return;
      }
    } catch (e) {
      _showSnack('❌ Error matching employee: $e', isError: true);
      setState(() => isScanning = false);
      return;
    }

    // ✅ এখানে কোন ফিঙ্গারটা ম্যাচ করেছে সেটা বের করি
    String matchedFingerLabel = 'Fingerprint';
    try {
      matchedFingerLabel = await _detectFingerLabel(
        employeeNo: employee.employeeNo,
        scannedTemplate: scannedTemplate,
      );
    } catch (_) {
      // চুপচাপ fallback থাকবে 'Fingerprint'
    }

// আগে যেটা ছিল: await _saveAndMaybeSync(employee, 'Fingerprint');
// বদলে:
    await _saveAndMaybeSync(employee, matchedFingerLabel);

    // Finger label আর দরকার নেই—একীভূত “Fingerprint” লেবেল রাখছি
    // await _saveAndMaybeSync(employee, 'Fingerprint');
  }

  Future<void> _saveAndMaybeSync(
      EmployeeModel employee,
      String fingerprintLabel,
      ) async {
    final now = DateTime.now().toUtc().add(const Duration(hours: 6));
    final time = _timeLogFormat.format(now);
    final date = _dateLogFormat.format(now);

    final locationService = LocationService();
    final location = await locationService.getCurrentLocation();
    final safeLocation =
    (location != null && location.isNotEmpty) ? location : 'Unknown';

    final projectId =
    await DatabaseHelper.instance.getSettingBySlug('project_id');
    final blockId =
    await DatabaseHelper.instance.getSettingBySlug('block_id');

    final attendance = AttendanceModel(
      deviceId: 'Device001',
      projectId: projectId?.value ?? '',   // 🔥 now String
      blockId: blockId?.value ?? '',       // 🔥 now String
      employeeNo: employee.employeeNo,
      workingDate: date,
      attendanceStatus: selectedAction,
      inTime:
      (selectedAction == 'Check In' || selectedAction == 'Break In') ? time : '',
      outTime:
      (selectedAction == 'Check Out' || selectedAction == 'Break Out') ? time : '',
      location: safeLocation,
      fingerprint: fingerprintLabel, // unified label
      status: 'Regular',
      remarks: '',
      createAt: now.toIso8601String(),
      updateAt: now.toIso8601String(),
      synced: 0, // offline-first
    );

    final attendanceProvider = context.read<AttendanceProvider>();

    // 1) Save locally first
    final localId = await attendanceProvider.insertAttendance(attendance);
    await _refreshPending();

    // 2) Try to sync
    try {
      final message = await ApiService.createAttendance(attendance);
      final ok = message.toLowerCase().contains('success');
      if (ok) {
        await attendanceProvider.updateAttendance(
          attendance.copyWith(id: localId, synced: 1),
        );
        await _refreshPending();
        _showSnack('✅ $message');
      } else {
        _showSnack('⚠️ $message', isError: true);
      }
    } on SocketException {
      _showSnack('📴 Saved locally (offline). Will sync when online.');
    } catch (e) {
      _showSnack('⚠️ Saved locally. Sync pending. ($e)', isError: true);
    } finally {
      if (mounted) setState(() => isScanning = false);
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

  // ------------------- UI -------------------
  @override
  Widget build(BuildContext context) {
    final bigButtonChild = isScanning
        ? const SizedBox(
      height: 24,
      width: 24,
      child: CircularProgressIndicator(strokeWidth: 2),
    )
        : const Text(
      'Scan & Save',
      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance'),
        backgroundColor: Colors.blueGrey,
        actions: [
          IconButton(
            tooltip: 'Sync pending',
            onPressed: () async {
              final synced =
              await context.read<AttendanceProvider>().syncPendingAttendance();
              await _refreshPending();
              final msg = synced > 0
                  ? '✅ Synced $synced record(s)'
                  : 'No pending records';
              _showSnack(msg, isError: synced == 0);
            },
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.sync),
                if (_pending > 0)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$_pending',
                        style:
                        const TextStyle(fontSize: 10, color: Colors.white),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 0),
              const Icon(Icons.fingerprint, size: 70, color: Colors.blueGrey),
              const SizedBox(height: 10),
              Text(
                'Fingerprint Attendance',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey[800],
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Quick and secure check-ins',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              const SizedBox(height: 30),
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
                  formattedTime.isEmpty ? 'Loading...' : formattedTime,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 24,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // Action selector
              // Action selector – দুই রোতে ভাগ করা
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildActionChip('Check In'),
                      const SizedBox(width: 18),
                      _buildActionChip('Check Out'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildActionChip('Break In'),
                      const SizedBox(width: 18),
                      _buildActionChip('Break Out'),
                    ],
                  ),
                ],
              ),


              const SizedBox(height: 30),

              // Single primary button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: isScanning ? null : _startFingerprintScanAndSave,
                  icon: const Icon(Icons.fingerprint),
                  label: bigButtonChild,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),
              Text(
                'Selected: $selectedAction',
                style: TextStyle(
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionChip(String action) {
    final isSelected = selectedAction == action;
    return FilterChip(
      selected: isSelected,
      onSelected: (_) => setState(() => selectedAction = action),
      label: Text(
        action,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: isSelected ? Colors.white : Colors.black87,
        ),
      ),
      selectedColor: Colors.green,
      checkmarkColor: Colors.white,
      backgroundColor: Colors.grey[300],
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }
}
