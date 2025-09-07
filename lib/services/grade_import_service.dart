import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import '../models/grade_data.dart';
import 'grade_service.dart';

class GradeImportService {
  static const _uuid = Uuid();

  /// خواندن و وارد کردن داده‌های عیار از فایل CSV
  static Future<Map<String, dynamic>> importGradeDataFromCSV() async {
    try {
      // خواندن فایل CSV از assets
      final csvString = await rootBundle.loadString('grade_data.csv');

      // پردازش داده‌های CSV
      final lines = csvString.split('\n');
      if (lines.isEmpty) {
        return {
          'success': false,
          'message': 'فایل خالی است',
          'imported_count': 0,
        };
      }

      // حذف header
      final dataLines = lines.skip(1).where((line) => line.trim().isNotEmpty);

      int importedCount = 0;
      int errorCount = 0;
      List<String> errors = [];

      for (final line in dataLines) {
        try {
          final fields = line.split(',');
          if (fields.length < 7) {
            errorCount++;
            errors.add('خط نامعتبر: $line');
            continue;
          }

          // استخراج داده‌ها
          final year = int.parse(fields[1].trim());
          final month = int.parse(fields[2].trim());
          final day = int.parse(fields[3].trim());
          final shift = _parseShift(fields[4].trim());
          final gradeType = fields[5].trim();
          final gradeValue = double.parse(fields[6].trim());

          // اعتبارسنجی داده‌ها
          if (!_isValidGradeType(gradeType)) {
            errorCount++;
            errors.add('نوع عیار نامعتبر: $gradeType');
            continue;
          }

          if (gradeValue < 0 || gradeValue > 100) {
            errorCount++;
            errors.add('مقدار عیار نامعتبر: $gradeValue');
            continue;
          }

          // ثبت در دیتابیس
          await GradeService.recordGrade(
            year: year,
            month: month,
            day: day,
            shift: shift,
            gradeType: gradeType,
            gradeValue: gradeValue,
            userId: 'system_import',
            workGroup: 1, // پیش‌فرض گروه کاری 1
          );

          importedCount++;
        } catch (e) {
          errorCount++;
          errors.add('خطا در پردازش خط: $line - ${e.toString()}');
        }
      }

      return {
        'success': true,
        'message': 'وارد کردن داده‌ها با موفقیت انجام شد',
        'imported_count': importedCount,
        'error_count': errorCount,
        'errors': errors,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'خطا در خواندن فایل: ${e.toString()}',
        'imported_count': 0,
      };
    }
  }

