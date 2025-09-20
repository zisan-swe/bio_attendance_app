class AttendanceModel {
  final int? id; // Nullable for auto-incremented ID from database
  final String deviceId;
  final int projectId;
  final int blockId;
  final String employeeNo;
  final String workingDate;
  final String attendanceStatus;
  final String fingerprint; // Name of the finger used (e.g., "Left Thumb")
  final String inTime; // Time of check-in or break-in
  final String outTime; // Time of check-out or break-out
  final String? location; // Nullable location (e.g., from LocationService)
  final int status; // Status code (e.g., 1 for active)
  final String remarks; // Optional remarks
  final String createAt; // Creation timestamp
  final String updateAt; // Last update timestamp

  AttendanceModel({
    this.id,
    required this.deviceId,
    required this.projectId,
    required this.blockId,
    required this.employeeNo,
    required this.workingDate,
    required this.attendanceStatus,
    required this.fingerprint,
    required this.inTime,
    required this.outTime,
    this.location,
    required this.status,
    required this.remarks,
    required this.createAt,
    required this.updateAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'device_id': deviceId,
      'project_id': projectId,
      'block_id': blockId,
      'employee_no': employeeNo,
      'working_date': workingDate,
      'attendance_status': attendanceStatus,
      'fingerprint': fingerprint,
      'in_time': inTime,
      'out_time': outTime,
      'location': location,
      'status': status,
      'remarks': remarks,
      'create_at': createAt,
      'update_at': updateAt,
    };
  }

  factory AttendanceModel.fromMap(Map<String, dynamic> map) {
    return AttendanceModel(
      id: map['id'] as int?,
      deviceId: map['device_id'] as String? ?? 'UnknownDevice',
      projectId: map['project_id'] as int? ?? 0,
      blockId: map['block_id'] as int? ?? 0,
      employeeNo: map['employee_no'] as String? ?? 'Unknown',
      workingDate: map['working_date'] as String? ?? DateTime.now().toIso8601String().split('T')[0],
      attendanceStatus: map['attendance_status'] as String? ?? 'Unknown',
      fingerprint: map['fingerprint'] as String? ?? 'UnknownFinger',
      inTime: map['in_time'] as String? ?? '',
      outTime: map['out_time'] as String? ?? '',
      location: map['location'] as String?,
      status: map['status'] as int? ?? 0,
      remarks: map['remarks'] as String? ?? '',
      createAt: map['create_at'] as String? ?? DateTime.now().toIso8601String(),
      updateAt: map['update_at'] as String? ?? DateTime.now().toIso8601String(),
    );
  }
}