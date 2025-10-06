import 'dart:io';
import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../models/employee_model.dart';
import '../../providers/employee_provider.dart';
import '../../services/api_service.dart';
import '../../services/fingerprint_service.dart';

class WorkerEditPage extends StatefulWidget {
  final EmployeeModel employee;

  const WorkerEditPage({Key? key, required this.employee}) : super(key: key);

  @override
  State<WorkerEditPage> createState() => _WorkerEditPageState();
}

class _WorkerEditPageState extends State<WorkerEditPage> {
  final _formKey = GlobalKey<FormState>();
  final service = FingerprintService();

  late EmployeeModel employee;

  late TextEditingController nameController;
  late TextEditingController emailController;
  late TextEditingController codeController;
  late TextEditingController nidController;
  late TextEditingController dailyWagesController;
  late TextEditingController phoneController;
  late TextEditingController fatherController;
  late TextEditingController motherController;
  late TextEditingController dobController;
  late TextEditingController joiningController;

  File? _profileImage;

  final Map<String, bool> fingerScanStatus = {
    'Left Thumb': false,
    'Left Index': false,
    'Left Middle': false,
    'Left Ring': false,
    'Left Little': false,
    'Right Thumb': false,
    'Right Index': false,
    'Right Middle': false,
    'Right Ring': false,
    'Right Little': false,
  };

  @override
  void initState() {
    super.initState();

    employee = widget.employee;

    nameController = TextEditingController(text: employee.name);
    emailController = TextEditingController(text: employee.email);
    codeController = TextEditingController(text: employee.employeeNo);
    nidController = TextEditingController(text: employee.nid);
    dailyWagesController = TextEditingController(
        text: employee.dailyWages.toStringAsFixed(2));
    phoneController = TextEditingController(text: employee.phone);
    fatherController = TextEditingController(text: employee.fatherName);
    motherController = TextEditingController(text: employee.motherName);
    dobController = TextEditingController(text: employee.dob);
    joiningController = TextEditingController(text: employee.joiningDate);

    _profileImage =
    employee.imagePath.isNotEmpty ? File(employee.imagePath) : null;

    final fingerValues = [
      employee.fingerInfo1,
      employee.fingerInfo2,
      employee.fingerInfo3,
      employee.fingerInfo4,
      employee.fingerInfo5,
      employee.fingerInfo6,
      employee.fingerInfo7,
      employee.fingerInfo8,
      employee.fingerInfo9,
      employee.fingerInfo10,
    ];

    final keys = fingerScanStatus.keys.toList();
    for (int j = 0; j < keys.length; j++) {
      fingerScanStatus[keys[j]] = fingerValues[j].isNotEmpty;
    }
  }

