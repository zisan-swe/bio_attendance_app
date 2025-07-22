import 'package:flutter/material.dart';
import '../models/employee_model.dart';
import '../db/database_helper.dart';

class EmployeeProvider with ChangeNotifier {
  List<EmployeeModel> _employees = [];

  List<EmployeeModel> get employees => _employees;

  // Load all employees from database
  Future<void> fetchEmployees() async {
    try {
      _employees = await DatabaseHelper.instance.getAllEmployees();
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching employees: $e');
    }
  }

  // Add new employee and refresh list
  Future<void> addEmployee(EmployeeModel employee) async {
    try {
      await DatabaseHelper.instance.insertEmployee(employee);
      await fetchEmployees();
    } catch (e) {
      debugPrint('Error adding employee: $e');
    }
  }

  // Update employee if ID exists
  Future<void> updateEmployee(EmployeeModel employee) async {
    try {
      if (employee.id != null) {
        await DatabaseHelper.instance.updateEmployee(employee);
        await fetchEmployees();
      }
    } catch (e) {
      debugPrint('Error updating employee: $e');
    }
  }

  // Delete employee by ID
  Future<void> deleteEmployee(int id) async {
    try {
      await DatabaseHelper.instance.deleteEmployee(id);
      await fetchEmployees();
    } catch (e) {
      debugPrint('Error deleting employee: $e');
    }
  }

  // Get employee by ID
  EmployeeModel? getEmployeeById(int id) {
    try {
      return _employees.firstWhere((e) => e.id == id, orElse: () => EmployeeModel(
        id: 0,
        name: '',
        email: '',
        employeeNo: '',
        phone: '',
        fatherName: '',
        motherName: '',
        dob: '',
        joiningDate: '',
        employeeType: 1,
        fingerInfo1: '',
        fingerInfo2: '',
        fingerInfo3: '',
        fingerInfo4: '',
        fingerInfo5: '',
        fingerInfo6: '',
        fingerInfo7: '',
        fingerInfo8: '',
        fingerInfo9: '',
        fingerInfo10: '',
        imagePath: '',
      ));
    } catch (e) {
      debugPrint('Error getting employee by ID: $e');
      return null;
    }
  }

  // Optional: Clear employee list (for logout or app reset)
  void clearEmployees() {
    _employees.clear();
    notifyListeners();
  }
}
