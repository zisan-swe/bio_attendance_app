// lib/seeders/attendance_seeder.dart
import '../db/database_helper.dart';
import '../models/attendance_model.dart';

class AttendanceSeeder {
  static Future<void> seedAttendance() async {
    final dbHelper = DatabaseHelper.instance;

    final now = DateTime.now();

    final List<AttendanceModel> attendances = [
      AttendanceModel(
        id: 1,
        deviceId: "DEV001",
        projectId: 101,
        blockId: 1,
        employeeNo: "EMP001",
        workingDate: now.toIso8601String().split("T").first,
        attendanceStatus: "Employee1",
        inTime: "09:00",
        outTime: "",
        location: "Rangpur Office",
        fingerprint: "Right Thumb",
        status: "Regular",
        remarks: "On time",
        createAt: now.toIso8601String(),
        updateAt: now.toIso8601String(),
        synced: 0,
      ),
      AttendanceModel(
        id: 2,
        deviceId: "DEV001",
        projectId: 101,
        blockId: 2,
        employeeNo: "EMP002",
        workingDate: now.toIso8601String().split("T").first,
        attendanceStatus: "Hasan",
        inTime: "",
        outTime: "18:10",
        location: "Rangpur Office",
        fingerprint: "Left Index",
        status: "Late",
        remarks: "Arrived late",
        createAt: now.toIso8601String(),
        updateAt: now.toIso8601String(),
        synced: 0,
      ),
      AttendanceModel(
        id: 3,
        deviceId: "DEV002",
        projectId: 102,
        blockId: 1,
        employeeNo: "EMP003",
        workingDate: now.toIso8601String().split("T").first,
        attendanceStatus: "Empolyee2",
        inTime: "09:10",
        outTime: "",
        location: "Dhaka Office",
        fingerprint: "Left Thumb",
        status: "Regular",
        remarks: "Absent without notice",
        createAt: now.toIso8601String(),
        updateAt: now.toIso8601String(),
        synced: 0,
      ),
    ];

    for (final attendance in attendances) {
      await dbHelper.insertAttendance(attendance);
    }

    print("✅ Attendance Seeder: ${attendances.length} records inserted.");
  }
}