  /// وارد کردن داده‌های عیار از رشته CSV
  static Future<Map<String, dynamic>> importGradeDataFromString(
      String csvString) async {
    try {
      // پردازش داده‌های CSV
      final lines = csvString.split('\n');
      if (lines.isEmpty) {
        return {
          'success': false,
          'message': 'داده‌ای وارد نشده است',
          'imported_count': 0,
        };
      }

      // بررسی header (اختیاری)
      int startIndex = 0;
      if (lines[0].contains('تاریخ') || lines[0].contains('سال')) {
        startIndex = 1; // پرش از header
      }

      final dataLines =
          lines.skip(startIndex).where((line) => line.trim().isNotEmpty);

      int importedCount = 0;
      int errorCount = 0;
      List<String> errors = [];

      for (final line in dataLines) {
        try {
          final fields = line.split(',');
          if (fields.length < 6) {
            errorCount++;
            errors.add('خط نامعتبر (کم‌فیلد): $line');
            continue;
          }

          // استخراج داده‌ها (format: تاریخ,سال,ماه,روز,شیفت,نوع عیار,مقدار عیار)
          int year, month, day, shift;
          String gradeType;
          double gradeValue;

          if (fields.length >= 7) {
            // فرمت کامل با شیفت
            year = int.parse(fields[1].trim());
            month = int.parse(fields[2].trim());
            day = int.parse(fields[3].trim());
            shift = _parseShift(fields[4].trim());
            gradeType = fields[5].trim();
            gradeValue = double.parse(fields[6].trim());
          } else if (fields.length == 6) {
            // فرمت ساده با شیفت: سال,ماه,روز,شیفت,نوع عیار,مقدار عیار
            year = int.parse(fields[0].trim());
            month = int.parse(fields[1].trim());
            day = int.parse(fields[2].trim());
            shift = _parseShift(fields[3].trim());
            gradeType = fields[4].trim();
            gradeValue = double.parse(fields[5].trim());
          } else if (fields.length == 5) {
            // فرمت روزانه: سال,ماه,روز,نوع عیار,مقدار عیار (بدون شیفت)
            year = int.parse(fields[0].trim());
            month = int.parse(fields[1].trim());
            day = int.parse(fields[2].trim());
            gradeType = fields[3].trim();
            gradeValue = double.parse(fields[4].trim());
            shift = 1; // شیفت پیش‌فرض برای میانگین روزانه
          } else {
            errorCount++;
            errors.add('تعداد فیلدهای نامعتبر در خط: $line');
            continue;
          }

          // اعتبارسنجی داده‌ها
          if (!_isValidGradeType(gradeType)) {
            errorCount++;
            errors.add('نوع عیار نامعتبر: $gradeType در خط: $line');
            continue;
          }

          if (gradeValue < 0 || gradeValue > 100) {
            errorCount++;
            errors.add('مقدار عیار نامعتبر: $gradeValue در خط: $line');
            continue;
          }

          // بررسی تاریخ معتبر
          if (year < 1380 ||
              year > 1450 ||
              month < 1 ||
              month > 12 ||
              day < 1 ||
              day > 31) {
            errorCount++;
            errors.add('تاریخ نامعتبر: $year/$month/$day در خط: $line');
            continue;
          }

          // ثبت در دیتابیس
          if (fields.length == 5) {
            // برای داده‌های روزانه، برای هر 3 شیفت ذخیره کن
            for (int shiftNum = 1; shiftNum <= 3; shiftNum++) {
              await GradeService.recordGrade(
                year: year,
                month: month,
                day: day,
                shift: shiftNum,
                gradeType: gradeType,
                gradeValue: gradeValue,
                userId: 'daily_average_import',
                workGroup: 1, // پیش‌فرض گروه کاری 1
              );
            }
            importedCount += 3; // سه شیفت اضافه شد
          } else {
            // برای داده‌های شیفتی، فقط یک بار ذخیره کن
            await GradeService.recordGrade(
              year: year,
              month: month,
              day: day,
              shift: shift,
              gradeType: gradeType,
              gradeValue: gradeValue,
              userId: 'manual_import',
              workGroup: 1, // پیش‌فرض گروه کاری 1
            );
            importedCount++;
          }
        } catch (e) {
          errorCount++;
          errors.add('خطا در پردازش خط: $line - ${e.toString()}');
        }
      }

      return {
        'success': importedCount > 0,
        'message': importedCount > 0
            ? 'وارد کردن داده‌ها انجام شد'
            : 'هیچ داده معتبری وارد نشد',
        'imported_count': importedCount,
        'error_count': errorCount,
        'errors': errors,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'خطا در پردازش داده‌ها: ${e.toString()}',
        'imported_count': 0,
      };
    }
  }

