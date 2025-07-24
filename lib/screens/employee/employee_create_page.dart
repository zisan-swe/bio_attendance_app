import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart'; // ✅ Needed for Provider
import '../../models/employee_model.dart';
import '../../providers/employee_provider.dart';



class EmployeeCreatePage extends StatefulWidget {
  final EmployeeModel? employee; // <-- add this

  const EmployeeCreatePage({Key? key, this.employee}) : super(key: key); // <-- add this

  @override
  _EmployeeCreatePageState createState() => _EmployeeCreatePageState();
}

class _EmployeeCreatePageState extends State<EmployeeCreatePage> {
  final _formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final codeController = TextEditingController();
  final nidController = TextEditingController();
  final dailyWagesController = TextEditingController();
  final phoneController = TextEditingController();
  final fatherController = TextEditingController();
  final motherController = TextEditingController();
  final dobController = TextEditingController();
  final joiningController = TextEditingController();

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

  // Future<void> _pickImage() async {
  //   final picker = ImagePicker();
  //   final pickedFile = await picker.pickImage(source: ImageSource.gallery);
  //
  //   if (pickedFile != null) {
  //     setState(() {
  //       _profileImage = File(pickedFile.path);
  //     });
  //   }
  // }



  Future<void> _pickImage() async {
    final picker = ImagePicker();

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Take Photo'),
                onTap: () async {
                  Navigator.pop(context); // close the sheet
                  final pickedFile = await picker.pickImage(source: ImageSource.camera);
                  if (pickedFile != null) {
                    setState(() {
                      _profileImage = File(pickedFile.path);
                    });
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () async {
                  Navigator.pop(context); // close the sheet
                  final pickedFile = await picker.pickImage(source: ImageSource.gallery);
                  if (pickedFile != null) {
                    setState(() {
                      _profileImage = File(pickedFile.path);
                    });
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }


  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2025),
      firstDate: DateTime(1950),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        controller.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  void _save() async {
    if (_formKey.currentState!.validate()) {
      final provider = Provider.of<EmployeeProvider>(context, listen: false);

      // Parse dailyWages outside the constructor

      final dailyWages = double.tryParse(dailyWagesController.text.trim());

      if (dailyWages == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid Daily Wages')),
        );
        return;
      }

      final employee = EmployeeModel(
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
        employeeType: 1, // default
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

      await provider.addEmployee(employee);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Employee Saved Successfully')),
      );

      Navigator.pop(context, true);
    }
  }



  Widget _buildInputField(String label, TextEditingController controller, IconData icon, {bool isRequired = true}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
      validator: (val) {
        if (!isRequired) return null;
        return val == null || val.trim().isEmpty ? 'Enter $label' : null;
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
        prefixIcon: const Icon(Icons.calendar_today),
        border: const OutlineInputBorder(),
      ),
      validator: (val) => val == null || val.trim().isEmpty ? 'Select $label' : null,
    );
  }

  Widget _buildFinger(String fingerName) {
    bool isScanned = fingerScanStatus[fingerName] ?? false;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            fingerScanStatus[fingerName] = !isScanned;
          });
        },
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(140, 40),
          backgroundColor: isScanned ? Colors.green : Colors.grey[300],
          foregroundColor: isScanned ? Colors.white : Colors.black,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isScanned ? Icons.fingerprint : Icons.fingerprint_outlined, size: 18),
            const SizedBox(width: 6),
            Text(fingerName.split(' ').last),
          ],
        ),
      ),
    );
  }

  Widget _buildFingerScanSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Biometric Finger Scan',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Hand
            Column(
              children: [
                const Text('Left Hand', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _buildFinger('Left Thumb'),
                _buildFinger('Left Index'),
                _buildFinger('Left Middle'),
                _buildFinger('Left Ring'),
                _buildFinger('Left Little'),
              ],
            ),

            // Hand Icon (optional visual center)
            Column(
              children: const [
                SizedBox(height: 30),
                Icon(Icons.pan_tool_alt_rounded, size: 60, color: Colors.grey),
                SizedBox(height: 10),
                Icon(Icons.pan_tool_alt_rounded, size: 60, color: Colors.grey),
              ],
            ),

            // Right Hand
            Column(
              children: [
                const Text('Right Hand', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _buildFinger('Right Thumb'),
                _buildFinger('Right Index'),
                _buildFinger('Right Middle'),
                _buildFinger('Right Ring'),
                _buildFinger('Right Little'),
              ],
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Employee'),
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
                  GestureDetector(
                    onTap: _pickImage,
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey[300],
                      backgroundImage: _profileImage != null ? FileImage(_profileImage!) : null,
                      child: _profileImage == null
                          ? const Icon(Icons.camera_alt, size: 40, color: Colors.white70)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Tap to upload profile image'),
                  const SizedBox(height: 30),
                  Wrap(
                    runSpacing: 20,
                    spacing: 20,
                    children: [
                      SizedBox(
                        width: isWide ? 400 : double.infinity,
                        child: _buildInputField('Employee Name', nameController, Icons.person),
                      ),
                      SizedBox(
                        width: isWide ? 400 : double.infinity,
                        child: _buildInputField('Employee Email', emailController, Icons.email, isRequired: false),
                      ),
                      SizedBox(
                        width: isWide ? 400 : double.infinity,
                        child: _buildInputField('Employee ID', codeController, Icons.code),
                      ),SizedBox(
                        width: isWide ? 400 : double.infinity,
                        child: _buildInputField('Employee NID', nidController, Icons.badge),
                      ),SizedBox(
                        width: isWide ? 400 : double.infinity,
                        child: _buildInputField('Employee Daily Wages', dailyWagesController, Icons.attach_money),
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
                    ],
                  ),
                  const SizedBox(height: 30),
                  _buildFingerScanSection(),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _save,
                      icon: const Icon(Icons.save),
                      label: const Text('Save Employee'),
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
