import 'package:flutter/material.dart';
import '../../db/setting_seeder.dart';
import '../../db/attendance_seeder.dart'; // Make sure this is imported
import 'settings_list_page.dart';

class SettingSeedingPage extends StatelessWidget {
  const SettingSeedingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final seeder = SettingSeeder();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Setting Seeder Page"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.storage),
              label: const Text("Seed Settings"),
              onPressed: () async {
                await seeder.seedDummySettings();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("✅ Dummy settings seeded successfully!"),
                  ),
                );
              },
            ),

            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.list),
              label: const Text("View Settings"),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SettingsListPage(),
                  ),
                );
              },
            ),

            const SizedBox(height: 20),
            // ElevatedButton.icon(
            //   icon: const Icon(Icons.fingerprint),
            //   label: const Text("Seed Attendance"),
            //   onPressed: () async {
            //     await AttendanceSeeder.seedAttendance();
            //     ScaffoldMessenger.of(context).showSnackBar(
            //       const SnackBar(
            //         content: Text("✅ Dummy attendance seeded successfully!"),
            //       ),
            //     );
            //   },
            // ),
          ],
        ),
      ),
    );
  }
}
