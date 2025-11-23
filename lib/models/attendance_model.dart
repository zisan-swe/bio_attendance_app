class AttendanceModel {
  final int? id; // ✅ Nullable (SQLite auto-increment ID)
  final String deviceId;
  final String projectId;
  final String blockId;
  final String employeeNo;
  final String workingDate;
  final String attendanceStatus; // Check In, Check Out, Break In, Break Out
  final String inTime;
  final String outTime;
  final String location;
  final String fingerprint;
  final String status; // Regular, Early, Late
  final String remarks;
  final String createAt;
  final String updateAt;
  final int synced; // 0 = not synced, 1 = synced

  AttendanceModel({
    this.id,
    required this.deviceId,
    required this.projectId,
    required this.blockId,
    required this.employeeNo,
    required this.workingDate,
    required this.attendanceStatus,
    required this.inTime,
    required this.outTime,
    required this.location,
    required this.fingerprint,
    required this.status,
    required this.remarks,
    required this.createAt,
    required this.updateAt,
    required this.synced,
  }) : assert(['Regular', 'Early', 'Late'].contains(status), "Invalid status");

  /// ✅ Copy existing model with modifications
  AttendanceModel copyWith({
    int? id,
    String? deviceId,
    String? projectId,
    String? blockId,
    String? employeeNo,
    String? workingDate,
    String? attendanceStatus,
    String? inTime,
    String? outTime,
    String? location,
    String? fingerprint,
    String? status,
    String? remarks,
    String? createAt,
    String? updateAt,
    int? synced,
  }) {
    final safeStatus = (status != null && ['Regular', 'Early', 'Late'].contains(status))
        ? status
        : this.status;
    return AttendanceModel(
      id: id ?? this.id,
      deviceId: deviceId ?? this.deviceId,
      projectId: projectId ?? this.projectId,
      blockId: blockId ?? this.blockId,
      employeeNo: employeeNo ?? this.employeeNo,
      workingDate: workingDate ?? this.workingDate,
      attendanceStatus: attendanceStatus ?? this.attendanceStatus,
      inTime: inTime ?? this.inTime,
      outTime: outTime ?? this.outTime,
      location: location ?? this.location,
      fingerprint: fingerprint ?? this.fingerprint,
      status: safeStatus,
      remarks: remarks ?? this.remarks,
      createAt: createAt ?? this.createAt,
      updateAt: updateAt ?? this.updateAt,
      synced: synced ?? this.synced,
    );
  }

  /// ✅ Convert object → Map (for SQLite insert/update)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'device_id': deviceId,
      'project_id': projectId,
      'block_id': blockId,
      'employee_no': employeeNo,
      'working_date': workingDate,
      'attendance_status': attendanceStatus,
      'in_time': inTime,
      'out_time': outTime,
      'location': location,
      'fingerprint': fingerprint,
      'status': ['Regular', 'Early', 'Late'].contains(status) ? status : 'Regular',
      'remarks': remarks,
      'create_at': createAt,
      'update_at': updateAt,
      'synced': synced,
    };
  }

  /// ✅ Convert Map → Model (for reading from SQLite)
  factory AttendanceModel.fromMap(Map<String, dynamic> map) {
    String rawStatus = map['status']?.toString() ?? 'Regular';
    if (!['Regular', 'Early', 'Late'].contains(rawStatus)) {
      rawStatus = 'Regular';
    }

    return AttendanceModel(
      id: map['id'] != null ? int.tryParse(map['id'].toString()) : null,
      deviceId: map['device_id']?.toString() ?? '',
      projectId: map['project_id']?.toString() ?? '', // updated
      blockId: map['block_id']?.toString() ?? '',     // updated
      employeeNo: map['employee_no']?.toString() ?? '',
      workingDate: map['working_date']?.toString() ?? '',
      attendanceStatus: map['attendance_status']?.toString() ?? '',
      inTime: map['in_time']?.toString() ?? '',
      outTime: map['out_time']?.toString() ?? '',
      location: map['location']?.toString() ?? '',
      fingerprint: map['fingerprint']?.toString() ?? '',
      status: rawStatus,
      remarks: map['remarks']?.toString() ?? '',
      createAt: map['create_at']?.toString() ?? '',
      updateAt: map['update_at']?.toString() ?? '',
      synced: int.tryParse(map['synced']?.toString() ?? '0') ?? 0,
    );
  }
}
