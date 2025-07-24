import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../models/employee_model.dart';
import '../../providers/employee_provider.dart';

class WorkerEditPage extends StatefulWidget {
  final EmployeeModel employee;

  const WorkerEditPage({Key? key, required this.employee}) : super(key: key);

  @override
  State<WorkerEditPage> createState() => _WorkerEditPageState();
}

class _WorkerEditPageState extends State<WorkerEditPage> {
  final _formKey = GlobalKey<FormState>();

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

  Map<String, bool> fingerScanStatus = {
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

    final emp = widget.employee;
    nameController = TextEditingController(text: emp.name);
    emailController = TextEditingController(text: emp.email);
    codeController = TextEditingController(text: emp.employeeNo);
    nidController = TextEditingController(text: emp.nid);
    dailyWagesController = TextEditingController(text: emp.dailyWages.toStringAsFixed(2));
    phoneController = TextEditingController(text: emp.phone);
    fatherController = TextEditingController(text: emp.fatherName);
    motherController = TextEditingController(text: emp.motherName);
    dobController = TextEditingController(text: emp.dob);
    joiningController = TextEditingController(text: emp.joiningDate);
    _profileImage = emp.imagePath.isNotEmpty ? File(emp.imagePath) : null;

    // Initialize finger scan values
    final fingerValues = [
      emp.fingerInfo1, emp.fingerInfo2, emp.fingerInfo3, emp.fingerInfo4, emp.fingerInfo5,
      emp.fingerInfo6, emp.fingerInfo7, emp.fingerInfo8, emp.fingerInfo9, emp.fingerInfo10,
    ];

    fingerScanStatus.updateAll((key, _) => fingerValues.removeAt(0).isNotEmpty);
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
                final picked = await picker.pickImage(source: ImageSource.camera);
                if (picked != null) setState(() => _profileImage = File(picked.path));
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () async {
                Navigator.pop(context);
                final picked = await picker.pickImage(source: ImageSource.gallery);
                if (picked != null) setState(() => _profileImage = File(picked.path));
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
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

  void _updateEmployee() async {
    if (_formKey.currentState!.validate()) {
      final provider = Provider.of<EmployeeProvider>(context, listen: false);
      final emp = widget.employee;

      final dailyWages = double.tryParse(dailyWagesController.text.trim());

      if (dailyWages == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid Daily Wages')),
        );
        return;
      }

      final updated = emp.copyWith(
        name: nameController.text,
        email: emailController.text,
        employeeNo: codeController.text,
        nid: nidController.text,
        dailyWages: dailyWages,
        phone: phoneController.text,
        fatherName: fatherController.text,
        motherName: motherController.text,
        dob: dobController.text,
        joiningDate: joiningController.text,
        fingerInfo1: fingerScanStatus['Left Thumb']! ? '1' : '',
        fingerInfo2: fingerScanStatus['Left Index']! ? '1' : '',
        fingerInfo3: fingerScanStatus['Left Middle']! ? '1' : '',
        fingerInfo4: fingerScanStatus['Left Ring']! ? '1' : '',
        fingerInfo5: fingerScanStatus['Left Little']! ? '1' : '',
        fingerInfo6: fingerScanStatus['Right Thumb']! ? '1' : '',
        fingerInfo7: fingerScanStatus['Right Index']! ? '1' : '',
        fingerInfo8: fingerScanStatus['Right Middle']! ? '1' : '',
        fingerInfo9: fingerScanStatus['Right Ring']! ? '1' : '',
        fingerInfo10: fingerScanStatus['Right Little']! ? '1' : '',
        imagePath: _profileImage?.path ?? '',
      );

      await provider.updateEmployee(updated);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Worker Updated Successfully')),
      );
      Navigator.pop(context, true);
    }
  }

  Widget _buildField(String label, TextEditingController controller, IconData icon, {bool isRequired = true}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
      validator: isRequired ? (val) => val == null || val.trim().isEmpty ? 'Enter $label' : null : null,
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
      validator: (val) => val == null || val.trim().isEmpty ? 'Select $label' : null,
    );
  }

  Widget _buildFingerButton(String label) {
    final isScanned = fingerScanStatus[label] ?? false;
    return ElevatedButton(
      onPressed: () => setState(() => fingerScanStatus[label] = !isScanned),
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
        const Text('Biometric Fingers', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
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
    final wide = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Worker')),
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
                  backgroundImage: _profileImage != null ? FileImage(_profileImage!) : null,
                  backgroundColor: Colors.grey[300],
                  child: _profileImage == null ? const Icon(Icons.camera_alt) : null,
                ),
              ),
              const SizedBox(height: 12),
              _buildField('Worker Name', nameController, Icons.person),
              const SizedBox(height: 12),
              _buildField('Email', emailController, Icons.email, isRequired: false),
              const SizedBox(height: 12),
              _buildField('Worker ID', codeController, Icons.badge),
              const SizedBox(height: 12),
              _buildField('Worker NID', nidController, Icons.badge),
              const SizedBox(height: 12),
              _buildField('Worker Daily Wages', dailyWagesController, Icons.badge),
              const SizedBox(height: 12),
              _buildField('Phone', phoneController, Icons.phone),
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
