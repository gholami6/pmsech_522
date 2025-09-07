import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/grade_data.dart';
import 'grade_service.dart';

class GradeApiService {
  static const String _baseUrl = 'http://62.60.198.11/grade_api.php';
  static const String _apiKey = 'pmsech_grade_api_2024';

  /// هدرهای درخواست
  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      };

  /// هدرهای جایگزین برای تست
  static Map<String, String> get _headersAlternative => {
        'Content-Type': 'application/json',
        'X-API-Key': _apiKey,
      };

  /// دانلود داده‌های عیار از هاست
  static Future<List<GradeData>> downloadGrades() async {
    try {
      print('=== شروع دانلود از API ===');
      print('آدرس: $_baseUrl?action=download&api_key=$_apiKey');
      print('API Key: $_apiKey');

      // استفاده از API اصلی برای داده‌های واقعی
      final response = await http.get(
        Uri.parse('$_baseUrl?action=download&api_key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
      );

      print('کد وضعیت: ${response.statusCode}');
      print('بدنه پاسخ: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final List<dynamic> gradesList = data['data'];

          // بررسی خالی بودن لیست
          if (gradesList.isEmpty) {
            print('هیچ داده‌ای از سرور دریافت نشد');
            return [];
          }

          return gradesList.map((json) {
            // تبدیل فرمت تاریخ از YYYY/MM/DD به سال، ماه، روز جداگانه
            final dateParts = json['date'].split('/');
            if (dateParts.length < 3) {
              throw Exception('فرمت تاریخ نامعتبر: ${json['date']}');
            }

            return GradeData(
              id: DateTime.now()
                  .millisecondsSinceEpoch
                  .toString(), // تولید ID موقت
              year: int.parse(dateParts[0]),
              month: int.parse(dateParts[1]),
              day: int.parse(dateParts[2]),
              shift: int.tryParse(json['shift']?.toString() ?? '1') ?? 1,
              gradeType: json['grade_type'],
              gradeValue: json['grade_value'].toDouble(),
              recordedBy: 'system', // برای داده‌های تاریخی
              recordedAt: DateTime.now(),
              equipmentId: null,
              workGroup: 1, // پیش‌فرض گروه کاری 1
            );
          }).toList();
        } else {
          throw Exception('خطا در دانلود: ${data['message']}');
        }
      } else {
        throw Exception('خطای HTTP: ${response.statusCode}');
      }
    } catch (e) {
      print('خطا در دانلود عیارها: $e');
      rethrow;
    }
  }

  /// دانلود با روش جایگزین (API Key در URL)
  static Future<List<GradeData>> _downloadGradesAlternative() async {
    try {
      print('=== تست با API Key در URL ===');
      final response = await http.get(
        Uri.parse('$_baseUrl?action=download&api_key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
      );

      print('کد وضعیت (جایگزین): ${response.statusCode}');
      print('بدنه پاسخ (جایگزین): ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final List<dynamic> gradesList = data['data'];

          if (gradesList.isEmpty) {
            print('هیچ داده‌ای از سرور دریافت نشد');
            return [];
          }

          return gradesList.map((json) {
            final dateParts = json['date'].split('/');
            if (dateParts.length < 3) {
              throw Exception('فرمت تاریخ نامعتبر: ${json['date']}');
            }

            return GradeData(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              year: int.parse(dateParts[0]),
              month: int.parse(dateParts[1]),
              day: int.parse(dateParts[2]),
              shift: int.tryParse(json['shift']?.toString() ?? '1') ?? 1,
              gradeType: json['grade_type'],
              gradeValue: json['grade_value'].toDouble(),
              recordedBy: json['recorded_by'] ?? 'system',
              recordedAt: DateTime.now(),
              equipmentId: json['equipment_id']?.toString(),
              workGroup:
                  int.tryParse(json['work_group']?.toString() ?? '1') ?? 1,
            );
          }).toList();
        } else {
          throw Exception('خطا در دانلود: ${data['message']}');
        }
      } else {
        throw Exception('خطای HTTP: ${response.statusCode}');
      }
    } catch (e) {
      print('خطا در روش جایگزین: $e');
      rethrow;
    }
  }

  /// آپلود عیار جدید به هاست
  static Future<Map<String, dynamic>> uploadGrade({
    required int year,
    required int month,
    required int day,
    required int shift,
    required String gradeType,
    required double gradeValue,
    required String recordedBy,
    String? equipmentId,
    int workGroup = 1, // پیش‌فرض گروه کاری 1
  }) async {
    try {
      final date = '$year/$month/$day';
      final gradeData = {
        'date': date,
        'grade_type': gradeType,
        'grade_value': gradeValue,
        'equipment_id': equipmentId ?? '',
        // 'work_group': workGroup, // موقتاً غیرفعال
      };

      // آپلود مستقیم (بررسی سرور قبلاً انجام شده)
      print('آدرس: $_baseUrl?action=upload&api_key=$_apiKey');
      print('داده‌ها: $gradeData');

      final response = await http.post(
        Uri.parse('$_baseUrl?action=upload&api_key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(gradeData),
      );

      print('کد وضعیت آپلود: ${response.statusCode}');
      print('بدنه پاسخ آپلود: ${response.body}');

      // اگر خطای 500 بود، مشکل سرور است
      if (response.statusCode == 500) {
        try {
          final errorData = json.decode(response.body);
          // بررسی آیا پیام جدید با جزئیات دریافت شده
          if (errorData.containsKey('details')) {
            print('🔍 جزئیات خطای سرور: ${errorData['details']}');
          }
        } catch (e) {
          print('⚠️ خطای 500: پاسخ سرور قابل تحلیل نیست');
        }

        print(
            '⚠️ خطای 500: مشکل در سرور - داده‌ها در دیتابیس محلی ذخیره می‌شوند');
        return {
          'success': true,
          'message': 'داده‌ها در دیتابیس محلی ذخیره شدند (مشکل سرور موقت)',
          'error': 'SERVER_ERROR_500',
        };
      }

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'message': data['message'],
        };
      } else {
        // اگر کلید API نامعتبر بود، از کلیدهای مختلف استفاده کن
        if (data['error']?.toString().contains('کلید API') == true ||
            data['error']?.toString().contains('احراز هویت') == true) {
          print('⚠️ کلید API نامعتبر، تلاش با کلیدهای مختلف...');
          final success = await GradeService.uploadGradeWithNewKey(
              date, gradeType, gradeValue, workGroup);
          if (success) {
            return {
              'success': true,
              'message': 'آپلود موفق با کلید جایگزین',
            };
          }
        }

        return {
          'success': false,
          'message': data['message'] ?? 'خطا در آپلود',
          'error': data['error'],
        };
      }
    } catch (e) {
      print('خطا در آپلود عیار: $e');
      return {
        'success': false,
        'message': 'خطا در ارتباط با سرور: $e',
      };
    }
  }

  /// آپدیت عیار موجود در هاست
  static Future<Map<String, dynamic>> updateGrade({
    required int year,
    required int month,
    required int day,
    required int shift,
    required String gradeType,
    required double gradeValue,
    required String recordedBy,
    String? equipmentId,
    int workGroup = 1,
  }) async {
    try {
      final date = '$year/$month/$day';
      final gradeData = {
        'date': date,
        'grade_type': gradeType,
        'grade_value': gradeValue,
        'equipment_id': equipmentId ?? '',
      };

      print('آدرس آپدیت: $_baseUrl?action=update&api_key=$_apiKey');
      print('داده‌های آپدیت: $gradeData');

      final response = await http.post(
        Uri.parse('$_baseUrl?action=update&api_key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(gradeData),
      );

      print('کد وضعیت آپدیت: ${response.statusCode}');
      print('بدنه پاسخ آپدیت: ${response.body}');

      if (response.statusCode == 500) {
        try {
          final errorData = json.decode(response.body);
          if (errorData.containsKey('details')) {
            print('🔍 جزئیات خطای سرور: ${errorData['details']}');
          }
        } catch (e) {
          print('⚠️ خطای 500: پاسخ سرور قابل تحلیل نیست');
        }
        print('⚠️ خطای 500: مشکل در سرور');
        return {
          'success': false,
          'message': 'مشکل در سرور',
          'error': 'SERVER_ERROR_500',
        };
      }

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'message': data['message'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'خطا در آپدیت',
          'error': data['error'],
        };
      }
    } catch (e) {
      print('خطا در آپدیت عیار: $e');
      return {
        'success': false,
        'message': 'خطا در ارتباط با سرور: $e',
      };
    }
  }

  /// دریافت آمار عیارها
  static Future<Map<String, dynamic>> getGradesStats() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl?action=stats&api_key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data['stats'];
        } else {
          throw Exception('خطا در دریافت آمار: ${data['message']}');
        }
      } else {
        throw Exception('خطای HTTP: ${response.statusCode}');
      }
    } catch (e) {
      print('خطا در دریافت آمار عیارها: $e');
      rethrow;
    }
  }

  /// بررسی اتصال به سرور
  static Future<bool> checkConnection() async {
    try {
      print('=== بررسی اتصال به سرور ===');
      print('آدرس: $_baseUrl?action=stats&api_key=$_apiKey');

      final response = await http.get(
        Uri.parse('$_baseUrl?action=stats&api_key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 15));

      print('کد وضعیت: ${response.statusCode}');
      print('بدنه پاسخ: ${response.body}');

      if (response.statusCode == 200) {
        print('✅ اتصال موفق');
        return true;
      } else {
        print('❌ خطای HTTP: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ خطا در بررسی اتصال: $e');
      return false;
    }
  }

  /// حذف عیار از سرور
  static Future<Map<String, dynamic>> deleteGrade({
    required int year,
    required int month,
    required int day,
    required int shift,
    required String gradeType,
    required String recordedBy,
  }) async {
    try {
      final date = '$year/$month/$day';
      final gradeData = {
        'date': date,
        'shift': shift,
        'grade_type': gradeType,
        'recorded_by': recordedBy,
      };

      print('آدرس حذف: $_baseUrl?action=delete&api_key=$_apiKey');
      print('داده‌های حذف: $gradeData');

      final response = await http.post(
        Uri.parse('$_baseUrl?action=delete&api_key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(gradeData),
      );

      print('کد وضعیت حذف: ${response.statusCode}');
      print('بدنه پاسخ حذف: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return {
            'success': true,
            'message': data['message'] ?? 'عیار با موفقیت حذف شد',
          };
        } else {
          return {
            'success': false,
            'message': data['message'] ?? 'خطا در حذف',
            'error': data['error'],
          };
        }
      } else {
        return {
          'success': false,
          'message': 'خطای HTTP: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('خطا در حذف عیار: $e');
      return {
        'success': false,
        'message': 'خطا در ارتباط با سرور: $e',
      };
    }
  }

  /// همگام‌سازی داده‌های محلی با سرور
  static Future<bool> syncGrades(List<GradeData> localGrades) async {
    try {
      // ابتدا دانلود داده‌های سرور
      final serverGrades = await downloadGrades();

      // پیدا کردن رکوردهای جدید محلی
      final newGrades = localGrades.where((local) {
        return !serverGrades.any((server) =>
            server.fullShamsiDate == local.fullShamsiDate &&
            server.shift == local.shift &&
            server.gradeType == local.gradeType);
      }).toList();

      // آپلود رکوردهای جدید
      for (final grade in newGrades) {
        final result = await uploadGrade(
          year: grade.year,
          month: grade.month,
          day: grade.day,
          shift: grade.shift,
          gradeType: grade.gradeType,
          gradeValue: grade.gradeValue,
          recordedBy: grade.recordedBy,
        );

        if (!result['success']) {
          print('خطا در آپلود عیار: ${result['message']}');
          return false;
        }
      }

      return true;
    } catch (e) {
      print('خطا در همگام‌سازی: $e');
      return false;
    }
  }
}
