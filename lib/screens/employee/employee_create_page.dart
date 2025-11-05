import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../models/employee_model.dart';
import '../../providers/employee_provider.dart';
import '../../services/fingerprint_service.dart';
import '../../services/api_service.dart';
import '../../db/database_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  bool _saving = false;


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

  /// Every finger stores up to 5 samples (templates).
  /// We'll persist as JSON strings into finger_info1..10.
  Map<String, List<String>> fingerTemplates = {};

  @override
  void initState() {
    super.initState();

    // Initialize finger map
    final emptyMap = <String, List<String>>{
      'Left Thumb': [],
      'Left Index': [],
      'Left Middle': [],
      'Left Ring': [],
      'Left Little': [],
      'Right Thumb': [],
      'Right Index': [],
      'Right Middle': [],
      'Right Ring': [],
      'Right Little': [],
    };

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

      // Decode finger templates for editing
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
          if (s.isNotEmpty) return [s];
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
    } else {
      fingerTemplates = emptyMap;

      // 🧠 Auto-generate new Employee ID
      generateSequentialEmployeeId().then((newId) {
        setState(() {
          codeController.text = newId;
        });
      });
    }
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

  Future<bool> _employeeNoExists(String employeeNo) async {
    final trimmed = employeeNo.trim();
    if (trimmed.isEmpty) return false;

    final existing = await DatabaseHelper.instance.getEmployeeByNumber(trimmed);

    // If creating new: any existing means duplicate
    if (widget.employee == null) {
      return existing != null;
    }

    // If editing: allow same record to keep its number
    return existing != null && existing.id != widget.employee!.id;
  }


  /// Full-screen enrollment dialog for a single finger (auto-capture).
  /// - Automatically captures up to 5 samples (no Start/Capture buttons)
  /// - Shows duplicate/error SnackBars INSIDE the popup
  /// Full-screen enrollment dialog (auto-capture + throttled errors)
  Future<void> _enrollFinger(String fingerName) async {
    const totalSamples = 5;
    int step = fingerTemplates[fingerName]!.length.clamp(0, totalSamples);
    bool cancelled = false;
    bool _autoStarted = false;

    // Popup-লোকাল SnackBar
    final messengerKey = GlobalKey<ScaffoldMessengerState>();

    // Inline status text (SnackBar স্প্যাম এড়াতে)
    String statusText = 'Place your ${fingerName.toLowerCase()} on the sensor';

    // একই SnackBar বারবার না দেখানোর জন্য throttle
    DateTime nextSnackAllowed = DateTime.now();

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
                  // ডিভাইস SDK থেকে স্ক্যান-এর জন্য অপেক্ষা
                  final tpl = await _fingerSvc.scanFingerprint();

                  // DB-level duplicate check
                  final existing = await DatabaseHelper.instance
                      .getEmployeeByFingerprint(tpl, threshold: 70.0);

                  if (existing != null && existing.id != widget.employee?.id) {
                    // Duplicate গুরুত্বপূর্ণ—তবে থ্রটল করে দেখাই
                    if (DateTime.now().isAfter(nextSnackAllowed)) {
                      messengerKey.currentState?.showSnackBar(
                        SnackBar(
                          content: Text(
                            '⚠️ Duplicate! Already registered to ${existing.name} (ID: ${existing.employeeNo}).',
                          ),
                          behavior: SnackBarBehavior.floating,
                          margin: const EdgeInsets.fromLTRB(16, 16, 16, 0), // top
                          dismissDirection: DismissDirection.up,
                          showCloseIcon: true,
                          backgroundColor: const Color(0xFFB00020),
                        ),
                      );
                      nextSnackAllowed =
                          DateTime.now().add(const Duration(seconds: 2));
                    }
                    // ইউজারকে সামান্য সময় দিন
                    await Future.delayed(const Duration(milliseconds: 900));
                    continue; // এই স্যাম্পল কাউন্ট করবেন না
                  }

                  // Local duplicate (same finger) রোধ
                  final list = fingerTemplates[fingerName]!;
                  if (!list.contains(tpl)) {
                    list.add(tpl);
                    setStateSB(() {
                      step = list.length;
                      statusText =
                      'Captured $step/$totalSamples • lift & place again';
                    });
                  }

                  // লাইট কুলডাউন – ইউজার লিফট/প্রেস করতে পারবে
                  await Future.delayed(const Duration(milliseconds: 700));
                } catch (e) {
                  final msg = e.toString();
                  final isEmpty = msg.contains('CAPTURE_EMPTY') ||
                      msg.contains('No finger image');

                  if (isEmpty) {
                    // Empty capture হলে SnackBar নয়, inline hint
                    setStateSB(() {
                      statusText =
                      'No image detected • press firmly and cover the sensor';
                    });
                  } else {
                    // অন্য error হলে থ্রটল করা SnackBar
                    if (DateTime.now().isAfter(nextSnackAllowed)) {
                      messengerKey.currentState?.showSnackBar(
                        SnackBar(
                          content: Text('⚠️ Capture failed: $msg'),
                          behavior: SnackBarBehavior.floating,
                          margin:
                          const EdgeInsets.fromLTRB(16, 16, 16, 0), // top
                          dismissDirection: DismissDirection.up,
                          showCloseIcon: true,
                        ),
                      );
                      nextSnackAllowed =
                          DateTime.now().add(const Duration(seconds: 2));
                    }
                  }

                  // টাইট লুপ এড়াতে ছোট delay
                  await Future.delayed(const Duration(milliseconds: 700));
                }
              }

              if (!cancelled) {
                Navigator.of(ctx).pop(); // done (5/5)
              }
            }

            // ডায়ালগ ভিউ রেন্ডারের পরই অটো-ক্যাপচার শুরু
            WidgetsBinding.instance
                .addPostFrameCallback((_) => _startAutoCapture());

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
                                icon: const Icon(Icons.close,
                                    color: Colors.white),
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
                                statusText, // <-- inline dynamic status
                                style: const TextStyle(color: Colors.yellow),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 28),
                              const Icon(Icons.fingerprint,
                                  size: 132, color: Colors.white70),
                              const SizedBox(height: 28),

                              // Progress Dots (5)
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
                              Text(
                                'Sample $step/5',
                                style:
                                const TextStyle(color: Colors.white70),
                              ),
                            ],
                          ),

                          // Bottom spacer (no buttons needed)
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

    if (cancelled) return;
    setState(() {}); // refresh finger buttons state after dialog closes
  }



  /// Final duplicate check across all captured templates before save.
  Future<bool> _hasDuplicateFingerInDB() async {
    for (final samples in fingerTemplates.values) {
      for (final tpl in samples) {
        if (tpl.isEmpty) continue;
        final existing = await DatabaseHelper.instance
            .getEmployeeByFingerprint(tpl, threshold: 70.0);
        if (existing != null && existing.id != widget.employee?.id) {
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

  Future<String> generateSequentialEmployeeId() async {
    final now = DateTime.now();
    final prefs = await SharedPreferences.getInstance();

    // আগের সংরক্ষিত কাউন্টার পড়া
    int lastNumber = prefs.getInt('employee_counter') ?? 0;

    // এক বাড়ানো
    lastNumber++;

    // নতুন কাউন্টার সংরক্ষণ
    await prefs.setInt('employee_counter', lastNumber);

    // তারিখ ও সময় অংশ (YYYYMMDD)
    final datePart = "${now.year}"
        "${now.month.toString().padLeft(2, '0')}"
        "${now.day.toString().padLeft(2, '0')}";

    // ৫-ডিজিটে প্যাড করা সংখ্যা
    final countPart = lastNumber.toString().padLeft(5, '0');

    // চূড়ান্ত ID
    final employeeId = "EMP${datePart}_$countPart";

    return employeeId;
  }

  void _showRequiredFieldsDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // force user to tap OK
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
          contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
          actionsPadding: const EdgeInsets.only(right: 16, bottom: 8),
          title: Row(
            children: const [
              Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 30),
              SizedBox(width: 10),
              Text(
                'Incomplete Form',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          content: const Text(
            'Please fill in all required fields marked with (*) before saving.',
            style: TextStyle(
              fontSize: 16,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.blueGrey,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Text(
                  'OK, Got it',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        );
      },
    );
  }



  Future<void> _save() async {
    // ফর্ম ভ্যালিডেশন—ফেল করলে পপআপ
    final isValid = _formKey.currentState!.validate();
    if (!isValid) {
      _showRequiredFieldsDialog(); // <- পপআপ
      return;
    }

    setState(() => _saving = true); // Loader ON
    try {
      // 🔎 Duplicate employeeNo guard
      final empNo = codeController.text.trim();
      if (await _employeeNoExists(empNo)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Employee ID already exists. Please use a different ID.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      // Block save if any duplicate fingerprint exists
      if (await _hasDuplicateFingerInDB()) return;

      final provider = Provider.of<EmployeeProvider>(context, listen: false);
      final dailyWages = double.tryParse(dailyWagesController.text.trim()) ?? 0.0;

      final setting = await DatabaseHelper.instance.getSettingBySlug('company_id');
      final companyId = int.tryParse(setting?.value ?? '') ?? 1;

      String enc(String key) => jsonEncode(fingerTemplates[key] ?? const []);

      final employee = EmployeeModel(
        id: widget.employee?.id,
        name: nameController.text.trim(),
        email: emailController.text.trim(),
        employeeNo: empNo,
        nid: nidController.text.trim(),
        dailyWages: dailyWages,
        phone: phoneController.text.trim(),
        fatherName: fatherController.text.trim(),
        motherName: motherController.text.trim(),
        dob: dobController.text.trim(),
        joiningDate: joiningController.text.trim(),
        employeeType: 'Wages',
        companyId: companyId,
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

      if (widget.employee == null) {
        await provider.addEmployee(employee);
      } else {
        await provider.updateEmployee(employee);
      }

      try {
        await ApiService.createLabour(employee.toJson());
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Employee saved & uploaded to API')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('⚠️ Saved locally but API failed: $e')),
        );
      }

      if (mounted) Navigator.pop(context, true);
    } finally {
      if (mounted) setState(() => _saving = false); // Loader OFF
    }
  }


  /// Common input field
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
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
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

  /// Optional phone field (11 digits if provided)
  Widget _buildInputFieldPhone(
      String label, TextEditingController controller, IconData icon) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.phone,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.black, fontSize: 16),
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
      maxLength: 11,
      validator: (value) {
        if (value != null && value.isNotEmpty) {
          if (!RegExp(r'^\d{11}$').hasMatch(value)) {
            return 'Phone number must be exactly 11 digits';
          }
        }
        return null;
      },
    );
  }

  /// Date field
  Widget _buildDateField(
      String label,
      TextEditingController controller, {
        bool isRequired = true,
      }) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      onTap: () async {
        DateTime initialDate = DateTime.now();

        // If the controller already has a date, try parsing it
        if (controller.text.isNotEmpty) {
          try {
            initialDate = DateFormat('yyyy-MM-dd').parse(controller.text);
          } catch (_) {
            // If parsing fails, fallback to current date
            initialDate = DateTime.now();
          }
        }

        final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: initialDate,
          firstDate: DateTime(1950),
          lastDate: DateTime(2100),
        );
        if (picked != null) {
          setState(() {
            controller.text = DateFormat('yyyy-MM-dd').format(picked);
          });
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
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
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
          minimumSize: const Size(140, 60), // increased height for 2 rows
          backgroundColor: done ? Colors.green : Colors.grey[300],
          foregroundColor: done ? Colors.white : Colors.black,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top row: icon + finger name
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(done ? Icons.fingerprint : Icons.fingerprint_outlined, size: 18),
                const SizedBox(width: 4),
                Text(fingerName.split(' ').last),
              ],
            ),

            const SizedBox(height: 6), // spacing between top and dots

            // Bottom row: 5-dot progress
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
                Icon(Icons.pan_tool_alt_rounded, size: 60, color: Colors.grey),
                SizedBox(height: 10),
                Icon(Icons.pan_tool_alt_rounded, size: 60, color: Colors.grey),
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
        title:
        Text(widget.employee == null ? 'Create Employee' : 'Edit Employee'),
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
                      _buildInputField(
                          'Employee Name', nameController, Icons.person),
                      _buildInputField(
                          'Employee Email', emailController, Icons.email,
                          isRequired: false),
             //Employee ID Field
                      // TextFormField(
                      //   controller: codeController,
                      //   readOnly: true,
                      //   decoration: const InputDecoration(
                      //     labelText: 'Employee ID (Auto)',
                      //     prefixIcon: Icon(Icons.code),
                      //     border: OutlineInputBorder(),
                      //   ),
                      // ),
                      _buildInputField(
                          'Employee NID', nidController, Icons.badge,
                          isRequired: false),
                      _buildInputField('Employee Daily Wages',
                          dailyWagesController, Icons.attach_money),
                      _buildInputFieldPhone(
                          'Phone Number', phoneController, Icons.phone),
                      _buildInputField(
                          'Father\'s Name', fatherController, Icons.man),
                      _buildInputField(
                          'Mother\'s Name', motherController, Icons.woman,
                          isRequired: false),
                      _buildDateField('Date of Birth', dobController,
                          isRequired: false),
                      _buildDateField('Joining Date', joiningController),
                    ],
                  ),
                  const SizedBox(height: 30),
                  _buildFingerScanSection(),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _saving ? null : _save,
                      icon: _saving
                          ? const SizedBox(
                        height: 20, width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                          : const Icon(Icons.save),
                      label: Text(_saving ? 'Saving...' : 'Save Employee'),
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
