import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/attendance_model.dart';
import '../../providers/attendance_provider.dart';
import '../../services/location_service.dart';
import '../attendance/attendance_list_page.dart';

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

  void _updateTime() {
    final now = DateTime.now().toUtc().add(const Duration(hours: 6));
    setState(() {
      formattedTime = DateFormat('hh:mm:ss a').format(now);
      formattedDate = DateFormat('EEEE, MMMM d').format(now);
    });
  }

  Future<void> _storeAttendance() async {
    final hasAtLeastOneScan = fingerScanStatus.values.any((v) => v == true);

    if (!hasAtLeastOneScan) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please scan at least one finger before submitting attendance.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final selectedFinger = fingerScanStatus.entries.firstWhere((e) => e.value == true).key;

    final now = DateTime.now().toUtc().add(const Duration(hours: 6));
    final time = DateFormat('HH:mm:ss').format(now);
    final date = DateFormat('yyyy-MM-dd').format(now);

    final locationService = LocationService();
    String? location = await locationService.getCurrentLocation();
    final safeLocation = (location != null && location.isNotEmpty) ? location : 'Unknown';

    final attendance = AttendanceModel(
      deviceId: 'Device001',
      projectId: 1,
      blockId: 1,
      employeeNo: '101',
      workingDate: date,
      attendanceStatus: selectedAction,
      inTime: (selectedAction == 'Check In' || selectedAction == 'Break In') ? time : '',
      outTime: (selectedAction == 'Check Out' || selectedAction == 'Break Out') ? time : '',
      location: safeLocation,
      fingerprint: selectedFinger,
      status: 1,
      remarks: '',
      createAt: now.toIso8601String(),
      updateAt: now.toIso8601String(),
    );

    await AttendanceProvider().insertAttendance(attendance);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ $selectedAction Successful')),
      );
    }

    setState(() {
      fingerScanStatus.updateAll((key, value) => false);
    });
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
      body: Center(
        child: SingleChildScrollView(
          child: Column(
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
                children: [
                  _buildRadioButton('Check In'),
                  _buildRadioButton('Check Out'),
                  _buildRadioButton('Break In'),
                  _buildRadioButton('Break Out'),
                ],
              ),
              const SizedBox(height: 30),

              // Updated Finger Layout (Left-Right Pairs)
              Column(
                children: [
                  _buildFingerRow('Left Thumb', 'Right Thumb'),
                  _buildFingerRow('Left Index', 'Right Index'),
                  _buildFingerRow('Left Middle', 'Right Middle'),
                  _buildFingerRow('Left Ring', 'Right Ring'),
                  _buildFingerRow('Left Little', 'Right Little'),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _storeAttendance,
                icon: const Icon(Icons.check_circle),
                label: const Text('Submit Attendance'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AttendanceListPage(),
                    ),
                  );
                },
                child: const Text('View Attendance Records'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  backgroundColor: Colors.blueGrey,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRadioButton(String action) {
    final isSelected = selectedAction == action;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedAction = action;
        });
      },
      child: Container(
        width: 130,
        height: 50,
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
    );
  }

  Widget _buildFinger(String fingerName) {
    final isScanned = fingerScanStatus[fingerName] ?? false;
    final screenWidth = MediaQuery.of(context).size.width;
    final buttonWidth = (screenWidth - 64) / 2;

    return SizedBox(
      width: buttonWidth,
      height: 50,
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            // ❗ Reset all to false, then mark only selected one as true
            fingerScanStatus.updateAll((key, value) => false);
            fingerScanStatus[fingerName] = true;
          });
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
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon(
            //   isScanned ? Icons.radio_button_checked : Icons.radio_button_unchecked,
            //   size: 20,
            // ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                fingerName,
                style: const TextStyle(fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }






  // Widget _buildFinger(String fingerName) {
  //   final isScanned = fingerScanStatus[fingerName] ?? false;
  //   final screenWidth = MediaQuery.of(context).size.width;
  //   final buttonWidth = (screenWidth - 64) / 2; // 32px padding on each side + spacing
  //
  //   return SizedBox(
  //     width: buttonWidth,
  //     height: 50,
  //     child: ElevatedButton(
  //       onPressed: () {
  //         setState(() {
  //           fingerScanStatus[fingerName] = !isScanned;
  //         });
  //       },
  //       style: ElevatedButton.styleFrom(
  //         backgroundColor: isScanned ? Colors.green : Colors.grey[300],
  //         foregroundColor: isScanned ? Colors.white : Colors.black,
  //         shape: RoundedRectangleBorder(
  //           borderRadius: BorderRadius.circular(20),
  //         ),
  //         elevation: 2,
  //         padding: const EdgeInsets.symmetric(horizontal: 10),
  //       ),
  //       child: Row(
  //         mainAxisAlignment: MainAxisAlignment.center,
  //         children: [
  //           Icon(
  //             isScanned ? Icons.fingerprint : Icons.fingerprint_outlined,
  //             size: 20,
  //           ),
  //           const SizedBox(width: 6),
  //           Flexible(
  //             child: Text(
  //               fingerName,
  //               style: const TextStyle(fontSize: 13),
  //               overflow: TextOverflow.ellipsis,
  //             ),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }



  Widget _buildFingerRow(String leftFinger, String rightFinger) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildFinger(leftFinger),
          const SizedBox(width: 16),
          _buildFinger(rightFinger),
        ],
      ),
    );
  }
}
