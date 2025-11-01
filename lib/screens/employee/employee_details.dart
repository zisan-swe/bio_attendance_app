import 'dart:io';
import 'package:flutter/material.dart';
import '../../models/employee_model.dart';

class EmployeeDetailsPage extends StatelessWidget {
  final EmployeeModel employee;

  const EmployeeDetailsPage({Key? key, required this.employee}) : super(key: key);

  Widget _buildReadOnlyField(String label, String value, IconData icon) {
    return TextFormField(
      initialValue: value,
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.blueGrey),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.blueGrey),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
    );
  }

  Widget _buildReadOnlyDate(String label, String value) {
    return TextFormField(
      initialValue: value,
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.calendar_today, color: Colors.blueGrey),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.blueGrey),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
    );
  }

  Widget _buildFingerBase64(String label, String base64Data) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ElevatedButton(
            onPressed: null,
            style: ElevatedButton.styleFrom(
              backgroundColor: base64Data.isNotEmpty ? Colors.green[700] : Colors.grey[400],
              foregroundColor: Colors.white,
              minimumSize: const Size(140, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
            ),
            child: Text(
              label.split(' ').last,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.blueGrey[200]!),
              borderRadius: BorderRadius.circular(12),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            constraints: const BoxConstraints(maxHeight: 100, minWidth: double.infinity),
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: Text(
                base64Data.isNotEmpty ? base64Data : 'Not Captured',
                style: TextStyle(fontSize: 12, color: Colors.blueGrey[800]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBiometricSection(EmployeeModel emp) {
    final leftFingers = [
      'Left Thumb', 'Left Index', 'Left Middle', 'Left Ring', 'Left Little'
    ];
    final rightFingers = [
      'Right Thumb', 'Right Index', 'Right Middle', 'Right Ring', 'Right Little'
    ];

    final leftValues = [
      emp.fingerInfo1, emp.fingerInfo2, emp.fingerInfo3, emp.fingerInfo4, emp.fingerInfo5
    ];
    final rightValues = [
      emp.fingerInfo6, emp.fingerInfo7, emp.fingerInfo8, emp.fingerInfo9, emp.fingerInfo10
    ];

    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Biometric Fingers',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Colors.blueGrey,
              ),
            ),
            const SizedBox(height: 16),
            Column(
              children: List.generate(5, (index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFingerBase64(leftFingers[index], leftValues[index]),
                      const SizedBox(width: 20),
                      _buildFingerBase64(rightFingers[index], rightValues[index]),
                    ],
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final emp = employee;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Employee Details'),
        backgroundColor: Colors.blueGrey[700],
        elevation: 0,
        centerTitle: true,
        titleTextStyle: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blueGrey[50]!, Colors.white],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Card(
                elevation: 6,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundImage: emp.imagePath.isNotEmpty ? FileImage(File(emp.imagePath)) : null,
                        backgroundColor: Colors.blueGrey[100],
                        child: emp.imagePath.isEmpty
                            ? const Icon(Icons.person, size: 50, color: Colors.blueGrey)
                            : null,
                      ),
                      const SizedBox(height: 20),
                      _buildReadOnlyField('Employee Name', emp.name, Icons.person),
                      const SizedBox(height: 16),
                      _buildReadOnlyField('Email', emp.email, Icons.email),
                      const SizedBox(height: 16),
                      _buildReadOnlyField('Employee ID', emp.employeeNo, Icons.badge),
                      const SizedBox(height: 16),
                      _buildReadOnlyField('Employee NID', emp.nid, Icons.badge),
                      const SizedBox(height: 16),
                      _buildReadOnlyField('Employee Daily Wages', emp.dailyWages.toStringAsFixed(2), Icons.attach_money),
                      const SizedBox(height: 16),
                      _buildReadOnlyField('Phone', emp.phone, Icons.phone),
                      const SizedBox(height: 16),
                      _buildReadOnlyField('Father\'s Name', emp.fatherName, Icons.person_outline),
                      const SizedBox(height: 16),
                      _buildReadOnlyField('Mother\'s Name', emp.motherName, Icons.person_outline),
                      const SizedBox(height: 16),
                      _buildReadOnlyDate('Date of Birth', emp.dob),
                      const SizedBox(height: 16),
                      _buildReadOnlyDate('Joining Date', emp.joiningDate),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _buildBiometricSection(emp),
            ],
          ),
        ),
      ),
    );
  }
}