import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/employee_model.dart';
import '../models/attendance_model.dart';
import '../models/setting_model.dart';
import 'dart:developer' as dev;
import '../../services/fingerprint_service.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null && _database!.isOpen) return _database!;
    _database = await _initDB('biometric.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 12, // ⬅️ bumped version so _onUpgrade runs
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  /// Create all tables fresh (first install or after delete DB)
  Future<void> _createDB(Database db, int version) async {
    // Employee table
    await db.execute('''
      CREATE TABLE employee (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT,
        employee_no TEXT NOT NULL,
        nid TEXT,
        daily_wages DOUBLE,
        phone TEXT,
        father_name TEXT,
        mother_name TEXT,
        dob TEXT,
        joining_date TEXT,
        employee_type INTEGER NOT NULL,
        finger_info1 TEXT,
        finger_info2 TEXT,
        finger_info3 TEXT,
        finger_info4 TEXT,
        finger_info5 TEXT,
        finger_info6 TEXT,
        finger_info7 TEXT,
        finger_info8 TEXT,
        finger_info9 TEXT,
        finger_info10 TEXT,
        image_path TEXT
      )
    ''');

    // Attendance table
    await db.execute('''
      CREATE TABLE attendance (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        device_id TEXT NOT NULL,
        project_id INTEGER NOT NULL,
        block_id INTEGER NOT NULL,
        employee_no TEXT NOT NULL,
        working_date TEXT NOT NULL,
        attendance_status TEXT NOT NULL,
        fingerprint TEXT NOT NULL,
        in_time TEXT,
        out_time TEXT,
        location TEXT,
        status INTEGER NOT NULL,
        remarks TEXT,
        create_at TEXT NOT NULL,
        update_at TEXT NOT NULL
      )
    ''');

    // Settings table
    await db.execute('''
      CREATE TABLE settings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        value TEXT,
        slug TEXT UNIQUE
      )
    ''');
  }

  /// Runs when version number increases
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Add fingerprint column if upgrading from < v10
    if (oldVersion < 10) {
      final result = await db.rawQuery("PRAGMA table_info(attendance)");
      final columns = result.map((row) => row['name'] as String?).whereType<String>().toList();

      if (!columns.contains('fingerprint')) {
        await db.execute(
          'ALTER TABLE attendance ADD COLUMN fingerprint TEXT NOT NULL DEFAULT ""',
        );
      }
    }

    // Update settings table if upgrading from < v11
    if (oldVersion < 11) {
      await db.execute('ALTER TABLE settings RENAME TO settings_old');
      await db.execute('''
    CREATE TABLE settings (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      value TEXT,
      slug TEXT UNIQUE
    )
  ''');
      await db.execute('''
    INSERT INTO settings (id, name, value, slug)
    SELECT id, company_name, company_value, slug FROM settings_old
  ''');
      await db.execute('DROP TABLE settings_old');
    }
  }


  // ---------------- Employee CRUD ----------------
  Future<int> insertEmployee(EmployeeModel employee) async {
    final db = await instance.database;
    return await db.insert(
      'employee',
      employee.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<EmployeeModel>> getAllEmployees({required int employeeType}) async {
    final db = await instance.database;
    final result = await db.query(
      'employee',
      where: 'employee_type = ?',
      whereArgs: [employeeType],
    );
    return result.map((e) => EmployeeModel.fromMap(e)).toList();
  }

  Future<int> updateEmployee(EmployeeModel employee) async {
    final db = await instance.database;
    return await db.update(
      'employee',
      employee.toMap(),
      where: 'id = ?',
      whereArgs: [employee.id],
    );
  }

  Future<int> deleteEmployee(int id) async {
    final db = await instance.database;
    return await db.delete(
      'employee',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<EmployeeModel?> getEmployeeByNumber(dynamic employeeNo) async {
    final db = await instance.database;
    final result = await db.query(
      'employee',
      where: 'employee_no = ?',
      whereArgs: [employeeNo],
      limit: 1,
    );
    return result.isNotEmpty ? EmployeeModel.fromMap(result.first) : null;
  }

  // ---------------- Attendance CRUD ----------------
  Future<int> insertAttendance(AttendanceModel attendance) async {
    final db = await instance.database;
    return await db.insert(
      'attendance',
      attendance.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> deleteAttendance(int id) async {
    final db = await instance.database;
    return await db.delete('attendance', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> updateAttendance(AttendanceModel attendance) async {
    final db = await instance.database;
    return await db.update(
      'attendance',
      attendance.toMap(),
      where: 'id = ?',
      whereArgs: [attendance.id],
    );
  }

  // ---------------- Fingerprint matching ----------------
  Future<EmployeeModel?> getEmployeeByFingerprint(
      String scannedTemplate, {
        double threshold = 40.0,
      }) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('employee');
    if (maps.isEmpty) return null;

    for (var map in maps) {
      EmployeeModel employee = EmployeeModel.fromMap(map);

      // Collect all finger_info templates
      final storedTemplates = <String>[];
      for (int i = 1; i <= 10; i++) {
        String? storedTemplate = map['finger_info$i'] as String?;
        if (storedTemplate != null && storedTemplate.isNotEmpty) {
          storedTemplates.add(storedTemplate);
        }
      }

      if (storedTemplates.isNotEmpty) {
        try {
          final verificationResult =
          await FingerprintService.verifyFingerprint(
            scannedTemplate: scannedTemplate,
            storedTemplates: storedTemplates,
          );

          if (verificationResult['matched'] == true &&
              (verificationResult['score'] ?? 0) >= threshold) {
            dev.log(
              '✅ Matched fingerprint for ${employee.name} with score: ${verificationResult['score']}',
              name: 'DatabaseHelper',
            );
            return employee;
          }
        } catch (e) {
          dev.log(
            '❌ Verification error for ${employee.name}: $e',
            name: 'DatabaseHelper',
          );
          continue;
        }
      }
    }

    dev.log('⚠️ No fingerprint match found', name: 'DatabaseHelper');
    return null;
  }

  // ---------------- Settings CRUD ----------------
  Future<int> insertSetting(SettingModel setting) async {
    final db = await instance.database;
    return await db.insert(
      'settings',
      setting.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<SettingModel>> getAllSettings() async {
    final db = await instance.database;
    final result = await db.query('settings');
    return result.map((e) => SettingModel.fromMap(e)).toList();
  }

  Future<SettingModel?> getSettingBySlug(String slug) async {
    final db = await instance.database;
    final result = await db.query(
      'settings',
      where: 'slug = ?',
      whereArgs: [slug],
      limit: 1,
    );
    return result.isNotEmpty ? SettingModel.fromMap(result.first) : null;
  }

  Future<int> updateSetting(SettingModel setting) async {
    final db = await instance.database;
    return await db.update(
      'settings',
      setting.toMap(),
      where: 'id = ?',
      whereArgs: [setting.id],
    );
  }

  Future<int> deleteSetting(int id) async {
    final db = await instance.database;
    return await db.delete(
      'settings',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // database_helper.dart

  Future<SettingModel?> getFirstSetting() async {
    final db = await instance.database;
    final maps = await db.query(
      'settings',
      orderBy: 'id ASC',
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return SettingModel.fromMap(maps.first);
    }
    return null;
  }


  // ---------------- Close DB ----------------
  Future<void> close() async {
    if (_database != null && _database!.isOpen) {
      await _database!.close();
      _database = null;
    }
  }
}
