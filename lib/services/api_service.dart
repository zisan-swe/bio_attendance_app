import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/attendance_model.dart';
import '../models/employee_model.dart';

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

  /// --- Fetch Employee / Labour List ---
  static Future<List<EmployeeModel>> fetchEmployees({
    required String code,
    required int blockId,
  }) async {
    final url = Uri.parse("$baseUrl/labour-list?code=$code&block_id=$blockId");

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> employees = data['data'] ?? [];
        return employees.map((e) => EmployeeModel.fromJson(e)).toList();
      } else {
        print("❌ Failed to fetch employees: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      print("❌ Exception while fetching employees: $e");
      return [];
    }
  }

  /// --- Update Employee ---
  static Future<bool> updateEmployee(EmployeeModel employee) async {
    final url = Uri.parse("$baseUrl/labour-update/${employee.id}");
    final headers = {"Content-Type": "application/json"};

    try {
      final response = await http.put(
        url,
        headers: headers,
        body: jsonEncode(employee.toJson()),
      );

      if (response.statusCode == 200) {
        print("✅ Employee updated successfully: ${response.body}");
        return true;
      } else {
        print("❌ Failed to update employee: ${response.statusCode}");
        print("Response: ${response.body}");
        return false;
      }
    } catch (e) {
      print("❌ Exception while updating employee: $e");
      return false;
    }
  }





}
