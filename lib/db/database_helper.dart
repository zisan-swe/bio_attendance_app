import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/employee_model.dart';
import '../models/attendance_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null && _database!.isOpen) return _database!;

    // Don't delete database every time — only during development if you want.
    //  await deleteDatabase(join(await getDatabasesPath(), 'biometric.db'));

    _database = await _initDB('biometric.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 10,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _createDB(Database db, int version) async {
    // Employee table
    await db.execute('''
      CREATE TABLE employee (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        email TEXT,
        employee_no TEXT,
        nid TEXT,
        daily_wages DOUBLE,
        phone TEXT,
        father_name TEXT,
        mother_name TEXT,
        dob TEXT,
        joining_date TEXT,
        employee_type INTEGER,
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
        device_id TEXT,
        project_id INTEGER,
        block_id INTEGER,
        employee_no TEXT,
        working_date TEXT,
        attendance_status TEXT,
        fingerprint TEXT,
        in_time TEXT,
        out_time TEXT,
        location TEXT,          -- renamed from check_out_location to location
        status INTEGER,
        remarks TEXT,
        create_at TEXT,
        update_at TEXT          -- fixed typo from update_ad to update_at
      )
    ''');
  }
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 10) {
      final result = await db.rawQuery("PRAGMA table_info(attendance)");
      final columns = result.map((row) => row['name']).toList();

      if (!columns.contains('fingerprint')) {
        await db.execute('ALTER TABLE attendance ADD COLUMN fingerprint TEXT');
      }
    }
  }

  // Employee CRUD operations

  Future<int> insertEmployee(EmployeeModel employee) async {
    final db = await instance.database;
    return await db.insert('employee', employee.toMap());
  }

  // Future<List<EmployeeModel>> getAllEmployees() async {
  //   final db = await instance.database;
  //   final result = await db.query(
  //     'employee',
  //     where: 'employee_type = ?',
  //     whereArgs: [1],
  //   );
  //   return result.map((e) => EmployeeModel.fromMap(e)).toList();
  // }

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

  // Attendance CRUD

  Future<int> insertAttendance(AttendanceModel attendance) async {
    final db = await instance.database;
    return await db.insert('attendance', attendance.toMap());
  }

  Future close() async {
    if (_database != null && _database!.isOpen) {
      await _database!.close();
      _database = null;
    }
  }
}
