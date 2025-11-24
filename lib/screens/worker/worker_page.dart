import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/employee_model.dart';
import '../../db/database_helper.dart';
import '../../providers/attendance_provider.dart';
import '../../services/api_service.dart';
import 'worker_create_page.dart';
import 'worker_edit_page.dart';
import 'worker_details.dart';

class WorkerPage extends StatefulWidget {
  const WorkerPage({super.key});

  @override
  State<WorkerPage> createState() => _WorkerPageState();
}

class _WorkerPageState extends State<WorkerPage> {
  List<EmployeeModel> employees = [];
  Map<int, File> _profileImages = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEmployees('Labour');
  }

  /// লোড + সিঙ্ক করবে API থেকে, এবং লোকালে সেভ করবে
  Future<void> _loadEmployees(String employeeType) async {
    setState(() => _isLoading = true);

    try {
      // প্রজেক্ট ও ব্লক আইডি নেওয়া
      final projectSetting = await DatabaseHelper.instance.getSettingBySlug('project_id');
      final blockSetting = await DatabaseHelper.instance.getSettingBySlug('block_id');
      final String projectId = projectSetting?.value ?? "0";
      final String blockId = blockSetting?.value ?? "0";

      List<EmployeeModel> apiEmployees = [];

      // API থেকে ডেটা আনা
      try {
        apiEmployees = await ApiService.fetchEmployees(code: projectId, blockId: blockId);
        debugPrint("API থেকে পাওয়া কর্মী: ${apiEmployees.length} জন");
      } catch (e) {
        debugPrint("API fetch failed: $e");
      }

      List<EmployeeModel> employeesToShow = [];

      if (apiEmployees.isNotEmpty) {
        // API থেকে ডেটা পেলে → লোকালে পুরোনো ডেটা মুছে নতুনগুলো সেভ করো
        final db = await DatabaseHelper.instance.database;

        await db.delete(
          'employee',
          where: 'project_id = ? AND block_id = ?',
          whereArgs: [projectId, blockId],
        );

        for (var emp in apiEmployees) {
          final employeeToSave = emp.copyWith(
            employeeType: employeeType,
            projectId: projectId,
            blockId: blockId,
            imagePath: emp.imagePath.isNotEmpty ? emp.imagePath : '',
          );
          await DatabaseHelper.instance.insertEmployee(employeeToSave);
        }

        employeesToShow = apiEmployees;

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Sync complete! ${apiEmployees.length} employees loaded"),
              // content: Text("সিঙ্ক সম্পন্ন! ${apiEmployees.length} জন কর্মী লোড হয়েছে"),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // অফলাইন বা API ফেল → লোকাল ডেটা দেখাও
        employeesToShow = await DatabaseHelper.instance.getAllEmployees(employeeType: employeeType);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("No internet – showing local data"),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }

      // প্রোফাইল ছবি লোড (শুধু লোকাল পাথ থাকলে)
      Map<int, File> imageMap = {};
      for (var emp in employeesToShow) {
        if (emp.id != null &&
            emp.imagePath.isNotEmpty &&
            emp.imagePath.startsWith('/')) {
          final file = File(emp.imagePath);
          if (await file.exists()) {
            imageMap[emp.id!] = file;
          }
        }
      }

      setState(() {
        employees = employeesToShow;
        _profileImages = imageMap;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error in _loadEmployees: $e");
      setState(() => _isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  /// রিফ্রেশ বাটন চাপলে আবার সিঙ্ক করবে
  // Future<void> _onRefresh() async {
  //   await _loadEmployees('Labour');
  // }

  Future<void> _onRefresh() async {
    await _loadEmployees('Labour');
    await Provider.of<AttendanceProvider>(context, listen: false).syncPendingAttendance();
  }

  void _navigateToCreate({EmployeeModel? employee}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WorkerCreatePage(employee: employee),
      ),
    );

    if (result == true) {
      _loadEmployees('Labour');
    }
  }

  void _confirmDeleteEmployee(int id) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('কর্মী মুছে ফেলবেন?'),
        content: const Text('এই কর্মীর সব তথ্য মুছে যাবে। নিশ্চিত?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('না')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('হ্যাঁ, মুছে ফেলুন', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      await DatabaseHelper.instance.deleteEmployee(id);
      _loadEmployees('Labour');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("কর্মী মুছে ফেলা হয়েছে")),
      );
    }
  }

  String _getEmployeeTypeLabel(String type) {
    switch (type) {
      case 'Labour':
        return 'শ্রমিক';
      case 'Wages':
        return 'মজুরি কর্মী';
      case 'Staff':
        return 'অফিস স্টাফ';
      default:
        return type;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Employee List'),
        backgroundColor: Colors.blueGrey[800],
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'সিঙ্ক করুন',
            onPressed: _onRefresh,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : employees.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              'কোনো কর্মী পাওয়া যায়নি',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _onRefresh,
              icon: const Icon(Icons.sync),
              label: const Text('আবার চেষ্টা করুন'),
            ),
          ],
        ),
      )
          : RefreshIndicator(
        onRefresh: _onRefresh,
        child: ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: employees.length,
          itemBuilder: (context, index) {
            final emp = employees[index];

            return Card(
              elevation: 3,
              margin: const EdgeInsets.symmetric(vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                contentPadding: const EdgeInsets.all(12),
                leading: CircleAvatar(
                  radius: 32,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: _profileImages[emp.id] != null
                      ? FileImage(_profileImages[emp.id]!)
                      : emp.imagePath.isNotEmpty
                      ? NetworkImage(emp.imagePath) as ImageProvider
                      : null,
                  child: (_profileImages[emp.id] == null && emp.imagePath.isEmpty)
                      ? Text(
                    emp.name.isNotEmpty ? emp.name[0].toUpperCase() : 'ক',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  )
                      : null,
                ),
                title: Text(
                  emp.name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text('Emp No: ${emp.employeeNo}'),
                    // Text('প্রকার: ${_getEmployeeTypeLabel(emp.employeeType)}'),
                    if (emp.dailyWages > 0)
                      Text('Daily Wages: ৳${emp.dailyWages.toStringAsFixed(0)}'),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () async {
                        final updated = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => WorkerEditPage(employee: emp),
                          ),
                        );
                        if (updated == true) {
                          _loadEmployees('Labour');
                        }
                      },
                    ),
                    // IconButton(
                    //   icon: const Icon(Icons.delete, color: Colors.red),
                    //   onPressed: () => _confirmDeleteEmployee(emp.id!),
                    // ),
                  ],
                ),


                // trailing: PopupMenuButton(
                //   icon: const Icon(Icons.more_vert),
                //   itemBuilder: (context) => [
                //     const PopupMenuItem(value: 'edit', child: Text('এডিট করুন')),
                //     // const PopupMenuItem(value: 'delete', child: Text('মুছে ফেলুন', style: TextStyle(color: Colors.red))),
                //   ],
                //   onSelected: (value) async {
                //     if (value == 'edit') {
                //       final updated = await Navigator.push(
                //         context,
                //         MaterialPageRoute(builder: (_) => WorkerEditPage(employee: emp)),
                //       );
                //       if (updated == true) _loadEmployees('Labour');
                //     } else if (value == 'delete') {
                //       _confirmDeleteEmployee(emp.id!);
                //     }
                //   },
                // ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => WorkerDetailsPage(employee: emp)),
                  );
                },
              ),
            );
          },
        ),
      ),

      // floatingActionButton: FloatingActionButton.extended(
      //   onPressed: () => _navigateToCreate(),
      //   icon: const Icon(Icons.person_add),
      //   label: const Text('নতুন কর্মী যোগ করুন'),
      //   backgroundColor: Colors.green,
      // ),
    );
  }
}