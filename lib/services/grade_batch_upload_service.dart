import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

class GradeBatchUploadService {
  static const String _baseUrl =
      'http://62.60.198.11/grade_batch_upload_api.php';

  /// آپلود دسته‌ای داده‌های عیار از فایل CSV
  static Future<Map<String, dynamic>> uploadGradesFromCsv({
    bool clearExisting = false,
  }) async {
    try {
      // خواندن فایل CSV
      final csvString = await rootBundle.loadString('assets/real_grades.csv');
      final lines = csvString.split('\n');

      // حذف خط اول (عنوان)
      lines.removeAt(0);

      final List<Map<String, dynamic>> grades = [];

      for (final line in lines) {
        if (line.trim().isEmpty) continue;

        final parts = line.split(',');
        if (parts.length >= 6) {
          final grade = {
            'day': int.tryParse(parts[0].trim()) ?? 0,
            'month': int.tryParse(parts[1].trim()) ?? 0,
            'year': int.tryParse(parts[2].trim()) ?? 0,
            'feed_grade': double.tryParse(parts[3].trim()) ?? 0.0,
            'product_grade': double.tryParse(parts[4].trim()) ?? 0.0,
            'tailing_grade': double.tryParse(parts[5].trim()) ?? 0.0,
          };

          // فقط رکوردهای معتبر را اضافه کن
          if ((grade['day'] as int) > 0 &&
              (grade['month'] as int) > 0 &&
              (grade['year'] as int) > 0) {
            grades.add(grade);
          }
        }
      }

      // آماده‌سازی داده‌ها برای ارسال
      final requestData = {
        'grades': grades,
        'clear_existing': clearExisting,
      };

      // ارسال درخواست به سرور
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
        },
        body: jsonEncode(requestData),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return result;
      } else {
        return {
          'success': false,
          'message': 'خطا در ارتباط با سرور: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'خطا در آپلود دسته‌ای: $e',
      };
    }
  }

  /// بررسی وضعیت اتصال به سرور
  static Future<bool> checkServerConnection() async {
    try {
      final response = await http.get(Uri.parse(_baseUrl));
      return response.statusCode == 200 ||
          response.statusCode == 405; // 405 برای OPTIONS
    } catch (e) {
      return false;
    }
  }

  /// دریافت آمار داده‌های آپلود شده
  static Future<Map<String, dynamic>> getUploadStats() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl?action=stats'));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          'success': false,
          'message': 'خطا در دریافت آمار',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'خطا در دریافت آمار: $e',
      };
    }
  }
}
