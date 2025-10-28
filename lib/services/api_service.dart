import 'dart:convert';
import 'package:http/http.dart' as http;
import '../db/database_helper.dart';
import '../models/attendance_model.dart';
import '../models/employee_model.dart';
import '../providers/employee_provider.dart';

class ApiService {
  static const String baseUrl = "https://bats.kisanbotanix.com/api/v1";

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
  static Future<String> createAttendance(AttendanceModel attendance) async {
    final url = Uri.parse("$baseUrl/attendance");
    final headers = {"Content-Type": "application/json"};

    final body = {
      "project_id": attendance.projectId,
      "device_id": attendance.deviceId,
      "block_id": attendance.blockId,
      "employee_no": attendance.employeeNo,
      "working_date": attendance.workingDate,
      "attendance_date": attendance.workingDate,
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

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return responseBody['message'] ?? "Attendance synced successfully!";
      } else {
        return responseBody['message'] ?? "Failed to sync attendance.";
      }
    } catch (e) {
      return "Exception occurred: $e";
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


  //// --- Fetch + Update finger data from API and sync (local + server)
  static Future<EmployeeModel?> fetchAndUpdateFingers({
    required String employeeNo,
    required EmployeeModel existingEmployee,
    required EmployeeProvider provider,
  }) async {
    final url = Uri.parse("$baseUrl/get-finger-data");
    final headers = {"Content-Type": "application/json"};

    // 🔹 Always send employee_no + all fingers
    final body = jsonEncode({
      "employee_no": employeeNo,
      "finger_info1": existingEmployee.fingerInfo1,
      "finger_info2": existingEmployee.fingerInfo2,
      "finger_info3": existingEmployee.fingerInfo3,
      "finger_info4": existingEmployee.fingerInfo4,
      "finger_info5": existingEmployee.fingerInfo5,
      "finger_info6": existingEmployee.fingerInfo6,
      "finger_info7": existingEmployee.fingerInfo7,
      "finger_info8": existingEmployee.fingerInfo8,
      "finger_info9": existingEmployee.fingerInfo9,
      "finger_info10": existingEmployee.fingerInfo10,
    });

    try {
      print("📤 Sending finger fetch request: $body");

      final response = await http.post(url, headers: headers, body: body);
      print("📥 Response: ${response.statusCode} ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // ✅ Merge new server finger data with existing
        final updatedEmployee = existingEmployee.copyWith(
          fingerInfo1: data['finger_info1'] ?? existingEmployee.fingerInfo1,
          fingerInfo2: data['finger_info2'] ?? existingEmployee.fingerInfo2,
          fingerInfo3: data['finger_info3'] ?? existingEmployee.fingerInfo3,
          fingerInfo4: data['finger_info4'] ?? existingEmployee.fingerInfo4,
          fingerInfo5: data['finger_info5'] ?? existingEmployee.fingerInfo5,
          fingerInfo6: data['finger_info6'] ?? existingEmployee.fingerInfo6,
          fingerInfo7: data['finger_info7'] ?? existingEmployee.fingerInfo7,
          fingerInfo8: data['finger_info8'] ?? existingEmployee.fingerInfo8,
          fingerInfo9: data['finger_info9'] ?? existingEmployee.fingerInfo9,
          fingerInfo10: data['finger_info10'] ?? existingEmployee.fingerInfo10,
        );

        // 1️⃣ Update locally
        await provider.updateEmployee(updatedEmployee);

        // 2️⃣ Update on server
        final serverUpdated = await updateEmployee(employeeNo);
        if (serverUpdated) {
          print("✅ Worker & Finger Data Updated Successfully");
        } else {
          print("⚠️ Worker updated locally, but finger sync failed");
        }

        return updatedEmployee;
      } else {
        print("❌ Failed to fetch finger data: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("❌ Exception fetching finger data: $e");
      return null;
    }
  }


  /// --- Update Employee + Finger Data ---
  static Future<bool> updateEmployee(String employeeNo) async {
    try {
      final existingEmployee = await DatabaseHelper.instance
          .getEmployeeByNumber(employeeNo);

      if (existingEmployee == null) {
        print("❌ No local employee found with employee_no: $employeeNo");
        return false;
      }

      final url = Uri.parse("$baseUrl/update-employee");
      final headers = {"Content-Type": "application/json"};

      final body = {
        "employee_no": employeeNo,

        // অন্য যেসব ফিল্ড পাঠাতে হবে এখানে যোগ করো
      };

      /// 👉 শুধু non-empty ফিঙ্গার ডাটা পাঠাও
      if (existingEmployee.fingerInfo1.isNotEmpty)
        body["finger_info1"] = existingEmployee.fingerInfo1;
      if (existingEmployee.fingerInfo2.isNotEmpty)
        body["finger_info2"] = existingEmployee.fingerInfo2;
      if (existingEmployee.fingerInfo3.isNotEmpty)
        body["finger_info3"] = existingEmployee.fingerInfo3;
      if (existingEmployee.fingerInfo4.isNotEmpty)
        body["finger_info4"] = existingEmployee.fingerInfo4;
      if (existingEmployee.fingerInfo5.isNotEmpty)
        body["finger_info5"] = existingEmployee.fingerInfo5;
      if (existingEmployee.fingerInfo6.isNotEmpty)
        body["finger_info6"] = existingEmployee.fingerInfo6;
      if (existingEmployee.fingerInfo7.isNotEmpty)
        body["finger_info7"] = existingEmployee.fingerInfo7;
      if (existingEmployee.fingerInfo8.isNotEmpty)
        body["finger_info8"] = existingEmployee.fingerInfo8;
      if (existingEmployee.fingerInfo9.isNotEmpty)
        body["finger_info9"] = existingEmployee.fingerInfo9;
      if (existingEmployee.fingerInfo10.isNotEmpty)
        body["finger_info10"] = existingEmployee.fingerInfo10;

      print("📤 Sending update request: ${jsonEncode(body)}");

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(body),
      );

      print("📥 Response: ${response.statusCode} ${response.body}");

      if (response.statusCode == 200) {
        print("✅ Worker & Finger Data Updated Successfully");
        return true;
      } else {
        print("⚠️ Worker updated locally, but finger sync failed");
        return false;
      }
    } catch (e) {
      print("❌ updateEmployee() Exception: $e");
      return false;
    }
  }



  /// --- Fetch Finger Data ---
  static Future<bool> fetchFingerData(String employeeNo) async {
    try {
      final existingEmployee = await DatabaseHelper.instance.getEmployeeByNumber(employeeNo);

      final url = Uri.parse("$baseUrl/get-finger-data");
      final headers = {"Content-Type": "application/json"};

      final body = {
        "employee_no": employeeNo,
      };

      /// 👉 শুধু তখনই পাঠাও যদি লোকাল ডাটা থাকে
      if (existingEmployee != null) {
        if (existingEmployee.fingerInfo1.isNotEmpty) body["finger_info1"] = existingEmployee.fingerInfo1;
        if (existingEmployee.fingerInfo2.isNotEmpty) body["finger_info2"] = existingEmployee.fingerInfo2;
        if (existingEmployee.fingerInfo3.isNotEmpty) body["finger_info3"] = existingEmployee.fingerInfo3;
        if (existingEmployee.fingerInfo4.isNotEmpty) body["finger_info4"] = existingEmployee.fingerInfo4;
        if (existingEmployee.fingerInfo5.isNotEmpty) body["finger_info5"] = existingEmployee.fingerInfo5;
        if (existingEmployee.fingerInfo6.isNotEmpty) body["finger_info6"] = existingEmployee.fingerInfo6;
        if (existingEmployee.fingerInfo7.isNotEmpty) body["finger_info7"] = existingEmployee.fingerInfo7;
        if (existingEmployee.fingerInfo8.isNotEmpty) body["finger_info8"] = existingEmployee.fingerInfo8;
        if (existingEmployee.fingerInfo9.isNotEmpty) body["finger_info9"] = existingEmployee.fingerInfo9;
        if (existingEmployee.fingerInfo10.isNotEmpty) body["finger_info10"] = existingEmployee.fingerInfo10;
      }

      print("📤 Sending finger fetch request: ${jsonEncode(body)}");

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(body),
      );

      print("📥 Response: ${response.statusCode} ${response.body}");

      if (response.statusCode == 200) {
        print("✅ Finger data synced successfully");
        return true;
      } else {
        print("⚠️ Finger sync failed");
        return false;
      }
    } catch (e) {
      print("❌ fetchFingerData() Exception: $e");
      return false;
    }
  }


}
