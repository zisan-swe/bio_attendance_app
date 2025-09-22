import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import '../screens/setting/settings_list_page.dart';


class SettingSeeder extends StatelessWidget {
  const SettingSeeder({super.key});

  Future<void> seedDummySettings() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'biometric.db');

    final db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS settings(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            value TEXT,
            slug TEXT
          )
        ''');
      },
    );

    // Ensure table exists
    await db.execute('''
      CREATE TABLE IF NOT EXISTS settings(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        value TEXT,
        slug TEXT
      )
    ''');

    // Clear old data
    await db.delete('settings');

    // Dummy data
    List<Map<String, dynamic>> dummySettings = [
      {
        'name': 'Project Code',
        'value': '1',
        'slug': 'project_code',
      },

      {
        'name': 'Block',
        'value': '2',
        'slug': 'block',
      },

      {
        'name': 'Project 1',
        'value': '33',
        'slug': 'project1',
      },

    ];

    for (var setting in dummySettings) {
      await db.insert('settings', setting);
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
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SettingsListPage(),
              ),
            );
          },
          child: const Text('Seed Dummy Settings'),
        ),
      ),
    );
  }
}
