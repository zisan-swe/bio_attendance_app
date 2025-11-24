import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../db/database_helper.dart';
import '../../models/attendance_model.dart';
import '../../models/employee_model.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/employee_provider.dart';
import 'attendance_details_page.dart';

import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

class AttendanceListPage extends StatefulWidget {
  const AttendanceListPage({super.key});

  @override
  State<AttendanceListPage> createState() => _AttendanceListPageState();
}

/// PDF report row model
class AttendanceReportRow {
  final String empId;
  final String name;
  final String date;
  String checkIn;
  String breakIn;
  String breakOut;
  String checkOut;

  AttendanceReportRow({
    required this.empId,
    required this.name,
    required this.date,
    this.checkIn = '',
    this.breakIn = '',
    this.breakOut = '',
    this.checkOut = '',
  });
}

class _AttendanceListPageState extends State<AttendanceListPage> {
  late Future<List<AttendanceModel>> _attendanceFuture;
  late Future<Map<String, EmployeeModel?>> _employeeMapFuture;

  final DateFormat _dateFormatUi = DateFormat('MMM dd, yyyy');

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();

  bool _showSyncedOnly = false;

  int _totalCount = 0;
  int _totalSynced = 0;
  int _totalUnsynced = 0;

  /// currently selected date filter: yyyy-MM-dd
  String? _selectedDateYMD;

  /// 🔥 optional month filter for PDF: yyyy-MM (e.g. 2025-11)
  String? _selectedMonthYM;

  @override
  void initState() {
    super.initState();

    // default: আজকের তারিখ
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    _selectedDateYMD = todayStr;
    _dateController.text = todayStr;

    _attendanceFuture = Future.value([]);
    _employeeMapFuture = Future.value({});

    _refreshData(); // initial load

    _searchController.addListener(() {
      _refreshData(searchQuery: _searchController.text);
    });
  }

  // 🔁 মূল data reload ফাংশন — সব সময় _selectedDateYMD এর উপর কাজ করবে
  Future<void> _refreshData({String? searchQuery}) async {
    final attendanceProvider =
    Provider.of<AttendanceProvider>(context, listen: false);
    final employeeProvider =
    Provider.of<EmployeeProvider>(context, listen: false);

    // ফিল্টার date; নাহলে আজকের তারিখ
    final String dateStr =
        _selectedDateYMD ?? DateFormat('yyyy-MM-dd').format(DateTime.now());

    // 1) নির্দিষ্ট date এর attendance নাও
    List<AttendanceModel> attendanceList =
    await attendanceProvider.getAttendanceByDate(dateStr);

    // 2) employee map (name lookup)
    final Map<String, EmployeeModel?> employeeMap = {};
    for (final a in attendanceList) {
      if (!employeeMap.containsKey(a.employeeNo)) {
        employeeMap[a.employeeNo] =
        await employeeProvider.getEmployeeByNumber(a.employeeNo);
      }
    }

    // 3) সার্চ: Name/Employee No
    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final q = searchQuery.trim().toLowerCase();
      attendanceList = attendanceList.where((a) {
        final emp = employeeMap[a.employeeNo];
        final name = emp?.name.toLowerCase() ?? '';
        final no = a.employeeNo.toLowerCase();
        return name.contains(q) || no.contains(q);
      }).toList();
    }

    // 4) synced filter
    if (_showSyncedOnly) {
      attendanceList = attendanceList.where((a) => a.synced == 1).toList();
    }

    // 5) sort: latest → oldest (createAt)
    attendanceList.sort((a, b) {
      final aDate = DateTime.tryParse(a.createAt) ?? DateTime(1970);
      final bDate = DateTime.tryParse(b.createAt) ?? DateTime(1970);
      return bDate.compareTo(aDate);
    });

    // setState(() {
    //   _totalCount = attendanceList.length;
    //   _totalSynced = attendanceList.where((a) => a.synced == 1).length;
    //   _totalUnsynced = attendanceList.where((a) => a.synced == 0).length;
    //   _attendanceFuture = Future.value(attendanceList);
    //   _employeeMapFuture = Future.value(employeeMap);
    // });

