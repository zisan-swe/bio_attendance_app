import 'package:flutter/material.dart';
import 'enroll_screen.dart';
// import 'attendance_screen.dart';
import 'worker/worker_page.dart';
import 'employee/employee_page.dart';
import 'attendance/attendance_page.dart';


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
          Navigator.push(context, MaterialPageRoute(builder: (_) => destination));
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
        SizedBox(height: 80),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              SizedBox(height: 40),
              _buildHeader(),
              // _buildButton(
              //   context: context,
              //   label: 'Worker',
              //   icon: Icons.person,
              //   destination: WorkerPage(),
              //   color: Colors.indigo,
              // ),
              // _buildButton(
              //   context: context,
              //   label: 'Employee',
              //   icon: Icons.badge,
              //   destination: EmployeePage(),
              //   color: Colors.green,
              // ),
              // _buildButton(
              //   context: context,
              //   label: 'Enroll Worker',
              //   icon: Icons.fingerprint,
              //   destination: WorkerPage(),
              //   color: Colors.orange,
              // ),
              // _buildButton(
              //   context: context,
              //   label: 'Mark Attendance',
              //   icon: Icons.check_circle_outline,
              //   destination: WorkerPage(),
              //   color: Colors.blueAccent,
              // ),

              //Same Weight Box
              SizedBox(
                width: 250, // Set same width for all buttons
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
                  label: 'Employee',
                  icon: Icons.badge,
                  destination: EmployeePage(),
                  color: Colors.green,
                ),
              ),
              SizedBox(
                width: 250,
                // height: 70,
                child: _buildButton(
                  context: context,
                  label: 'Enroll Worker',
                  icon: Icons.fingerprint,
                  destination: AttendancePage(),
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
            ],
          ),
        ),
      ),
    );
  }
}
