import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/grade_data.dart';
import 'package:hive/hive.dart';
import 'package:shamsi_date/shamsi_date.dart';

class GradeDownloadService {
  static const String _baseUrl = 'http://62.60.198.11/grade_download_api.php';

  /// دانلود عیارها از سرور و ذخیره در کش محلی
  static Future<Map<String, dynamic>> downloadGradesFromServer() async {
    try {
      print('🔄 شروع دانلود عیارها از سرور...');

      final response = await http.get(
        Uri.parse(_baseUrl),
        headers: {'Content-Type': 'application/json; charset=utf-8'},
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);

        if (result['success'] == true) {
          final grades = result['grades'] as List;
          final count = result['count'] as int;

          print('✅ دریافت ${count} رکورد عیار از سرور');

          // ذخیره در کش محلی
          await _saveGradesToLocalCache(grades);

          return {
            'success': true,
            'message': 'تعداد $count رکورد عیار با موفقیت دانلود و ذخیره شد',
            'count': count,
            'last_updated': result['last_updated']
          };
        } else {
          return {
            'success': false,
            'message': result['message'] ?? 'خطا در دریافت داده‌ها از سرور'
          };
        }
      } else {
        return {
          'success': false,
          'message': 'خطا در ارتباط با سرور: ${response.statusCode}'
        };
      }
    } catch (e) {
      print('❌ خطا در دانلود عیارها: $e');
      return {'success': false, 'message': 'خطا در دانلود عیارها: $e'};
    }
  }

  /// ذخیره عیارها در کش محلی
  static Future<void> _saveGradesToLocalCache(List grades) async {
    try {
      final box = await Hive.openBox<GradeData>('gradeData');

      // پاک کردن داده‌های قبلی
      await box.clear();

      int savedCount = 0;

      for (final gradeData in grades) {
        try {
          final grade = GradeData(
            id: '${gradeData['year']}_${gradeData['month'].toString().padLeft(2, '0')}_${gradeData['day'].toString().padLeft(2, '0')}_${gradeData['shift']}_${gradeData['grade_type']}',
            year: gradeData['year'],
            month: gradeData['month'],
            day: gradeData['day'],
            shift: gradeData['shift'],
            gradeType: gradeData['grade_type'],
            gradeValue: gradeData['grade_value'].toDouble(),
            recordedBy: gradeData['recorded_by'],
            recordedAt: DateTime.parse(gradeData['recorded_at']),
            equipmentId: gradeData['equipment_id']?.toString(),
            workGroup: gradeData['work_group'],
          );

          await box.put(grade.id, grade);
          savedCount++;
        } catch (e) {
          print('⚠️ خطا در ذخیره رکورد: $e');
        }
      }

      print('💾 تعداد $savedCount رکورد در کش محلی ذخیره شد');
    } catch (e) {
      print('❌ خطا در ذخیره در کش محلی: $e');
      throw Exception('خطا در ذخیره داده‌ها در کش محلی: $e');
    }
  }

  /// بررسی وضعیت اتصال به سرور
  static Future<bool> checkServerConnection() async {
    try {
      final response = await http.get(Uri.parse(_baseUrl));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// دریافت آمار داده‌های سرور
  static Future<Map<String, dynamic>> getServerStats() async {
    try {
      final response = await http.get(Uri.parse(_baseUrl));

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return {
          'success': true,
          'count': result['count'] ?? 0,
          'last_updated': result['last_updated']
        };
      } else {
        return {'success': false, 'message': 'خطا در دریافت آمار سرور'};
      }
    } catch (e) {
      return {'success': false, 'message': 'خطا در ارتباط با سرور: $e'};
    }
  }
}
