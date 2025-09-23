import 'package:flutter/material.dart';
import '../../models/employee_model.dart';
import '../../services/api_service.dart';
import 'employee_edit_page.dart';

class EmployeeListPage extends StatefulWidget {
  const EmployeeListPage({super.key});

  @override
  State<EmployeeListPage> createState() => _EmployeeListPageState();
}

class _EmployeeListPageState extends State<EmployeeListPage> {
  List<EmployeeModel> _employees = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  Future<void> _loadEmployees() async {
    setState(() => _isLoading = true);
    final list = await ApiService.fetchEmployees(code: "01", blockId: 1);
    setState(() {
      _employees = list;
      _isLoading = false;
    });
  }

  void _editEmployee(EmployeeModel employee) async {
    final updatedEmployee = await Navigator.push<EmployeeModel>(
      context,
      MaterialPageRoute(
        builder: (_) => EmployeeEditPage(employee: employee),
      ),
    );

    if (updatedEmployee != null) {
      // Update locally
      final index = _employees.indexWhere((e) => e.id == updatedEmployee.id);
      if (index != -1) {
        setState(() {
          _employees[index] = updatedEmployee;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Employee List")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _employees.isEmpty
          ? const Center(child: Text("⚠ No employees found!"))
          : ListView.builder(
        itemCount: _employees.length,
        itemBuilder: (context, index) {
          final emp = _employees[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ListTile(
              leading: CircleAvatar(
                backgroundImage: emp.imagePath.isNotEmpty
                    ? NetworkImage(emp.imagePath)
                    : null,
                child: emp.imagePath.isEmpty ? Text(emp.name[0]) : null,
              ),
              title: Text(emp.name),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Employee No: ${emp.employeeNo}"),
                  Text("Phone: ${emp.phone}"),
                  // Text("Daily Wages: ${emp.dailyWages}"),
                ],
              ),
              trailing: IconButton(
                icon: const Icon(Icons.edit, color: Colors.blue),
                onPressed: () => _editEmployee(emp),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadEmployees,
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
