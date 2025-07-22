import 'package:flutter/material.dart';
import 'employee_create_page.dart';

class EmployeePage extends StatefulWidget {
  const EmployeePage({super.key});

  @override
  _EmployeePageState createState() => _EmployeePageState();
}

class _EmployeePageState extends State<EmployeePage> {
  List<Map<String, String>> employees = [
    {'name': 'Alice Brown1', 'employee_id': 'E001'},
    {'name': 'Bob Green', 'employee_id': 'E002'},
  ];

  void _addEmployee(Map<String, String> newEmployee) {
    setState(() {
      employees.add(newEmployee);
    });
  }

  void _navigateToCreate() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EmployeeCreatePage()),
    );

    if (result != null && result is Map<String, String>) {
      _addEmployee(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Employee List'),
        centerTitle: true,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (employees.isEmpty) {
            return const Center(child: Text('No employees added yet.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: employees.length,
            itemBuilder: (context, index) {
              final employee = employees[index];
              return Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 4,
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  leading: const Icon(Icons.badge),
                  title: Text(employee['name'] ?? ''),
                  subtitle: Text('ID: ${employee['employee_id']}'),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToCreate,
        icon: const Icon(Icons.add),
        label: const Text('Add Employee'),
      ),
    );
  }
}
