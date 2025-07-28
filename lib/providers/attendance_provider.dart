import 'package:flutter/cupertino.dart';
import 'package:sqflite/sqflite.dart';
import '../db/database_helper.dart';
import '../models/attendance_model.dart';

class AttendanceProvider with ChangeNotifier{
  final dbHelper = DatabaseHelper.instance;


  /// Insert new attendance record
  Future<int> insertAttendance(AttendanceModel attendance) async {
    final db = await dbHelper.database;
    return await db.insert('attendance', attendance.toMap());
  }

  /// Fetch all attendance records
  Future<List<AttendanceModel>> getAllAttendance() async {
    final db = await dbHelper.database;
    final result = await db.query('attendance');
    return result.map((map) => AttendanceModel.fromMap(map)).toList();
  }

  /// Fetch attendance records by working date
  Future<List<AttendanceModel>> getAttendanceByDate(String date) async {
    final db = await dbHelper.database;
    final result = await db.query(
      'attendance',
      where: 'working_date = ?',
      whereArgs: [date],
    );
    return result.map((map) => AttendanceModel.fromMap(map)).toList();
  }

  /// Fetch attendance by employee number
  Future<List<AttendanceModel>> getAttendanceByEmployeeNo(int employeeNo) async {
    final db = await dbHelper.database;
    final result = await db.query(
      'attendance',
      where: 'employee_no = ?',
      whereArgs: [employeeNo],
    );
    return result.map((map) => AttendanceModel.fromMap(map)).toList();
  }

  /// Update an existing attendance record
  Future<int> updateAttendance(AttendanceModel attendance) async {
    final db = await dbHelper.database;
    return await db.update(
      'attendance',
      attendance.toMap(),
      where: 'id = ?',
      whereArgs: [attendance.id],
    );
  }

  /// Delete attendance by ID
  Future<int> deleteAttendance(int id) async {
    final db = await dbHelper.database;
    return await db.delete(
      'attendance',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Clear all attendance records (use with caution!)
  Future<int> clearAllAttendance() async {
    final db = await dbHelper.database;
    return await db.delete('attendance');
  }
}
