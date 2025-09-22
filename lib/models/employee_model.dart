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
  final int employeeType;
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
      employeeType: map['employee_type'] as int? ?? 1,
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
    );
  }

  /// --- From API Response ---
  factory EmployeeModel.fromJson(Map<String, dynamic> json) {
    return EmployeeModel(
      id: json['id'] as int?,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      employeeNo: json['employee_no'] ?? '',
      nid: json['nid'] ?? '',
      dailyWages: (json['daily_salary'] as num?)?.toDouble() ?? 0.0,
      phone: json['mobile'] ?? '',
      fatherName: json['father_name'] ?? '',
      motherName: json['mother_name'] ?? '',
      dob: json['dob'] ?? '',
      joiningDate: json['joining_date'] ?? '',
      employeeType: json['employee_type'] ?? 1,
      fingerInfo1: json['finger_info1'] ?? '',
      fingerInfo2: json['finger_info2'] ?? '',
      fingerInfo3: json['finger_info3'] ?? '',
      fingerInfo4: json['finger_info4'] ?? '',
      fingerInfo5: json['finger_info5'] ?? '',
      fingerInfo6: json['finger_info6'] ?? '',
      fingerInfo7: json['finger_info7'] ?? '',
      fingerInfo8: json['finger_info8'] ?? '',
      fingerInfo9: json['finger_info9'] ?? '',
      fingerInfo10: json['finger_info10'] ?? '',
      imagePath: json['image_path'] ?? '',
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
    int? employeeType,
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
    );
  }
}