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

  @override
  void initState() {
    super.initState();
    _attendanceFuture = Future.value([]);
    _employeeMapFuture = Future.value({});
    _refreshData();
  }

  Future<void> _refreshData() async {
    final attendanceProvider =
    Provider.of<AttendanceProvider>(context, listen: false);
    final employeeProvider =
    Provider.of<EmployeeProvider>(context, listen: false);

    // ✅ সব attendance নিন
    final attendanceList = await attendanceProvider.getAllAttendance();

    // ✅ employee mapping
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
        title: const Text('Attendance List Records'),
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
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            final attendanceList = snapshot.data ?? [];

            if (attendanceList.isEmpty) {
              return const Center(
                child: Text('No attendance records found'),
              );
            }

            return FutureBuilder<Map<String, EmployeeModel?>>(
              future: _employeeMapFuture,
              builder: (context, employeeMapSnapshot) {
                if (employeeMapSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (employeeMapSnapshot.hasError) {
                  return Center(
                    child: Text(
                        'Error loading employees: ${employeeMapSnapshot.error}'),
                  );
                }

                final employeeMap = employeeMapSnapshot.data ?? {};

                return ListView.builder(
                  itemCount: attendanceList.length,
                  itemBuilder: (context, index) {
                    final attendance = attendanceList[index];
                    final employee = employeeMap[attendance.employeeNo];

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.green,
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
                            Text(
                              '${attendance.attendanceStatus} - ${_dateFormat.format(DateTime.parse(attendance.workingDate))}',
                            ),
                            if (attendance.inTime.isNotEmpty)
                              Text(
                                'In Time: ${attendance.inTime}',
                              ),
                            if (attendance.outTime.isNotEmpty)
                              Text(
                                'Out Time: ${attendance.outTime}',
                              ),
                            if (attendance.fingerprint.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Row(
                                  children: [
                                    const Icon(Icons.fingerprint,
                                        size: 16, color: Colors.deepPurple),
                                    const SizedBox(width: 4),
                                    Text(
                                        'Used Fingerprint: ${attendance.fingerprint}'),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          final sameDateAttendances = attendanceList
                              .where((a) =>
                          a.employeeNo == attendance.employeeNo &&
                              a.workingDate == attendance.workingDate)
                              .toList();

                          sameDateAttendances.sort((a, b) {
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