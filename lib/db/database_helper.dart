import 'dart:convert'; // ✅ for JSON lists in finger_info fields
import 'dart:developer' as dev;
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/attendance_model.dart';
import '../models/employee_model.dart';
import '../models/setting_model.dart';
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

    // পুরোনো database ডিলিট করে দিন (শুধু dev/test এর জন্য)
    // await deleteDatabase(path);

    return await openDatabase(
      path,
      version: 18,
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
        employee_type TEXT NOT NULL,
        company_id INTEGER NOT NULL,
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
        image_path TEXT,
        department_id INTEGER,
        shift_id INTEGER,
        role_in_project TEXT,   -- "supervisor" | "worker"
        project_id TEXT,
        block_id TEXT
        
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
        status TEXT NOT NULL CHECK (status IN ('Regular', 'Early', 'Late')),
        remarks TEXT,
        synced INTEGER,
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

    // Company Settings table
    await db.execute('''
      CREATE TABLE company_settings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        company_name TEXT,
        address TEXT,
        branch_id INTEGER,
        user TEXT
      )
    ''');
  }

  /// Runs when version number increases
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    dev.log('🛠 Upgrading DB from $oldVersion to $newVersion', name: 'DatabaseHelper');

    // Add company_settings table when upgrading from versions <18
    if (oldVersion < 18) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS company_settings (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          company_name TEXT,
          address TEXT,
          branch_id INTEGER,
          user TEXT
        )
      ''');
      dev.log('✅ Created company_settings table', name: 'DatabaseHelper');
    }

    // Add 'company_id' to employee table if upgrading from <12
    if (oldVersion < 12) {
      final empColumns = await db.rawQuery("PRAGMA table_info(employee)");
      final empCols = empColumns.map((c) => c['name'] as String?).whereType<String>().toList();

      if (!empCols.contains('company_id')) {
        await db.execute('ALTER TABLE employee ADD COLUMN company_id INTEGER NOT NULL DEFAULT 1');
        dev.log('✅ Added company_id to employee table', name: 'DatabaseHelper');
      }
    }

    // Attendance table: Add 'status' column if missing
    if (oldVersion < 12) {
      final attColumns = await db.rawQuery("PRAGMA table_info(attendance)");
      final attCols = attColumns.map((c) => c['name'] as String?).whereType<String>().toList();

      if (!attCols.contains('status')) {
        await db.execute("ALTER TABLE attendance ADD COLUMN status TEXT NOT NULL DEFAULT 'Regular'");
        dev.log('✅ Added status to attendance table', name: 'DatabaseHelper');
      }
    }

    // Existing logic for settings table upgrade from <11
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

    // _onUpgrade এর ভিতরে শেষে যোগ করুন
    if (oldVersion < 17) {
      final cols = (await db.rawQuery('PRAGMA table_info(employee)'))
          .map((c) => c['name'] as String?)
          .whereType<String>()
          .toSet();

      Future<void> addCol(String name, String ddl) async {
        if (!cols.contains(name)) {
          await db.execute('ALTER TABLE employee ADD COLUMN $name $ddl');
          dev.log('✅ Added $name to employee', name: 'DatabaseHelper');
        }
      }

      await addCol('department_id', 'INTEGER');
      await addCol('shift_id', 'INTEGER');
      await addCol('role_in_project', 'TEXT');
      await addCol('project_id', 'TEXT');
      await addCol('block_id', 'TEXT');
    }

    if (oldVersion < 18) {
      await db.execute('ALTER TABLE employee RENAME TO employee_old');

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
      employee_type TEXT NOT NULL,
      company_id INTEGER NOT NULL,
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
      image_path TEXT,
      department_id INTEGER,
      shift_id INTEGER,
      role_in_project TEXT,
      project_id TEXT,
      block_id TEXT
    )
  ''');

      await db.execute('''
    INSERT INTO employee (
      id, name, email, employee_no, nid, daily_wages, phone,
      father_name, mother_name, dob, joining_date, employee_type,
      company_id, finger_info1, finger_info2, finger_info3, finger_info4,
      finger_info5, finger_info6, finger_info7, finger_info8, finger_info9,
      finger_info10, image_path, department_id, shift_id, role_in_project,
      project_id, block_id
    )
    SELECT
      id, name, email, employee_no, nid, daily_wages, phone,
      father_name, mother_name, dob, joining_date, employee_type,
      company_id, finger_info1, finger_info2, finger_info3, finger_info4,
      finger_info5, finger_info6, finger_info7, finger_info8, finger_info9,
      finger_info10, image_path, department_id, shift_id, role_in_project,
      project_id, block_id
    FROM employee_old
  ''');

      await db.execute('DROP TABLE employee_old');
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

  Future<List<EmployeeModel>> getAllEmployees({String? employeeType}) async {
    final db = await database;

    final result = employeeType != null
        ? await db.query(
      'employee',
      where: 'employee_type = ?',
      whereArgs: [employeeType],
    )
        : await db.query('employee');

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
      conflictAlgorithm: ConflictAlgorithm.abort, // ✅ নতুন row add করবে, পুরনো delete করবে না
    );
  }

  Future<List<AttendanceModel>> getAllAttendance() async {
    final db = await instance.database;
    final result = await db.query(
      'attendance',
      orderBy: 'create_at DESC',
    );
    return result.map((e) => AttendanceModel.fromMap(e)).toList();
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


  Future<List<AttendanceModel>> getAttendanceByDate(String ymd) async {
    final db = await database;
    final result = await db.query(
      'attendance',
      where: 'working_date = ?',
      whereArgs: [ymd],
      orderBy: 'create_at DESC',
    );
    return result.map((e) => AttendanceModel.fromMap(e)).toList();
  }

  Future<int> countAttendanceByDate(String ymd) async {
    final db = await database;
    final x = Sqflite.firstIntValue(await db.rawQuery(
      'SELECT COUNT(*) FROM attendance WHERE working_date = ?',
      [ymd],
    ));
    return x ?? 0;
  }

  // ---------------- Fingerprint matching (supports JSON lists) ----------------
  /// Looks for a match of [scannedTemplate] in any employee's stored templates.
  /// Each finger_infoX can be:
  ///   - a plain single template string
  ///   - a JSON array string: ["tpl1", "tpl2", ...]

  // Future<EmployeeModel?> getEmployeeByFingerprint(
  //     String scannedTemplate, {
  //       double threshold = 40.0,
  //     }) async {
  //   final db = await database;
  //   final List<Map<String, dynamic>> maps = await db.query('employee');
  //   if (maps.isEmpty) return null;
  //
  //   for (final map in maps) {
  //     final employee = EmployeeModel.fromMap(map);
  //
  //     // Collect all stored templates across finger_info1..10
  //     final storedTemplates = <String>[];
  //
  //     for (int i = 1; i <= 10; i++) {
  //       final raw = map['finger_info$i'] as String?;
  //       if (raw == null || raw.isEmpty) continue;
  //
  //       // If JSON list -> add all; else add single
  //       try {
  //         final decoded = jsonDecode(raw);
  //         if (decoded is List) {
  //           for (final e in decoded) {
  //             final s = (e ?? '').toString();
  //             if (s.isNotEmpty) storedTemplates.add(s);
  //           }
  //         } else {
  //           // not a list (string/other) — treat as single
  //           storedTemplates.add(raw);
  //         }
  //       } catch (_) {
  //         // not JSON — treat as single
  //         storedTemplates.add(raw);
  //       }
  //     }
  //
  //     if (storedTemplates.isEmpty) continue;
  //
  //     try {
  //       final verificationResult = await FingerprintService.verifyFingerprint(
  //         scannedTemplate: scannedTemplate,
  //         storedTemplates: storedTemplates,
  //       );
  //
  //       if (verificationResult['matched'] == true &&
  //           (verificationResult['score'] ?? 0) >= threshold) {
  //         dev.log(
  //           '✅ Matched fingerprint for ${employee.name} with score: ${verificationResult['score']}',
  //           name: 'DatabaseHelper',
  //         );
  //         return employee;
  //       }
  //     } catch (e) {
  //       dev.log(
  //         '❌ Verification error for ${employee.name}: $e',
  //         name: 'DatabaseHelper',
  //       );
  //       // continue to next employee
  //     }
  //   }
  //
  //   dev.log('⚠️ No fingerprint match found', name: 'DatabaseHelper');
  //   return null;
  // }


  Future<EmployeeModel?> getEmployeeByFingerprint(
      String scannedTemplate, {
        double threshold = 40.0,
      }) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('employee');
    if (maps.isEmpty) return null;

    // helper: decode one finger_info column to List<String>
    List<String> _decodeSamples(dynamic raw) {
      if (raw == null) return const [];
      final s = raw.toString();
      if (s.isEmpty) return const [];
      try {
        final j = jsonDecode(s);
        if (j is List) {
          return j.map((e) => (e ?? '').toString())
              .where((e) => e.isNotEmpty)
              .toList();
        }
      } catch (_) {
        // legacy single-string template
        return [s];
      }
      return const [];
    }

    for (var map in maps) {
      final employee = EmployeeModel.fromMap(map);

      // collect ALL samples from finger_info1..10
      final storedTemplates = <String>[];
      for (int i = 1; i <= 10; i++) {
        storedTemplates.addAll(_decodeSamples(map['finger_info$i']));
      }

      if (storedTemplates.isEmpty) continue;

      try {
        final verificationResult = await FingerprintService.verifyFingerprint(
          scannedTemplate: scannedTemplate,
          storedTemplates: storedTemplates,
        );

        if (verificationResult['matched'] == true &&
            (verificationResult['score'] ?? 0) >= threshold) {
          dev.log('✅ Matched fingerprint for ${employee.name} '
              'with score: ${verificationResult['score']}',
              name: 'DatabaseHelper');
          return employee;
        }
      } catch (e) {
        dev.log('❌ Verification error for ${employee.name}: $e',
            name: 'DatabaseHelper');
        continue;
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

  /// First settings row (if any)
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

  // ---------------- Company Settings CRUD ----------------
  Future<int> insertCompanySetting({
    required String companyName,
    String? address,
    int? branchId,
    String? user,
  }) async {
    final db = await instance.database;
    return await db.insert(
      'company_settings',
      {
        'company_name': companyName,
        'address': address,
        'branch_id': branchId,
        'user': user,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, dynamic>?> getFirstCompanySetting() async {
    final db = await instance.database;
    final rows = await db.query('company_settings', orderBy: 'id ASC', limit: 1);
    return rows.isNotEmpty ? rows.first : null;
  }

  Future<List<Map<String, dynamic>>> getAllCompanySettings() async {
    final db = await instance.database;
    return await db.query('company_settings', orderBy: 'id ASC');
  }

  Future<int> updateCompanySetting(
      int id, {
        String? companyName,
        String? address,
        int? branchId,
        String? user,
      }) async {
    final db = await instance.database;
    final updates = <String, Object?>{};
    if (companyName != null) updates['company_name'] = companyName;
    if (address != null) updates['address'] = address;
    if (branchId != null) updates['branch_id'] = branchId;
    if (user != null) updates['user'] = user;

    if (updates.isEmpty) return 0;
    return await db.update('company_settings', updates, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteCompanySetting(int id) async {
    final db = await instance.database;
    return await db.delete('company_settings', where: 'id = ?', whereArgs: [id]);
  }

  // ---------------- Close DB ----------------
  Future<void> close() async {
    if (_database != null && _database!.isOpen) {
      await _database!.close();
      _database = null;
    }
  }
}
