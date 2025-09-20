import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:intl/intl.dart'; // Import for DateFormat
import '../db/database_helper.dart';
import '../models/attendance_model.dart';
import '../../services/fingerprint_service.dart'; // Import for FingerprintService
import '../models/employee_model.dart'; // Ensure EmployeeModel is imported

class AttendanceProvider with ChangeNotifier {
  final DatabaseHelper dbHelper = DatabaseHelper.instance;

  /// Insert a new attendance record
  Future<int> insertAttendance(AttendanceModel attendance) async {
    try {
      final db = await dbHelper.database;
      final id = await db.insert('attendance', attendance.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
      notifyListeners();
      return id;
    } catch (e) {
      debugPrint('Error inserting attendance: $e');
      return -1; // Return -1 to indicate failure
    }
  }

  /// Fetch all attendance records
  Future<List<AttendanceModel>> getAllAttendance() async {
    try {
      final db = await dbHelper.database;
      final result = await db.query('attendance', orderBy: 'create_at DESC');
      return result.map((map) => AttendanceModel.fromMap(map)).toList();
    } catch (e) {
      debugPrint('Error fetching attendance: $e');
      return [];
    }
  }

  /// Fetch attendance records by date
  Future<List<AttendanceModel>> getAttendanceByDate(String date) async {
    try {
      final db = await dbHelper.database;
      final result = await db.query(
        'attendance',
        where: 'working_date = ?',
        whereArgs: [date],
        orderBy: 'create_at DESC',
      );
      return result.map((map) => AttendanceModel.fromMap(map)).toList();
    } catch (e) {
      debugPrint('Error fetching attendance by date: $e');
      return [];
    }
  }

  /// Fetch attendance records by employee number
  Future<List<AttendanceModel>> getAttendanceByEmployeeNo(String employeeNo) async {
    try {
      final db = await dbHelper.database;
      final result = await db.query(
        'attendance',
        where: 'employee_no = ?',
        whereArgs: [employeeNo],
        orderBy: 'create_at DESC',
      );
      return result.map((map) => AttendanceModel.fromMap(map)).toList();
    } catch (e) {
      debugPrint('Error fetching attendance by employee: $e');
      return [];
    }
  }

  /// Update an attendance record by ID
  Future<int> updateAttendance(AttendanceModel attendance) async {
    try {
      final db = await dbHelper.database;
      return await db.update(
        'attendance',
        attendance.toMap(),
        where: 'id = ?',
        whereArgs: [attendance.id],
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      debugPrint('Error updating attendance: $e');
      return 0; // Return 0 to indicate failure
    }
  }

  /// Delete attendance record by ID
  Future<int> deleteAttendance(int id) async {
    try {
      final db = await dbHelper.database;
      return await db.delete(
        'attendance',
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      debugPrint('Error deleting attendance: $e');
      return 0; // Return 0 to indicate failure
    }
  }

  /// Clear all attendance records (⚠️ Use with caution)
  Future<int> clearAllAttendance() async {
    try {
      final db = await dbHelper.database;
      return await db.delete('attendance');
    } catch (e) {
      debugPrint('Error clearing attendance: $e');
      return 0; // Return 0 to indicate failure
    }
  }

  /// Retrieve enrolled fingerprints for an employee
  Future<Map<String, String>> getEnrolledFingerprints({required String employeeNo}) async {
    try {
      final db = await dbHelper.database;
      final result = await db.query(
        'employee',
        columns: [
          'finger_info1',
          'finger_info2',
          'finger_info3',
          'finger_info4',
          'finger_info5',
          'finger_info6',
          'finger_info7',
          'finger_info8',
          'finger_info9',
          'finger_info10',
        ],
        where: 'employee_no = ?',
        whereArgs: [employeeNo],
        limit: 1,
      );

      if (result.isNotEmpty) {
        final map = result.first;
        final fingerprints = <String, String>{};
        const fingerMap = {
          'finger_info1': 'Left Thumb',
          'finger_info2': 'Right Thumb',
          'finger_info3': 'Left Index',
          'finger_info4': 'Right Index',
          'finger_info5': 'Left Middle',
          'finger_info6': 'Right Middle',
          'finger_info7': 'Left Ring',
          'finger_info8': 'Right Ring',
          'finger_info9': 'Left Little',
          'finger_info10': 'Right Little',
        };
        fingerMap.forEach((key, value) {
          final template = map[key] as String?;
          if (template != null && template.isNotEmpty) {
            fingerprints[value] = template;
          }
        });
        return fingerprints;
      }
      return {};
    } catch (e) {
      debugPrint('Error fetching enrolled fingerprints: $e');
      return {};
    }
  }

  /// Insert batch attendance records
  Future<void> insertBatchAttendance(List<AttendanceModel> records) async {
    try {
      final db = await dbHelper.database;
      final batch = db.batch();

      for (var record in records) {
        batch.insert('attendance', record.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace);
      }

      await batch.commit(noResult: true);
      notifyListeners();
    } catch (e) {
      debugPrint('Error inserting batch attendance: $e');
    }
  }

  /// Fetch attendance records by project and block
  Future<List<AttendanceModel>> getAttendanceByProjectBlock(
      int projectId, int blockId) async {
    try {
      final db = await dbHelper.database;
      final result = await db.query(
        'attendance',
        where: 'project_id = ? AND block_id = ?',
        whereArgs: [projectId, blockId],
        orderBy: 'create_at DESC',
      );
      return result.map((map) => AttendanceModel.fromMap(map)).toList();
    } catch (e) {
      debugPrint('Error fetching attendance by project/block: $e');
      return [];
    }
  }

  /// Helper to get an employee by fingerprint (delegates to DatabaseHelper)
  Future<EmployeeModel?> getEmployeeByFingerprint(String scannedTemplate) async {
    try {
      final dbHelper = DatabaseHelper.instance;
      // Use a threshold that aligns with ZKTeco recommendation (adjust based on testing)
      return await dbHelper.getEmployeeByFingerprint(scannedTemplate, threshold: 70.0);
    } catch (e) {
      debugPrint('Error getting employee by fingerprint: $e');
      return null;
    }
  }

  // Static DateFormat instances for consistency
  static final _timeLogFormat = DateFormat('HH:mm:ss');
  static final _dateLogFormat = DateFormat('yyyy-MM-dd');
}