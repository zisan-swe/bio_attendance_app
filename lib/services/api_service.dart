import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'https://your-laravel-domain.com/api';

  static Future<void> enrollWorker(String workerId, String template) async {
    final response = await http.post(
      Uri.parse('$baseUrl/enroll'),
      body: {
        'worker_id': workerId,
        'fingerprint_template': template,
      },
    );
    print('Enroll response: ${response.body}');
  }

  static Future<void> markAttendance(String template) async {
    final response = await http.post(
      Uri.parse('$baseUrl/attendance'),
      body: {
        'fingerprint_template': template,
      },
    );
    print('Attendance response: ${response.body}');
  }
}