  /// وارد کردن میانگین ماهیانه عیارها برای ماه‌های قبل
  /// برای هر روز از ماه، میانگین ماهیانه را تکرار می‌کند
  static Future<Map<String, dynamic>> importMonthlyAverageGrades({
    required Map<String, double>
        monthlyAverages, // {'خوراک': 35.5, 'محصول': 42.3, 'باطله': 12.1}
    required int year,
    required int month,
    bool overrideExisting = false,
  }) async {
    try {
      // اعتبارسنجی ورودی‌ها
      if (year < 1380 || year > 1450 || month < 1 || month > 12) {
        return {
          'success': false,
          'message': 'تاریخ نامعتبر: $year/$month',
          'imported_count': 0,
        };
      }

      if (monthlyAverages.isEmpty) {
        return {
          'success': false,
          'message': 'میانگین ماهیانه وارد نشده است',
          'imported_count': 0,
        };
      }

      // بررسی انواع عیار وارد شده
      final validTypes = ['خوراک', 'محصول', 'باطله'];
      for (final gradeType in monthlyAverages.keys) {
        if (!validTypes.contains(gradeType)) {
          return {
            'success': false,
            'message': 'نوع عیار نامعتبر: $gradeType',
            'imported_count': 0,
          };
        }
      }

      // محاسبه تعداد روزهای ماه
      final daysInMonth = _getDaysInMonth(year, month);

      int importedCount = 0;
      int skipCount = 0;
      List<String> messages = [];

      // برای هر روز از ماه
      for (int day = 1; day <= daysInMonth; day++) {
        // برای هر نوع عیار
        for (final gradeEntry in monthlyAverages.entries) {
          final gradeType = gradeEntry.key;
          final gradeValue = gradeEntry.value;

          // برای هر 3 شیفت
          for (int shift = 1; shift <= 3; shift++) {
            // بررسی وجود داده قبلی
            if (!overrideExisting) {
              final existingGrades = await GradeService.getGradeDataByShift(
                  year, month, day, shift);

              final hasExistingGrade =
                  existingGrades.any((grade) => grade.gradeType == gradeType);

              if (hasExistingGrade) {
                skipCount++;
                continue;
              }
            }

            // ثبت میانگین ماهیانه برای این روز و شیفت
            await GradeService.recordGrade(
              year: year,
              month: month,
              day: day,
              shift: shift,
              gradeType: gradeType,
              gradeValue: gradeValue,
              userId: 'monthly_average_import',
              workGroup: 1, // پیش‌فرض گروه کاری 1
            );

            importedCount++;
          }
        }
      }

      final successMessage = 'میانگین ماهیانه $year/$month وارد شد';
      if (skipCount > 0) {
        messages.add('$skipCount رکورد تکراری نادیده گرفته شد');
      }

      return {
        'success': true,
        'message': successMessage,
        'imported_count': importedCount,
        'skip_count': skipCount,
        'details': messages,
        'month_info': {
          'year': year,
          'month': month,
          'days_in_month': daysInMonth,
          'averages': monthlyAverages,
        },
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'خطا در وارد کردن میانگین ماهیانه: ${e.toString()}',
        'imported_count': 0,
      };
    }
  }

  /// وارد کردن میانگین ماهیانه برای چندین ماه به صورت دسته‌ای
  static Future<Map<String, dynamic>> importMultipleMonthlyAverages({
    required List<Map<String, dynamic>>
        monthsData, // [{'year': 1402, 'month': 1, 'averages': {...}}]
    bool overrideExisting = false,
  }) async {
    try {
      int totalImported = 0;
      int totalSkipped = 0;
      List<Map<String, dynamic>> results = [];
      List<String> errors = [];

      for (final monthData in monthsData) {
        try {
          final year = monthData['year'] as int;
          final month = monthData['month'] as int;
          final averages =
              Map<String, double>.from(monthData['averages'] as Map);

          final result = await importMonthlyAverageGrades(
            monthlyAverages: averages,
            year: year,
            month: month,
            overrideExisting: overrideExisting,
          );

          if (result['success']) {
            totalImported += result['imported_count'] as int;
            totalSkipped += result['skip_count'] as int? ?? 0;
          } else {
            errors.add('خطا در $year/$month: ${result['message']}');
          }

          results.add({
            'year': year,
            'month': month,
            'result': result,
          });
        } catch (e) {
          errors.add('خطا در پردازش یکی از ماه‌ها: ${e.toString()}');
        }
      }

      return {
        'success': errors.isEmpty,
        'message': errors.isEmpty
            ? 'وارد کردن میانگین ${monthsData.length} ماه تکمیل شد'
            : 'وارد کردن با خطا تکمیل شد',
        'total_imported': totalImported,
        'total_skipped': totalSkipped,
        'results': results,
        'errors': errors,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'خطا در وارد کردن دسته‌ای: ${e.toString()}',
        'total_imported': 0,
      };
    }
  }

