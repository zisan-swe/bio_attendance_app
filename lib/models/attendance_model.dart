class AttendanceModel {
  final int? id;
  final String deviceId;
  final int projectId;
  final int blockId;
  final int employeeNo;
  final String workingDate;
  final String attendanceData;
  final String? checkInLocation;
  final String inTime;
  final String outTime;
  final String? checkOutLocation;
  final int status;
  final String remarks;
  final String createAt;
  final String updateAd;

  AttendanceModel({
    this.id,
    required this.deviceId,
    required this.projectId,
    required this.blockId,
    required this.employeeNo,
    required this.workingDate,
    required this.attendanceData,
    required this.checkInLocation,
    required this.inTime,
    required this.outTime,
    required this.checkOutLocation,
    required this.status,
    required this.remarks,
    required this.createAt,
    required this.updateAd,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'device_id': deviceId,
      'project_id': projectId,
      'block_id': blockId,
      'employee_no': employeeNo,
      'working_date': workingDate,
      'attendance_data': attendanceData,
      'check_in_location': checkInLocation,
      'in_time': inTime,
      'out_time': outTime,
      'check_out_location': checkOutLocation,
      'status': status,
      'remarks': remarks,
      'create_at': createAt,
      'update_ad': updateAd,
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
      attendanceData: map['attendance_data'],
      checkInLocation: map['check_in_location'],
      inTime: map['in_time'],
      outTime: map['out_time'],
      checkOutLocation: map['check_out_location'],
      status: map['status'],
      remarks: map['remarks'],
      createAt: map['create_at'],
      updateAd: map['update_ad'],
    );
  }
}
