import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../models/attendance_model.dart';
import '../../models/employee_model.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/employee_provider.dart';
import 'attendance_details_page.dart';

class AttendanceListPage extends StatefulWidget {
  const AttendanceListPage({super.key});

  @override
  State<AttendanceListPage> createState() => _AttendanceListPageState();
}

class _AttendanceListPageState extends State<AttendanceListPage> {
  late Future<List<AttendanceModel>> _attendanceFuture;
  late Future<Map<String, EmployeeModel?>> _employeeMapFuture;
  final DateFormat _dateFormat = DateFormat('MMM dd, yyyy');
  final DateFormat _timeFormat = DateFormat('hh:mm a');

  final TextEditingController _searchController = TextEditingController();
  bool _showSyncedOnly = false;

  @override
  void initState() {
    super.initState();
    _attendanceFuture = Future.value([]);
    _employeeMapFuture = Future.value({});
    _refreshData();
    _searchController.addListener(() {
      _refreshData(searchQuery: _searchController.text);
    });
  }

  // Future<void> _refreshData({String? searchQuery}) async {
  //   final attendanceProvider =
  //   Provider.of<AttendanceProvider>(context, listen: false);
  //   final employeeProvider =
  //   Provider.of<EmployeeProvider>(context, listen: false);
  //
  //   // Fetch all attendance records
  //   List<AttendanceModel> attendanceList =
  //   await attendanceProvider.getAllAttendance();
  //
  //   // Apply live search filter
  //   if (searchQuery != null && searchQuery.isNotEmpty) {
  //     attendanceList = attendanceList
  //         .where((a) =>
  //         a.employeeNo.toLowerCase().contains(searchQuery.toLowerCase()))
  //         .toList();
  //   }
  //
  //   // Apply synced filter
  //   if (_showSyncedOnly) {
  //     attendanceList = attendanceList.where((a) => a.synced == 1).toList();
  //   }
  //
  //   // Employee mapping
  //   final Map<String, EmployeeModel?> employeeMap = {};
  //   for (var attendance in attendanceList) {
  //     if (!employeeMap.containsKey(attendance.employeeNo)) {
  //       final employee =
  //       await employeeProvider.getEmployeeByNumber(attendance.employeeNo);
  //       employeeMap[attendance.employeeNo] = employee;
  //     }
  //   }
  //
  //   setState(() {
  //     _attendanceFuture = Future.value(attendanceList);
  //     _employeeMapFuture = Future.value(employeeMap);
  //   });
  // }

  Future<void> _refreshData({String? searchQuery}) async {
    final attendanceProvider =
    Provider.of<AttendanceProvider>(context, listen: false);
    final employeeProvider =
    Provider.of<EmployeeProvider>(context, listen: false);

    // 1) সব attendance আনুন
    List<AttendanceModel> attendanceList =
    await attendanceProvider.getAllAttendance();

    // 2) সার্চ ফিল্টার
    if (searchQuery != null && searchQuery.isNotEmpty) {
      attendanceList = attendanceList
          .where((a) =>
          a.employeeNo.toLowerCase().contains(searchQuery.toLowerCase()))
          .toList();
    }

    // 3) synced filter
    if (_showSyncedOnly) {
      attendanceList = attendanceList.where((a) => a.synced == 1).toList();
    }

    // 🔥 4) নতুনটি আগে দেখাতে descending sort (createAt সর্বশেষ আগে)
    attendanceList.sort((a, b) {
      final aDate = DateTime.tryParse(a.createAt) ?? DateTime(1970);
      final bDate = DateTime.tryParse(b.createAt) ?? DateTime(1970);
      return bDate.compareTo(aDate); // latest → oldest
    });

    // 5) employee map
    final Map<String, EmployeeModel?> employeeMap = {};
    for (var attendance in attendanceList) {
      if (!employeeMap.containsKey(attendance.employeeNo)) {
        final employee =
        await employeeProvider.getEmployeeByNumber(attendance.employeeNo);
        employeeMap[attendance.employeeNo] = employee;
      }
    }

    setState(() {
      _attendanceFuture = Future.value(attendanceList);
      _employeeMapFuture = Future.value(employeeMap);
    });
  }

