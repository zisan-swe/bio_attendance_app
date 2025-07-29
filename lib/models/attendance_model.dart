class AttendanceModel {
  final int? id;
  final String deviceId;
  final int projectId;
  final int blockId;
  final String employeeNo;
  final String workingDate;
  final String attendanceStatus;
  // final String? checkInLocation;
  final String inTime;
  final String outTime;
  final String? location;
  final int status;
  final String remarks;
  final String createAt;
  final String updateAt;

  AttendanceModel({
    this.id,
    required this.deviceId,
    required this.projectId,
    required this.blockId,
    required this.employeeNo,
    required this.workingDate,
    required this.attendanceStatus,
    // required this.checkInLocation,
    required this.inTime,
    required this.outTime,
    required this.location,
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
      // 'check_in_location': checkInLocation,
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
      id: map['id'],
      deviceId: map['device_id'],
      projectId: map['project_id'],
      blockId: map['block_id'],
      employeeNo: map['employee_no'],
      workingDate: map['working_date'],
      attendanceStatus: map['attendance_status'],
      // checkInLocation: map['check_in_location'],
      inTime: map['in_time'],
      outTime: map['out_time'],
      location: map['location'],
      status: map['status'],
      remarks: map['remarks'],
      createAt: map['create_at'],
      updateAt: map['update_at'],
    );
  }
}
