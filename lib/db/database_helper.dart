import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/employee_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('biometric.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 4, // Increment this if schema changed
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
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS employee_temp AS 
        SELECT 
          id, name, email, employee_no, phone, father_name, mother_name, dob, 
          joining_date, CAST(employee_type AS INTEGER) AS employee_type,
          finger_info1, finger_info2, finger_info3, finger_info4, finger_info5,
          finger_info6, finger_info7, finger_info8, finger_info9, finger_info10,
          image_path
        FROM employee
      ''');

      await db.execute('DROP TABLE employee');
      await db.execute('ALTER TABLE employee_temp RENAME TO employee');
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
