import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/employee_provider.dart';
import '../../models/employee_model.dart';
import 'employee_create_page.dart';

class EmployeeListPage extends StatelessWidget {
  const EmployeeListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Employee List'),
        centerTitle: true,
      ),
      body: Consumer<EmployeeProvider>(
        builder: (context, provider, child) {
          final employees = provider.employees;

          if (employees.isEmpty) {
            return const Center(child: Text('No employees found.'));
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: employees.length,
                itemBuilder: (context, index) {
                  final employee = employees[index];
                  return Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 4,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      title: Text(employee.name),
                      subtitle: Text('Employee ID: ${employee.employeeNo}'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        // You can add navigation to detail/edit page here
                      },
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => EmployeeCreatePage()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Employee'),
      ),
    );
  }
}
