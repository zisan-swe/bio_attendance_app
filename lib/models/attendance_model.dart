class AttendanceModel {
  final int id;
  final String deviceId;
  final int projectId;
  final int blockId;
  final String employeeNo;
  final String workingDate;
  final String attendanceStatus;
  final String inTime;
  final String outTime;
  final String location;
  final String fingerprint;
  final int status;
  final String remarks;
  final String createAt;
  final String updateAt;
  final int synced; // 0 = not synced, 1 = synced

  AttendanceModel({
    required this.id,
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
  });

  AttendanceModel copyWith({
    int? id,
    String? deviceId,
    int? projectId,
    int? blockId,
    String? employeeNo,
    String? workingDate,
    String? attendanceStatus,
    String? inTime,
    String? outTime,
    String? location,
    String? fingerprint,
    int? status,
    String? remarks,
    String? createAt,
    String? updateAt,
    int? synced,
  }) {
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
      status: status ?? this.status,
      remarks: remarks ?? this.remarks,
      createAt: createAt ?? this.createAt,
      updateAt: updateAt ?? this.updateAt,
      synced: synced ?? this.synced,
    );
  }

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
      'status': status,
      'remarks': remarks,
      'create_at': createAt,
      'update_at': updateAt,
      'synced': synced,
    };
  }

  factory AttendanceModel.fromMap(Map<String, dynamic> map) {
    return AttendanceModel(
      id: map['id'] ?? 0,
      deviceId: map['device_id'] ?? '',
      projectId: map['project_id'] ?? 0,
      blockId: map['block_id'] ?? 0,
      employeeNo: map['employee_no'] ?? '',
      workingDate: map['working_date'] ?? '',
      attendanceStatus: map['attendance_status'] ?? '',
      inTime: map['in_time'] ?? '',
      outTime: map['out_time'] ?? '',
      location: map['location'] ?? '',
      fingerprint: map['fingerprint'] ?? '',
      status: map['status'] ?? 1,
      remarks: map['remarks'] ?? '',
      createAt: map['create_at'] ?? '',
      updateAt: map['update_at'] ?? '',
      synced: map['synced'] ?? 0,
    );
  }
}
