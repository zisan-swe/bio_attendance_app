import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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

  // Track scan status of fingers
  Map<String, bool> fingerScanStatus = {
    'Right Thumb': false,
  };

  @override
  void initState() {
    super.initState();
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateTime();
    });
  }

  void _updateTime() {
    final now = DateTime.now();
    final timeFormatter = DateFormat('hh:mm:ss a'); // e.g., 02:45:30 PM
    final dateFormatter = DateFormat('EEEE, MMMM d'); // e.g., Friday, July 26
    setState(() {
      formattedTime = timeFormatter.format(now);
      formattedDate = dateFormatter.format(now);
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

            // Date
            Text(
              formattedDate,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),

            const SizedBox(height: 10),

            // Time Box with seconds
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

            const SizedBox(height: 50),

            // Row 1: Check In & Check Out
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildRadioButton('Check In'),
                const SizedBox(width: 20),
                _buildRadioButton('Check Out'),
              ],
            ),
            const SizedBox(height: 20),

            // Row 2: Break In & Break Out
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildRadioButton('Break In'),
                const SizedBox(width: 20),
                _buildRadioButton('Break Out'),
              ],
            ),

            const SizedBox(height: 30),

            // Rounded Finger Scan Button
            _buildFinger('Right Thumb'),
          ],
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
    bool isScanned = fingerScanStatus[fingerName] ?? false;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            fingerScanStatus[fingerName] = !isScanned;
          });
        },
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          backgroundColor: isScanned ? Colors.green : Colors.grey[300],
          foregroundColor: isScanned ? Colors.white : Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 2,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isScanned ? Icons.fingerprint : Icons.fingerprint_outlined,
              size: 40,
            ),
            // const SizedBox(width: 8),
            // Text(
            //   fingerName.split(' ').last,
            //   style: const TextStyle(fontWeight: FontWeight.bold),
            // ),
          ],
        ),
      ),
    );
  }
}
