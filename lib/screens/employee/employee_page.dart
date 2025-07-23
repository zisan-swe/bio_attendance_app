import 'package:flutter/material.dart';
import 'employee_create_page.dart';
import '../../models/employee_model.dart';
import '../../db/database_helper.dart';
import 'employee_edit_page.dart';

class EmployeePage extends StatefulWidget {
  const EmployeePage({super.key});

  @override
  _EmployeePageState createState() => _EmployeePageState();
}

class _EmployeePageState extends State<EmployeePage> {
  List<EmployeeModel> employees = [];

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  Future<void> _loadEmployees() async {
    try {
      final data = await DatabaseHelper.instance.getAllEmployees();
      setState(() {
        employees = data;
      });
    } catch (e) {
      debugPrint("Error loading employees: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load employees')),
      );
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
      _loadEmployees();
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
      _deleteEmployee(id); // Call the actual delete method
    }
  }

  void _deleteEmployee(int id) async {
    try {
      await DatabaseHelper.instance.deleteEmployee(id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Employee deleted')),
      );
      _loadEmployees(); // Refresh the list
    } catch (e) {
      debugPrint("Delete error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Failed to delete employee')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Employee List'),
        centerTitle: true,
      ),
      body: employees.isEmpty
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
              leading: const Icon(Icons.person_outline_outlined),
              title: Text(emp.name),
              subtitle: Text(
                  'ID: ${emp.id} • Type: ${emp.employeeType == 1 ? 'Employee' : 'Worker'}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () async {
                      final updated = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EmployeeEditPage(employee: emp),
                        ),
                      );
                      if (updated == true) {
                        _loadEmployees(); // Refresh the list
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
