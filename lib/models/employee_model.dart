import 'dart:convert';

class EmployeeModel {
  final int? id;
  final String name;
  final String email;
  final String employeeNo;
  final String nid;
  final double dailyWages;
  final String phone;
  final String fatherName;
  final String motherName;
  final String dob;
  final String joiningDate;
  final String employeeType;
  final int companyId;
  final String fingerInfo1;
  final String fingerInfo2;
  final String fingerInfo3;
  final String fingerInfo4;
  final String fingerInfo5;
  final String fingerInfo6;
  final String fingerInfo7;
  final String fingerInfo8;
  final String fingerInfo9;
  final String fingerInfo10;
  final String imagePath;
  final int? departmentId;
  final int? shiftId;
  final String? roleInProject; // "supervisor" | "worker"
  final String? projectId;
  final String? blockId;

  EmployeeModel({
    this.id,
    required this.name,
    required this.email,
    required this.employeeNo,
    required this.nid,
    required this.dailyWages,
    required this.phone,
    required this.fatherName,
    required this.motherName,
    required this.dob,
    required this.joiningDate,
    required this.employeeType,
    required this.companyId,
    required this.fingerInfo1,
    required this.fingerInfo2,
    required this.fingerInfo3,
    required this.fingerInfo4,
    required this.fingerInfo5,
    required this.fingerInfo6,
    required this.fingerInfo7,
    required this.fingerInfo8,
    required this.fingerInfo9,
    required this.fingerInfo10,
    required this.imagePath,
    this.departmentId,
    this.shiftId,
    this.roleInProject,
    this.projectId,
    this.blockId,
  });

  /// --- From SQLite Row ---
  factory EmployeeModel.fromMap(Map<String, dynamic> map) {
    return EmployeeModel(
      id: map['id'] as int?,
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      employeeNo: map['employee_no'] as String? ?? '',
      nid: map['nid'] as String? ?? '',
      dailyWages: (map['daily_wages'] as num?)?.toDouble() ?? 0.0,
      phone: map['phone'] as String? ?? '',
      fatherName: map['father_name'] as String? ?? '',
      motherName: map['mother_name'] as String? ?? '',
      dob: map['dob'] as String? ?? '',
      joiningDate: map['joining_date'] as String? ?? '',
      employeeType: map['employee_type'] as String? ?? 'Labour',
      companyId: map['company_id'] as int? ?? 1,
      fingerInfo1: map['finger_info1'] as String? ?? '',
      fingerInfo2: map['finger_info2'] as String? ?? '',
      fingerInfo3: map['finger_info3'] as String? ?? '',
      fingerInfo4: map['finger_info4'] as String? ?? '',
      fingerInfo5: map['finger_info5'] as String? ?? '',
      fingerInfo6: map['finger_info6'] as String? ?? '',
      fingerInfo7: map['finger_info7'] as String? ?? '',
      fingerInfo8: map['finger_info8'] as String? ?? '',
      fingerInfo9: map['finger_info9'] as String? ?? '',
      fingerInfo10: map['finger_info10'] as String? ?? '',
      imagePath: map['image_path'] as String? ?? '',
      departmentId: map['department_id'] as int?,
      shiftId: map['shift_id'] as int?,
      roleInProject: map['role_in_project'] as String?,
      projectId: map['project_id'] as String?,
      blockId: map['block_id'] as String?,
    );
  }

  /// --- From API Response ---
  factory EmployeeModel.fromJson(Map<String, dynamic> json) {
    // Handle daily_wages as JSON string/object
    double latestDailyWage = 0.0;
    try {
      if (json['daily_wages'] != null) {
        Map<String, dynamic> wages;
        if (json['daily_wages'] is String) {
          wages = jsonDecode(json['daily_wages']);
        } else if (json['daily_wages'] is Map) {
          wages = Map<String, dynamic>.from(json['daily_wages']);
        } else {
          wages = {};
        }

        if (wages.isNotEmpty) {
          final latestDate =
              wages.keys.reduce((a, b) => a.compareTo(b) > 0 ? a : b);
          latestDailyWage = (wages[latestDate] as num).toDouble();
        }
      }
    } catch (_) {
      latestDailyWage = 0.0;
    }

    return EmployeeModel(
      id: int.tryParse(json['id'].toString()),
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      employeeNo: json['employee_no']?.toString() ?? '',
      nid: json['nid']?.toString() ?? '',
      dailyWages: latestDailyWage,
      phone: json['mobile']?.toString() ?? '',
      fatherName: json['father_name']?.toString() ?? '',
      motherName: json['mother_name']?.toString() ?? '',
      dob: json['dob']?.toString() ?? '',
      joiningDate: json['joining_date']?.toString() ?? '',
      employeeType: json['employee_type_id']?.toString() ?? 'Labour',
      companyId: int.tryParse(json['company_id']?.toString() ?? '1') ?? 1,
      fingerInfo1: json['finger_info1']?.toString() ?? '',
      fingerInfo2: json['finger_info2']?.toString() ?? '',
      fingerInfo3: json['finger_info3']?.toString() ?? '',
      fingerInfo4: json['finger_info4']?.toString() ?? '',
      fingerInfo5: json['finger_info5']?.toString() ?? '',
      fingerInfo6: json['finger_info6']?.toString() ?? '',
      fingerInfo7: json['finger_info7']?.toString() ?? '',
      fingerInfo8: json['finger_info8']?.toString() ?? '',
      fingerInfo9: json['finger_info9']?.toString() ?? '',
      fingerInfo10: json['finger_info10']?.toString() ?? '',
      imagePath: json['image_path']?.toString() ?? '',
    );
  }

