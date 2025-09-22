import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class SettingsListPage extends StatefulWidget {
  const SettingsListPage({super.key});

  @override
  State<SettingsListPage> createState() => _SettingsListPageState();
}

class _SettingsListPageState extends State<SettingsListPage> {
  List<Map<String, dynamic>> _settings = [];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<Database> _openDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'biometric.db');
    return await openDatabase(path, version: 1);
  }

  Future<void> _loadSettings() async {
    final db = await _openDB();

    await db.execute('''
      CREATE TABLE IF NOT EXISTS settings(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        value TEXT,
        slug TEXT
      )
    ''');

    final data = await db.query('settings');
    setState(() {
      _settings = data;
    });
  }

  Future<void> _editSetting(BuildContext parentContext, Map<String, dynamic> setting) async {
    final nameController = TextEditingController(text: setting['name']);
    final valueController = TextEditingController(text: setting['value']);
    final slugController = TextEditingController(text: setting['slug']);

    await showDialog(
      context: parentContext, // ✅ BuildContext ব্যবহার
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text("Edit Setting"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Name"),
              ),
              TextField(
                controller: valueController,
                decoration: const InputDecoration(labelText: "Value"),
              ),
              TextField(
                controller: slugController,
                decoration: const InputDecoration(labelText: "Slug"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                final db = await _openDB();
                await db.update(
                  'settings',
                  {
                    'name': nameController.text,
                    'value': valueController.text,
                    'slug': slugController.text,
                  },
                  where: 'id = ?',
                  whereArgs: [setting['id']],
                );
                Navigator.pop(dialogContext);
                _loadSettings();
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Settings List")),
      body: _settings.isEmpty
          ? const Center(child: Text("⚠ No settings found!"))
          : ListView.builder(
        itemCount: _settings.length,
        itemBuilder: (context, index) {
          final item = _settings[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ListTile(
              leading: CircleAvatar(
                child: Text(item['id'].toString()),
              ),
              title: Text(item['name'] ?? ''),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Value: ${item['value']}"),
                  Text("Slug: ${item['slug']}"),
                ],
              ),
              trailing: IconButton(
                icon: const Icon(Icons.edit, color: Colors.blue),
                onPressed: () => _editSetting(context, item),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadSettings,
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
