import 'package:flutter/material.dart';

class EmployeeCreatePage extends StatefulWidget {
  @override
  _EmployeeCreatePageState createState() => _EmployeeCreatePageState();
}

class _EmployeeCreatePageState extends State<EmployeeCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final idController = TextEditingController();

  void _save() {
    if (_formKey.currentState!.validate()) {
      Navigator.pop(context, {
        'name': nameController.text.trim(),
        'employee_id': idController.text.trim(),
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create Employee'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: nameController,
                decoration: InputDecoration(labelText: 'Employee Name'),
                validator: (val) =>
                val == null || val.isEmpty ? 'Enter employee name' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: idController,
                decoration: InputDecoration(labelText: 'Employee ID'),
                validator: (val) =>
                val == null || val.isEmpty ? 'Enter employee ID' : null,
              ),
              SizedBox(height: 30),
              ElevatedButton(
                onPressed: _save,
                child: Text('Save Employee'),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 48),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
