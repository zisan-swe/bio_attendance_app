import 'dart:convert';
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
import '../../db/database_helper.dart';

class WorkerEditPage extends StatefulWidget {
  final EmployeeModel employee;

  const WorkerEditPage({Key? key, required this.employee}) : super(key: key);

  @override
  State<WorkerEditPage> createState() => _WorkerEditPageState();
}

class _WorkerEditPageState extends State<WorkerEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _fingerSvc = FingerprintService();

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

  /// Up to 5 templates per finger — stored as JSON array in finger_info1..10
  late Map<String, List<String>> fingerTemplates;

  @override
  void initState() {
    super.initState();

    employee = widget.employee;

    nameController = TextEditingController(text: employee.name);
    emailController = TextEditingController(text: employee.email);
    codeController = TextEditingController(text: employee.employeeNo);
    nidController = TextEditingController(text: employee.nid);
    dailyWagesController =
        TextEditingController(text: employee.dailyWages.toStringAsFixed(2));
    phoneController = TextEditingController(text: employee.phone);
    fatherController = TextEditingController(text: employee.fatherName);
    motherController = TextEditingController(text: employee.motherName);
    dobController = TextEditingController(text: employee.dob);
    joiningController = TextEditingController(text: employee.joiningDate);

    _profileImage =
    employee.imagePath.isNotEmpty ? File(employee.imagePath) : null;

    List<String> _decode(String s) {
      if (s.isEmpty) return [];
      try {
        final d = jsonDecode(s);
        if (d is List) {
          return d
              .map((e) => (e ?? '').toString())
              .where((e) => e.isNotEmpty)
              .toList();
        }
      } catch (_) {
        if (s.isNotEmpty) return [s]; // legacy single template
      }
      return [];
    }

    fingerTemplates = {
      'Left Thumb': _decode(employee.fingerInfo1),
      'Left Index': _decode(employee.fingerInfo2),
      'Left Middle': _decode(employee.fingerInfo3),
      'Left Ring': _decode(employee.fingerInfo4),
      'Left Little': _decode(employee.fingerInfo5),
      'Right Thumb': _decode(employee.fingerInfo6),
      'Right Index': _decode(employee.fingerInfo7),
      'Right Middle': _decode(employee.fingerInfo8),
      'Right Ring': _decode(employee.fingerInfo9),
      'Right Little': _decode(employee.fingerInfo10),
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

  // -------------------- Finger enrollment (5 samples, auto) --------------------

  Future<void> _enrollFinger(String fingerName) async {
    const totalSamples = 5;
    int step =
    (fingerTemplates[fingerName] ?? const []).length.clamp(0, totalSamples);
    bool cancelled = false;
    bool _autoStarted = false;

    final messengerKey = GlobalKey<ScaffoldMessengerState>();
    String statusText = 'Place your ${fingerName.toLowerCase()} on the sensor';
    DateTime nextSnackAllowed = DateTime.now(); // throttle SnackBars

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setStateSB) {
          Future<void> _startAuto() async {
            if (_autoStarted) return;
            _autoStarted = true;

            while (step < totalSamples && !cancelled) {
              try {
                final tpl = await _fingerSvc.scanFingerprint();

                // DB duplicate check to block saving other person's print
                final existing = await DatabaseHelper.instance
                    .getEmployeeByFingerprint(tpl, threshold: 70.0);

                if (existing != null && existing.id != widget.employee.id) {
                  if (DateTime.now().isAfter(nextSnackAllowed)) {
                    messengerKey.currentState?.showSnackBar(
                      SnackBar(
                        content: Text(
                            '⚠️ Duplicate! Already registered to ${existing.name} (ID: ${existing.employeeNo}).'),
                        behavior: SnackBarBehavior.floating,
                        margin:
                        const EdgeInsets.fromLTRB(16, 16, 16, 0), // top
                        showCloseIcon: true,
                        backgroundColor: const Color(0xFFB00020),
                      ),
                    );
                    nextSnackAllowed =
                        DateTime.now().add(const Duration(seconds: 2));
                  }
                  await Future.delayed(const Duration(milliseconds: 900));
                  continue;
                }

                final list = fingerTemplates[fingerName]!;
                if (!list.contains(tpl)) {
                  list.add(tpl);
                  setStateSB(() {
                    step = list.length;
                    statusText =
                    'Captured $step/$totalSamples • lift & place again';
                  });
                }

                await Future.delayed(const Duration(milliseconds: 700));
              } catch (e) {
                final msg = e.toString();
                final isEmpty = msg.contains('CAPTURE_EMPTY') ||
                    msg.contains('No finger image');

                if (isEmpty) {
                  setStateSB(() {
                    statusText =
                    'No image detected • press firmly & cover the sensor';
                  });
                } else {
                  if (DateTime.now().isAfter(nextSnackAllowed)) {
                    messengerKey.currentState?.showSnackBar(
                      SnackBar(
                        content: Text('⚠️ Capture failed: $msg'),
                        behavior: SnackBarBehavior.floating,
                        margin:
                        const EdgeInsets.fromLTRB(16, 16, 16, 0), // top
                        showCloseIcon: true,
                      ),
                    );
                    nextSnackAllowed =
                        DateTime.now().add(const Duration(seconds: 2));
                  }
                }
                await Future.delayed(const Duration(milliseconds: 700));
              }
            }

            if (!cancelled) Navigator.of(ctx).pop();
          }

          WidgetsBinding.instance.addPostFrameCallback((_) => _startAuto());

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
                        Row(
                          children: [
                            IconButton(
                              onPressed: () {
                                cancelled = true;
                                Navigator.of(ctx).pop();
                              },
                              icon: const Icon(Icons.close,
                                  color: Colors.white),
                              tooltip: 'Cancel',
                            ),
                            const Spacer(),
                            const SizedBox(width: 48),
                          ],
                        ),
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
                              style: const TextStyle(
                                  color: Colors.yellowAccent),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 28),
                            const Icon(Icons.fingerprint,
                                size: 132, color: Colors.white70),
                            const SizedBox(height: 28),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(5, (i) {
                                final filled = i < step;
                                return AnimatedContainer(
                                  duration:
                                  const Duration(milliseconds: 250),
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 6),
                                  width: 14,
                                  height: 14,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: filled
                                        ? Colors.white
                                        : Colors.white24,
                                  ),
                                );
                              }),
                            ),
                            const SizedBox(height: 10),
                            Text('Sample $step/5',
                                style:
                                const TextStyle(color: Colors.white70)),
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
        });
      },
    );

    if (!mounted) return;
    setState(() {}); // refresh finger buttons (progress dots)
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
              content: Text(
                  '⚠️ Duplicate fingerprint detected for ${existing.name} (ID: ${existing.employeeNo}).'),
            ),
          );
          return true;
        }
      }
    }
    return false;
  }

  // -------------------- Save / Update --------------------

  Future<void> _updateEmployee() async {
    if (!_formKey.currentState!.validate()) return;

    // Block if any duplicate detected
    if (await _hasDuplicateFingerInDB()) return;

    final provider = Provider.of<EmployeeProvider>(context, listen: false);
    final dailyWages = double.tryParse(dailyWagesController.text.trim());

    if (dailyWages == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Invalid Daily Wages')),
      );
      return;
    }

    String enc(String key) => jsonEncode(fingerTemplates[key] ?? const []);

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

      // Persist JSON arrays (5 samples max per finger)
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
    );

    dev.log(
        'Update finger samples — LThumb: ${fingerTemplates['Left Thumb']?.length}, RThumb: ${fingerTemplates['Right Thumb']?.length}',
        name: 'WorkerEditPage');

    await provider.updateEmployee(updated);

    // Optional: sync to API (kept consistent with your flow)
    try {
      await ApiService.fetchAndUpdateFingers(
        employeeNo: updated.employeeNo,
        existingEmployee: updated,
        provider: provider,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Worker & Finger Data Updated')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('⚠ Updated locally but API failed: $e')),
      );
    }
  }

  // -------------------- UI helpers --------------------

  Widget _buildField(
      String label,
      TextEditingController controller,
      IconData icon, {
        bool isRequired = true,
        TextInputType? type,
      }) {
    return TextFormField(
      controller: controller,
      keyboardType: type ?? TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
      validator: isRequired
          ? (val) => val == null || val.trim().isEmpty ? 'Enter $label' : null
          : null,
    );
  }

  /// ✅ FIXED: add isRequired
  Widget _buildFieldPhone(
      String label,
      TextEditingController controller,
      IconData icon, {
        bool isRequired = true,
      }) {
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
        // Allow empty if not required
        if (!isRequired) return null;
        if (value == null || value.trim().isEmpty) {
          return 'Enter $label';
        }
        if (!RegExp(r'^\d{11}$').hasMatch(value)) {
          return 'Phone number must be exactly 11 digits';
        }
        return null;
      },
    );
  }

  /// ✅ FIXED: add isRequired
  Widget _buildDateField(
      String label,
      TextEditingController controller, {
        bool isRequired = true,
      }) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      onTap: () => _selectDate(context, controller),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.calendar_month),
        border: const OutlineInputBorder(),
      ),
      validator: (val) {
        if (!isRequired) return null;
        return val == null || val.trim().isEmpty ? 'Select $label' : null;
      },
    );
  }

  /// Button that opens the auto-capture dialog and shows 5-dot progress
  Widget _buildFingerButton(String fingerName) {
    final count = (fingerTemplates[fingerName] ?? const []).length;
    final done = count >= 5;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: ElevatedButton(
        onPressed: () => _enrollFinger(fingerName),
        style: ElevatedButton.styleFrom(
          backgroundColor: done ? Colors.green : Colors.grey[300],
          foregroundColor: done ? Colors.white : Colors.black,
          minimumSize: const Size(140, 60),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(done ? Icons.fingerprint : Icons.fingerprint_outlined,
                    size: 18),
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
                    color: i < count
                        ? (done ? Colors.white : Colors.black)
                        : Colors.black26,
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

  Widget _buildBiometricSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Biometric Fingers',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 12),
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
                  child:
                  _profileImage == null ? const Icon(Icons.camera_alt) : null,
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
              _buildField('Worker NID', nidController, Icons.badge,
                  isRequired: false),
              const SizedBox(height: 12),
              _buildField('Daily Wages', dailyWagesController, Icons.money,
                  type: TextInputType.number),
              const SizedBox(height: 12),
              _buildFieldPhone('Phone', phoneController, Icons.phone,
                  isRequired: false),
              const SizedBox(height: 12),
              _buildField('Father\'s Name', fatherController, Icons.person),
              const SizedBox(height: 12),
              _buildField('Mother\'s Name', motherController, Icons.person,
                  isRequired: false),
              const SizedBox(height: 12),
              _buildDateField('Date of Birth', dobController,
                  isRequired: false),
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
