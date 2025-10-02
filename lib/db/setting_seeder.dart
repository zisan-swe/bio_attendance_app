import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import '../screens/setting/settings_list_page.dart';

class SettingSeeder extends StatelessWidget {
  const SettingSeeder({super.key});

  Future<void> seedDummySettings() async {
    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, 'biometric.db');

      final db = await openDatabase(
        path,
        version: 2, // 🔼 bump version
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS settings(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL,
              value TEXT,
              slug TEXT UNIQUE
            )
          ''');
        },
      );

      // Ensure table exists (if upgrading manually)
      await db.execute('''
        CREATE TABLE IF NOT EXISTS settings(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          value TEXT,
          slug TEXT UNIQUE
        )
      ''');

      // Clear old data
      await db.delete('settings');

      // Dummy data
      final dummySettings = [
        {
          'name': 'Project Code',
          'value': '10',
          'slug': 'project_id',
        },
        {
          'name': 'Block',
          'value': '2',
          'slug': 'block_id',
        },
        {
          'name': 'Company',
          'value': '1',
          'slug': 'company_id',
        },
      ];

      for (var setting in dummySettings) {
        await db.insert(
          'settings',
          setting,
          conflictAlgorithm: ConflictAlgorithm.replace, // ✅ overwrite if exists
        );
      }
    } catch (e) {
      debugPrint("❌ Error seeding settings: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Setting Seeder')),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            await seedDummySettings();

            // Navigate to Settings List Page
            if (context.mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsListPage(),
                ),
              );
            }
          },
          child: const Text('Seed Dummy Settings'),
        ),
      ),
    );
  }
}
