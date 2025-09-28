import 'package:flutter/material.dart';
import '../../db/attendance_seeder.dart';


class AttendanceSeedingPage extends StatelessWidget {
  const AttendanceSeedingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final seeder = AttendanceSeeder();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Attendance Seeder Page"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.fingerprint),
              label: const Text("Seed Attendance"),
              onPressed: () async {
                await AttendanceSeeder.seedAttendance();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("✅ Dummy attendance seeded successfully!"),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
