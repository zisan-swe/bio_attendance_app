import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/attendance_model.dart';
import '../../models/employee_model.dart';

class AttendanceDetailsPage extends StatelessWidget {
  final List<AttendanceModel> attendances;
  final EmployeeModel? employee;

  AttendanceDetailsPage({
    super.key,
    required this.attendances,
    this.employee,
  });

  final DateFormat _dateFormat = DateFormat('MMM dd, yyyy');
  final DateFormat _timeFormat = DateFormat('hh:mm a');

  Color _getStatusColor(int status) {
    return status == 1 ? Colors.green : Colors.orange;
  }

  IconData _getActionIcon(String action) {
    switch (action) {
      case 'Check In':
        return Icons.login;
      case 'Check Out':
        return Icons.logout;
      case 'Break In':
        return Icons.coffee;
      case 'Break Out':
        return Icons.work;
      default:
        return Icons.access_time;
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🔹 Group attendances by date
    Map<String, List<AttendanceModel>> grouped = {};
    for (var att in attendances) {
      grouped.putIfAbsent(att.workingDate, () => []).add(att);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Attendance Details"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 3,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🔹 Employee Header
                if (employee != null)
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.blue,
                        child: const Icon(Icons.person, color: Colors.white, size: 32),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              employee!.name,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              "ID: ${employee!.employeeNo}",
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),

                const SizedBox(height: 20),

                // 🔹 Attendance grouped by date
                ...grouped.entries.map((entry) {
                  String date = entry.key;
                  List<AttendanceModel> records = entry.value;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ...records.map((attendance) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: _getStatusColor(attendance.status),
                                  child: Icon(
                                    _getActionIcon(attendance.attendanceStatus),
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  attendance.attendanceStatus,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            // 🔹 Date
                            _infoRow("Date", _dateFormat.format(DateTime.parse(date))),

                            // 🔹 In/Out Time
                            if (attendance.inTime.isNotEmpty)
                              _infoRow(
                                "In Time",
                                _timeFormat.format(DateTime.parse("2023-01-01 ${attendance.inTime}")),
                              ),
                            if (attendance.outTime.isNotEmpty)
                              _infoRow(
                                "Out Time",
                                _timeFormat.format(DateTime.parse("2023-01-01 ${attendance.outTime}")),
                              ),

                            // 🔹 Fingerprint
                            if (attendance.fingerprint.isNotEmpty)
                              _infoRow("Used Finger", attendance.fingerprint),

                            const Divider(height: 30),
                          ],
                        );
                      }).toList(),
                    ],
                  );
                }),

                // 🔹 Employee Details at bottom
                // if (employee != null) ...[
                //   const Text(
                //     "Employee Details",
                //     style: TextStyle(
                //       fontSize: 18,
                //       fontWeight: FontWeight.bold,
                //       color: Colors.deepPurple,
                //     ),
                //   ),
                //   const SizedBox(height: 10),
                //   _infoRow("Name", employee!.name),
                //   _infoRow("Number", employee!.employeeNo.toString()),
                // ]
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              "$title:",
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }
}
