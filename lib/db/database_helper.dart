import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/employee_model.dart';

class DatabaseHelper {
  // Singleton pattern
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('biometric.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, filePath);
      return await openDatabase(
        path,
        version: 1,
        onCreate: _createDB,
        onConfigure: _onConfigure,
      );
    } catch (e) {
      throw Exception('Failed to initialize database: $e');
    }
  }

  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE employees (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT UNIQUE,
        employee_no TEXT UNIQUE,
        phone TEXT,
        father_name TEXT,
        mother_name TEXT,
        dob TEXT,
        joining_date TEXT,
        employee_type INTEGER DEFAULT 1, 
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
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Create indexes for better performance
    await db.execute('CREATE INDEX idx_employee_type ON employees(employee_type)');
    await db.execute('CREATE INDEX idx_employee_no ON employees(employee_no)');
  }

  // CRUD Operations

  /// Insert a new employee
  Future<int> insertEmployee(EmployeeModel employee) async {
    final db = await instance.database;
    try {
      return await db.insert(
        'employees',
        employee.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } on DatabaseException catch (e) {
      if (e.isUniqueConstraintError()) {
        throw Exception('Employee with this email or ID already exists');
      }
      rethrow;
    }
  }

  /// Get all employees (with optional filtering by type)
  Future<List<EmployeeModel>> getAllEmployees({int? employeeType}) async {
    final db = await instance.database;
    try {
      final result = employeeType != null
          ? await db.query(
        'employees',
        where: 'employee_type = ?',
        whereArgs: [employeeType],
        orderBy: 'name ASC',
      )
          : await db.query('employees', orderBy: 'name ASC');

      return result.map((e) => EmployeeModel.fromMap(e)).toList();
    } catch (e) {
      throw Exception('Failed to load employees: $e');
    }
  }

  /// Get single employee by ID
  Future<EmployeeModel?> getEmployeeById(int id) async {
    final db = await instance.database;
    try {
      final result = await db.query(
        'employees',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      return result.isNotEmpty ? EmployeeModel.fromMap(result.first) : null;
    } catch (e) {
      throw Exception('Failed to get employee by ID: $e');
    }
  }

  /// Get employee by employee number
  Future<EmployeeModel?> getEmployeeByNumber(String employeeNo) async {
    final db = await instance.database;
    try {
      final result = await db.query(
        'employees',
        where: 'employee_no = ?',
        whereArgs: [employeeNo],
        limit: 1,
      );
      return result.isNotEmpty ? EmployeeModel.fromMap(result.first) : null;
    } catch (e) {
      throw Exception('Failed to get employee by number: $e');
    }
  }

  /// Update employee
  Future<int> updateEmployee(EmployeeModel employee) async {
    final db = await instance.database;
    try {
      if (employee.id == null) throw Exception('Employee ID cannot be null');

      return await db.update(
        'employees',
        employee.toMap()..['updated_at'] = DateTime.now().toIso8601String(),
        where: 'id = ?',
        whereArgs: [employee.id],
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } on DatabaseException catch (e) {
      throw Exception('Failed to update employee: ${e.toString()}');
    }
  }

  /// Delete employee
  Future<int> deleteEmployee(int id) async {
    final db = await instance.database;
    try {
      return await db.delete(
        'employees',
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw Exception('Failed to delete employee: $e');
    }
  }

  /// Batch insert employees
  Future<void> insertEmployees(List<EmployeeModel> employees) async {
    final db = await instance.database;
    final batch = db.batch();
    try {
      for (var employee in employees) {
        batch.insert('employees', employee.toMap());
      }
      await batch.commit(noResult: true);
    } catch (e) {
      throw Exception('Failed to batch insert employees: $e');
    }
  }

  /// Search employees by name
  Future<List<EmployeeModel>> searchEmployees(String query) async {
    final db = await instance.database;
    try {
      final result = await db.query(
        'employees',
        where: 'name LIKE ?',
        whereArgs: ['%$query%'],
        orderBy: 'name ASC',
      );
      return result.map((e) => EmployeeModel.fromMap(e)).toList();
    } catch (e) {
      throw Exception('Failed to search employees: $e');
    }
  }

  /// Get employee count
  Future<int> getEmployeeCount({int? employeeType}) async {
    final db = await instance.database;
    try {
      final result = employeeType != null
          ? await db.rawQuery(
        'SELECT COUNT(*) FROM employees WHERE employee_type = ?',
        [employeeType],
      )
          : await db.rawQuery('SELECT COUNT(*) FROM employees');

      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      throw Exception('Failed to get employee count: $e');
    }
  }

  /// Close database connection
  Future<void> close() async {
    try {
      final db = await instance.database;
      await db.close();
      _database = null;
    } catch (e) {
      throw Exception('Failed to close database: $e');
    }
  }
}

// Extension to help identify unique constraint errors
extension DatabaseExceptionExtensions on DatabaseException {
  bool isUniqueConstraintError() {
    return toString().contains('UNIQUE constraint failed');
  }
}