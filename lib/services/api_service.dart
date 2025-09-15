import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/employee_model.dart';

class ApiService {
  static const String baseUrl =
      "https://kisan.rahmangrouperp.com/api/v1";

  static Future<void> createLabour(EmployeeModel employee) async {
    final url = Uri.parse("$baseUrl/labour-create");

    final body = {
      "name": employee.name,
      "phone": employee.phone,
      "email": employee.email,
      "employee_no": employee.employeeNo,
      "nid": employee.nid,
      "daily_wages": employee.dailyWages.toString(),
      "father_name": employee.fatherName,
      "mother_name": employee.motherName,
      "dob": employee.dob,
      "joining_date": employee.joiningDate,
      "employee_type": employee.employeeType.toString(),

      // Finger data (Base64)
      "finger_info1": employee.fingerInfo1,
      "finger_info2": employee.fingerInfo2,
      "finger_info3": employee.fingerInfo3,
      "finger_info4": employee.fingerInfo4,
      "finger_info5": employee.fingerInfo5,
      "finger_info6": employee.fingerInfo6,
      "finger_info7": employee.fingerInfo7,
      "finger_info8": employee.fingerInfo8,
      "finger_info9": employee.fingerInfo9,
      "finger_info10": employee.fingerInfo10,
    };

    final headers = {
      "Content-Type": "application/json",
      // যদি auth token লাগে, এখানে যোগ করতে হবে
      // "Authorization": "Bearer YOUR_TOKEN"
    };

    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode(body),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      print("✅ Labour created successfully: ${response.body}");
    } else {
      print("❌ Failed to create labour: ${response.statusCode}");
      print("Response: ${response.body}");
      throw Exception("Failed to save labour");
    }
  }
}
