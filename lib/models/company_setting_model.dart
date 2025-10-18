import 'package:flutter/foundation.dart';

class CompanySettingModel {
  final int? id;
  final String companyName;
  final String? address;
  final int? branchId;
  final String? user;

  const CompanySettingModel({
    this.id,
    required this.companyName,
    this.address,
    this.branchId,
    this.user,
  });

  CompanySettingModel copyWith({
    int? id,
    String? companyName,
    String? address,
    int? branchId,
    String? user,
  }) {
    return CompanySettingModel(
      id: id ?? this.id,
      companyName: companyName ?? this.companyName,
      address: address ?? this.address,
      branchId: branchId ?? this.branchId,
      user: user ?? this.user,
    );
  }

  factory CompanySettingModel.fromMap(Map<String, dynamic> map) {
    return CompanySettingModel(
      id: map['id'] as int?,
      companyName: (map['company_name'] ?? '') as String,
      address: map['address'] as String?,
      branchId: map['branch_id'] != null ? (map['branch_id'] as num).toInt() : null,
      user: map['user'] as String?,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'company_name': companyName,
      'address': address,
      'branch_id': branchId,
      'user': user,
    };
  }
}
