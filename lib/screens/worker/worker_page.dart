import 'dart:io';
import 'package:flutter/material.dart';
import 'worker_create_page.dart';
import '../../models/employee_model.dart';
import '../../db/database_helper.dart';
import 'worker_edit_page.dart';
import 'worker_details.dart';


class WorkerPage extends StatefulWidget {
  const WorkerPage({super.key});

  @override
  _WorkerPageState createState() => _WorkerPageState();
}

class _WorkerPageState extends State<WorkerPage> {
  List<EmployeeModel> employees = [];

  Map<int, File> _profileImages = { };

  @override
  void initState() {
    super.initState();
    _loadEmployees(2);
  }

  Future<void> _loadEmployees(int employeeType) async {
    try {
      final data = await DatabaseHelper.instance.getAllEmployees(employeeType: employeeType);

      // Build the profileImages map using stored image paths
      Map<int, File> imageMap = {};
      for (var emp in data) {
        if (emp.imagePath.isNotEmpty) {
          imageMap[emp.id!] = File(emp.imagePath);
        }
      }

      setState(() {
        employees = data;
        _profileImages = imageMap;
      });
    } catch (e) {
      debugPrint("Error loading employees: $e");
      // Optionally show UI error feedback
      // ScaffoldMessenger.of(context).showSnackBar(
      //   const SnackBar(content: Text('Failed to load employees')),
      // );
    }
  }


  void _navigateToCreate({EmployeeModel? employee}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WorkerCreatePage(employee: employee),
      ),
    );

    if (result == true) {
      _loadEmployees(2);
    }
  }

  void _confirmDeleteEmployee(int id) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: const Text('Are you sure you want to delete this Worker?'),
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
        const SnackBar(content: Text('✅ Worker deleted')),
      );
      _loadEmployees(2); // Refresh the list
    } catch (e) {
      debugPrint("Delete error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Failed to delete Worker')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Worker List'),
        backgroundColor: Colors.blueGrey,
        centerTitle: true,
        toolbarOpacity: 1,
        elevation: 100,
      ),
      body: employees.isEmpty
          ? const Center(child: Text('No Workers added yet.'))
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
                      builder: (_) => WorkerDetailsPage(employee: emp),
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
                    'ID: ${emp.id} • Type: ${emp.employeeType == 2 ? 'Employee' : 'Worker'}'
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
                            builder: (context) => WorkerEditPage(employee: emp),
                          ),
                        );
                        if (updated == true) {
                          _loadEmployees(2); // Refresh the list
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
        label: const Text('Add Worker'),
      ),
    );
  }
}