    setState(() {
      // ✅ Unique employee count (কতজন employee attendance দিয়েছে)
      final uniqueEmployeeCount =
          attendanceList.map((a) => a.employeeNo).toSet().length;

      _totalCount = uniqueEmployeeCount;

      // চাইলে synced/unsynced ও employee base-এ করতে পারো,
      // আপাতত raw log হিসাবেই থাকুক:
      _totalSynced = attendanceList.where((a) => a.synced == 1).length;
      _totalUnsynced = attendanceList.where((a) => a.synced == 0).length;

      _attendanceFuture = Future.value(attendanceList);
      _employeeMapFuture = Future.value(employeeMap);
    });

  }

  // 📅 Date picker (filter)
  Future<void> _pickFilterDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDateYMD != null
          ? (DateTime.tryParse(_selectedDateYMD!) ?? now)
          : now,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;

    final ymd =
        "${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";

    _selectedDateYMD = ymd;
    _dateController.text = ymd;

    // month filter clear করে দিচ্ছি, কারণ তুমি এখন specific date দেখছো
    _selectedMonthYM = null;

    await _refreshData(searchQuery: _searchController.text);
  }

  /// 📅 Month picker শুধু PDF report-এর জন্য (yyyy-MM)
  Future<void> _pickFilterMonthForPdf() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: 'Select any date of the month for PDF report',
    );
    if (picked == null) return;

    final ym =
        "${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}";

    setState(() {
      _selectedMonthYM = ym;
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('PDF report will use full month: $ym'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }


  /// 🧾 PDF export (condition: day → full history, with SL No)
  Future<void> _exportFullPdfReport() async {
    final attendanceProvider =
    Provider.of<AttendanceProvider>(context, listen: false);
    final employeeProvider =
    Provider.of<EmployeeProvider>(context, listen: false);

    // 0) Company info from local DB
    final companyRow =
    await DatabaseHelper.instance.getFirstCompanySetting(); // Map<String, dynamic>?

    final String companyName =
    (companyRow?['company_name'] as String?)?.trim().isNotEmpty == true
        ? (companyRow!['company_name'] as String)
        : 'Company Name';

    final String companyAddress =
    (companyRow?['address'] as String?)?.trim().isNotEmpty == true
        ? (companyRow!['address'] as String)
        : '';

    final String companyBranch =
    companyRow?['branch_id'] != null ? companyRow!['branch_id'].toString() : '';

    final String companyUser =
    (companyRow?['user'] as String?)?.trim().isNotEmpty == true
        ? (companyRow!['user'] as String)
        : '';

    // 1) কোন ডেটা নেবো? ─ date filter নাকি full history?
    List<AttendanceModel> allAttendance;
    String reportTitleSuffix;
    String fileName;

    if (_selectedDateYMD != null && _selectedDateYMD!.isNotEmpty) {
      // 🔹 Filtered by specific date
      allAttendance =
      await attendanceProvider.getAttendanceByDate(_selectedDateYMD!);
      reportTitleSuffix = ' (Date: $_selectedDateYMD)';
      fileName = 'attendance_${_selectedDateYMD!}.pdf';
    } else {
      // 🔹 Full history
      allAttendance = await attendanceProvider.getAllAttendance();
      reportTitleSuffix = ' (All Dates)';
      fileName =
      'attendance_full_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.pdf';
    }

    if (allAttendance.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No attendance data to export.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // 2) Employee map বানাই (employee_no -> EmployeeModel)
    final Map<String, EmployeeModel?> empMap = {};
    for (final a in allAttendance) {
      if (!empMap.containsKey(a.employeeNo)) {
        empMap[a.employeeNo] =
        await employeeProvider.getEmployeeByNumber(a.employeeNo);
      }
    }

    // 3) প্রতি Employee + Date এর জন্য এক লাইন বানাই
    final Map<String, AttendanceReportRow> rowMap = {};

    for (final a in allAttendance) {
      final key = '${a.employeeNo}_${a.workingDate}';
      final emp = empMap[a.employeeNo];
      final name = emp?.name ?? '';

      if (!rowMap.containsKey(key)) {
        rowMap[key] = AttendanceReportRow(
          empId: a.employeeNo,
          name: name,
          date: a.workingDate,
        );
      }

      final row = rowMap[key]!;

      // status অনুযায়ী proper কলাম সেট
      switch (a.attendanceStatus) {
        case 'Check In':
          row.checkIn = a.inTime.isNotEmpty ? a.inTime : row.checkIn;
          break;
        case 'Break In':
          row.breakIn = a.inTime.isNotEmpty ? a.inTime : row.breakIn;
          break;
        case 'Break Out':
          row.breakOut = a.outTime.isNotEmpty ? a.outTime : row.breakOut;
          break;
        case 'Check Out':
          row.checkOut = a.outTime.isNotEmpty ? a.outTime : row.checkOut;
          break;
        default:
          break;
      }
    }

    final rows = rowMap.values.toList()
      ..sort((a, b) {
        final da = DateTime.tryParse(a.date) ?? DateTime(1970);
        final db = DateTime.tryParse(b.date) ?? DateTime(1970);
        return da.compareTo(db); // পুরনো → নতুন
      });

    // 👉 Total attendance count (raw logs)
    // final int totalAttendanceCount = allAttendance.length;

    // 👉 Total Attendance = কতজন employee attendance দিয়েছে (unique employee_no)
    final int totalAttendanceCount =
        allAttendance.map((a) => a.employeeNo).toSet().length;

    // 4) PDF বানানো
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (pw.Context context) {
          return [
            // 🔷 Company Header (centered)
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text(
                  companyName,
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                if (companyAddress.isNotEmpty)
                  pw.Text(
                    companyAddress,
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                pw.SizedBox(height: 2),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    if (companyBranch.isNotEmpty)
                      pw.Text(
                        'Plot ID: $companyBranch',
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                    if (companyBranch.isNotEmpty && companyUser.isNotEmpty)
                      pw.SizedBox(width: 12),
                    if (companyUser.isNotEmpty)
                      pw.Text(
                        'Supervisor: $companyUser',
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 12),

            // Report title + generated time
            pw.Text(
              'Employee Attendance Report$reportTitleSuffix',
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'Generated: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}',
              style: const pw.TextStyle(fontSize: 9),
            ),
            pw.SizedBox(height: 6),

            // ✅ Total Attendance line
            pw.Text(
              'Total Attendance (Employees): $totalAttendanceCount',
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 12),

            // 📋 Table with SL No
            pw.Table.fromTextArray(
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.grey300,
              ),
              headerStyle: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
              ),
              cellStyle: const pw.TextStyle(fontSize: 9),
              cellAlignment: pw.Alignment.center,
              headers: const [
                'SL',
                'Emp ID',
                'Name',
                'Date',
                'Check In',
                'Break In',
                'Break Out',
                'Check Out',
              ],
              data: rows.asMap().entries.map((entry) {
                final index = entry.key;        // 0,1,2,...
                final r = entry.value;          // AttendanceReportRow
                final sl = (index + 1).toString();

                return [
                  sl,
                  r.empId,
                  r.name,
                  r.date,
                  r.checkIn,
                  r.breakIn,
                  r.breakOut,
                  r.checkOut,
                ];
              }).toList(),
            ),
          ];
        },
      ),
    );

    // 5) save/share
    final bytes = await pdf.save();
    await Printing.sharePdf(
      bytes: bytes,
      filename: fileName,
    );
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
    final String currentFilterDate =
        _selectedDateYMD ?? DateFormat('yyyy-MM-dd').format(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Records'),
        backgroundColor: Colors.blueGrey,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Export Attendance PDF',
            onPressed: _exportFullPdfReport,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _refreshData(searchQuery: _searchController.text),
          ),
          IconButton(
            tooltip:
            _showSyncedOnly ? 'Showing Synced Only' : 'Show Synced Only',
            icon: Icon(
              _showSyncedOnly ? Icons.cloud_done : Icons.cloud_off,
              color: _showSyncedOnly ? Colors.green : Colors.white,
            ),
            onPressed: () {
              setState(() => _showSyncedOnly = !_showSyncedOnly);
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
                hintText: 'Search by Name or Employee No (selected date)',
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

      body: Column(
        children: [
          // 📅 Date + Month filter row
          Padding(
            padding:
            const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _dateController,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: 'Filter Date (yyyy-MM-dd)',
                      prefixIcon: const Icon(Icons.calendar_today),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    onTap: _pickFilterDate,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'PDF Month',
                  icon: const Icon(Icons.calendar_view_month),
                  onPressed: _pickFilterMonthForPdf,
                ),
                IconButton(
                  tooltip: 'Today',
                  icon: const Icon(Icons.today),
                  onPressed: () {
                    final todayStr =
                    DateFormat('yyyy-MM-dd').format(DateTime.now());
                    _selectedDateYMD = todayStr;
                    _dateController.text = todayStr;
                    _selectedMonthYM = null; // month mode cancel
                    _refreshData(searchQuery: _searchController.text);
                  },
                ),
                IconButton(
                  tooltip: 'Clear to full history (PDF only)',
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _selectedDateYMD = null;
                    _dateController.clear();
                    _selectedMonthYM = null;
                    _refreshData(searchQuery: _searchController.text);
                  },
                ),
              ],
            ),
          ),

          // 🔢 Top summary bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: Colors.blueGrey[50],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Date filter (list): $currentFilterDate",
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
                if (_selectedMonthYM != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    "PDF Month: $_selectedMonthYM",
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.deepPurple,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  "Total Attendance: $_totalCount",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey,
                  ),
                ),
                // const SizedBox(height: 2),
                // Text(
                //   "Synced: $_totalSynced   |   Unsynced: $_totalUnsynced",
                //   style: const TextStyle(
                //     fontSize: 13,
                //     color: Colors.black87,
                //     fontWeight: FontWeight.w500,
                //   ),
                // ),
              ],
            ),
          ),

          // 📋 List
          Expanded(
            child: RefreshIndicator(
              onRefresh: () =>
                  _refreshData(searchQuery: _searchController.text),
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
                      child:
                      Text('No attendance records found for this date.'),
                    );
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
                            'Error loading employees: ${employeeSnapshot.error}',
                          ),
                        );
                      }

                      final employeeMap = employeeSnapshot.data ?? {};

                      return ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: attendanceList.length,
                        separatorBuilder: (_, __) =>
                        const Divider(height: 1),
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
                                  _getActionIcon(
                                      attendance.attendanceStatus),
                                  color: Colors.white,
                                ),
                              ),
                              title: Text(
                                employee != null
                                    ? '${employee.name} (#${attendance.employeeNo})'
                                    : 'Employee #${attendance.employeeNo}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(
                                    '${attendance.attendanceStatus} • ${_dateFormatUi.format(DateTime.parse(attendance.workingDate))}',
                                  ),
                                  if (attendance.inTime.isNotEmpty)
                                    Text('In Time: ${attendance.inTime}'),
                                  if (attendance.outTime.isNotEmpty)
                                    Text('Out Time: ${attendance.outTime}'),
                                  if (attendance.fingerprint.isNotEmpty)
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.fingerprint,
                                          size: 16,
                                          color: Colors.deepPurple,
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            attendance.fingerprint,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                              trailing: Icon(
                                attendance.synced == 1
                                    ? Icons.cloud_done
                                    : Icons.cloud_off,
                                color: attendance.synced == 1
                                    ? Colors.green
                                    : Colors.red,
                              ),
                              onTap: () {
                                final sameDayRecords = attendanceList
                                    .where((a) =>
                                a.employeeNo ==
                                    attendance.employeeNo &&
                                    a.workingDate ==
                                        attendance.workingDate)
                                    .toList();

                                sameDayRecords.sort((a, b) {
                                  final timeA = a.inTime.isNotEmpty
                                      ? a.inTime
                                      : a.outTime;
                                  final timeB = b.inTime.isNotEmpty
                                      ? b.inTime
                                      : b.outTime;

                                  final dtA =
                                      DateTime.tryParse('2023-01-01 $timeA') ??
                                          DateTime(1970);
                                  final dtB =
                                      DateTime.tryParse('2023-01-01 $timeB') ??
                                          DateTime(1970);

                                  return dtA.compareTo(dtB);
                                });

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => AttendanceDetailsPage(
                                      attendances: sameDayRecords,
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
          ),
        ],
      ),
    );
  }
}
