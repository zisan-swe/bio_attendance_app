import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/employee_model.dart';

class WorkerDetailsPage extends StatelessWidget {
  final EmployeeModel employee;

  const WorkerDetailsPage({Key? key, required this.employee}) : super(key: key);

  Widget _buildReadOnlyField(String label, String value, IconData icon) {
    return TextFormField(
      initialValue: value,
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget _buildReadOnlyDate(String label, String value) {
    return TextFormField(
      initialValue: value,
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.calendar_today),
        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget _buildFingerStatus(String label, bool isScanned) {
    return ElevatedButton(
      onPressed: null,
      style: ElevatedButton.styleFrom(
        backgroundColor: isScanned ? Colors.green : Colors.grey[300],
        foregroundColor: isScanned ? Colors.white : Colors.black,
        minimumSize: const Size(130, 40),
      ),
      child: Text(label.split(' ').last),
    );
  }



  Widget _buildFingerBase64(String label, String base64Data) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ElevatedButton(
            onPressed: null,
            style: ElevatedButton.styleFrom(
              backgroundColor: base64Data.isNotEmpty ? Colors.green : Colors.grey[300],
              foregroundColor: base64Data.isNotEmpty ? Colors.white : Colors.black,
              minimumSize: const Size(130, 40),
            ),
            child: Text(label.split(' ').last),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(4),
              color: Colors.grey.shade100,
            ),
            constraints: const BoxConstraints(maxHeight: 80),
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: Text(
                base64Data.isNotEmpty ? base64Data : 'Not Captured',
                style: const TextStyle(fontSize: 12),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Biometric Fingers', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 10),
        Column(
          children: List.generate(5, (index) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFingerBase64(leftFingers[index], leftValues[index]),
                  const SizedBox(width: 16),
                  _buildFingerBase64(rightFingers[index], rightValues[index]),
                ],
              ),
            );
          }),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final emp = employee;
    final wide = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Worker Details'),
        backgroundColor: Colors.blueGrey,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundImage: emp.imagePath.isNotEmpty ? FileImage(File(emp.imagePath)) : null,
              backgroundColor: Colors.grey[300],
              child: emp.imagePath.isEmpty ? const Icon(Icons.person, size: 40) : null,
            ),
            const SizedBox(height: 12),
            _buildReadOnlyField('Worker Name', emp.name, Icons.person),
            const SizedBox(height: 12),
            _buildReadOnlyField('Email', emp.email, Icons.email),
            const SizedBox(height: 12),
            _buildReadOnlyField('Worker ID', emp.employeeNo, Icons.badge),
            const SizedBox(height: 12),
            _buildReadOnlyField('Worker NID', emp.nid, Icons.badge),
            const SizedBox(height: 12),
            _buildReadOnlyField('Worker Daily Wages', emp.dailyWages.toStringAsFixed(2), Icons.badge),
            const SizedBox(height: 12),
            _buildReadOnlyField('Phone', emp.phone, Icons.phone),
            const SizedBox(height: 12),
            _buildReadOnlyField('Father\'s Name', emp.fatherName, Icons.person),
            const SizedBox(height: 12),
            _buildReadOnlyField('Mother\'s Name', emp.motherName, Icons.person),
            const SizedBox(height: 12),
            _buildReadOnlyDate('Date of Birth', emp.dob),
            const SizedBox(height: 12),
            _buildReadOnlyDate('Joining Date', emp.joiningDate),
            const SizedBox(height: 20),

            // _buildBiometricSection(emp),
          ],
        ),
      ),
    );
  }
}
