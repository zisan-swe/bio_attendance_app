import 'dart:convert';
import 'dart:io';
import 'dart:ui' show FontFeature;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/employee_model.dart';

class EmployeeDetailsPage extends StatelessWidget {
  final EmployeeModel employee;

  const EmployeeDetailsPage({Key? key, required this.employee})
      : super(key: key);

  // ---------- Helpers ----------
  /// Safely parse a JSON array string like '["tpl1","tpl2"]'.
  /// Returns empty list if invalid or empty.
  List<String> _parseTemplates(String raw) {
    if (raw.isEmpty) return const [];
    try {
      final j = jsonDecode(raw);
      if (j is List) {
        return j
            .map((e) => (e ?? '').toString())
            .where((e) => e.isNotEmpty)
            .toList();
      }
      // legacy single string (non-JSON)
      return raw.isNotEmpty ? [raw] : const [];
    } catch (_) {
      // legacy single string (non-JSON)
      return raw.isNotEmpty ? [raw] : const [];
    }
  }

  /// Styled, read-only text field
  Widget _buildReadOnlyField(String label, String value, IconData icon) {
    return TextFormField(
      initialValue: value,
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.blueGrey),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.blueGrey),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
    );
  }

  Widget _buildReadOnlyDate(String label, String value) {
    return _buildReadOnlyField(label, value, Icons.calendar_today);
  }

  /// Pretty, read-only Employee ID with monospaced digits and Copy button
  Widget _buildEmployeeId(BuildContext context, String id) {
    final value = id.isNotEmpty ? id : '—';
    return TextFormField(
      initialValue: value,
      readOnly: true,
      style: const TextStyle(
        letterSpacing: 1.1,
        fontFeatures: [FontFeature.tabularFigures()], // monospaced digits
      ),
      decoration: InputDecoration(
        labelText: 'Employee ID (Auto)',
        prefixIcon: const Icon(Icons.badge, color: Colors.blueGrey),
        suffixIcon: IconButton(
          tooltip: 'Copy ID',
          icon: const Icon(Icons.copy),
          onPressed: id.isEmpty
              ? null
              : () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            Clipboard.setData(ClipboardData(text: id));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Employee ID copied'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.blueGrey),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
    );
  }

  /// One finger “status button” with optional sample count badge (e.g., 3/5)
  Widget _buildFingerStatus(String label, List<String> samples) {
    final hasFinger = samples.isNotEmpty;
    final count = samples.length;

    final bg = hasFinger ? Colors.green : Colors.grey[400];
    final fg = Colors.white;

    return Expanded(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ElevatedButton(
            onPressed: null, // read-only
            style: ElevatedButton.styleFrom(
              // normal colors (won't be used since it's disabled)
              backgroundColor: bg,
              foregroundColor: fg,
              // ✅ ensure the *disabled* state is also green when enrolled
              disabledBackgroundColor: bg,
              disabledForegroundColor: fg,
              minimumSize: const Size(140, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
            ),
            child: Text(
              label.split(' ').last, // "Thumb", "Index", ...
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),

          if (hasFinger)
            Positioned(
              right: -6,
              top: -6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.green.shade700),
                ),
                child: Text(
                  '$count/5',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.green.shade800,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Biometric Section – reads JSON arrays & shows enrolled/not-enrolled properly
  Widget _buildBiometricSection(EmployeeModel emp) {
    // Parse JSON arrays (or legacy single strings) into lists
    final left = <String, List<String>>{
      'Left Thumb': _parseTemplates(emp.fingerInfo1),
      'Left Index': _parseTemplates(emp.fingerInfo2),
      'Left Middle': _parseTemplates(emp.fingerInfo3),
      'Left Ring': _parseTemplates(emp.fingerInfo4),
      'Left Little': _parseTemplates(emp.fingerInfo5),
    };
    final right = <String, List<String>>{
      'Right Thumb': _parseTemplates(emp.fingerInfo6),
      'Right Index': _parseTemplates(emp.fingerInfo7),
      'Right Middle': _parseTemplates(emp.fingerInfo8),
      'Right Ring': _parseTemplates(emp.fingerInfo9),
      'Right Little': _parseTemplates(emp.fingerInfo10),
    };

    final leftKeys = [
      'Left Thumb',
      'Left Index',
      'Left Middle',
      'Left Ring',
      'Left Little'
    ];
    final rightKeys = [
      'Right Thumb',
      'Right Index',
      'Right Middle',
      'Right Ring',
      'Right Little'
    ];

    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Biometric Fingers',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Colors.blueGrey,
              ),
            ),
            const SizedBox(height: 16),

            // Headers
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Expanded(
                  child: Text(
                    'Left Hand',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey,
                      fontSize: 16,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Right Hand',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Rows of finger buttons (Left | Right)
            Column(
              children: List.generate(5, (i) {
                final leftLabel = leftKeys[i];
                final rightLabel = rightKeys[i];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFingerStatus(leftLabel, left[leftLabel] ?? const []),
                      const SizedBox(width: 20),
                      _buildFingerStatus(
                          rightLabel, right[rightLabel] ?? const []),
                    ],
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    final emp = employee;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Employee Details'),
        backgroundColor: Colors.blueGrey[700],
        elevation: 0,
        centerTitle: true,
        titleTextStyle: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blueGrey[50]!, Colors.white],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Card(
                elevation: 6,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundImage: emp.imagePath.isNotEmpty
                            ? FileImage(File(emp.imagePath))
                            : null,
                        backgroundColor: Colors.blueGrey[100],
                        child: emp.imagePath.isEmpty
                            ? const Icon(Icons.person,
                            size: 50, color: Colors.blueGrey)
                            : null,
                      ),
                      const SizedBox(height: 20),

                      // Employee ID (copyable)
                      _buildEmployeeId(context, emp.employeeNo),
                      const SizedBox(height: 16),

                      _buildReadOnlyField(
                          'Employee Name', emp.name, Icons.person),
                      const SizedBox(height: 16),
                      _buildReadOnlyField('Email', emp.email, Icons.email),
                      const SizedBox(height: 16),
                      _buildReadOnlyField(
                          'Employee NID', emp.nid, Icons.badge),
                      const SizedBox(height: 16),
                      _buildReadOnlyField(
                        'Employee Daily Wages',
                        emp.dailyWages.toStringAsFixed(2),
                        Icons.attach_money,
                      ),
                      const SizedBox(height: 16),
                      _buildReadOnlyField('Phone', emp.phone, Icons.phone),
                      const SizedBox(height: 16),
                      _buildReadOnlyField("Father's Name", emp.fatherName,
                          Icons.person_outline),
                      const SizedBox(height: 16),
                      _buildReadOnlyField("Mother's Name", emp.motherName,
                          Icons.person_outline),
                      const SizedBox(height: 16),
                      _buildReadOnlyDate('Date of Birth', emp.dob),
                      const SizedBox(height: 16),
                      _buildReadOnlyDate('Joining Date', emp.joiningDate),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _buildBiometricSection(emp),
            ],
          ),
        ),
      ),
    );
  }
}