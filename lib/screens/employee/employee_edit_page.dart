// E:\Android\bio_attendance_app\lib\screens\employee\employee_edit_page.dart

import 'dart:convert';
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

class EmployeeEditPage extends StatefulWidget {
  final EmployeeModel employee;

  const EmployeeEditPage({Key? key, required this.employee}) : super(key: key);

  @override
  _EmployeeEditPageState createState() => _EmployeeEditPageState();
}

class _EmployeeEditPageState extends State<EmployeeEditPage> {
  final _formKey = GlobalKey<FormState>();
  final picker = ImagePicker();
  final _fingerSvc = FingerprintService();

  // Controllers
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

  /// Every finger stores up to 5 samples. Persisted as JSON strings.
  Map<String, List<String>> fingerTemplates = {};

  @override
  void initState() {
    super.initState();

    final emp = widget.employee;

    nameController = TextEditingController(text: emp.name);
    emailController = TextEditingController(text: emp.email);
    codeController = TextEditingController(text: emp.employeeNo);
    nidController = TextEditingController(text: emp.nid);
    dailyWagesController = TextEditingController(text: emp.dailyWages.toString());
    phoneController = TextEditingController(text: emp.phone);
    fatherController = TextEditingController(text: emp.fatherName);
    motherController = TextEditingController(text: emp.motherName);
    dobController = TextEditingController(text: emp.dob);
    joiningController = TextEditingController(text: emp.joiningDate);

    if (emp.imagePath.isNotEmpty) {
      _profileImage = File(emp.imagePath);
    }

    List<String> _decode(String s) {
      if (s.isEmpty) return [];
      try {
        final d = jsonDecode(s);
        if (d is List) {
          return d.map((e) => (e ?? '').toString()).where((e) => e.isNotEmpty).toList();
        }
      } catch (_) {
        if (s.isNotEmpty) return [s]; // legacy single template
      }
      return [];
    }

    fingerTemplates = {
      'Left Thumb': _decode(emp.fingerInfo1),
      'Left Index': _decode(emp.fingerInfo2),
      'Left Middle': _decode(emp.fingerInfo3),
      'Left Ring': _decode(emp.fingerInfo4),
      'Left Little': _decode(emp.fingerInfo5),
      'Right Thumb': _decode(emp.fingerInfo6),
      'Right Index': _decode(emp.fingerInfo7),
      'Right Middle': _decode(emp.fingerInfo8),
      'Right Ring': _decode(emp.fingerInfo9),
      'Right Little': _decode(emp.fingerInfo10),
    };
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    codeController.dispose();
    nidController.dispose();
    dailyWagesController.dispose();
    phoneController.dispose();
    fatherController.dispose();
    motherController.dispose();
    dobController.dispose();
    joiningController.dispose();
    super.dispose();
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
                  final pickedFile = await picker.pickImage(source: ImageSource.camera);
                  if (pickedFile != null) {
                    setState(() => _profileImage = File(pickedFile.path));
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () async {
                  Navigator.pop(context);
                  final pickedFile = await picker.pickImage(source: ImageSource.gallery);
                  if (pickedFile != null) {
                    setState(() => _profileImage = File(pickedFile.path));
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<bool> _employeeNoExists(String employeeNo) async {
    final trimmed = employeeNo.trim();
    if (trimmed.isEmpty) return false;

    // Look up any employee with this employee_no
    final existing = await DatabaseHelper.instance.getEmployeeByNumber(trimmed);

    // If none found, it's unique
    if (existing == null) return false;

    // If found but it's the SAME record we're editing, allow it
    return existing.id != widget.employee.id;
  }


  /// Full-screen enrollment dialog (auto-capture + throttled errors)
  Future<void> _enrollFinger(String fingerName) async {
    const totalSamples = 5;
    int step = fingerTemplates[fingerName]!.length.clamp(0, totalSamples);
    bool cancelled = false;
    bool _autoStarted = false;

    // Popup-local SnackBar
    final messengerKey = GlobalKey<ScaffoldMessengerState>();

    // Inline status (avoid SnackBar spam on CAPTURE_EMPTY)
    String statusText = 'Place your ${fingerName.toLowerCase()} on the sensor';
    DateTime nextSnackAllowed = DateTime.now(); // throttle

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setStateSB) {
            Future<void> _startAutoCapture() async {
              if (_autoStarted) return;
              _autoStarted = true;

              while (step < totalSamples && !cancelled) {
                try {
                  final tpl = await _fingerSvc.scanFingerprint();

                  // DB duplicate check
                  final existing = await DatabaseHelper.instance
                      .getEmployeeByFingerprint(tpl, threshold: 70.0);

                  if (existing != null && existing.id != widget.employee.id) {
                    if (DateTime.now().isAfter(nextSnackAllowed)) {
                      messengerKey.currentState?.showSnackBar(
                        SnackBar(
                          content: Text(
                            '⚠️ Duplicate! Already registered to ${existing.name} (ID: ${existing.employeeNo}).',
                          ),
                          behavior: SnackBarBehavior.floating,
                          margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                          dismissDirection: DismissDirection.up,
                          showCloseIcon: true,
                          backgroundColor: const Color(0xFFB00020),
                        ),
                      );
                      nextSnackAllowed = DateTime.now().add(const Duration(seconds: 2));
                    }
                    await Future.delayed(const Duration(milliseconds: 900));
                    continue;
                  }

                  // Local unique check for this finger
                  final list = fingerTemplates[fingerName]!;
                  if (!list.contains(tpl)) {
                    list.add(tpl);
                    setStateSB(() {
                      step = list.length;
                      statusText = 'Captured $step/$totalSamples • lift & place again';
                    });
                  }

                  await Future.delayed(const Duration(milliseconds: 700));
                } catch (e) {
                  final msg = e.toString();
                  final isEmpty = msg.contains('CAPTURE_EMPTY') || msg.contains('No finger image');

                  if (isEmpty) {
                    setStateSB(() {
                      statusText = 'No image detected • press firmly and cover the sensor';
                    });
                  } else {
                    if (DateTime.now().isAfter(nextSnackAllowed)) {
                      messengerKey.currentState?.showSnackBar(
                        SnackBar(
                          content: Text('⚠️ Capture failed: $msg'),
                          behavior: SnackBarBehavior.floating,
                          margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                          dismissDirection: DismissDirection.up,
                          showCloseIcon: true,
                        ),
                      );
                      nextSnackAllowed = DateTime.now().add(const Duration(seconds: 2));
                    }
                  }

                  await Future.delayed(const Duration(milliseconds: 700));
                }
              }

              if (!cancelled) Navigator.of(ctx).pop();
            }

            WidgetsBinding.instance.addPostFrameCallback((_) => _startAutoCapture());

            return WillPopScope(
              onWillPop: () async => false,
              child: Dialog(
                insetPadding: EdgeInsets.zero,
                backgroundColor: Colors.black,
                child: ScaffoldMessenger(
                  key: messengerKey,
                  child: Scaffold(
                    backgroundColor: Colors.black,
                    body: SafeArea(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Header
                          Row(
                            children: [
                              IconButton(
                                onPressed: () {
                                  cancelled = true;
                                  Navigator.of(ctx).pop();
                                },
                                icon: const Icon(Icons.close, color: Colors.white),
                                tooltip: 'Cancel',
                              ),
                              const Spacer(),
                              const SizedBox(width: 48),
                            ],
                          ),

                          // Center area
                          Column(
                            children: [
                              const SizedBox(height: 8),
                              Text(
                                'Place your ${fingerName.toLowerCase()} on the sensor',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                statusText,
                                style: const TextStyle(color: Colors.yellow),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 28),
                              const Icon(Icons.fingerprint, size: 132, color: Colors.white70),
                              const SizedBox(height: 28),

                              // Progress Dots (5)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(5, (i) {
                                  final filled = i < step;
                                  return AnimatedContainer(
                                    duration: const Duration(milliseconds: 250),
                                    margin: const EdgeInsets.symmetric(horizontal: 6),
                                    width: 14,
                                    height: 14,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: filled ? Colors.white : Colors.white24,
                                    ),
                                  );
                                }),
                              ),
                              const SizedBox(height: 10),
                              Text('Sample $step/5', style: const TextStyle(color: Colors.white70)),
                            ],
                          ),

                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (!mounted) return;
    if (cancelled) return;
    setState(() {}); // refresh finger buttons
  }

  /// Final duplicate check across all captured templates before update.
  Future<bool> _hasDuplicateFingerInDB() async {
    for (final samples in fingerTemplates.values) {
      for (final tpl in samples) {
        if (tpl.isEmpty) continue;
        final existing = await DatabaseHelper.instance
            .getEmployeeByFingerprint(tpl, threshold: 70.0);
        if (existing != null && existing.id != widget.employee.id) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('⚠️ Duplicate fingerprint detected for ${existing.name} (ID: ${existing.employeeNo}).'),
            ),
          );
          return true;
        }
      }
    }
    return false;
  }

  Future<void> _updateEmployee() async {
    if (!_formKey.currentState!.validate()) return;

    // 🔎 Guard against duplicate Employee ID
    final newEmpNo = codeController.text.trim();
    if (await _employeeNoExists(newEmpNo)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Employee ID already exists. Please use a different ID.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Block update if any duplicate fingerprint exists
    if (await _hasDuplicateFingerInDB()) return;

    final provider = Provider.of<EmployeeProvider>(context, listen: false);
    final dailyWages = double.tryParse(dailyWagesController.text.trim()) ?? 0.0;

    String enc(String key) => jsonEncode(fingerTemplates[key] ?? const []);

    final employee = EmployeeModel(
      id: widget.employee.id,
      name: nameController.text.trim(),
      email: emailController.text.trim(),
      employeeNo: newEmpNo, // <-- use the trimmed, validated ID
      nid: nidController.text.trim(),
      dailyWages: dailyWages,
      phone: phoneController.text.trim(),
      fatherName: fatherController.text.trim(),
      motherName: motherController.text.trim(),
      dob: dobController.text.trim(),
      joiningDate: joiningController.text.trim(),
      employeeType: widget.employee.employeeType,
      companyId: widget.employee.companyId,
      fingerInfo1: enc('Left Thumb'),
      fingerInfo2: enc('Left Index'),
      fingerInfo3: enc('Left Middle'),
      fingerInfo4: enc('Left Ring'),
      fingerInfo5: enc('Left Little'),
      fingerInfo6: enc('Right Thumb'),
      fingerInfo7: enc('Right Index'),
      fingerInfo8: enc('Right Middle'),
      fingerInfo9: enc('Right Ring'),
      fingerInfo10: enc('Right Little'),
      imagePath: _profileImage?.path ?? '',
    );

    await provider.updateEmployee(employee);

    try {
      await ApiService.createLabour(employee.toJson());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Employee updated & uploaded to API')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('⚠️ Updated locally but API failed: $e')),
      );
    }

    if (mounted) Navigator.pop(context, true);
  }


  // ---------- UI helpers ----------

  Widget _buildInputField(
      String label,
      TextEditingController controller,
      IconData icon, {
        bool isRequired = true,
      }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        label: RichText(
          text: TextSpan(
            text: label,
            style: const TextStyle(color: Colors.black, fontSize: 16),
            children: isRequired
                ? const [
              TextSpan(
                text: ' *',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
            ]
                : [],
          ),
        ),
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
      validator: (val) {
        if (!isRequired) return null;
        return val == null || val.trim().isEmpty ? 'Enter $label' : null;
      },
    );
  }

  Widget _buildDateField(
      String label,
      TextEditingController controller, {
        bool isRequired = true,
      }) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      onTap: () async {
        final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: DateTime.tryParse(controller.text) ?? DateTime(2025),
          firstDate: DateTime(1950),
          lastDate: DateTime(2100),
        );
        if (picked != null) {
          setState(() => controller.text = DateFormat('yyyy-MM-dd').format(picked));
        }
      },
      decoration: InputDecoration(
        label: RichText(
          text: TextSpan(
            text: label,
            style: const TextStyle(color: Colors.black, fontSize: 16),
            children: isRequired
                ? const [
              TextSpan(
                text: ' *',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
            ]
                : [],
          ),
        ),
        prefixIcon: const Icon(Icons.calendar_today),
        border: const OutlineInputBorder(),
      ),
      validator: (val) {
        if (!isRequired) return null;
        return val == null || val.trim().isEmpty ? 'Select $label' : null;
      },
    );
  }

