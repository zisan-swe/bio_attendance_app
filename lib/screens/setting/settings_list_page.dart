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

    final data = await db.query('settings', orderBy: "id DESC");
    setState(() {
      _settings = data;
    });
  }

  Future<void> _editOrAddSetting(
      BuildContext parentContext, {
        Map<String, dynamic>? setting,
      }) async {
    final nameController = TextEditingController(text: setting?['name'] ?? '');
    final valueController = TextEditingController(text: setting?['value'] ?? '');
    final slugController = TextEditingController(text: setting?['slug'] ?? '');

    final isEdit = setting != null;

    await showDialog(
      context: parentContext,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(isEdit ? "Edit Setting" : "Add Setting"),
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
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: "Slug",
                  // Optionally add hint or change style
                ),
                style: TextStyle(color: Colors.grey), // Makes it look "disabled"
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

                if (isEdit) {
                  await db.update(
                    'settings',
                    {
                      'name': nameController.text,
                      'value': valueController.text,
                      'slug': slugController.text,
                    },
                    where: 'id = ?',
                    whereArgs: [setting!['id']],
                  );
                } else {
                  await db.insert(
                    'settings',
                    {
                      'name': nameController.text,
                      'value': valueController.text,
                      'slug': slugController.text,
                    },
                  );
                }

                Navigator.pop(dialogContext);
                _loadSettings();
              },
              child: Text(isEdit ? "Save" : "Add"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteSetting(int id) async {
    final db = await _openDB();
    await db.delete('settings', where: 'id = ?', whereArgs: [id]);
    _loadSettings();
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
                backgroundColor: Colors.blueGrey,
                child: Text(item['id'].toString(),
                    style: const TextStyle(color: Colors.white)),
              ),
              title: Text(item['name'] ?? '',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Value: ${item['value']}"),
                  Text("Slug: ${item['slug']}"),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () => _editOrAddSetting(context, setting: item),
                  ),
                  // IconButton(
                  //   icon: const Icon(Icons.delete, color: Colors.red),
                  //   onPressed: () => _deleteSetting(item['id']),
                  // ),
                ],
              ),
            ),
          );
        },
      ),
  //Add Button
      // floatingActionButton: FloatingActionButton(
      //   onPressed: () => _editOrAddSetting(context),
      //   child: const Icon(Icons.add),
      // ),
    );
  }
}
