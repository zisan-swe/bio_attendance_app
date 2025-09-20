import 'package:flutter/material.dart';
import '../models/employee_model.dart';
import '../db/database_helper.dart';
import '../../services/fingerprint_service.dart'; // Import FingerprintService

class EmployeeProvider with ChangeNotifier {
  List<EmployeeModel> _employees = [];

  List<EmployeeModel> get employees => _employees;

  // 🔹 Load all employees from database
  Future<void> fetchEmployees(int employeeType) async {
    try {
      _employees = await DatabaseHelper.instance.getAllEmployees(employeeType: employeeType);
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching employees: $e');
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
        await fetchEmployees(employee.employeeType);
      }
    } catch (e) {
      debugPrint('Error updating employee: $e');
    }
  }

  // 🔹 Delete employee by ID
  Future<void> deleteEmployee(int id, int employeeType) async {
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

  // 🔹 Get employee by fingerprint (delegates to FingerprintService)
  Future<EmployeeModel?> getEmployeeByFingerprint(String scannedTemplate) async {
    try {
      // Use FingerprintService statically with all enrolled fingerprints
      final enrolledFingerprints = _getAllEnrolledFingerprints(); // Get all templates
      if (enrolledFingerprints.isEmpty) {
        debugPrint('No enrolled fingerprints available locally');
        // Fall back to DatabaseHelper
        return await DatabaseHelper.instance.getEmployeeByFingerprint(scannedTemplate, threshold: 70.0);
      }

      final verificationResult = await FingerprintService.verifyFingerprint(
        scannedTemplate: scannedTemplate,
        storedTemplates: enrolledFingerprints, // Provide required parameter
      );

      if (verificationResult['matched'] == true && (verificationResult['score'] ?? 0) >= 70.0) {
        debugPrint("✅ Matched fingerprint with score: ${verificationResult['score']}");
        final matchedEmployeeId = verificationResult['matchedEmployeeId'] as int?;
        return _getEmployeeFromLocalList(matchedEmployeeId);
      }

      // Fall back to DatabaseHelper for a full search if local match fails
      return await DatabaseHelper.instance.getEmployeeByFingerprint(scannedTemplate, threshold: 70.0);
    } catch (e) {
      debugPrint('Error matching fingerprint: $e');
      return null;
    }
  }

  // Helper to get all enrolled fingerprints from local employees
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
        if (finger != null && finger.isNotEmpty) {
          fingerprints.add(finger);
        }
      }
    }
    return fingerprints;
  }

  // Helper to get employee by ID from local list
  EmployeeModel? _getEmployeeFromLocalList(int? id) {
    if (id == null) return null;
    for (var e in _employees) {
      if (e.id == id) return e;
    }
    return null;
  }

  // 🔹 Clear all employees (e.g., on logout)
  void clearEmployees() {
    _employees.clear();
    notifyListeners();
  }
}