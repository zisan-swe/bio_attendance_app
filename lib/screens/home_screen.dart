import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'attendance/attendance_seeding_page.dart';
import 'login_screen.dart';
import 'attendance/attendance_list_page.dart';
import 'employee/labour_list.dart';
import 'worker/worker_page.dart';
import 'employee/employee_page.dart';
import 'attendance/attendance_page.dart';
import 'finger/fingerprint_test_page.dart';
import 'setting/setting_seeding_page.dart';
import 'settings.dart';

class HomeScreen extends StatelessWidget {
  Widget _buildButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required Widget destination,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 25.0),
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: color ?? Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 6,
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => destination),
          );
        },
        icon: Icon(icon, size: 24),
        label: Text(
          label,
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Icon(Icons.fingerprint, size: 80, color: Colors.blueGrey),
        SizedBox(height: 10),
        Text(
          'Fingerprint Attendance',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.blueGrey[800],
          ),
        ),
        SizedBox(height: 5),
        Text(
          'Quick and secure check-ins',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
          ),
        ),
        SizedBox(height: 30),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);

    /// Logout confirmation dialog
    void _confirmLogout() {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('Logout Confirmation'),
          content: Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop(); // Close dialog
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(ctx).pop(); // Close dialog first
                if (auth.token != null) {
                  await auth.logoutApi(); // Server + local logout
                } else {
                  auth.logout(); // Local logout only
                }
                // Navigate back to login
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => LoginScreen()),
                );
              },
              child: Text('Logout', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.transparent, // Make AppBar transparent
        elevation: 0, // Remove shadow
        automaticallyImplyLeading: false, // Remove back button if any
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: Colors.redAccent),
            tooltip: 'Logout',
            onPressed: _confirmLogout,
          ),
        ],
      ),

      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  SizedBox(height: 0),
                  _buildHeader(),
                  SizedBox(
                    width: 250,
                    child: _buildButton(
                      context: context,
                      label: 'Employee',
                      icon: Icons.badge,
                      destination: EmployeePage(),
                      color: Colors.green,
                    ),
                  ),
                  SizedBox(
                    width: 250,
                    child: _buildButton(
                      context: context,
                      label: 'Worker',
                      icon: Icons.person,
                      destination: WorkerPage(),
                      color: Colors.indigo,
                    ),
                  ),
                  SizedBox(
                    width: 250,
                    child: _buildButton(
                      context: context,
                      label: 'Finger Test',
                      icon: Icons.fingerprint,
                      destination: FingerprintTestPage(),
                      color: Colors.orange,
                    ),
                  ),
                  SizedBox(
                    width: 250,
                    child: _buildButton(
                      context: context,
                      label: 'Attendance',
                      icon: Icons.check_circle_outline,
                      destination: AttendancePage(),
                      color: Colors.blueAccent,
                    ),
                  ),
                  SizedBox(
                    width: 250,
                    child: _buildButton(
                      context: context,
                      label: 'Attendance List',
                      icon: Icons.list_alt,
                      destination: AttendanceListPage(),
                      color: Colors.teal,
                    ),
                  ),
                  SizedBox(
                    width: 250,
                    child: _buildButton(
                      context: context,
                      label: 'Setting ',
                      icon: Icons.settings,
                      destination: SettingSeedingPage(),
                      color: Colors.blueGrey,
                    ),
                  ),
                  // SizedBox(
                  //   width: 250,
                  //   child: _buildButton(
                  //     context: context,
                  //     label: 'Attendance Seeder ',
                  //     icon: Icons.settings,
                  //     destination: AttendanceSeedingPage(),
                  //     color: Colors.blueGrey,
                  //   ),
                  // ),

                  // SizedBox(
                  //   width: 250,
                  //   child: _buildButton(
                  //     context: context,
                  //     label: 'Labour List ',
                  //     icon: Icons.man,
                  //     destination: EmployeeListPage(),
                  //     color: Colors.brown,
                  //   ),
                  // ),
                ],
              ),
            ),

            // Bottom-left Settings Icon

            // Align(
            //   alignment: Alignment.bottomLeft,
            //   child: Padding(
            //     padding: const EdgeInsets.all(16.0),
            //     child: IconButton(
            //       icon: Icon(Icons.settings, size: 35, color: Colors.grey[800]),
            //       onPressed: () {
            //         Navigator.push(
            //           context,
            //           MaterialPageRoute(builder: (_) => SettingsPage()),
            //         );
            //       },
            //     ),
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
}