  /// وارد کردن داده‌های عیار با فرمت سال,ماه,روز,شیفت,نوع عیار,مقدار
  /// این متد قابلیت ثبت چندین عیار برای هر شیفت و هر نوع را دارد
  /// فرمت: year,month,day,shift,grade_type,grade_value
  /// مثال: 1404,4,1,1,خوراک,29.5
  ///        1404,4,1,1,خوراک,30.2
  ///        1404,4,1,1,خوراک,29.8
  ///        1404,4,1,1,محصول,38.1
  ///        1404,4,1,1,محصول,37.9
  ///        1404,4,1,1,محصول,38.5
  ///        1404,4,1,1,باطله,10.2
  ///        1404,4,1,1,باطله,11.1
  ///        1404,4,1,2,خوراک,31.1
  ///        1404,4,1,2,خوراک,30.9
  ///        1404,4,1,2,محصول,39.2
  ///        1404,4,1,2,محصول,38.8
  ///        1404,4,1,2,باطله,9.8
  ///        1404,4,1,2,باطله,10.4
  static Future<Map<String, dynamic>> importMultipleGradesPerShift({
    required String csvString,
    bool clearExisting = false,
  }) async {
    try {
      if (clearExisting) {
        await GradeService.clearAllGradeData();
      }

      int importedCount = 0;
      int errorCount = 0;
      List<String> errors = [];

      final lines = csvString.split('\n').where((l) => l.trim().isNotEmpty);

      for (final line in lines) {
        try {
          final parts = line.split(',');
          if (parts.length < 6) {
            errorCount++;
            errors.add('کمبود فیلد در خط: $line');
            continue;
          }

          final year = int.parse(parts[0].trim());
          final month = int.parse(parts[1].trim());
          final day = int.parse(parts[2].trim());
          final shift = int.parse(parts[3].trim());
          final gradeType = parts[4].trim();
          final gradeValue = double.parse(parts[5].trim());

          // اعتبارسنجی نوع عیار
          if (!_isValidGradeType(gradeType)) {
            errorCount++;
            errors.add('نوع عیار نامعتبر ($gradeType) در خط: $line');
            continue;
          }

          // اعتبارسنجی مقدار عیار
          if (gradeValue < 0 || gradeValue > 100) {
            errorCount++;
            errors.add('مقدار عیار نامعتبر ($gradeValue) در خط: $line');
            continue;
          }

          // اعتبارسنجی تاریخ
          if (year < 1380 ||
              year > 1450 ||
              month < 1 ||
              month > 12 ||
              day < 1 ||
              day > 31) {
            errorCount++;
            errors.add('تاریخ نامعتبر ($year/$month/$day) در خط: $line');
            continue;
          }

          // اعتبارسنجی شیفت
          if (shift < 1 || shift > 3) {
            errorCount++;
            errors.add('شیفت نامعتبر ($shift) در خط: $line');
            continue;
          }

          await GradeService.recordGrade(
            year: year,
            month: month,
            day: day,
            shift: shift,
            gradeType: gradeType,
            gradeValue: gradeValue,
            userId: 'csv_import_multiple',
            workGroup: 1, // پیش‌فرض گروه کاری 1
          );

          importedCount++;
        } catch (e) {
          errorCount++;
          errors.add('خطا در پردازش خط: $line - ${e.toString()}');
        }
      }

      return {
        'success': importedCount > 0,
        'message': importedCount > 0
            ? 'وارد کردن ${importedCount.toString()} رکورد عیار انجام شد'
            : 'هیچ داده معتبری وارد نشد',
        'imported_count': importedCount,
        'error_count': errorCount,
        'errors': errors,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'خطای کلی در وارد کردن: ${e.toString()}',
        'imported_count': 0,
        'error_count': 0,
        'errors': [e.toString()],
      };
    }
  }

