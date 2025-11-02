import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import '../db/database_helper.dart';
import '../models/attendance_model.dart';
import '../models/employee_model.dart';
import '../services/api_service.dart';
import '../../services/fingerprint_service.dart';
import 'dart:io';

class AttendanceProvider with ChangeNotifier {
  final DatabaseHelper dbHelper = DatabaseHelper.instance;

  static const String _attendanceTable = 'attendance';
  static const String _employeeTable = 'employee';

  // Static DateFormat instances for consistency
  static final _timeLogFormat = DateFormat('HH:mm:ss');
  static final _dateLogFormat = DateFormat('yyyy-MM-dd');

  /// Insert a new attendance record
  Future<int> insertAttendance(AttendanceModel attendance) async {
    try {
      final db = await dbHelper.database;
      final id = await db.insert(
        _attendanceTable,
        attendance.toMap(),
        conflictAlgorithm: ConflictAlgorithm.ignore, // ✅ replace বাদ
      );
      notifyListeners();
      return id;
    } catch (e, stack) {
      debugPrint('❌ Error inserting attendance: $e\n$stack');
      return -1;
    }
  }

  /// Insert batch attendance records
  Future<void> insertBatchAttendance(List<AttendanceModel> records) async {
    if (records.isEmpty) return;
    try {
      final db = await dbHelper.database;
      final batch = db.batch();
      for (final record in records) {
        batch.insert(
          _attendanceTable,
          record.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
      notifyListeners();
    } catch (e, stack) {
      debugPrint('❌ Error inserting batch attendance: $e\n$stack');
    }
  }

  // Future<List<AttendanceModel>> getAllAttendance() async {
  //   final db = await dbHelper.database;
  //   final result = await db.query('attendance', orderBy: 'id DESC');
  //   return result.map((map) => AttendanceModel.fromMap(map)).toList();
  // }



  // Fetch all attendance records
  Future<List<AttendanceModel>> getAllAttendance({String? query}) async {
    try {
      final allData = await dbHelper.getAllAttendance();
      List<AttendanceModel> data = allData;

      // optional search
      if (query != null && query.isNotEmpty) {
        data = data
            .where((a) => a.employeeNo.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }

      // Correct sorting by DateTime
      data.sort((a, b) {
        final aDate = DateTime.tryParse(a.createAt) ?? DateTime(1970);
        final bDate = DateTime.tryParse(b.createAt) ?? DateTime(1970);
        return aDate.compareTo(bDate); // oldest → latest
      });

      return data;
    } catch (e, stack) {
      debugPrint('❌ Error fetching attendance: $e\n$stack');
      return [];
    }
  }

  /// Fetch attendance records by date
  Future<List<AttendanceModel>> getAttendanceByDate(String date) async {
    try {
      final db = await dbHelper.database;
      final result = await db.query(
        _attendanceTable,
        where: 'working_date = ?',
        whereArgs: [date],
        orderBy: 'create_at DESC',
      );
      return result.map(AttendanceModel.fromMap).toList();
    } catch (e, stack) {
      debugPrint('❌ Error fetching attendance by date: $e\n$stack');
      return [];
    }
  }

  /// Fetch attendance records by employee number
  Future<List<AttendanceModel>> getAttendanceByEmployeeNo(String employeeNo) async {
    try {
      final db = await dbHelper.database;
      final result = await db.query(
        _attendanceTable,
        where: 'employee_no = ?',
        whereArgs: [employeeNo],
        orderBy: 'create_at DESC',
      );
      return result.map(AttendanceModel.fromMap).toList();
    } catch (e, stack) {
      debugPrint('❌ Error fetching attendance by employee: $e\n$stack');
      return [];
    }
  }

  /// Fetch attendance records by project and block
  Future<List<AttendanceModel>> getAttendanceByProjectBlock(int projectId, int blockId) async {
    try {
      final db = await dbHelper.database;
      final result = await db.query(
        _attendanceTable,
        where: 'project_id = ? AND block_id = ?',
        whereArgs: [projectId, blockId],
        orderBy: 'create_at DESC',
      );
      return result.map(AttendanceModel.fromMap).toList();
    } catch (e, stack) {
      debugPrint('❌ Error fetching attendance by project/block: $e\n$stack');
      return [];
    }
  }

  /// Update an attendance record by ID
  Future<int> updateAttendance(AttendanceModel attendance) async {
    try {
      final db = await dbHelper.database;
      final updatedRows = await db.update(
        _attendanceTable,
        attendance.toMap(),
        where: 'id = ?',
        whereArgs: [attendance.id],
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      if (updatedRows > 0) notifyListeners();
      return updatedRows;
    } catch (e, stack) {
      debugPrint('❌ Error updating attendance: $e\n$stack');
      return 0;
    }
  }

  /// Delete attendance record by ID
  Future<int> deleteAttendance(int id) async {
    try {
      final db = await dbHelper.database;
      final deletedRows = await db.delete(
        _attendanceTable,
        where: 'id = ?',
        whereArgs: [id],
      );
      if (deletedRows > 0) notifyListeners();
      return deletedRows;
    } catch (e, stack) {
      debugPrint('❌ Error deleting attendance: $e\n$stack');
      return 0;
    }
  }

  /// Clear all attendance records
  Future<int> clearAllAttendance() async {
    try {
      final db = await dbHelper.database;
      final deletedRows = await db.delete(_attendanceTable);
      if (deletedRows > 0) notifyListeners();
      return deletedRows;
    } catch (e, stack) {
      debugPrint('❌ Error clearing attendance: $e\n$stack');
      return 0;
    }
  }

  /// Retrieve enrolled fingerprints for an employee
  // Future<Map<String, String>> getEnrolledFingerprints({required String employeeNo}) async {
  //   try {
  //     final db = await dbHelper.database;
  //     final result = await db.query(
  //       _employeeTable,
  //       columns: [
  //         'finger_info1', 'finger_info2', 'finger_info3', 'finger_info4', 'finger_info5',
  //         'finger_info6', 'finger_info7', 'finger_info8', 'finger_info9', 'finger_info10',
  //       ],
  //       where: 'employee_no = ?',
  //       whereArgs: [employeeNo],
  //       limit: 1,
  //     );
  //
  //     if (result.isEmpty) return {};
  //
  //     final map = result.first;
  //     final fingerprints = <String, String>{};
  //     const fingerMap = {
  //       'finger_info1': 'Left Thumb',
  //       'finger_info2': 'Right Thumb',
  //       'finger_info3': 'Left Index',
  //       'finger_info4': 'Right Index',
  //       'finger_info5': 'Left Middle',
  //       'finger_info6': 'Right Middle',
  //       'finger_info7': 'Left Ring',
  //       'finger_info8': 'Right Ring',
  //       'finger_info9': 'Left Little',
  //       'finger_info10': 'Right Little',
  //     };
  //
  //     fingerMap.forEach((key, value) {
  //       final template = map[key] as String?;
  //       if (template != null && template.isNotEmpty) {
  //         fingerprints[value] = template;
  //       }
  //     });
  //
  //     return fingerprints;
  //   } catch (e, stack) {
  //     debugPrint('❌ Error fetching enrolled fingerprints: $e\n$stack');
  //     return {};
  //   }
  // }


  Future<Map<String, List<String>>> getEnrolledFingerprints({
    required String employeeNo,
  }) async {
    try {
      final db = await dbHelper.database;
      final result = await db.query(
        _employeeTable,
        columns: [
          'finger_info1','finger_info2','finger_info3','finger_info4','finger_info5',
          'finger_info6','finger_info7','finger_info8','finger_info9','finger_info10',
        ],
        where: 'employee_no = ?',
        whereArgs: [employeeNo],
        limit: 1,
      );

      if (result.isEmpty) return {};

      List<String> _decode(dynamic raw) {
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
          return [s];
        }
        return const [];
      }

      final map = result.first;
      return {
        'Left Thumb':  _decode(map['finger_info1']),
        'Left Index':  _decode(map['finger_info2']),
        'Left Middle': _decode(map['finger_info3']),
        'Left Ring':   _decode(map['finger_info4']),
        'Left Little': _decode(map['finger_info5']),
        'Right Thumb': _decode(map['finger_info6']),
        'Right Index': _decode(map['finger_info7']),
        'Right Middle':_decode(map['finger_info8']),
        'Right Ring':  _decode(map['finger_info9']),
        'Right Little':_decode(map['finger_info10']),
      };
    } catch (e, stack) {
      debugPrint('❌ Error fetching enrolled fingerprints: $e\n$stack');
      return {};
    }
  }
  /// Helper to get an employee by fingerprint
  Future<EmployeeModel?> getEmployeeByFingerprint(String scannedTemplate) async {
    try {
      return await dbHelper.getEmployeeByFingerprint(scannedTemplate, threshold: 70.0);
    } catch (e, stack) {
      debugPrint('❌ Error getting employee by fingerprint: $e\n$stack');
      return null;
    }
  }



  Future<int> countPendingUnsynced() async {
    try {
      final db = await dbHelper.database;
      final res = await db.query(
        _attendanceTable,
        where: 'synced = ?',
        whereArgs: [0],
      );
      return res.length;
    } catch (_) {
      return 0;
    }
  }

  Future<int> syncPendingAttendance() async {
    final db = await dbHelper.database;
    final pending = await db.query(
      _attendanceTable,
      where: 'synced = ?',
      whereArgs: [0],
      orderBy: 'id ASC',
    );

    int success = 0;
    for (final row in pending) {
      final model = AttendanceModel.fromMap(row);
      try {
        final message = await ApiService.createAttendance(model);
        final ok = message.toLowerCase().contains('success');
        if (ok) {
          await db.update(
            _attendanceTable,
            model.copyWith(synced: 1).toMap(),
            where: 'id = ?',
            whereArgs: [model.id],
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
          success++;
        }
      } on SocketException {
        // এখনও অফলাইন: লুপ থামাও
        break;
      } catch (_) {
        // সার্ভার/অন্যান্য ইস্যু: পরেরটা ট্রাই করো
      }
    }

    if (success > 0) notifyListeners();
    return success;
  }

}