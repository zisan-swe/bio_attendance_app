import 'package:flutter/material.dart';
import '../models/employee_model.dart';
import '../db/database_helper.dart';
import '../../services/fingerprint_service.dart';
import '../services/api_service.dart';

class EmployeeProvider with ChangeNotifier {
  List<EmployeeModel> _employees = [];

  List<EmployeeModel> get employees => _employees;

  // 🔹 Load employees by type (Labour, Wages, Staff)
  Future<void> fetchEmployees(String employeeType) async {
    try {
      final db = await DatabaseHelper.instance.database;

      final result = await db.query(
        'employee',
        where: 'employee_type = ?',
        whereArgs: [employeeType],
      );

      _employees = result.map((map) => EmployeeModel.fromMap(map)).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching employees by type: $e');
    }
  }

  // 🔹 Load ALL employees (no filter)
  Future<void> fetchAllEmployees() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final result = await db.query('employee'); // fetch all rows
      _employees = result.map((map) => EmployeeModel.fromMap(map)).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching all employees: $e');
    }
  }

  // 🔹 Add new employee and refresh list
  Future<void> addEmployee(EmployeeModel employee) async {
    try {
      await DatabaseHelper.instance.insertEmployee(employee);
      await fetchEmployees(employee.employeeType);
    } catch (e) {
      debugPrint('Error adding employee: $e');
    }
  }

  // 🔹 Update existing employee
  Future<void> updateEmployee(EmployeeModel employee) async {
    try {
      if (employee.id != null) {
        await DatabaseHelper.instance.updateEmployee(employee);
        await fetchEmployees(employee.employeeType); // Reload from DB
      }
    } catch (e) {
      debugPrint('Error updating employee: $e');
    }
  }

  // 🔹 Delete employee by ID
  Future<void> deleteEmployee(int id, String employeeType) async {
    try {
      await DatabaseHelper.instance.deleteEmployee(id);
      await fetchEmployees(employeeType);
    } catch (e) {
      debugPrint('Error deleting employee: $e');
    }
  }

  // 🔹 Get employee by ID
  EmployeeModel? getEmployeeById(int id) {
    try {
      for (var e in _employees) {
        if (e.id == id) return e;
      }
      return null;
    } catch (e) {
      debugPrint('Error getting employee by ID: $e');
      return null;
    }
  }

  // 🔹 Get employee by employee number
  Future<EmployeeModel?> getEmployeeByNumber(String employeeNo) async {
    try {
      for (var e in _employees) {
        if (e.employeeNo == employeeNo) return e;
      }
      return await DatabaseHelper.instance.getEmployeeByNumber(employeeNo);
    } catch (e) {
      debugPrint('Error getting employee by number: $e');
      return null;
    }
  }

  // 🔹 Get employee by fingerprint
  Future<EmployeeModel?> getEmployeeByFingerprint(String scannedTemplate) async {
    try {
      final enrolledFingerprints = _getAllEnrolledFingerprints();
      if (enrolledFingerprints.isEmpty) {
        debugPrint('No enrolled fingerprints available locally');
        return await DatabaseHelper.instance
            .getEmployeeByFingerprint(scannedTemplate, threshold: 70.0);
      }

      final verificationResult = await FingerprintService.verifyFingerprint(
        scannedTemplate: scannedTemplate,
        storedTemplates: enrolledFingerprints,
      );

      if (verificationResult['matched'] == true &&
          (verificationResult['score'] ?? 0) >= 70.0) {
        debugPrint("✅ Matched fingerprint with score: ${verificationResult['score']}");
        final matchedEmployeeId = verificationResult['matchedEmployeeId'] as int?;
        return _getEmployeeFromLocalList(matchedEmployeeId);
      }

      return await DatabaseHelper.instance
          .getEmployeeByFingerprint(scannedTemplate, threshold: 70.0);
    } catch (e) {
      debugPrint('Error matching fingerprint: $e');
      return null;
    }
  }

  // 🔹 Helper to get all enrolled fingerprints
  List<String> _getAllEnrolledFingerprints() {
    final fingerprints = <String>[];
    for (var emp in _employees) {
      final fingerList = [
        emp.fingerInfo1,
        emp.fingerInfo2,
        emp.fingerInfo3,
        emp.fingerInfo4,
        emp.fingerInfo5,
        emp.fingerInfo6,
        emp.fingerInfo7,
        emp.fingerInfo8,
        emp.fingerInfo9,
        emp.fingerInfo10,
      ];
      for (var finger in fingerList) {
        if (finger.isNotEmpty) {
          fingerprints.add(finger);
        }
      }
    }
    return fingerprints;
  }

  // 🔹 Update fingerprints from API
  Future<void> updateFingerData() async {
    // Loop through all local employees
    for (int i = 0; i < _employees.length; i++) {
      final emp = _employees[i];

      // Fetch finger data for this employee
      final updatedEmployee = await ApiService.fetchAndUpdateFingers(
        employeeNo: emp.employeeNo,
        existingEmployee: emp,
        provider: this,
      );

      // Update local list if fetched successfully
      if (updatedEmployee != null) {
        _employees[i] = updatedEmployee;
      }
    }

    // Notify listeners after all updates
    notifyListeners();
  }


  // 🔹 Helper to get employee by ID from local list
  EmployeeModel? _getEmployeeFromLocalList(int? id) {
    if (id == null) return null;
    for (var e in _employees) {
      if (e.id == id) return e;
    }
    return null;
  }

  // 🔹 Clear all employees
  void clearEmployees() {
    _employees.clear();
    notifyListeners();
  }
}
