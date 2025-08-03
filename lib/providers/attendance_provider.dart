import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import '../db/database_helper.dart';
import '../models/attendance_model.dart';

class AttendanceProvider with ChangeNotifier {
  final dbHelper = DatabaseHelper.instance;

  /// Insert new attendance record
  Future<int> insertAttendance(AttendanceModel attendance) async {
    final db = await dbHelper.database;
    final id = await db.insert('attendance', attendance.toMap());
    notifyListeners(); // <- NOW this runs
    return id;
  }

  /// Fetch all attendance records
  Future<List<AttendanceModel>> getAllAttendance() async {
    try {
      final db = await dbHelper.database;
      final result = await db.query('attendance');
      return result.map((map) => AttendanceModel.fromMap(map)).toList();
    } catch (e) {
      debugPrint('Error fetching attendance: $e');
      return [];
    }
  }


  /// Fetch attendance records by date
  Future<List<AttendanceModel>> getAttendanceByDate(String date) async {
    final db = await dbHelper.database;
    final result = await db.query(
      'attendance',
      where: 'working_date = ?',
      whereArgs: [date],
    );
    return result.map((map) => AttendanceModel.fromMap(map)).toList();
  }

  /// Fetch attendance records by employee number
  Future<List<AttendanceModel>> getAttendanceByEmployeeNo(String employeeNo) async {
    final db = await dbHelper.database;
    final result = await db.query(
      'attendance',
      where: 'employee_no = ?',
      whereArgs: [employeeNo],
    );
    return result.map((map) => AttendanceModel.fromMap(map)).toList();
  }

  /// Update an attendance record by ID
  Future<int> updateAttendance(AttendanceModel attendance) async {
    final db = await dbHelper.database;
    return await db.update(
      'attendance',
      attendance.toMap(),
      where: 'id = ?',
      whereArgs: [attendance.id],
    );
  }

  /// Delete attendance record by ID
  Future<int> deleteAttendance(int id) async {
    final db = await dbHelper.database;
    return await db.delete(
      'attendance',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Clear all attendance records (⚠️ Use with caution)
  Future<int> clearAllAttendance() async {
    final db = await dbHelper.database;
    return await db.delete('attendance');
  }

  /// Example placeholder for enrolled fingerprint retrieval
  // Future<List<String>> getEnrolledFingerprints({required String employeeNo}) async {
  //   // In real scenario: Query DB or API to fetch fingerprints
  //   return ['Left Thumb', 'Right Index']; // Dummy data
  // }

        //Extra***************
  Future<List<String>> getEnrolledFingerprints({required String employeeNo}) async {
    final db = await dbHelper.database;
    final result = await db.query(
      'employee',
      columns: [
        'finger_info1', 'finger_info2', 'finger_info3', 'finger_info4', 'finger_info5',
        'finger_info6', 'finger_info7', 'finger_info8', 'finger_info9', 'finger_info10'
      ],
      where: 'employee_no = ?',
      whereArgs: [employeeNo],
      limit: 1,
    );

    if (result.isNotEmpty) {
      final map = result.first;
      final enrolled = <String>[];
      map.forEach((key, value) {
        if (value != null && value.toString().isNotEmpty) {
          enrolled.add(key);
        }
      });
      return enrolled;
    }
    return [];
  }

  Future<void> insertBatchAttendance(List<AttendanceModel> records) async {
    final db = await dbHelper.database;
    final batch = db.batch();

    for (var record in records) {
      batch.insert('attendance', record.toMap());
    }

    await batch.commit(noResult: true);
    notifyListeners();
  }

  Future<List<AttendanceModel>> getAttendanceByProjectBlock(int projectId, int blockId) async {
    final db = await dbHelper.database;
    final result = await db.query(
      'attendance',
      where: 'project_id = ? AND block_id = ?',
      whereArgs: [projectId, blockId],
    );
    return result.map((map) => AttendanceModel.fromMap(map)).toList();
  }


}