  /// Finger button with 5-dot progress + opens enrollment dialog
  Widget _buildFinger(String fingerName) {
    final count = (fingerTemplates[fingerName] ?? const []).length;
    final done = count >= 5;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: ElevatedButton(
        onPressed: () => _enrollFinger(fingerName),
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(140, 60),
          backgroundColor: done ? Colors.green : Colors.grey[300],
          foregroundColor: done ? Colors.white : Colors.black,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(done ? Icons.fingerprint : Icons.fingerprint_outlined, size: 18),
                const SizedBox(width: 4),
                Text(fingerName.split(' ').last),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                5,
                    (i) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: i < count ? (done ? Colors.white : Colors.black) : Colors.black26,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFingerScanSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Biometric Finger Scan',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            Column(
              children: const [
                SizedBox(height: 30),
                Icon(Icons.pan_tool_alt_rounded, size: 60, color: Colors.grey),
                SizedBox(height: 10),
                Icon(Icons.pan_tool_alt_rounded, size: 60, color: Colors.grey),
              ],
            ),
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
        title: const Text('Edit Employee'),
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
                        child: _buildInputField('Employee Email', emailController, Icons.email,
                            isRequired: false),
                      ),
                      SizedBox(
                        width: isWide ? 400 : double.infinity,
                        child: _buildInputField('Employee ID', codeController, Icons.code),
                      ),
                      SizedBox(
                        width: isWide ? 400 : double.infinity,
                        child: _buildInputField('Employee NID', nidController, Icons.badge,
                            isRequired: false),
                      ),
                      SizedBox(
                        width: isWide ? 400 : double.infinity,
                        child: _buildInputField(
                            'Employee Daily Wages', dailyWagesController, Icons.attach_money),
                      ),
                      SizedBox(
                        width: isWide ? 400 : double.infinity,
                        child: _buildInputField('Phone Number', phoneController, Icons.phone,
                            isRequired: false),
                      ),
                      SizedBox(
                        width: isWide ? 400 : double.infinity,
                        child: _buildInputField('Father\'s Name', fatherController, Icons.man),
                      ),
                      SizedBox(
                        width: isWide ? 400 : double.infinity,
                        child: _buildInputField('Mother\'s Name', motherController, Icons.woman,
                            isRequired: false),
                      ),
                      SizedBox(
                        width: isWide ? 400 : double.infinity,
                        child: _buildDateField('Date of Birth', dobController, isRequired: false),
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
                      onPressed: _updateEmployee,
                      icon: const Icon(Icons.save),
                      label: const Text('Update Employee'),
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
