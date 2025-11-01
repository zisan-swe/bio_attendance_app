import 'package:biometric_attendance/providers/company_settings_provider.dart';
import 'package:biometric_attendance/providers/settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'db/database_helper.dart';
import 'providers/auth_provider.dart';
import 'providers/employee_provider.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart'; // ✅ Add this import
import 'package:timezone/data/latest.dart' as tz;
import 'providers/attendance_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize database helper
  final dbHelper = DatabaseHelper.instance;
  tz.initializeTimeZones(); // Initialize timezones

  try {
    // Verify database connection
    final db = await dbHelper.database;
    if (db.isOpen) {
      debugPrint('Database initialized successfully');
    }

    // ✅ Create AuthProvider and check for saved credentials
    final authProvider = AuthProvider();
    await authProvider.tryAutoLogin(); // auto-load saved login info

    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: authProvider),
          ChangeNotifierProvider(create: (_) => EmployeeProvider()),
          ChangeNotifierProvider(create: (_) => SettingsProvider()),
          ChangeNotifierProvider(create: (_) => CompanySettingsProvider()..load()),
          ChangeNotifierProvider(create: (_) => AttendanceProvider()),
        ],
        child: MyApp(),
      ),
    );
  } catch (e) {
    debugPrint('Failed to initialize database: $e');
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('Failed to initialize app: $e'),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return MaterialApp(
      title: 'Biometric Attendance App',
      theme: ThemeData(primarySwatch: Colors.blueGrey),
      darkTheme: ThemeData(primarySwatch: Colors.indigo),
      debugShowCheckedModeBanner: false,

      // ✅ If user already logged in, skip login screen
      home: auth.isAuthenticated ?  HomeScreen() : const LoginScreen(),
    );
  }
}
