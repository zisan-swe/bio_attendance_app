import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class WorkerCreatePage extends StatefulWidget {
  @override
  _WorkerCreatePageState createState() => _WorkerCreatePageState();
}

class _WorkerCreatePageState extends State<WorkerCreatePage> {
  final _formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final codeController = TextEditingController();
  final phoneController = TextEditingController();
  final fatherController = TextEditingController();
  final motherController = TextEditingController();
  final dobController = TextEditingController();
  final joiningController = TextEditingController();
  final fingerController = TextEditingController();

  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1990),
      firstDate: DateTime(1950),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        controller.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      Navigator.pop(context, {
        'name': nameController.text.trim(),
        'email': emailController.text.trim(),
        'worker_code': codeController.text.trim(),
        'phone': phoneController.text.trim(),
        'father_name': fatherController.text.trim(),
        'mother_name': motherController.text.trim(),
        'dob': dobController.text.trim(),
        'joining_date': joiningController.text.trim(),
        'finger_info': fingerController.text.trim(),
      });
    }
  }

  Widget _buildInputField(String label, TextEditingController controller, IconData icon) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
      validator: (val) => val == null || val.trim().isEmpty ? 'Enter $label' : null,
    );
  }

  Widget _buildDateField(String label, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      onTap: () => _selectDate(context, controller),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.calendar_today),
        border: const OutlineInputBorder(),
      ),
      validator: (val) => val == null || val.trim().isEmpty ? 'Select $label' : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Worker'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isWide ? screenWidth * 0.1 : 16,
          vertical: 20,
        ),
        child: Form(
          key: _formKey,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: Column(
                children: [
                  Wrap(
                    runSpacing: 20,
                    spacing: 20,
                    children: [
                      SizedBox(
                        width: isWide ? 400 : double.infinity,
                        child: _buildInputField('Worker Name', nameController, Icons.person),
                      ),
                      SizedBox(
                        width: isWide ? 400 : double.infinity,
                        child: _buildInputField('Worker Email', emailController, Icons.email),
                      ),
                      SizedBox(
                        width: isWide ? 400 : double.infinity,
                        child: _buildInputField('Worker ID', codeController, Icons.code),
                      ),
                      SizedBox(
                        width: isWide ? 400 : double.infinity,
                        child: _buildInputField('Phone Number', phoneController, Icons.phone),
                      ),
                      SizedBox(
                        width: isWide ? 400 : double.infinity,
                        child: _buildInputField('Father\'s Name', fatherController, Icons.man),
                      ),
                      SizedBox(
                        width: isWide ? 400 : double.infinity,
                        child: _buildInputField('Mother\'s Name', motherController, Icons.woman),
                      ),
                      SizedBox(
                        width: isWide ? 400 : double.infinity,
                        child: _buildDateField('Date of Birth', dobController),
                      ),
                      SizedBox(
                        width: isWide ? 400 : double.infinity,
                        child: _buildDateField('Joining Date', joiningController),
                      ),
                      SizedBox(
                        width: isWide ? 400 : double.infinity,
                        child: _buildInputField('Finger Info', fingerController, Icons.fingerprint),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _save,
                      icon: const Icon(Icons.save),
                      label: const Text('Save Worker'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
