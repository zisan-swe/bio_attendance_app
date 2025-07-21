import 'package:flutter/material.dart';
import 'employee_create_page.dart';

class EmployeePage extends StatefulWidget {
  @override
  _EmployeePageState createState() => _EmployeePageState();
}

class _EmployeePageState extends State<EmployeePage> {
  List<Map<String, String>> employees = [
    {'name': 'Alice Brown', 'employee_id': 'E001'},
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
        title: Text('Employees'),
      ),
      body: employees.isEmpty
          ? Center(child: Text('No employees added yet.'))
          : ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: employees.length,
        itemBuilder: (context, index) {
          final employee = employees[index];
          return Card(
            margin: EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              leading: Icon(Icons.badge),
              title: Text(employee['name'] ?? ''),
              subtitle: Text('ID: ${employee['employee_id']}'),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToCreate,
        child: Icon(Icons.add),
        tooltip: 'Create Employee',
      ),
    );
  }
}
