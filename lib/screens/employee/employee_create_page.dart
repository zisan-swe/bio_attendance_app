import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../models/employee_model.dart';
import '../../providers/employee_provider.dart';
import '../../services/fingerprint_service.dart';
import '../../services/api_service.dart';
import '../../db/database_helper.dart';

class EmployeeCreatePage extends StatefulWidget {
  final EmployeeModel? employee;

  const EmployeeCreatePage({Key? key, this.employee}) : super(key: key);

  @override
  _EmployeeCreatePageState createState() => _EmployeeCreatePageState();
}

class _EmployeeCreatePageState extends State<EmployeeCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final picker = ImagePicker();
  final _fingerSvc = FingerprintService();

  // Controllers
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
  Map<String, String> fingerTemplates = {};

  @override
  void initState() {
    super.initState();

    if (widget.employee != null) {
      final emp = widget.employee!;
      nameController.text = emp.name;
      emailController.text = emp.email;
      codeController.text = emp.employeeNo;
      nidController.text = emp.nid;
      dailyWagesController.text = emp.dailyWages.toString();
      phoneController.text = emp.phone;
      fatherController.text = emp.fatherName;
      motherController.text = emp.motherName;
      dobController.text = emp.dob;
      joiningController.text = emp.joiningDate;
      if (emp.imagePath.isNotEmpty) {
        _profileImage = File(emp.imagePath);
      }

      fingerTemplates = {
        'Left Thumb': emp.fingerInfo1,
        'Left Index': emp.fingerInfo2,
        'Left Middle': emp.fingerInfo3,
        'Left Ring': emp.fingerInfo4,
        'Left Little': emp.fingerInfo5,
        'Right Thumb': emp.fingerInfo6,
        'Right Index': emp.fingerInfo7,
        'Right Middle': emp.fingerInfo8,
        'Right Ring': emp.fingerInfo9,
        'Right Little': emp.fingerInfo10,
      };
    } else {
      // initialize empty
      fingerTemplates = {
        'Left Thumb': '',
        'Left Index': '',
        'Left Middle': '',
        'Left Ring': '',
        'Left Little': '',
        'Right Thumb': '',
        'Right Index': '',
        'Right Middle': '',
        'Right Ring': '',
        'Right Little': '',
      };
    }
  }

  Future<void> _pickImage() async {
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
                  Navigator.pop(context);
                  final pickedFile =
                  await picker.pickImage(source: ImageSource.camera);
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
                  Navigator.pop(context);
                  final pickedFile =
                  await picker.pickImage(source: ImageSource.gallery);
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

  Future<void> _selectDate(
      BuildContext context, TextEditingController controller) async {
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

  // Future<void> _scanFinger(String fingerName) async {
  //   try {
  //     final tpl = await _fingerSvc.scanFingerprint();
  //     setState(() {
  //       fingerTemplates[fingerName] = tpl;
  //     });
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text("✅ $fingerName captured")),
  //     );
  //   } catch (e) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text("❌ $fingerName failed: $e")),
  //     );
  //   }
  // }

  Future<void> _scanFinger(String fingerName) async {
    try {
      final tpl = await _fingerSvc.scanFingerprint();
      print("👉 Captured $fingerName = $tpl");  // Debugging

      setState(() {
        fingerTemplates[fingerName] = tpl;
      });

      print("👉 fingerTemplates map = $fingerTemplates"); // Debugging

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("✅ $fingerName captured")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("⚠️ $fingerName failed: $e")),
      );
    }
  }


  // void _save() async {
  //   if (_formKey.currentState!.validate()) {
  //     final provider =
  //     Provider.of<EmployeeProvider>(context, listen: false);
  //
  //     final dailyWages =
  //         double.tryParse(dailyWagesController.text.trim()) ?? 0.0;
  //
  //     final employee = EmployeeModel(
  //       id: widget.employee?.id,
  //       name: nameController.text.trim(),
  //       email: emailController.text.trim(),
  //       employeeNo: codeController.text.trim(),
  //       nid: nidController.text.trim(),
  //       dailyWages: dailyWages,
  //       phone: phoneController.text.trim(),
  //       fatherName: fatherController.text.trim(),
  //       motherName: motherController.text.trim(),
  //       dob: dobController.text.trim(),
  //       joiningDate: joiningController.text.trim(),
  //       employeeType: 1,
  //       fingerInfo1: fingerTemplates['Left Thumb'] ?? '',
  //       fingerInfo2: fingerTemplates['Left Index'] ?? '',
  //       fingerInfo3: fingerTemplates['Left Middle'] ?? '',
  //       fingerInfo4: fingerTemplates['Left Ring'] ?? '',
  //       fingerInfo5: fingerTemplates['Left Little'] ?? '',
  //       fingerInfo6: fingerTemplates['Right Thumb'] ?? '',
  //       fingerInfo7: fingerTemplates['Right Index'] ?? '',
  //       fingerInfo8: fingerTemplates['Right Middle'] ?? '',
  //       fingerInfo9: fingerTemplates['Right Ring'] ?? '',
  //       fingerInfo10: fingerTemplates['Right Little'] ?? '',
  //       imagePath: _profileImage?.path ?? '',
  //     );
  //
  //     if (widget.employee == null) {
  //       await provider.addEmployee(employee);
  //     } else {
  //       await provider.updateEmployee(employee);
  //     }
  //
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text('✅ Employee Saved Successfully')),
  //     );
  //
  //     Navigator.pop(context, true);
  //   }
  // }

  Future<void> _save() async {
    if (_formKey.currentState!.validate()) {
      final provider = Provider.of<EmployeeProvider>(context, listen: false);

      final dailyWages =
          double.tryParse(dailyWagesController.text.trim()) ?? 0.0;

      // ---- Settings থেকে company_id ফেচ ----
      final setting = await DatabaseHelper.instance.getSettingBySlug('company_id');
      final companyId = int.tryParse(setting?.value ?? '') ?? 1; // default = 1

      final employee = EmployeeModel(
        id: widget.employee?.id,
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
        employeeType: 'Wages',
        companyId:companyId,
        fingerInfo1: fingerTemplates['Left Thumb'] ?? '',
        fingerInfo2: fingerTemplates['Left Index'] ?? '',
        fingerInfo3: fingerTemplates['Left Middle'] ?? '',
        fingerInfo4: fingerTemplates['Left Ring'] ?? '',
        fingerInfo5: fingerTemplates['Left Little'] ?? '',
        fingerInfo6: fingerTemplates['Right Thumb'] ?? '',
        fingerInfo7: fingerTemplates['Right Index'] ?? '',
        fingerInfo8: fingerTemplates['Right Middle'] ?? '',
        fingerInfo9: fingerTemplates['Right Ring'] ?? '',
        fingerInfo10: fingerTemplates['Right Little'] ?? '',
        imagePath: _profileImage?.path ?? '',
      );

      if (widget.employee == null) {
        await provider.addEmployee(employee);
      } else {
        await provider.updateEmployee(employee);
      }

      // 🔹 API তে পাঠানো
      try {
        // await ApiService.createLabour(employee);
        await ApiService.createLabour(employee.toJson());
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('✅ Employee saved & uploaded to API')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('⚠️ Saved locally but API failed: $e')),
        );
      }

      Navigator.pop(context, true);
    }
  }

  Widget _buildInputField(String label, TextEditingController controller,
      IconData icon,
      {bool isRequired = true}) {
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

  Widget _buildInputFieldPhone(
      String label, TextEditingController controller, IconData icon) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.phone,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
      maxLength: 11,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your phone number';
        } else if (!RegExp(r'^\d{11}$').hasMatch(value)) {
          return 'Phone number must be exactly 11 digits';
        }
        return null;
      },
    );
  }

  Widget _buildDateField(
      String label, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      onTap: () => _selectDate(context, controller),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.calendar_today),
        border: const OutlineInputBorder(),
      ),
      validator: (val) =>
      val == null || val.trim().isEmpty ? 'Select $label' : null,
    );
  }

  Widget _buildFinger(String fingerName) {
    bool isScanned = (fingerTemplates[fingerName]?.isNotEmpty ?? false);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: ElevatedButton(
        onPressed: () => _scanFinger(fingerName),
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(140, 40),
          backgroundColor: isScanned ? Colors.green : Colors.grey[300],
          foregroundColor: isScanned ? Colors.white : Colors.black,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isScanned ? Icons.fingerprint : Icons.fingerprint_outlined,
                size: 18),
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
                const Text('Left Hand',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _buildFinger('Left Thumb'),
                _buildFinger('Left Index'),
                _buildFinger('Left Middle'),
                _buildFinger('Left Ring'),
                _buildFinger('Left Little'),
              ],
            ),

            Column(
              children: const [
                SizedBox(height: 30),
                Icon(Icons.pan_tool_alt_rounded,
                    size: 60, color: Colors.grey),
                SizedBox(height: 10),
                Icon(Icons.pan_tool_alt_rounded,
                    size: 60, color: Colors.grey),
              ],
            ),

            // Right Hand
            Column(
              children: [
                const Text('Right Hand',
                    style: TextStyle(fontWeight: FontWeight.bold)),
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
        title: Text(widget.employee == null
            ? 'Create Employee'
            : 'Edit Employee'),
        backgroundColor: Colors.blueGrey,
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
                      backgroundImage: _profileImage != null
                          ? FileImage(_profileImage!)
                          : null,
                      child: _profileImage == null
                          ? const Icon(Icons.camera_alt,
                          size: 40, color: Colors.white70)
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
                        child: _buildInputField(
                            'Employee Name', nameController, Icons.person),
                      ),
                      SizedBox(
                        width: isWide ? 400 : double.infinity,
                        child: _buildInputField(
                            'Employee Email', emailController, Icons.email,
                            isRequired: false),
                      ),
                      SizedBox(
                        width: isWide ? 400 : double.infinity,
                        child: _buildInputField(
                            'Employee ID', codeController, Icons.code),
                      ),
                      SizedBox(
                        width: isWide ? 400 : double.infinity,
                        child: _buildInputField(
                            'Employee NID', nidController, Icons.badge),
                      ),
                      SizedBox(
                        width: isWide ? 400 : double.infinity,
                        child: _buildInputField('Employee Daily Wages',
                            dailyWagesController, Icons.attach_money),
                      ),
                      SizedBox(
                        width: isWide ? 400 : double.infinity,
                        child: _buildInputFieldPhone(
                            'Phone Number', phoneController, Icons.phone),
                      ),
                      SizedBox(
                        width: isWide ? 400 : double.infinity,
                        child: _buildInputField(
                            'Father\'s Name', fatherController, Icons.man),
                      ),
                      SizedBox(
                        width: isWide ? 400 : double.infinity,
                        child: _buildInputField(
                            'Mother\'s Name', motherController, Icons.woman),
                      ),
                      SizedBox(
                        width: isWide ? 400 : double.infinity,
                        child: _buildDateField(
                            'Date of Birth', dobController),
                      ),
                      SizedBox(
                        width: isWide ? 400 : double.infinity,
                        child: _buildDateField(
                            'Joining Date', joiningController),
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
