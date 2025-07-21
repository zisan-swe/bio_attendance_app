import 'package:flutter/material.dart';
import '../models/employee_model.dart';
import '../db/database_helper.dart';

class EmployeeProvider with ChangeNotifier {
  List<EmployeeModel> _employees = [];

  List<EmployeeModel> get employees => _employees;

  Future<void> fetchEmployees() async {
    _employees = await DatabaseHelper.instance.getAllEmployees();
    notifyListeners();
  }

  Future<void> addEmployee(EmployeeModel employee) async {
    await DatabaseHelper.instance.insertEmployee(employee);
    await fetchEmployees(); // Refresh the list
  }

  Future<void> updateEmployee(EmployeeModel employee) async {
    if (employee.id != null) {
      await DatabaseHelper.instance.updateEmployee(employee);
      await fetchEmployees(); // Refresh the list
    }
  }

  Future<void> deleteEmployee(int id) async {
    await DatabaseHelper.instance.deleteEmployee(id);
    await fetchEmployees(); // Refresh the list
  }

  EmployeeModel? getEmployeeById(int id) {
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
  }
}
