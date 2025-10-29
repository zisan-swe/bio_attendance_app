import 'package:flutter/material.dart';
import '../../db/setting_seeder.dart';
import 'company_settings_info.dart';
import 'settings_list_page.dart';

class SettingSeedingPage extends StatefulWidget {
  const SettingSeedingPage({super.key});

  @override
  State<SettingSeedingPage> createState() => _SettingSeedingPageState();
}

class _SettingSeedingPageState extends State<SettingSeedingPage> {
  final seeder = SettingSeeder();
  bool _isSeeded = false; // Track whether seeding is done
  bool _isLoading = false; // Optional: show loading state while seeding

  Future<void> _seedSettings() async {
    setState(() => _isLoading = true);

    await seeder.seedDummySettings();

    setState(() {
      _isSeeded = true;
      _isLoading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("✅ Dummy settings seeded successfully!"),
        behavior: SnackBarBehavior.floating,
        showCloseIcon: true,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Setting Seeder Page"),
        centerTitle: true,
        elevation: 25,
        backgroundColor: Colors.blueGrey,
        titleTextStyle: const TextStyle(
          fontSize: 25,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.storage),
              label: _isLoading
                  ? const Text("Seeding...")
                  : Text(_isSeeded ? "Settings Seeded" : "Seed Settings"),
              onPressed: _isSeeded || _isLoading ? null : _seedSettings,
            ),

            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.settings_display_sharp),
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
            ElevatedButton.icon(
              icon: const Icon(Icons.settings_applications),
              label: const Text("Company Settings Info"),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CompanySettingsInfoPage(),
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
