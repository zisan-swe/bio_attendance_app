import 'package:sqflite/sqflite.dart';
import '../db/database_helper.dart';

class EmployeeTemplate {
  final int employeeId;
  final String template;

  EmployeeTemplate({required this.employeeId, required this.template});
}

class EmployeeProvider1 {
  /// Get all templates with employeeId
  Future<List<EmployeeTemplate>> getAllTemplatesWithEmployeeId() async {
    final db = await DatabaseHelper.instance.database;

    final List<Map<String, dynamic>> result = await db.query(
      "employee",
      columns: [
        "id",
        "finger_info1",
        "finger_info2",
        "finger_info3",
        "finger_info4",
        "finger_info5",
        "finger_info6",
        "finger_info7",
        "finger_info8",
        "finger_info9",
        "finger_info10",
      ],
    );

    final templates = <EmployeeTemplate>[];

    for (var row in result) {
      final employeeId = row["id"] as int;
      for (int i = 1; i <= 10; i++) {
        final tpl = row["finger_info$i"] as String?;
        if (tpl != null && tpl.isNotEmpty) {
          templates.add(EmployeeTemplate(employeeId: employeeId, template: tpl));
        }
      }
    }

    return templates;
  }
}

