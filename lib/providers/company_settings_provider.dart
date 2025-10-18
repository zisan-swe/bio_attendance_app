import 'dart:developer' as dev;
import 'package:flutter/foundation.dart';
import '../db/database_helper.dart';
import '../models/company_setting_model.dart';
import 'package:sqflite/sqflite.dart';

class CompanySettingsProvider with ChangeNotifier {
  CompanySettingModel? _setting;
  bool _loading = false;

  CompanySettingModel? get setting => _setting;
  bool get isLoading => _loading;

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    try {
      final db = await DatabaseHelper.instance.database;
      final rows = await db.query(
        'company_settings',
        orderBy: 'id ASC',
        limit: 1,
      );
      _setting = rows.isNotEmpty ? CompanySettingModel.fromMap(rows.first) : null;
    } catch (e, st) {
      dev.log('Failed to load company_settings: $e', name: 'CompanySettingsProvider', stackTrace: st);
      _setting = null;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Insert or update the single settings row.
  Future<void> save(CompanySettingModel value) async {
    final db = await DatabaseHelper.instance.database;

    await db.transaction((txn) async {
      if (_setting?.id != null) {
        // Update existing
        await txn.update(
          'company_settings',
          value.copyWith(id: _setting!.id).toMap(),
          where: 'id = ?',
          whereArgs: [_setting!.id],
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        _setting = value.copyWith(id: _setting!.id);
      } else {
        // Insert new
        final id = await txn.insert(
          'company_settings',
          value.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        _setting = value.copyWith(id: id);
      }
    });

    notifyListeners();
  }
}
