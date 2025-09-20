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
  final DateFormat _dateFormat = DateFormat('MMM dd, yyyy');
  final DateFormat _timeFormat = DateFormat('hh:mm a');

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  Future<void> _refreshData() async {
    setState(() {
      _attendanceFuture = Provider.of<AttendanceProvider>(context, listen: false)
          .getAllAttendance();
    });
  }

  Color _getStatusColor(int status) {
    return status == 1 ? Colors.green : Colors.orange;
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

  Widget _buildFingerprintStatus(EmployeeModel? employee) {
    if (employee == null) return const SizedBox.shrink();

    final fingerprints = <String>[
      if (employee.fingerInfo1.isNotEmpty) 'Left Thumb',
      if (employee.fingerInfo2.isNotEmpty) 'Left Index',
      if (employee.fingerInfo3.isNotEmpty) 'Left Middle',
      if (employee.fingerInfo4.isNotEmpty) 'Left Ring',
      if (employee.fingerInfo5.isNotEmpty) 'Left Little',
      if (employee.fingerInfo6.isNotEmpty) 'Right Thumb',
      if (employee.fingerInfo7.isNotEmpty) 'Right Index',
      if (employee.fingerInfo8.isNotEmpty) 'Right Middle',
      if (employee.fingerInfo9.isNotEmpty) 'Right Ring',
      if (employee.fingerInfo10.isNotEmpty) 'Right Little',
    ];

    if (fingerprints.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        // children: [
        //   const Text(
        //     'Registered Fingerprints:',
        //     style: TextStyle(fontSize: 12, color: Colors.grey),
        //   ),
        //   Wrap(
        //     spacing: 4,
        //     runSpacing: 4,
        //     children: fingerprints
        //         .map((finger) => Chip(
        //       label: Text(finger),
        //       backgroundColor: Colors.blue[50],
        //       labelStyle: const TextStyle(fontSize: 12),
        //     ))
        //         .toList(),
        //   ),
        // ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final employeeProvider = Provider.of<EmployeeProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Records'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: FutureBuilder<List<AttendanceModel>>(
          future: _attendanceFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Text('Error: ${snapshot.error}'),
              );
            }

            final attendanceList = snapshot.data ?? [];

            if (attendanceList.isEmpty) {
              return const Center(
                child: Text('No attendance records found'),
              );
            }

            return ListView.builder(
              itemCount: attendanceList.length,
              itemBuilder: (context, index) {
                final attendance = attendanceList[index];
                final employeeFuture = employeeProvider.getEmployeeByNumber(attendance.employeeNo.toString());

                return FutureBuilder<EmployeeModel?>(
                  future: employeeFuture,
                  builder: (context, employeeSnapshot) {
                    if (employeeSnapshot.connectionState == ConnectionState.waiting) {
                      return const Card(
                        margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        child: ListTile(
                          title: Text("Loading employee..."),
                          subtitle: Text("Please wait"),
                        ),
                      );
                    }

                    if (employeeSnapshot.hasError) {
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        child: ListTile(
                          title: const Text("Error loading employee"),
                          subtitle: Text(employeeSnapshot.error.toString()),
                        ),
                      );
                    }

                    final employee = employeeSnapshot.data;

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getStatusColor(attendance.status),
                          child: Icon(
                            _getActionIcon(attendance.attendanceStatus),
                            color: Colors.white,
                          ),
                        ),
                        title: Text(
                          'Employee #${attendance.employeeNo}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${attendance.attendanceStatus} - ${_dateFormat.format(DateTime.parse(attendance.workingDate))}',
                            ),
                            if (attendance.inTime.isNotEmpty)
                              Text('In Time: ${_timeFormat.format(DateTime.parse('2023-01-01 ${attendance.inTime}'))}'),
                            if (attendance.outTime.isNotEmpty)
                              Text('Out Time: ${_timeFormat.format(DateTime.parse('2023-01-01 ${attendance.outTime}'))}'),
                            if (attendance.fingerprint.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Row(
                                  children: [
                                    const Icon(Icons.fingerprint, size: 16, color: Colors.deepPurple),
                                    const SizedBox(width: 4),
                                    Text('Used Fingerprint: ${attendance.fingerprint}'),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          // Step 1: Filter attendances for the same employee and date
                          final sameDateAttendances = attendanceList.where((a) =>
                          a.employeeNo == attendance.employeeNo &&
                              a.workingDate == attendance.workingDate
                          ).toList();

                          // Step 2: Sort by inTime or outTime (if inTime is empty)
                          sameDateAttendances.sort((a, b) {
                            String timeA = a.inTime.isNotEmpty ? a.inTime : a.outTime;
                            String timeB = b.inTime.isNotEmpty ? b.inTime : b.outTime;

                            DateTime dtA = DateTime.parse('2023-01-01 $timeA');
                            DateTime dtB = DateTime.parse('2023-01-01 $timeB');

                            return dtA.compareTo(dtB); // ascending
                          });

                          // Step 3: Navigate to the details page
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AttendanceDetailsPage(
                                attendances: sameDateAttendances,
                                employee: employee,
                              ),
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