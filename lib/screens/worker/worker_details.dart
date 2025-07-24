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

  // Widget _buildBiometricSection(EmployeeModel emp) {
  //   final fingerValues = [
  //     emp.fingerInfo1, emp.fingerInfo2, emp.fingerInfo3, emp.fingerInfo4, emp.fingerInfo5,
  //     emp.fingerInfo6, emp.fingerInfo7, emp.fingerInfo8, emp.fingerInfo9, emp.fingerInfo10,
  //   ];
  //
  //   final fingerNames = [
  //     'Left Thumb', 'Left Index', 'Left Middle', 'Left Ring', 'Left Little',
  //     'Right Thumb', 'Right Index', 'Right Middle', 'Right Ring', 'Right Little',
  //   ];
  //
  //   final Map<String, bool> fingerScanStatus = {
  //     for (int i = 0; i < fingerNames.length; i++) fingerNames[i]: fingerValues[i].isNotEmpty
  //   };
  //
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       const Text('Biometric Fingers', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
  //       const SizedBox(height: 10),
  //       Row(
  //         mainAxisAlignment: MainAxisAlignment.spaceEvenly,
  //         children: [
  //           Column(
  //             children: [
  //               const Text('Left Hand'),
  //               _buildFingerStatus('Left Thumb', fingerScanStatus['Left Thumb']!),
  //               _buildFingerStatus('Left Index', fingerScanStatus['Left Index']!),
  //               _buildFingerStatus('Left Middle', fingerScanStatus['Left Middle']!),
  //               _buildFingerStatus('Left Ring', fingerScanStatus['Left Ring']!),
  //               _buildFingerStatus('Left Little', fingerScanStatus['Left Little']!),
  //             ],
  //           ),
  //           Column(
  //             children: [
  //               const Text('Right Hand'),
  //               _buildFingerStatus('Right Thumb', fingerScanStatus['Right Thumb']!),
  //               _buildFingerStatus('Right Index', fingerScanStatus['Right Index']!),
  //               _buildFingerStatus('Right Middle', fingerScanStatus['Right Middle']!),
  //               _buildFingerStatus('Right Ring', fingerScanStatus['Right Ring']!),
  //               _buildFingerStatus('Right Little', fingerScanStatus['Right Little']!),
  //             ],
  //           ),
  //         ],
  //       )
  //     ],
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    final emp = employee;
    final wide = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      appBar: AppBar(title: const Text('Worker Details')),
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