  /// Getter for fingerprints map (finger name to Base64 template)
  Map<String, String> get fingerprints {
    return {
      'Left Thumb': fingerInfo1,
      'Right Thumb': fingerInfo2,
      'Left Index': fingerInfo3,
      'Right Index': fingerInfo4,
      'Left Middle': fingerInfo5,
      'Right Middle': fingerInfo6,
      'Left Ring': fingerInfo7,
      'Right Ring': fingerInfo8,
      'Left Little': fingerInfo9,
      'Right Little': fingerInfo10,
    }..removeWhere((key, value) => value.isEmpty);
  }

  /// --- For SQLite Insert ---
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'employee_no': employeeNo,
      'nid': nid,
      'daily_wages': dailyWages,
      'phone': phone,
      'father_name': fatherName,
      'mother_name': motherName,
      'dob': dob,
      'joining_date': joiningDate,
      'employee_type': employeeType,
      'company_id': companyId,
      'finger_info1': fingerInfo1,
      'finger_info2': fingerInfo2,
      'finger_info3': fingerInfo3,
      'finger_info4': fingerInfo4,
      'finger_info5': fingerInfo5,
      'finger_info6': fingerInfo6,
      'finger_info7': fingerInfo7,
      'finger_info8': fingerInfo8,
      'finger_info9': fingerInfo9,
      'finger_info10': fingerInfo10,
      'image_path': imagePath,
      'department_id': departmentId,
      'shift_id': shiftId,
      'role_in_project': roleInProject,
      'project_id': projectId,
      'block_id': blockId,
    };
  }

  /// --- For API Request ---
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'employee_no': employeeNo,
      'nid': nid,
      'daily_salary': dailyWages,
      'mobile': phone,
      'father_name': fatherName,
      'mother_name': motherName,
      'dob': dob,
      'joining_date': joiningDate,
      'employee_type': employeeType,
      'company_id': companyId,
      'finger_info1': fingerInfo1,
      'finger_info2': fingerInfo2,
      'finger_info3': fingerInfo3,
      'finger_info4': fingerInfo4,
      'finger_info5': fingerInfo5,
      'finger_info6': fingerInfo6,
      'finger_info7': fingerInfo7,
      'finger_info8': fingerInfo8,
      'finger_info9': fingerInfo9,
      'finger_info10': fingerInfo10,
      'image_path': imagePath,
      'department_id': departmentId,
      'shift_id': shiftId,
      'role_in_project': roleInProject,
      'project_id': projectId,
      'block_id': blockId,

    };
  }

  /// --- Copy with updated fields ---
  EmployeeModel copyWith({
    int? id,
    String? name,
    String? email,
    String? employeeNo,
    String? nid,
    double? dailyWages,
    String? phone,
    String? fatherName,
    String? motherName,
    String? dob,
    String? joiningDate,
    String? employeeType,
    int? companyId,
    String? fingerInfo1,
    String? fingerInfo2,
    String? fingerInfo3,
    String? fingerInfo4,
    String? fingerInfo5,
    String? fingerInfo6,
    String? fingerInfo7,
    String? fingerInfo8,
    String? fingerInfo9,
    String? fingerInfo10,
    String? imagePath,
    int? departmentId,
    int? shiftId,
  }) {
    return EmployeeModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      employeeNo: employeeNo ?? this.employeeNo,
      nid: nid ?? this.nid,
      dailyWages: dailyWages ?? this.dailyWages,
      phone: phone ?? this.phone,
      fatherName: fatherName ?? this.fatherName,
      motherName: motherName ?? this.motherName,
      dob: dob ?? this.dob,
      joiningDate: joiningDate ?? this.joiningDate,
      employeeType: employeeType ?? this.employeeType,
      companyId: companyId ?? this.companyId,
      fingerInfo1: fingerInfo1 ?? this.fingerInfo1,
      fingerInfo2: fingerInfo2 ?? this.fingerInfo2,
      fingerInfo3: fingerInfo3 ?? this.fingerInfo3,
      fingerInfo4: fingerInfo4 ?? this.fingerInfo4,
      fingerInfo5: fingerInfo5 ?? this.fingerInfo5,
      fingerInfo6: fingerInfo6 ?? this.fingerInfo6,
      fingerInfo7: fingerInfo7 ?? this.fingerInfo7,
      fingerInfo8: fingerInfo8 ?? this.fingerInfo8,
      fingerInfo9: fingerInfo9 ?? this.fingerInfo9,
      fingerInfo10: fingerInfo10 ?? this.fingerInfo10,
      imagePath: imagePath ?? this.imagePath,
      departmentId: departmentId ?? this.departmentId,
      shiftId: shiftId ?? this.shiftId,
    );
  }
}
