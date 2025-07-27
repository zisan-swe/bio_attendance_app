import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/employee_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    // Only for development!
    // await deleteDatabase(join(await getDatabasesPath(), 'biometric.db'));

    if (_database != null) return _database!;
    _database = await _initDB('biometric.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 7, // Updated version
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _createDB(Database db, int version) async {
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

    await db.execute('''
      CREATE TABLE attendance (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        device_id TEXT,
        project_id INTEGER,
        block_id INTEGER,
        employee_no INTEGER,
        working_date TEXT,
        attendance_data TEXT,
        check_in_location TEXT,
        in_time TEXT,
        out_time TEXT,
        check_out_location TEXT,
        status INTEGER,
        remarks TEXT,
        create_at TEXT,
        update_ad TEXT
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 5) {
      await db.execute('ALTER TABLE employee ADD COLUMN phone TEXT');
    }

    if (oldVersion < 7) {
      await db.execute('''
        CREATE TABLE attendance (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          device_id TEXT,
          project_id INTEGER,
          block_id INTEGER,
          employee_no INTEGER,
          working_date TEXT,
          attendance_data TEXT,
          check_in_location TEXT,
          in_time TEXT,
          out_time TEXT,
          check_out_location TEXT,
          status INTEGER,
          remarks TEXT,
          create_at TEXT,
          update_ad TEXT
        )
      ''');
    }
  }

  Future<int> insertEmployee(EmployeeModel employee) async {
    final db = await instance.database;
    return await db.insert('employee', employee.toMap());
  }

  Future<List<EmployeeModel>> getAllEmployees() async {
    final db = await instance.database;
    final result = await db.query(
      'employee',
      where: 'employee_type = ?',
      whereArgs: [1],
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

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