  /// ⚠️ تابع منسوخ شده - این نگاشت اشتباه است!
  /// هر شیفت باید همه انواع عیار (خوراک، محصول، باطله) داشته باشد
  /// به جای این تابع از importMultipleGradesPerShift استفاده کنید
  @deprecated
  static Future<Map<String, dynamic>> importShiftMappedGrades({
    required String csvString,
    Map<int, String>? shiftGradeMap,
  }) async {
    return {
      'success': false,
      'message':
          'این تابع منسوخ شده است. از importMultipleGradesPerShift استفاده کنید.',
      'imported_count': 0,
      'error_count': 0,
      'errors': ['تابع منسوخ شده - نگاشت شیفت به عیار اشتباه است'],
    };
  }

  /// تبدیل نام شیفت به عدد
  static int _parseShift(String shiftName) {
    switch (shiftName.trim()) {
      case 'صبح':
        return 1;
      case 'عصر':
        return 2;
      case 'شب':
        return 3;
      default:
        // اگر عدد باشد
        return int.tryParse(shiftName.trim()) ?? 1;
    }
  }

  /// بررسی معتبر بودن نوع عیار
  static bool _isValidGradeType(String gradeType) {
    final validTypes = ['خوراک', 'محصول', 'باطله'];
    return validTypes.contains(gradeType.trim());
  }

  /// محاسبه تعداد روزهای ماه در تقویم شمسی
  static int _getDaysInMonth(int year, int month) {
    if (month >= 1 && month <= 6) {
      return 31; // فروردین تا شهریور
    } else if (month >= 7 && month <= 11) {
      return 30; // مهر تا بهمن
    } else if (month == 12) {
      // اسفند - بررسی سال کبیسه
      return _isLeapYear(year) ? 30 : 29;
    }
    return 30; // پیش‌فرض
  }

  /// بررسی سال کبیسه در تقویم شمسی
  static bool _isLeapYear(int year) {
    // فرمول سال کبیسه شمسی
    final cycle = ((year - 979) % 128);
    return (cycle % 33) % 4 == 1 && cycle != 1;
  }

  /// نمونه فرمت CSV برای کاربر
  static String getSampleCSVFormat() {
    return '''تاریخ,سال,ماه,روز,شیفت,نوع عیار,مقدار عیار
1403/10/01,1403,10,1,صبح,خوراک,0.85
1403/10/01,1403,10,1,صبح,محصول,0.42
1403/10/01,1403,10,1,صبح,باطله,0.15
1403/10/01,1403,10,1,عصر,خوراک,0.87
1403/10/01,1403,10,1,عصر,محصول,0.44
1403/10/01,1403,10,1,عصر,باطله,0.13''';
  }

  /// فرمت ساده (بدون ستون تاریخ)
  static String getSimpleCSVFormat() {
    return '''سال,ماه,روز,شیفت,نوع عیار,مقدار عیار
1403,10,1,1,خوراک,0.85
1403,10,1,1,محصول,0.42
1403,10,1,1,باطله,0.15
1403,10,1,2,خوراک,0.87
1403,10,1,2,محصول,0.44
1403,10,1,2,باطله,0.13''';
  }

  /// فرمت روزانه (برای میانگین روزانه)
  static String getDailyAverageFormat() {
    return '''سال,ماه,روز,نوع عیار,مقدار عیار
1403,10,1,خوراک,0.85
1403,10,1,محصول,0.42
1403,10,1,باطله,0.15
1403,10,2,خوراک,0.87
1403,10,2,محصول,0.44
1403,10,2,باطله,0.13''';
  }

  /// نمونه فرمت CSV صحیح برای چندین عیار در هر شیفت
  static String getMultipleGradesPerShiftFormat() {
    return '''سال,ماه,روز,شیفت,نوع عیار,مقدار عیار
1404,4,1,1,خوراک,29.5
1404,4,1,1,خوراک,30.2
1404,4,1,1,خوراک,29.8
1404,4,1,1,محصول,38.1
1404,4,1,1,محصول,37.9
1404,4,1,1,محصول,38.5
1404,4,1,1,باطله,10.2
1404,4,1,1,باطله,11.1
1404,4,1,2,خوراک,31.1
1404,4,1,2,خوراک,30.9
1404,4,1,2,محصول,39.2
1404,4,1,2,محصول,38.8
1404,4,1,2,باطله,9.8
1404,4,1,2,باطله,10.4''';
  }
}
