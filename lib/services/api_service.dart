import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/attendance_model.dart';

class ApiService {
  static const String baseUrl = "https://kisan.rahmangrouperp.com/api/v1";

  // --- Labour Create (already implemented) ---
  static Future<bool> createLabour(Map<String, dynamic> body) async {
    final url = Uri.parse("$baseUrl/labour-create");
    final headers = {"Content-Type": "application/json"};

    try {
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print("✅ Labour created successfully: ${response.body}");
        return true;
      } else {
        print("❌ Failed to create labour: ${response.statusCode}");
        print("Response: ${response.body}");
        return false;
      }
    } catch (e) {
      print("❌ Exception while creating labour: $e");
      return false;
    }
  }

  // --- Attendance Create (UPDATED) ---
  static Future<bool> createAttendance(AttendanceModel attendance) async {
    final url = Uri.parse("$baseUrl/attendance");
    final headers = {"Content-Type": "application/json"};

    final body = {
      "project_id": attendance.projectId,
      "device_id": attendance.deviceId,
      "block_id": attendance.blockId,
      "employee_no": attendance.employeeNo,
      "working_date": attendance.workingDate,
      "attendance_date": attendance.workingDate, // same as working_date or a separate field if needed
      "attendance_status": attendance.attendanceStatus,
      "fingerprint": attendance.fingerprint,
      "in_time": attendance.inTime,
      "out_time": attendance.outTime,
      "location": attendance.location ?? "Unknown",
      "status": attendance.status,
    };


    try {
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print("✅ Attendance synced successfully: ${response.body}");
        return true; // Success
      } else {
        print("❌ Failed to sync attendance: ${response.statusCode}");
        print("Response: ${response.body}");
        return false; // Sync failed
      }
    } catch (e) {
      print("❌ Exception while syncing attendance: $e");
      return false; // Sync failed due to exception
    }
  }


}
