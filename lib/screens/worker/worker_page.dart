import 'dart:io';
import 'package:flutter/material.dart';
import '../../models/employee_model.dart';
import '../../db/database_helper.dart';
import '../../services/api_service.dart';
import 'worker_create_page.dart';
import 'worker_edit_page.dart';
import 'worker_details.dart';

class WorkerPage extends StatefulWidget {
  const WorkerPage({super.key});

  @override
  _WorkerPageState createState() => _WorkerPageState();
}

class _WorkerPageState extends State<WorkerPage> {
  List<EmployeeModel> employees = [];
  Map<int, File> _profileImages = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEmployees('Labour');
  }

  Future<void> _loadEmployees(String employeeType) async {
    setState(() => _isLoading = true);
    try {
      // 1️⃣ Fetch local SQLite employees
      final localEmployees = await DatabaseHelper.instance.getAllEmployees(employeeType: employeeType);

      // Build profile images map
      Map<int, File> imageMap = {};
      for (var emp in localEmployees) {
        if (emp.imagePath.isNotEmpty) {
          imageMap[emp.id!] = File(emp.imagePath);
        }
      }

      // 2️⃣ Fetch API employees
      List<EmployeeModel> apiEmployees = [];
      try {
        apiEmployees = await ApiService.fetchEmployees(code: "01", blockId: 1);
      } catch (e) {
        debugPrint("API fetch error: $e");
      }

      // 3️⃣ Merge local + API employees (optional: avoid duplicates by employeeNo or id)
      final mergedEmployees = {
        for (var e in [...localEmployees, ...apiEmployees])
          e.employeeNo: e
      }.values.toList();

      setState(() {
        employees = mergedEmployees;
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
        builder: (_) => WorkerCreatePage(employee: employee),
      ),
    );

    if (result == true) {
      _loadEmployees('Labour');
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
      _deleteEmployee(id);
    }
  }

  void _deleteEmployee(int id) async {
    try {
      await DatabaseHelper.instance.deleteEmployee(id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Worker deleted')),
      );
      _loadEmployees('Labour');
    } catch (e) {
      debugPrint("Delete error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Failed to delete Worker')),
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
        title: const Text('Worker List'),
        backgroundColor: Colors.blueGrey,
        centerTitle: true,
        toolbarOpacity: 1,
        elevation: 100,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : employees.isEmpty
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
                    : emp.imagePath.isNotEmpty
                    ? NetworkImage(emp.imagePath) as ImageProvider
                    : null,
                backgroundColor: Colors.grey[300],
                child: (_profileImages[emp.id] == null && emp.imagePath.isEmpty)
                    ? const Icon(Icons.person)
                    : null,
              ),
              title: Text(emp.name),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      'ID: ${emp.id ?? '-'} • Type: ${_getEmployeeTypeLabel(emp.employeeType)}'),
                  if (emp.dailyWages > 0)
                    Text("Daily Wages: ${emp.dailyWages}"),

                ],
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
                        _loadEmployees('Labour');
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