  Future<void> _scanFinger(String fingerName) async {
    try {
      final updatedEmp = await service.scanAndUpdateFinger(
        employee: employee,
        fingerName: fingerName,
      );

      setState(() {
        employee = updatedEmp;
        fingerScanStatus[fingerName] = true;
      });

      dev.log(
        'Scanned $fingerName — length: ${_getFingerTemplateByName(fingerName).length}',
        name: 'WorkerEditPage',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$fingerName scanned successfully ✅')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error scanning $fingerName: $e')),
      );
    }
  }

  String _getFingerTemplateByName(String fingerName) {
    switch (fingerName) {
      case 'Left Thumb':
        return employee.fingerInfo1;
      case 'Left Index':
        return employee.fingerInfo3;
      case 'Left Middle':
        return employee.fingerInfo5;
      case 'Left Ring':
        return employee.fingerInfo7;
      case 'Left Little':
        return employee.fingerInfo9;
      case 'Right Thumb':
        return employee.fingerInfo2;
      case 'Right Index':
        return employee.fingerInfo4;
      case 'Right Middle':
        return employee.fingerInfo6;
      case 'Right Ring':
        return employee.fingerInfo8;
      case 'Right Little':
        return employee.fingerInfo10;
      default:
        return '';
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () async {
                Navigator.pop(context);
                final picked =
                await picker.pickImage(source: ImageSource.camera);
                if (picked != null) {
                  setState(() => _profileImage = File(picked.path));
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () async {
                Navigator.pop(context);
                final picked =
                await picker.pickImage(source: ImageSource.gallery);
                if (picked != null) {
                  setState(() => _profileImage = File(picked.path));
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate(
      BuildContext context, TextEditingController controller) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(controller.text) ?? DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      controller.text = DateFormat('yyyy-MM-dd').format(picked);
    }
  }

  Future<void> _updateEmployee() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = Provider.of<EmployeeProvider>(context, listen: false);
    final dailyWages = double.tryParse(dailyWagesController.text.trim());

    if (dailyWages == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Invalid Daily Wages')),
      );
      return;
    }

    final updated = employee.copyWith(
      name: nameController.text.trim(),
      email: emailController.text.trim(),
      employeeNo: codeController.text.trim(),
      nid: nidController.text.trim(),
      dailyWages: dailyWages,
      phone: phoneController.text.trim(),
      fatherName: fatherController.text.trim(),
      motherName: motherController.text.trim(),
      dob: dobController.text.trim(),
      joiningDate: joiningController.text.trim(),
      imagePath: _profileImage?.path ?? employee.imagePath,
    );

    dev.log('fingerInfo1 length: ${updated.fingerInfo1.length}',
        name: 'WorkerEditPage');
    dev.log('fingerInfo2 length: ${updated.fingerInfo2.length}',
        name: 'WorkerEditPage');

    await provider.updateEmployee(updated);

    final syncedEmployee = await ApiService.fetchAndUpdateFingers(
      employeeNo: updated.employeeNo,
      existingEmployee: updated,
      provider: provider,
    );

    if (syncedEmployee != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Worker & Finger Data Updated Successfully')),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠ Worker updated locally, but finger sync failed')),
      );
    }
  }

  Widget _buildField(
      String label, TextEditingController controller, IconData icon,
      {bool isRequired = true, TextInputType? type}) {
    return TextFormField(
      controller: controller,
      keyboardType: type ?? TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
      validator: isRequired
          ? (val) =>
      val == null || val.trim().isEmpty ? 'Enter $label' : null
          : null,
    );
  }

  Widget _buildFieldPhone(
      String label, TextEditingController controller, IconData icon) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.phone,
      maxLength: 11,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
        counterText: '',
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) return 'Enter $label';
        if (!RegExp(r'^\d{11}$').hasMatch(value)) {
          return 'Phone number must be exactly 11 digits';
        }
        return null;
      },
    );
  }

  Widget _buildDateField(String label, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      onTap: () => _selectDate(context, controller),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.calendar_month),
        border: const OutlineInputBorder(),
      ),
      validator: (val) =>
      val == null || val.trim().isEmpty ? 'Select $label' : null,
    );
  }

  Widget _buildFingerButton(String label) {
    final isScanned = fingerScanStatus[label] ?? false;
    return ElevatedButton(
      onPressed: () => _scanFinger(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: isScanned ? Colors.green : Colors.grey[300],
        foregroundColor: isScanned ? Colors.white : Colors.black,
        minimumSize: const Size(130, 40),
      ),
      child: Text(label.split(' ').last),
    );
  }

  Widget _buildBiometricSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Biometric Fingers',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Column(
              children: [
                const Text('Left Hand'),
                _buildFingerButton('Left Thumb'),
                _buildFingerButton('Left Index'),
                _buildFingerButton('Left Middle'),
                _buildFingerButton('Left Ring'),
                _buildFingerButton('Left Little'),
              ],
            ),
            Column(
              children: [
                const Text('Right Hand'),
                _buildFingerButton('Right Thumb'),
                _buildFingerButton('Right Index'),
                _buildFingerButton('Right Middle'),
                _buildFingerButton('Right Ring'),
                _buildFingerButton('Right Little'),
              ],
            ),
          ],
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
      AppBar(title: const Text('Edit Worker'), backgroundColor: Colors.blueGrey),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage:
                  _profileImage != null ? FileImage(_profileImage!) : null,
                  backgroundColor: Colors.grey[300],
                  child: _profileImage == null
                      ? const Icon(Icons.camera_alt)
                      : null,
                ),
              ),
              const SizedBox(height: 12),
              _buildField('Worker Name', nameController, Icons.person),
              const SizedBox(height: 12),
              _buildField('Email', emailController, Icons.email,
                  isRequired: false, type: TextInputType.emailAddress),
              const SizedBox(height: 12),
              _buildField('Worker ID', codeController, Icons.badge),
              const SizedBox(height: 12),
              _buildField('Worker NID', nidController, Icons.badge,isRequired: false),
              const SizedBox(height: 12),
              _buildField('Daily Wages', dailyWagesController, Icons.money,
                  type: TextInputType.number),
              const SizedBox(height: 12),
              _buildFieldPhone('Phone', phoneController, Icons.phone),
              const SizedBox(height: 12),
              _buildField('Father\'s Name', fatherController, Icons.person),
              const SizedBox(height: 12),
              _buildField('Mother\'s Name', motherController, Icons.person),
              const SizedBox(height: 12),
              _buildDateField('Date of Birth', dobController),
              const SizedBox(height: 12),
              _buildDateField('Joining Date', joiningController),
              const SizedBox(height: 20),
              _buildBiometricSection(),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _updateEmployee,
                  icon: const Icon(Icons.update),
                  label: const Text('Update Worker'),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
