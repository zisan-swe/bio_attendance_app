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
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE employees (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        email TEXT,
        employee_no TEXT,
        phone TEXT,
        father_name TEXT,
        mother_name TEXT,
        dob TEXT,
        joining_date TEXT,
        employee_type Int, //1 is employee and 2 is worker 
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

  Future<int> insertEmployee(EmployeeModel employee) async {
    final db = await instance.database;
    return await db.insert('employees', employee.toMap());
  }

  Future<List<EmployeeModel>> getAllEmployees() async {
    final db = await instance.database;
    final result = await db.query(
      'employees',
      where: 'employee_type = ?',
      whereArgs: [1],
    );
    return result.map((e) => EmployeeModel.fromMap(e)).toList();
  }


  Future<int> updateEmployee(EmployeeModel employee) async {
    final db = await instance.database;
    return await db.update(
      'employees',
      employee.toMap(),
      where: 'id = ?',
      whereArgs: [employee.id],
    );
  }

  Future<int> deleteEmployee(int id) async {
    final db = await instance.database;
    return await db.delete(
      'employees',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