  IconData _getActionIcon(String action) {
    switch (action) {
      case 'Check In':
        return Icons.login;
      case 'Check Out':
        return Icons.logout;
      case 'Break In':
        return Icons.coffee;
      case 'Break Out':
        return Icons.work;
      default:
        return Icons.access_time;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Records'),
        backgroundColor: Colors.blueGrey,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _refreshData(searchQuery: _searchController.text),
          ),
          // Toggle synced filter
          IconButton(
            tooltip:
            _showSyncedOnly ? 'Showing Synced Only' : 'Show Synced Only',
            icon: Icon(
              _showSyncedOnly ? Icons.cloud_done : Icons.cloud_off,
              color: _showSyncedOnly ? Colors.green : Colors.white,
            ),
            onPressed: () {
              setState(() {
                _showSyncedOnly = !_showSyncedOnly;
              });
              _refreshData(searchQuery: _searchController.text);
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by Employee No',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => _refreshData(searchQuery: _searchController.text),
        child: FutureBuilder<List<AttendanceModel>>(
          future: _attendanceFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            final attendanceList = snapshot.data ?? [];

            if (attendanceList.isEmpty) {
              return const Center(child: Text('No attendance records found.'));
            }

            return FutureBuilder<Map<String, EmployeeModel?>>(
              future: _employeeMapFuture,
              builder: (context, employeeSnapshot) {
                if (employeeSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (employeeSnapshot.hasError) {
                  return Center(
                      child: Text(
                          'Error loading employees: ${employeeSnapshot.error}'));
                }

                final employeeMap = employeeSnapshot.data ?? {};

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: attendanceList.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final attendance = attendanceList[index];
                    final employee = employeeMap[attendance.employeeNo];

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      elevation: 2,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        leading: CircleAvatar(
                          backgroundColor: Colors.blueAccent,
                          child: Icon(
                            _getActionIcon(attendance.attendanceStatus),
                            color: Colors.white,
                          ),
                        ),
                        title: Text(
                          employee != null
                              ? '${employee.name} (#${attendance.employeeNo})'
                              : 'Employee #${attendance.employeeNo}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                                '${attendance.attendanceStatus} • ${_dateFormat.format(DateTime.parse(attendance.workingDate))}'),
                            if (attendance.inTime.isNotEmpty)
                              Text('In: ${attendance.inTime}'),
                            if (attendance.outTime.isNotEmpty)
                              Text('Out: ${attendance.outTime}'),
                            if (attendance.fingerprint.isNotEmpty)
                              Row(
                                children: [
                                  const Icon(Icons.fingerprint,
                                      size: 16, color: Colors.deepPurple),
                                  const SizedBox(width: 4),
                                  Text(attendance.fingerprint),
                                ],
                              ),
                          ],
                        ),
                        trailing: Icon(
                          attendance.synced == 1
                              ? Icons.cloud_done
                              : Icons.cloud_off,
                          color:
                          attendance.synced == 1 ? Colors.green : Colors.red,
                        ),
                        onTap: () {
                          final sameDayRecords = attendanceList
                              .where((a) =>
                          a.employeeNo == attendance.employeeNo &&
                              a.workingDate == attendance.workingDate)
                              .toList();

                          sameDayRecords.sort((a, b) {
                            String timeA =
                            a.inTime.isNotEmpty ? a.inTime : a.outTime;
                            String timeB =
                            b.inTime.isNotEmpty ? b.inTime : b.outTime;

                            DateTime dtA =
                            DateTime.parse('2023-01-01 $timeA');
                            DateTime dtB =
                            DateTime.parse('2023-01-01 $timeB');

                            return dtA.compareTo(dtB);
                          });

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AttendanceDetailsPage(
                                  attendances: sameDayRecords,
                                  employee: employee),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
