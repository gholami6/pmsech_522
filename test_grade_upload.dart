import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  const baseUrl = 'https://sechahoon.liara.run/grade_api.php';
  const apiKey = 'pmsech_grade_api_2024';

  final testData = {
    'date': '1404/4/1',
    'grade_type': 'خوراک',
    'grade_value': 25.5,
    'work_group': 2,
  };

  print('=== تست آپلود عیار ===');
  print('داده‌ها: $testData');

  try {
    final response = await http.post(
      Uri.parse('$baseUrl?action=upload&api_key=$apiKey'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(testData),
    );

    print('کد وضعیت: ${response.statusCode}');
    print('بدنه پاسخ: ${response.body}');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true) {
        print('✅ آپلود موفق: ${data['message']}');
      } else {
        print('❌ خطا: ${data['message']}');
      }
    } else {
      print('❌ خطای HTTP: ${response.statusCode}');
    }
  } catch (e) {
    print('❌ خطا در اتصال: $e');
  }
}
