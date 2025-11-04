import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/auth_provider.dart';
import 'attendance/attendance_list_page.dart';
import 'employee/employee_page.dart';
import 'worker/worker_page.dart';
import 'attendance/attendance_page.dart';
import 'finger/fingerprint_test_page.dart';
import 'setting/setting_seeding_page.dart';
import 'login_screen.dart';
import '../services/auto_setting_seeder.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isSeeding = false;
  bool _isSeeded = false;

  @override
  void initState() {
    super.initState();
    _checkAndSeedOnce();
  }

  Future<void> _checkAndSeedOnce() async {
    final prefs = await SharedPreferences.getInstance();
    final alreadySeeded = prefs.getBool('settings_seeded') ?? false;

    if (!alreadySeeded) {
      setState(() => _isSeeding = true);

      await AutoSettingSeeder.seedIfNeeded();

      setState(() {
        _isSeeding = false;
        _isSeeded = true;
      });

      // Snackbar শুধু একবারই দেখাবে
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "✅ Settings seeded automatically (first install only)!",
            ),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } else {
      setState(() => _isSeeded = true);
    }
  }

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
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
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
          style: const TextStyle(fontSize: 18),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        const Icon(Icons.fingerprint, size: 80, color: Colors.blueGrey),
        const SizedBox(height: 10),
        Text(
          'Fingerprint Attendance',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.blueGrey[800],
          ),
        ),
        const SizedBox(height: 5),
        Text(
          'Quick and secure check-ins',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);

    void _confirmLogout() {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Logout Confirmation'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(ctx).pop();
                if (auth.token != null) {
                  await auth.logoutApi();
                } else {
                  auth.logout();
                }
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
              child: const Text('Logout', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            tooltip: 'Logout',
            onPressed: _confirmLogout,
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: _isSeeding
              ? const CircularProgressIndicator()
              : Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const SizedBox(height: 0),
              _buildHeader(),
              SizedBox(
                width: 250,
                child: _buildButton(
                  context: context,
                  label: 'Employee',
                  icon: Icons.badge,
                  destination: const EmployeePage(),
                  color: Colors.green,
                ),
              ),
              SizedBox(
                width: 250,
                child: _buildButton(
                  context: context,
                  label: 'Load Employee',
                  icon: Icons.person,
                  destination: const WorkerPage(),
                  color: Colors.indigo,
                ),
              ),
              SizedBox(
                width: 250,
                child: _buildButton(
                  context: context,
                  label: 'Finger Test',
                  icon: Icons.fingerprint,
                  destination: const FingerprintTestPage(),
                  color: Colors.orange,
                ),
              ),
              SizedBox(
                width: 250,
                child: _buildButton(
                  context: context,
                  label: 'Attendance',
                  icon: Icons.check_circle_outline,
                  destination: const AttendancePage(),
                  color: Colors.blueAccent,
                ),
              ),
              SizedBox(
                width: 250,
                child: _buildButton(
                  context: context,
                  label: 'Attendance List',
                  icon: Icons.list_alt,
                  destination: const AttendanceListPage(),
                  color: Colors.teal,
                ),
              ),
              SizedBox(
                width: 250,
                child: _buildButton(
                  context: context,
                  label: 'Setting',
                  icon: Icons.settings,
                  destination: const SettingSeedingPage(),
                  color: Colors.blueGrey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
