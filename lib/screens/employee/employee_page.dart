import 'dart:io';
import 'package:flutter/material.dart';
import 'employee_create_page.dart';
import '../../models/employee_model.dart';
import '../../db/database_helper.dart';
import 'employee_edit_page.dart';
import 'employee_details.dart';

class EmployeePage extends StatefulWidget {
  const EmployeePage({super.key});

  @override
  _EmployeePageState createState() => _EmployeePageState();
}

class _EmployeePageState extends State<EmployeePage> {
  List<EmployeeModel> employees = [];
  Map<int, File> _profileImages = {};
  bool _isLoading = true; // ✅ loading state

  @override
  void initState() {
    super.initState();
    _loadEmployees('Wages'); // default type load
  }

  Future<void> _loadEmployees(String employeeType) async {
    setState(() => _isLoading = true);
    try {
      final localEmployees = await DatabaseHelper.instance.getAllEmployees(employeeType: employeeType);

      // profile image load
      Map<int, File> imageMap = {};
      for (var emp in localEmployees) {
        if (emp.imagePath.isNotEmpty) {
          imageMap[emp.id!] = File(emp.imagePath);
        }
      }

      setState(() {
        employees = localEmployees;
        _profileImages = imageMap;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error loading employees: $e");
      setState(() => _isLoading = false);
    }
  }

  void _navigateToCreate({EmployeeModel? employee}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EmployeeCreatePage(employee: employee),
      ),
    );

    if (result == true) {
      _loadEmployees('Wages'); // reload after create
    }
  }

  void _confirmDeleteEmployee(int id) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: const Text('Are you sure you want to delete this employee?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      _deleteEmployee(id);
    }
  }

  void _deleteEmployee(int id) async {
    try {
      await DatabaseHelper.instance.deleteEmployee(id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Employee deleted')),
      );
      _loadEmployees('Wages'); // refresh list
    } catch (e) {
      debugPrint("Delete error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Failed to delete employee')),
      );
    }
  }

  String _getEmployeeTypeLabel(String type) {
    switch (type) {
      case 'Labour':
        return 'Labour Worker';
      case 'Wages':
        return 'Wages Employee';
      case 'Staff':
        return 'Office Staff';
      default:
        return type;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Employee List'),
        backgroundColor: Colors.blueGrey,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator()) // ✅ Loading state
          : employees.isEmpty
          ? const Center(child: Text('No employees added yet.'))
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: employees.length,
        itemBuilder: (context, index) {
          final emp = employees[index];
          return Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            elevation: 4,
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EmployeeDetailsPage(employee: emp),
                  ),
                );
              },
              leading: CircleAvatar(
                radius: 30,
                backgroundImage: _profileImages[emp.id] != null
                    ? FileImage(_profileImages[emp.id]!)
                    : null,
                backgroundColor: Colors.grey[300],
                child: _profileImages[emp.id] == null
                    ? const Icon(Icons.person)
                    : null,
              ),
              title: Text(emp.name),
              subtitle: Text(
                'ID: ${emp.id} • Type: ${_getEmployeeTypeLabel(emp.employeeType)}',
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () async {
                      final updated = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              EmployeeEditPage(employee: emp),
                        ),
                      );
                      if (updated == true) {
                        _loadEmployees('Wages');
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _confirmDeleteEmployee(emp.id!),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToCreate(),
        icon: const Icon(Icons.add),
        label: const Text('Add Employee'),
      ),
    );
  }
}
