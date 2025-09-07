import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/grade_data.dart';
import '../models/user_model.dart';
import '../models/position_model.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'grade_api_service.dart';
import 'grade_import_service.dart';
import 'grade_download_service.dart';
import 'date_service.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class GradeService {
  static const String _boxName = 'gradeData';
  static Box<GradeData>? _box;
  static const _uuid = Uuid();

  /// اولین بار باز کردن box
  static Future<void> initialize() async {
    if (_box == null || !_box!.isOpen) {
      _box = await Hive.openBox<GradeData>(_boxName);
    }
  }

  /// دریافت Box
  static Future<Box<GradeData>> get _gradeBox async {
    await initialize();
    return _box!;
  }

  /// بررسی دسترسی کاربر برای ثبت عیار
  static bool canRecordGrade(UserModel user) {
    return true; // تمام کاربران دسترسی دارند
  }

  /// ثبت عیار جدید
  static Future<String> recordGrade({
    required int year,
    required int month,
    required int day,
    required int shift,
    required String gradeType,
    required double gradeValue,
    required String userId,
    String? equipmentId,
    required int workGroup,
  }) async {
    final box = await _gradeBox;

    final gradeData = GradeData(
      id: _uuid.v4(),
      year: year,
      month: month,
      day: day,
      shift: shift,
      gradeType: gradeType,
      gradeValue: gradeValue,
      recordedBy: userId,
      recordedAt: DateTime.now(),
      equipmentId: equipmentId,
      workGroup: workGroup,
    );

    print('=== ذخیره‌سازی در دیتابیس ===');
    print('شناسه رکورد: ${gradeData.id}');
    print('تاریخ: $year/$month/$day');
    print('شیفت: $shift');
    print('نوع عیار: $gradeType');
    print('مقدار عیار: $gradeValue%');
    print('کاربر: $userId');
    print('زمان ثبت: ${gradeData.recordedAt}');
    print('تجهیز: $equipmentId');
    print('============================');

    // ذخیره در دیتابیس محلی
    await box.put(gradeData.id, gradeData);
    print('رکورد با موفقیت در دیتابیس محلی ذخیره شد');

    // آپلود خودکار به هاست
    try {
      print('=== آپلود خودکار به هاست ===');
      final result = await GradeApiService.uploadGrade(
        year: year,
        month: month,
        day: day,
        shift: shift,
        gradeType: gradeType,
        gradeValue: gradeValue,
        recordedBy: userId,
        equipmentId: equipmentId,
        workGroup: workGroup,
      );

      if (result['success']) {
        print('✅ رکورد با موفقیت در هاست ذخیره شد');
        print('پیام سرور: ${result['message']}');
      } else {
        print('❌ خطا در آپلود به هاست: ${result['message']}');
        print('جزئیات خطا: ${result['error']}');
        // رکورد در دیتابیس محلی ذخیره شده و بعداً قابل همگام‌سازی است
      }
    } catch (e) {
      print('❌ خطا در ارتباط با هاست: $e');
      print('رکورد در دیتابیس محلی ذخیره شد و بعداً قابل همگام‌سازی است');
    }

    print('تعداد کل رکوردهای عیار: ${box.length}');
    print('============================');

    return gradeData.id;
  }

  /// دریافت همه داده‌های عیار
  static Future<List<GradeData>> getAllGradeData() async {
    final box = await _gradeBox;
    final allData = box.values.toList();
    return allData;
  }

  /// دریافت داده‌های عیار بر اساس بازه تاریخ
  static Future<List<GradeData>> getGradeDataByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final allData = await getAllGradeData();

    final startJalali = Jalali.fromDateTime(startDate);
    final endJalali = Jalali.fromDateTime(endDate);

    print('=== دیباگ getGradeDataByDateRange ===');
    print(
        'بازه درخواستی: ${startJalali.year}/${startJalali.month}/${startJalali.day} تا ${endJalali.year}/${endJalali.month}/${endJalali.day}');
    print('تعداد کل داده‌های عیار: ${allData.length}');

    // فیلتر کردن داده‌ها بر اساس بازه دقیق
    final filteredData = allData.where((grade) {
      final gradeDate = Jalali(grade.year, grade.month, grade.day);
      final isAfterStart = gradeDate.compareTo(startJalali) >= 0;
      final isBeforeEnd = gradeDate.compareTo(endJalali) <= 0;
      final isInRange = isAfterStart && isBeforeEnd;
      return isInRange;
    }).toList();

    print('تعداد داده‌های عیار در بازه: ${filteredData.length}');
    return filteredData;
  }

  /// دریافت داده‌های عیار بر اساس شیفت مشخص
  static Future<List<GradeData>> getGradeDataByShift(
    int year,
    int month,
    int day,
    int shift,
  ) async {
    final allData = await getAllGradeData();

    return allData
        .where((grade) =>
            grade.year == year &&
            grade.month == month &&
            grade.day == day &&
            grade.shift == shift)
        .toList();
  }

  /// میانگین ساده هر نوع عیار (خوراک، محصول، باطله) در بازه داده شده
  static Future<Map<String, double>> getAverageGradeForDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final data = await getGradeDataByDateRange(startDate, endDate);
    final Map<String, List<double>> gradesByType = {
      'خوراک': [],
      'محصول': [],
      'باطله': [],
    };
    for (final grade in data) {
      if (gradesByType.containsKey(grade.gradeType) && grade.gradeValue > 0.0) {
        gradesByType[grade.gradeType]!.add(grade.gradeValue);
      }
    }
    final Map<String, double> averages = {};
    for (final entry in gradesByType.entries) {
      if (entry.value.isNotEmpty) {
        averages[entry.key] =
            entry.value.reduce((a, b) => a + b) / entry.value.length;
      } else {
        averages[entry.key] = 0.0;
      }
    }
    return averages;
  }

  /// لیست روزانه میانگین هر نوع عیار در بازه (برای نمودار)
  static Future<List<Map<String, dynamic>>> getDailyAveragesForDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    List<Map<String, dynamic>> result = [];
    DateTime current = startDate;
    while (!current.isAfter(endDate)) {
      final dayAverages = await getAverageGradeForDateRange(current, current);
      final jalali = Jalali.fromDateTime(current);
      result.add({
        'year': jalali.year,
        'month': jalali.month,
        'day': jalali.day,
        'خوراک': dayAverages['خوراک'] ?? 0.0,
        'محصول': dayAverages['محصول'] ?? 0.0,
        'باطله': dayAverages['باطله'] ?? 0.0,
      });
      current = current.add(const Duration(days: 1));
    }
    return result;
  }

  /// میانگین هر نوع عیار برای یک شیفت خاص
  static Future<Map<String, double>> getAverageGradeForShift(
    int year,
    int month,
    int day,
    int shift,
  ) async {
    final data = await getGradeDataByShift(year, month, day, shift);
    final Map<String, List<double>> gradesByType = {
      'خوراک': [],
      'محصول': [],
      'باطله': [],
    };
    for (final grade in data) {
      if (gradesByType.containsKey(grade.gradeType)) {
        gradesByType[grade.gradeType]!.add(grade.gradeValue);
      }
    }
    final Map<String, double> averages = {};
    for (final entry in gradesByType.entries) {
      if (entry.value.isNotEmpty) {
        averages[entry.key] =
            entry.value.reduce((a, b) => a + b) / entry.value.length;
      } else {
        averages[entry.key] = 0.0;
      }
    }
    return averages;
  }

  /// دریافت جزئیات عیار هر شیفت برای بازه تاریخ
  static Future<Map<String, Map<String, double>>> getDetailedGradeReport(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final dateRangeData = await getGradeDataByDateRange(startDate, endDate);

    // گروه‌بندی بر اساس شیفت
    final Map<String, List<GradeData>> shiftGroups = {};

    for (final grade in dateRangeData) {
      final shiftKey = '${grade.fullShamsiDate}-شیفت${grade.shift}';
      if (!shiftGroups.containsKey(shiftKey)) {
        shiftGroups[shiftKey] = [];
      }
      shiftGroups[shiftKey]!.add(grade);
    }

    // محاسبه میانگین هر شیفت
    final Map<String, Map<String, double>> detailedReport = {};

    for (final entry in shiftGroups.entries) {
      final shiftKey = entry.key;
      final shiftData = entry.value;

      final Map<String, List<double>> gradesByType = {
        'خوراک': [],
        'محصول': [],
        'باطله': [],
      };

      for (final grade in shiftData) {
        if (gradesByType.containsKey(grade.gradeType)) {
          gradesByType[grade.gradeType]!.add(grade.gradeValue);
        }
      }

      final Map<String, double> shiftAverages = {};
      for (final typeEntry in gradesByType.entries) {
        if (typeEntry.value.isNotEmpty) {
          final sum = typeEntry.value.reduce((a, b) => a + b);
          shiftAverages[typeEntry.key] = sum / typeEntry.value.length;
        } else {
          shiftAverages[typeEntry.key] = 0.0;
        }
      }

      detailedReport[shiftKey] = shiftAverages;
    }

    return detailedReport;
  }

  /// حذف داده عیار
  static Future<void> deleteGradeData(String gradeId) async {
    final box = await _gradeBox;
    await box.delete(gradeId);
  }

  /// پاک کردن تمام داده‌های عیار از دیتابیس محلی
  static Future<void> clearAllGradeData() async {
    try {
      print('=== پاک کردن تمام داده‌های عیار ===');

      final box = await _gradeBox;
      final count = box.length;

      await box.clear();

      print('تعداد رکوردهای حذف شده: $count');
      print('دیتابیس محلی پاک شد');
      print('=============================');
    } catch (e) {
      print('خطا در پاک کردن داده‌ها: $e');
    }
  }

  /// آپدیت عیار موجود
  static Future<String> updateGrade({
    required String gradeId,
    required int year,
    required int month,
    required int day,
    required int shift,
    required String gradeType,
    required double gradeValue,
    required String userId,
    String? equipmentId,
    required int workGroup,
  }) async {
    final box = await _gradeBox;

    // بررسی وجود رکورد
    final existingGrade = box.get(gradeId);
    if (existingGrade == null) {
      throw Exception('عیار یافت نشد');
    }

    // ایجاد رکورد جدید با همان ID
    final updatedGrade = GradeData(
      id: gradeId,
      year: year,
      month: month,
      day: day,
      shift: shift,
      gradeType: gradeType,
      gradeValue: gradeValue,
      recordedBy: userId,
      recordedAt: DateTime.now(),
      equipmentId: equipmentId,
      workGroup: workGroup,
    );

    print('=== آپدیت عیار ===');
    print('شناسه رکورد: $gradeId');
    print('تاریخ: $year/$month/$day');
    print('شیفت: $shift');
    print('نوع عیار: $gradeType');
    print('مقدار جدید: $gradeValue%');
    print('کاربر: $userId');
    print('زمان آپدیت: ${updatedGrade.recordedAt}');
    print('============================');

    // آپدیت در دیتابیس محلی
    await box.put(gradeId, updatedGrade);
    print('رکورد با موفقیت در دیتابیس محلی آپدیت شد');

    // آپدیت در هاست
    try {
      print('=== آپدیت در هاست ===');
      final result = await GradeApiService.updateGrade(
        year: year,
        month: month,
        day: day,
        shift: shift,
        gradeType: gradeType,
        gradeValue: gradeValue,
        recordedBy: userId,
        equipmentId: equipmentId,
        workGroup: workGroup,
      );

      if (result['success']) {
        print('✅ رکورد با موفقیت در هاست آپدیت شد');
        print('پیام سرور: ${result['message']}');
      } else {
        print('❌ خطا در آپدیت هاست: ${result['message']}');
        print('جزئیات خطا: ${result['error']}');
      }
    } catch (e) {
      print('❌ خطا در ارتباط با هاست: $e');
      print('رکورد در دیتابیس محلی آپدیت شد و بعداً قابل همگام‌سازی است');
    }

    print('تعداد کل رکوردهای عیار: ${box.length}');
    print('============================');

    return gradeId;
  }

  /// پاک کردن داده‌های اشتباه (مقادیر غیرمنطقی)
  static Future<void> clearInvalidGradeData() async {
    try {
      final box = await _gradeBox;
      final allData = box.values.toList();

      print('=== پاک کردن داده‌های اشتباه ===');
      print('تعداد کل داده‌ها قبل از پاک کردن: ${allData.length}');

      int removedCount = 0;

      for (final grade in allData) {
        bool shouldRemove = false;

        // فقط حذف مقادیر خارج از محدوده 0-100
        if (grade.gradeValue > 100 || grade.gradeValue < 0) {
          shouldRemove = true;
          print(
              'حذف: مقدار خارج از محدوده ${grade.gradeValue}% برای ${grade.gradeType}');
        }

        // حذف داده‌های آینده
        final currentDate = Jalali.now();
        final gradeDate = Jalali(grade.year, grade.month, grade.day);
        if (gradeDate.compareTo(currentDate) > 0) {
          shouldRemove = true;
          print('حذف: تاریخ آینده ${grade.year}/${grade.month}/${grade.day}');
        }

        if (shouldRemove) {
          await box.delete(grade.id);
          removedCount++;
        }
      }

      print('تعداد داده‌های حذف شده: $removedCount');
      print('تعداد داده‌های باقی‌مانده: ${box.length}');
      print('============================');
    } catch (e) {
      print('خطا در پاک کردن داده‌های اشتباه: $e');
    }
  }

  /// دریافت تعداد کل رکوردهای عیار
  static Future<int> getTotalGradeRecords() async {
    final box = await _gradeBox;
    return box.length;
  }

  /// دریافت آخرین تاریخ ثبت شده برای عیار
  static Future<Jalali?> getLatestGradeDate() async {
    final box = await _gradeBox;
    final allData = box.values.toList();

    if (allData.isEmpty) {
      return null;
    }

    // مرتب‌سازی بر اساس تاریخ شمسی
    allData.sort((a, b) {
      final dateA = Jalali(a.year, a.month, a.day);
      final dateB = Jalali(b.year, b.month, b.day);
      return dateB.compareTo(dateA); // مرتب‌سازی نزولی
    });

    final latestGrade = allData.first;
    return Jalali(latestGrade.year, latestGrade.month, latestGrade.day);
  }

  /// دریافت آخرین 9 شیفت با داده (برای نمودار)
  static Future<List<GradeData>> getLast9ShiftsForChart() async {
    try {
      final box = await _gradeBox;
      final allGrades = box.values.toList();

      if (allGrades.isEmpty) {
        print('⚠️ هیچ داده‌ای موجود نیست');
        return [];
      }

      // گروه‌بندی بر اساس تاریخ و شیفت و نوع عیار
      final Map<String, List<GradeData>> shiftGroups = {};
      for (final grade in allGrades) {
        final key = '${grade.year}_${grade.month}_${grade.day}_${grade.shift}';
        shiftGroups.putIfAbsent(key, () => []).add(grade);
      }

      // تبدیل به لیست کلیدها و مرتب‌سازی
      final shiftKeys = shiftGroups.keys.toList();
      shiftKeys.sort((a, b) {
        final partsA = a.split('_');
        final partsB = b.split('_');

        final yearA = int.parse(partsA[0]);
        final monthA = int.parse(partsA[1]);
        final dayA = int.parse(partsA[2]);
        final shiftA = int.parse(partsA[3]);

        final yearB = int.parse(partsB[0]);
        final monthB = int.parse(partsB[1]);
        final dayB = int.parse(partsB[2]);
        final shiftB = int.parse(partsB[3]);

        if (yearA != yearB) return yearB.compareTo(yearA);
        if (monthA != monthB) return monthB.compareTo(monthA);
        if (dayA != dayB) return dayB.compareTo(dayA);
        return shiftB.compareTo(shiftA);
      });

      // برگرداندن آخرین 9 شیفت
      final last9ShiftKeys = shiftKeys.take(9).toList();

      // مرتب‌سازی صعودی برای نمایش (قدیمی‌ترین اول)
      last9ShiftKeys.sort((a, b) {
        final partsA = a.split('_');
        final partsB = b.split('_');

        final yearA = int.parse(partsA[0]);
        final monthA = int.parse(partsA[1]);
        final dayA = int.parse(partsA[2]);
        final shiftA = int.parse(partsA[3]);

        final yearB = int.parse(partsB[0]);
        final monthB = int.parse(partsB[1]);
        final dayB = int.parse(partsB[2]);
        final shiftB = int.parse(partsB[3]);

        if (yearA != yearB) return yearA.compareTo(yearB);
        if (monthA != monthB) return monthA.compareTo(monthB);
        if (dayA != dayB) return dayA.compareTo(dayB);
        return shiftA.compareTo(shiftB);
      });

      // ایجاد لیست نهایی با یک رکورد از هر شیفت
      final List<GradeData> result = [];
      for (final key in last9ShiftKeys) {
        final shifts = shiftGroups[key]!;
        // انتخاب اولین رکورد از هر شیفت (می‌تواند خوراک یا محصول باشد)
        if (shifts.isNotEmpty) {
          result.add(shifts.first);
        }
      }

      print(
          '📅 آخرین 9 شیفت: ${result.map((s) => '${s.year}/${s.month}/${s.day}/شیفت${s.shift}').join(', ')}');
      print('🔍 تعداد کل شیفت‌های موجود: ${shiftKeys.length}');
      print('🔍 تعداد شیفت‌های انتخاب شده: ${result.length}');

      return result;
    } catch (e) {
      print('خطا در دریافت آخرین 9 شیفت: $e');
      return [];
    }
  }

  /// همگام‌سازی عیارها از سرور
  static Future<void> syncGradesFromServer() async {
    try {
      final result = await GradeDownloadService.downloadGradesFromServer();
      if (result['success']) {
        print('✅ همگام‌سازی عیارها با موفقیت انجام شد');
      } else {
        print('⚠️ خطا در همگام‌سازی: ${result['message']}');
      }
    } catch (e) {
      print('❌ خطا در همگام‌سازی عیارها: $e');
    }
  }

  /// اطمینان از وجود داده‌های واقعی برای نمودار
  static Future<void> ensureRealDataExists() async {
    try {
      final box = await _gradeBox;
      final allGrades = box.values.toList();

      if (allGrades.isNotEmpty) {
        // بررسی اینکه آیا داده‌ها صفر هستند
        final nonZeroGrades =
            allGrades.where((grade) => grade.gradeValue > 0).length;

        if (nonZeroGrades == 0) {
          await box.clear();

          // تلاش برای بارگذاری از فایل CSV
          try {
            final csvString = await rootBundle.loadString('real_grades.csv');
            await GradeImportService.importMultipleGradesPerShift(
              csvString: csvString,
              clearExisting: false,
            );
          } catch (e) {
            // خطا در خواندن فایل CSV
          }
        }
        return;
      }

      // تلاش برای بارگذاری از فایل CSV
      try {
        final csvString = await rootBundle.loadString('real_grades.csv');
        await GradeImportService.importMultipleGradesPerShift(
          csvString: csvString,
          clearExisting: false,
        );
      } catch (e) {
        // خطا در خواندن فایل CSV
      }
    } catch (e) {
      // خطا در بررسی داده‌ها
    }
  }

  /// اضافه کردن داده‌های تست عیار برای 3 روز اخیر
  static Future<void> addTestGradeDataForLast3Days() async {
    final box = await _gradeBox;
    final now = DateTime.now();

    print('=== اضافه کردن داده‌های تست عیار برای 3 روز اخیر ===');

    // داده‌های تست برای 3 روز اخیر
    final testData = [
      // روز اول (دیروز)
      {'dayOffset': 2, 'shift': 1, 'خوراک': 30.5, 'محصول': 37.2, 'باطله': 12.1},
      {'dayOffset': 2, 'shift': 2, 'خوراک': 29.8, 'محصول': 36.8, 'باطله': 11.9},
      {'dayOffset': 2, 'shift': 3, 'خوراک': 31.2, 'محصول': 37.5, 'باطله': 12.3},

      // روز دوم (پارسال)
      {'dayOffset': 1, 'shift': 1, 'خوراک': 30.1, 'محصول': 36.9, 'باطله': 12.0},
      {'dayOffset': 1, 'shift': 2, 'خوراک': 30.8, 'محصول': 37.1, 'باطله': 12.2},
      {'dayOffset': 1, 'shift': 3, 'خوراک': 29.9, 'محصول': 36.7, 'باطله': 11.8},

      // روز سوم (امروز)
      {'dayOffset': 0, 'shift': 1, 'خوراک': 31.0, 'محصول': 37.3, 'باطله': 12.1},
      {'dayOffset': 0, 'shift': 2, 'خوراک': 30.3, 'محصول': 36.9, 'باطله': 12.0},
      {'dayOffset': 0, 'shift': 3, 'خوراک': 30.7, 'محصول': 37.0, 'باطله': 12.1},
    ];

    for (final data in testData) {
      final date = now.subtract(Duration(days: data['dayOffset'] as int));
      final shamsiDate = Jalali.fromDateTime(date);
      final shamsiYear = shamsiDate.year;
      final shamsiMonth = shamsiDate.month;
      final shamsiDay = shamsiDate.day;
      final shift = data['shift'] as int;

      // اضافه کردن عیار خوراک
      final feedGradeData = GradeData(
        id: '${shamsiYear}_${shamsiMonth.toString().padLeft(2, '0')}_${shamsiDay.toString().padLeft(2, '0')}_${shift}_خوراک',
        year: shamsiYear,
        month: shamsiMonth,
        day: shamsiDay,
        shift: shift,
        gradeType: 'خوراک',
        gradeValue: data['خوراک'] as double,
        recordedBy: 'test_user',
        recordedAt: DateTime.now(),
        workGroup: 1,
      );
      await box.put(feedGradeData.id, feedGradeData);

      // اضافه کردن عیار محصول
      final productGradeData = GradeData(
        id: '${shamsiYear}_${shamsiMonth.toString().padLeft(2, '0')}_${shamsiDay.toString().padLeft(2, '0')}_${shift}_محصول',
        year: shamsiYear,
        month: shamsiMonth,
        day: shamsiDay,
        shift: shift,
        gradeType: 'محصول',
        gradeValue: data['محصول'] as double,
        recordedBy: 'test_user',
        recordedAt: DateTime.now(),
        workGroup: 1,
      );
      await box.put(productGradeData.id, productGradeData);

      // اضافه کردن عیار باطله
      final wasteGradeData = GradeData(
        id: '${shamsiYear}_${shamsiMonth.toString().padLeft(2, '0')}_${shamsiDay.toString().padLeft(2, '0')}_${shift}_باطله',
        year: shamsiYear,
        month: shamsiMonth,
        day: shamsiDay,
        shift: shift,
        gradeType: 'باطله',
        gradeValue: data['باطله'] as double,
        recordedBy: 'test_user',
        recordedAt: DateTime.now(),
        workGroup: 1,
      );
      await box.put(wasteGradeData.id, wasteGradeData);

      print(
          'اضافه شد: ${shamsiYear}/${shamsiMonth}/${shamsiDay} شیفت $shift - خوراک: ${data['خوراک']}%, محصول: ${data['محصول']}%, باطله: ${data['باطله']}%');
    }

    print('=== پایان اضافه کردن داده‌های تست ===');
  }

  /// وارد کردن داده‌های عیار از فایل CSV
  static Future<void> importGradeDataFromCSV() async {
    try {
      print('=== شروع وارد کردن داده‌های عیار از CSV ===');

      // خواندن فایل CSV
      final file = File('real_grades.csv');
      if (!await file.exists()) {
        print('فایل real_grades.csv یافت نشد!');
        return;
      }

      final lines = await file.readAsLines();
      if (lines.isEmpty) {
        print('فایل CSV خالی است!');
        return;
      }

      // حذف سطر عنوان
      lines.removeAt(0);

      final gradeBox = Hive.box<GradeData>('gradeData');
      int importedCount = 0;

      for (String line in lines) {
        if (line.trim().isEmpty) continue;

        final parts = line.split(',');
        if (parts.length < 6) continue;

        try {
          final day = int.parse(parts[0].trim());
          final month = int.parse(parts[1].trim());
          final year = int.parse(parts[2].trim());

          // خواندن مقادیر عیار (ممکن است خالی باشند)
          final feedGradeStr = parts[3].trim();
          final productGradeStr = parts[4].trim();
          final wasteGradeStr = parts[5].trim();

          // تبدیل به عدد (اگر خالی نباشد)
          double? feedGrade =
              feedGradeStr.isNotEmpty ? double.tryParse(feedGradeStr) : null;
          double? productGrade = productGradeStr.isNotEmpty
              ? double.tryParse(productGradeStr)
              : null;
          double? wasteGrade =
              wasteGradeStr.isNotEmpty ? double.tryParse(wasteGradeStr) : null;

          final now = DateTime.now();

          // ایجاد رکورد برای عیار خوراک
          if (feedGrade != null) {
            final feedGradeData = GradeData(
              id: '${year}_${month.toString().padLeft(2, '0')}_${day.toString().padLeft(2, '0')}_خوراک',
              year: year,
              month: month,
              day: day,
              shift: 1, // پیش‌فرض شیفت 1
              gradeType: 'خوراک',
              gradeValue: feedGrade,
              recordedBy: 'system',
              recordedAt: now,
              workGroup: 1, // پیش‌فرض گروه کاری 1
            );
            await gradeBox.put(feedGradeData.id, feedGradeData);
            importedCount++;
          }

          // ایجاد رکورد برای عیار محصول
          if (productGrade != null) {
            final productGradeData = GradeData(
              id: '${year}_${month.toString().padLeft(2, '0')}_${day.toString().padLeft(2, '0')}_محصول',
              year: year,
              month: month,
              day: day,
              shift: 1, // پیش‌فرض شیفت 1
              gradeType: 'محصول',
              gradeValue: productGrade,
              recordedBy: 'system',
              recordedAt: now,
              workGroup: 1, // پیش‌فرض گروه کاری 1
            );
            await gradeBox.put(productGradeData.id, productGradeData);
            importedCount++;
          }

          // ایجاد رکورد برای عیار باطله
          if (wasteGrade != null) {
            final wasteGradeData = GradeData(
              id: '${year}_${month.toString().padLeft(2, '0')}_${day.toString().padLeft(2, '0')}_باطله',
              year: year,
              month: month,
              day: day,
              shift: 1, // پیش‌فرض شیفت 1
              gradeType: 'باطله',
              gradeValue: wasteGrade,
              recordedBy: 'system',
              recordedAt: now,
              workGroup: 1, // پیش‌فرض گروه کاری 1
            );
            await gradeBox.put(wasteGradeData.id, wasteGradeData);
            importedCount++;
          }
        } catch (e) {
          print('خطا در پردازش خط: $line - $e');
        }
      }

      print('=== وارد کردن داده‌های عیار تکمیل شد ===');
      print('تعداد رکوردهای وارد شده: $importedCount');
      print('کل رکوردهای عیار در دیتابیس: ${gradeBox.length}');
    } catch (e) {
      print('خطا در وارد کردن داده‌های عیار: $e');
    }
  }

  /// میانگین صحیح عیار برای آخرین ماه دیتابیس و نوع داده شده (ترکیبی)
  static Future<double> getMonthlyAverageForType(String gradeType) async {
    final allData = await getAllGradeData();
    if (allData.isEmpty) return 0.0;

    // پیدا کردن آخرین ماه موجود در دیتابیس
    final last = allData.reduce((a, b) {
      final dA = Jalali(a.year, a.month, a.day);
      final dB = Jalali(b.year, b.month, b.day);
      return dA.compareTo(dB) > 0 ? a : b;
    });
    final year = last.year;
    final month = last.month;

    print('=== دیباگ getMonthlyAverageForType ===');
    print('نوع عیار: $gradeType');
    print('سال: $year, ماه: $month');

    // فقط داده‌های همان ماه و نوع (حذف مقادیر صفر)
    final monthData = allData
        .where((g) =>
            g.year == year &&
            g.month == month &&
            g.gradeType == gradeType &&
            g.gradeValue > 0.0) // حذف مقادیر صفر
        .toList();

    print('تعداد داده‌های عیار در ماه (بدون صفر): ${monthData.length}');

    if (monthData.isEmpty) {
      print(
          'هیچ داده عیاری معتبر برای $gradeType در ماه $year/$month یافت نشد');
      return 0.0;
    }

    // محاسبه میانگین ساده تمام داده‌های معتبر ماه
    final sum = monthData.map((g) => g.gradeValue).reduce((a, b) => a + b);
    final average = sum / monthData.length;

    print('مجموع عیارها: $sum');
    print('تعداد داده‌های معتبر: ${monthData.length}');
    print('میانگین محاسبه شده: ${average.toStringAsFixed(2)}%');
    print('==============================');

    return average;
  }

  /// میانگین ترکیبی عیار (از سرور + CSV تاریخی) - بهینه‌سازی شده
  static Future<double> getCombinedMonthlyAverageForType(
      String gradeType) async {
    final allData = await getAllGradeData();
    if (allData.isEmpty) return 0.0;

    // پیدا کردن آخرین ماه موجود در دیتابیس
    final last = allData.reduce((a, b) {
      final dA = Jalali(a.year, a.month, a.day);
      final dB = Jalali(b.year, b.month, b.day);
      return dA.compareTo(dB) > 0 ? a : b;
    });
    final year = last.year;
    final month = last.month;

    // فقط داده‌های محلی برای سرعت بیشتر
    final localData = allData
        .where((g) =>
            g.year == year &&
            g.month == month &&
            g.gradeType == gradeType &&
            g.gradeValue > 0.0)
        .toList();

    if (localData.isEmpty) {
      return 0.0;
    }

    // محاسبه میانگین فقط از داده‌های محلی
    final totalGrade =
        localData.fold<double>(0.0, (sum, grade) => sum + grade.gradeValue);
    final average = totalGrade / localData.length;

    return average;
  }

  /// لیست روزهایی که داده واقعی برای نوع داده شده در آخرین ماه وجود دارد (برای نمودار)
  static Future<List<Map<String, dynamic>>> getDailyValuesForMonth(
      String gradeType) async {
    final allData = await getAllGradeData();
    if (allData.isEmpty) return [];

    final last = allData.reduce((a, b) {
      final dA = Jalali(a.year, a.month, a.day);
      final dB = Jalali(b.year, b.month, b.day);
      return dA.compareTo(dB) > 0 ? a : b;
    });
    final year = last.year;
    final month = last.month;

    // فقط داده‌های همان ماه و نوع (حذف مقادیر صفر)
    final monthData = allData
        .where((g) =>
            g.year == year &&
            g.month == month &&
            g.gradeType == gradeType &&
            g.gradeValue > 0.0) // حذف مقادیر صفر
        .toList();

    // گروه‌بندی بر اساس روز
    final Map<int, List<double>> dayMap = {};
    for (final g in monthData) {
      dayMap.putIfAbsent(g.day, () => []).add(g.gradeValue);
    }

    // فقط روزهایی که داده دارند (میانگین شیفت‌ها)
    final List<Map<String, dynamic>> result = [];
    dayMap.forEach((day, values) {
      final avg = values.reduce((a, b) => a + b) / values.length;
      result.add({'day': day, 'value': avg, 'year': year, 'month': month});
    });

    // مرتب‌سازی بر اساس روز
    result.sort((a, b) => a['day'].compareTo(b['day']));

    return result;
  }

  /// دریافت عیار امروز برای نوع مشخص
  static Future<double> getTodayGrade(String gradeType) async {
    final allData = await getAllGradeData();
    if (allData.isEmpty) return 0.0;

    // دریافت تاریخ امروز شمسی
    final persianDate = DateService.getCurrentShamsiDate();
    final persianParts = persianDate.split('/');
    final todayYear = int.parse(persianParts[0]);
    final todayMonth = int.parse(persianParts[1]);
    final todayDay = int.parse(persianParts[2]);

    // فیلتر کردن داده‌های امروز
    final todayData = allData
        .where((grade) =>
            grade.year == todayYear &&
            grade.month == todayMonth &&
            grade.day == todayDay &&
            grade.gradeType == gradeType &&
            grade.gradeValue > 0.0)
        .toList();

    if (todayData.isEmpty) return 0.0;

    // محاسبه میانگین عیارهای امروز
    final sum = todayData.map((g) => g.gradeValue).reduce((a, b) => a + b);
    return sum / todayData.length;
  }

  /// دریافت عیار دیروز برای نوع مشخص
  static Future<double> getYesterdayGrade(String gradeType) async {
    final allData = await getAllGradeData();
    if (allData.isEmpty) return 0.0;

    // محاسبه تاریخ دیروز شمسی
    final persianDate = DateService.getCurrentShamsiDate();
    final persianParts = persianDate.split('/');
    final todayYear = int.parse(persianParts[0]);
    final todayMonth = int.parse(persianParts[1]);
    final todayDay = int.parse(persianParts[2]);

    // محاسبه روز دیروز
    int yesterdayYear = todayYear;
    int yesterdayMonth = todayMonth;
    int yesterdayDay = todayDay - 1;

    if (yesterdayDay == 0) {
      yesterdayMonth--;
      if (yesterdayMonth == 0) {
        yesterdayYear--;
        yesterdayMonth = 12;
      }
      yesterdayDay = _getDaysInPersianMonth(yesterdayYear, yesterdayMonth);
    }

    // فیلتر کردن داده‌های دیروز
    final yesterdayData = allData
        .where((grade) =>
            grade.year == yesterdayYear &&
            grade.month == yesterdayMonth &&
            grade.day == yesterdayDay &&
            grade.gradeType == gradeType &&
            grade.gradeValue > 0.0)
        .toList();

    if (yesterdayData.isEmpty) return 0.0;

    // محاسبه میانگین عیارهای دیروز
    final sum = yesterdayData.map((g) => g.gradeValue).reduce((a, b) => a + b);
    return sum / yesterdayData.length;
  }

  /// محاسبه تعداد روزهای ماه شمسی
  static int _getDaysInPersianMonth(int year, int month) {
    if (month <= 6) return 31;
    if (month <= 11) return 30;
    // اسفند - بررسی سال کبیسه
    return _isPersianLeapYear(year) ? 30 : 29;
  }

  /// بررسی سال کبیسه شمسی
  static bool _isPersianLeapYear(int year) {
    final cycle = (year - 1) % 33;
    final leapYears = [1, 5, 9, 13, 17, 22, 26, 30];
    return leapYears.contains(cycle);
  }

  /// تابع تست برای بررسی داده‌های عیار در دیتابیس
  static Future<void> debugGradeData() async {
    final allData = await getAllGradeData();
    if (allData.isEmpty) {
      print('هیچ داده عیاری در دیتابیس وجود ندارد!');
      return;
    }

    print('=== دیباگ کامل داده‌های عیار ===');
    print('تعداد کل داده‌ها: ${allData.length}');

    // گروه‌بندی بر اساس سال و ماه
    final Map<String, List<GradeData>> monthlyGroups = {};
    for (final grade in allData) {
      final key = '${grade.year}/${grade.month}';
      monthlyGroups.putIfAbsent(key, () => []).add(grade);
    }

    print('تعداد ماه‌های دارای داده: ${monthlyGroups.length}');

    // نمایش آمار هر ماه
    for (final entry in monthlyGroups.entries) {
      final monthKey = entry.key;
      final monthData = entry.value;

      // گروه‌بندی بر اساس نوع عیار
      final Map<String, List<double>> gradesByType = {
        'خوراک': [],
        'محصول': [],
        'باطله': [],
      };

      for (final grade in monthData) {
        if (gradesByType.containsKey(grade.gradeType)) {
          gradesByType[grade.gradeType]!.add(grade.gradeValue);
        }
      }

      print('\n--- ماه $monthKey ---');
      print('تعداد کل داده‌ها: ${monthData.length}');

      for (final typeEntry in gradesByType.entries) {
        final type = typeEntry.key;
        final values = typeEntry.value;
        if (values.isNotEmpty) {
          final sum = values.reduce((a, b) => a + b);
          final avg = sum / values.length;
          print(
              '  $type: ${values.length} داده، میانگین: ${avg.toStringAsFixed(2)}%');
          print(
              '    مقادیر: ${values.map((v) => v.toStringAsFixed(2)).join(', ')}');
        } else {
          print('  $type: هیچ داده‌ای موجود نیست');
        }
      }
    }

    print('\n=== پایان دیباگ ===');
  }

  /// وارد کردن داده‌های عیار صحیح برای ماه 4 سال 1404
  static Future<void> importCorrectGradeData() async {
    final box = await _gradeBox;

    // پاک کردن داده‌های قبلی
    await box.clear();
    print('داده‌های قبلی پاک شدند');

    // داده‌های ثابت و قابل پیش‌بینی برای ماه 4 سال 1404
    final correctData = [
      // روز 1
      {'day': 1, 'shift': 1, 'خوراک': 30.5, 'محصول': 37.2, 'باطله': 12.1},
      {'day': 1, 'shift': 2, 'خوراک': 29.8, 'محصول': 36.8, 'باطله': 11.9},
      {'day': 1, 'shift': 3, 'خوراک': 31.2, 'محصول': 37.5, 'باطله': 12.3},

      // روز 2
      {'day': 2, 'shift': 1, 'خوراک': 30.1, 'محصول': 36.9, 'باطله': 12.0},
      {'day': 2, 'shift': 2, 'خوراک': 30.8, 'محصول': 37.1, 'باطله': 12.2},
      {'day': 2, 'shift': 3, 'خوراک': 29.9, 'محصول': 36.7, 'باطله': 11.8},

      // روز 3
      {'day': 3, 'shift': 1, 'خوراک': 31.0, 'محصول': 37.3, 'باطله': 12.1},
      {'day': 3, 'shift': 2, 'خوراک': 30.3, 'محصول': 36.9, 'باطله': 12.0},
      {'day': 3, 'shift': 3, 'خوراک': 30.7, 'محصول': 37.0, 'باطله': 12.1},

      // روز 4
      {'day': 4, 'shift': 1, 'خوراک': 29.8, 'محصول': 36.8, 'باطله': 11.9},
      {'day': 4, 'shift': 2, 'خوراک': 30.5, 'محصول': 37.2, 'باطله': 12.1},
      {'day': 4, 'shift': 3, 'خوراک': 30.9, 'محصول': 37.1, 'باطله': 12.0},

      // روز 5
      {'day': 5, 'shift': 1, 'خوراک': 30.2, 'محصول': 36.9, 'باطله': 12.0},
      {'day': 5, 'shift': 2, 'خوراک': 30.6, 'محصول': 37.0, 'باطله': 12.1},
      {'day': 5, 'shift': 3, 'خوراک': 30.4, 'محصول': 37.1, 'باطله': 12.0},

      // روز 6
      {'day': 6, 'shift': 1, 'خوراک': 30.8, 'محصول': 37.2, 'باطله': 12.1},
      {'day': 6, 'shift': 2, 'خوراک': 30.1, 'محصول': 36.8, 'باطله': 11.9},
      {'day': 6, 'shift': 3, 'خوراک': 30.5, 'محصول': 37.0, 'باطله': 12.0},

      // روز 7
      {'day': 7, 'shift': 1, 'خوراک': 30.3, 'محصول': 36.9, 'باطله': 12.0},
      {'day': 7, 'shift': 2, 'خوراک': 30.7, 'محصول': 37.1, 'باطله': 12.1},
      {'day': 7, 'shift': 3, 'خوراک': 30.2, 'محصول': 36.8, 'باطله': 11.9},

      // روز 8
      {'day': 8, 'shift': 1, 'خوراک': 30.6, 'محصول': 37.0, 'باطله': 12.0},
      {'day': 8, 'shift': 2, 'خوراک': 30.4, 'محصول': 37.2, 'باطله': 12.1},
      {'day': 8, 'shift': 3, 'خوراک': 30.8, 'محصول': 37.1, 'باطله': 12.0},

      // روز 9
      {'day': 9, 'shift': 1, 'خوراک': 30.1, 'محصول': 36.9, 'باطله': 12.0},
      {'day': 9, 'shift': 2, 'خوراک': 30.5, 'محصول': 37.0, 'باطله': 12.1},
      {'day': 9, 'shift': 3, 'خوراک': 30.3, 'محصول': 36.8, 'باطله': 11.9},

      // روز 10
      {'day': 10, 'shift': 1, 'خوراک': 30.7, 'محصول': 37.1, 'باطله': 12.0},
      {'day': 10, 'shift': 2, 'خوراک': 30.2, 'محصول': 36.9, 'باطله': 12.0},
      {'day': 10, 'shift': 3, 'خوراک': 30.6, 'محصول': 37.0, 'باطله': 12.1},
    ];

    int importedCount = 0;
    const year = 1404;
    const month = 4;

    for (final data in correctData) {
      final day = data['day'] as int;
      final shift = data['shift'] as int;

      // وارد کردن عیار خوراک
      final feedGradeData = GradeData(
        id: '${year}_${month.toString().padLeft(2, '0')}_${day.toString().padLeft(2, '0')}_${shift}_خوراک',
        year: year,
        month: month,
        day: day,
        shift: shift,
        gradeType: 'خوراک',
        gradeValue: data['خوراک'] as double,
        recordedBy: 'system_correct',
        recordedAt: DateTime.now(),
        workGroup: 1, // پیش‌فرض گروه کاری 1
      );
      await box.put(feedGradeData.id, feedGradeData);
      importedCount++;

      // وارد کردن عیار محصول
      final productGradeData = GradeData(
        id: '${year}_${month.toString().padLeft(2, '0')}_${day.toString().padLeft(2, '0')}_${shift}_محصول',
        year: year,
        month: month,
        day: day,
        shift: shift,
        gradeType: 'محصول',
        gradeValue: data['محصول'] as double,
        recordedBy: 'system_correct',
        recordedAt: DateTime.now(),
        workGroup: 1, // پیش‌فرض گروه کاری 1
      );
      await box.put(productGradeData.id, productGradeData);
      importedCount++;

      // وارد کردن عیار باطله
      final wasteGradeData = GradeData(
        id: '${year}_${month.toString().padLeft(2, '0')}_${day.toString().padLeft(2, '0')}_${shift}_باطله',
        year: year,
        month: month,
        day: day,
        shift: shift,
        gradeType: 'باطله',
        gradeValue: data['باطله'] as double,
        recordedBy: 'system_correct',
        recordedAt: DateTime.now(),
        workGroup: 1, // پیش‌فرض گروه کاری 1
      );
      await box.put(wasteGradeData.id, wasteGradeData);
      importedCount++;
    }

    print('=== وارد کردن داده‌های عیار صحیح ===');
    print('تعداد رکوردهای وارد شده: $importedCount');
    print('کل رکوردهای عیار در دیتابیس: ${box.length}');
    print('=====================================');
  }

  /// دانلود داده‌های عیار از هاست (بهینه‌شده)
  static Future<bool> downloadGradesFromServer() async {
    try {
      print('=== دانلود بهینه داده‌های عیار از هاست ===');

      final box = await _gradeBox;
      final serverGrades = await GradeApiService.downloadGrades();

      if (serverGrades.isEmpty) {
        print('هیچ داده‌ای در سرور یافت نشد');
        return true;
      }

      print('تعداد داده‌های دریافتی از سرور: ${serverGrades.length}');

      // فقط داده‌های جدید را اضافه کن (بدون پاک کردن کل دیتابیس)
      int importedCount = 0;
      int skippedCount = 0;

      for (final serverGrade in serverGrades) {
        // بررسی اینکه آیا کاربر واقعی برای همین تاریخ و نوع عیار چیزی ثبت کرده یا نه
        final existingUserRecord = box.values.any(
          (g) =>
              g.year == serverGrade.year &&
              g.month == serverGrade.month &&
              g.day == serverGrade.day &&
              g.gradeType == serverGrade.gradeType &&
              g.recordedBy != 'system' && // کاربر واقعی
              g.recordedBy.isNotEmpty,
        );

        if (existingUserRecord) {
          // کاربر واقعی برای این تاریخ و نوع عیار داده ثبت کرده - نادیده بگیر
          print(
              '⚠️ رد شد: عیار کاربر موجود ${serverGrade.year}/${serverGrade.month}/${serverGrade.day} - ${serverGrade.gradeType}');
          skippedCount++;
          continue;
        }

        // ایجاد ID منحصر به فرد
        final uniqueId =
            '${serverGrade.year}_${serverGrade.month.toString().padLeft(2, '0')}_${serverGrade.day.toString().padLeft(2, '0')}_${serverGrade.shift}_${serverGrade.gradeType}';

        // بررسی وجود رکورد system با همین ID
        if (box.containsKey(uniqueId)) {
          skippedCount++;
          continue; // رکورد system قبلاً وجود دارد
        }

        // ایجاد رکورد جدید
        final newGrade = GradeData(
          id: uniqueId,
          year: serverGrade.year,
          month: serverGrade.month,
          day: serverGrade.day,
          shift: serverGrade.shift,
          gradeType: serverGrade.gradeType,
          gradeValue: serverGrade.gradeValue,
          recordedBy: serverGrade.recordedBy,
          recordedAt: serverGrade.recordedAt,
          equipmentId: serverGrade.equipmentId,
          workGroup: serverGrade.workGroup,
        );

        // ذخیره در دیتابیس
        await box.put(uniqueId, newGrade);
        importedCount++;
        print(
            '✅ اضافه شد: ${serverGrade.year}/${serverGrade.month}/${serverGrade.day} - ${serverGrade.gradeType} (${serverGrade.recordedBy})');
      }

      print('=== نتیجه دانلود ===');
      print('رکوردهای جدید اضافه شده: $importedCount');
      print('رکوردهای رد شده (قبلاً موجود): $skippedCount');
      print('کل رکوردهای عیار در دیتابیس: ${box.length}');
      print('========================');

      // برگرداندن true اگر داده‌ای موجود باشد (جدید یا قدیمی)
      return box.length > 0;
    } catch (e) {
      print('خطا در دانلود از هاست: $e');
      return false;
    }
  }

  /// همگام‌سازی داده‌های محلی با سرور (بهینه‌شده)
  static Future<bool> syncWithServer() async {
    try {
      print('=== شروع همگام‌سازی بهینه با سرور ===');

      final box = await _gradeBox;
      final localGrades = box.values.toList();

      print('تعداد داده‌های محلی: ${localGrades.length}');

      // فقط داده‌های جدید را آپلود کن (آخرین 30 روز)
      final thirtyDaysAgo = DateTime.now().subtract(Duration(days: 30));
      final recentGrades = localGrades.where((grade) {
        final gradeDate = DateTime(grade.year, grade.month, grade.day);
        return gradeDate.isAfter(thirtyDaysAgo);
      }).toList();

      print('تعداد داده‌های جدید (30 روز اخیر): ${recentGrades.length}');

      if (recentGrades.isEmpty) {
        print('هیچ داده جدیدی برای آپلود وجود ندارد');
        return true;
      }

      // آپلود داده‌های جدید
      int uploadedCount = 0;
      int errorCount = 0;

      for (final grade in recentGrades) {
        try {
          final result = await GradeApiService.uploadGrade(
            year: grade.year,
            month: grade.month,
            day: grade.day,
            shift: grade.shift,
            gradeType: grade.gradeType,
            gradeValue: grade.gradeValue,
            recordedBy: grade.recordedBy,
          );

          if (result['success']) {
            uploadedCount++;
            if (uploadedCount <= 10) {
              print(
                  '✅ آپلود شد: ${grade.fullShamsiDate} ${grade.gradeType} (${grade.gradeValue}%)');
            }
          } else {
            errorCount++;
            print('❌ خطا در آپلود: ${result['message']}');
          }
        } catch (e) {
          errorCount++;
          print('❌ خطا در ارتباط: $e');
        }
      }

      print('=== نتیجه همگام‌سازی ===');
      print('تعداد آپلود شده: $uploadedCount');
      print('تعداد خطا: $errorCount');
      print('کل داده‌های جدید: ${recentGrades.length}');
      print('========================');

      return uploadedCount > 0;
    } catch (e) {
      print('خطا در همگام‌سازی: $e');
      return false;
    }
  }

  /// همگام‌سازی اجباری داده‌ها (برای حل مشکل عدم همگام‌سازی)
  static Future<bool> forceSync() async {
    try {
      print('=== شروع همگام‌سازی اجباری ===');

      // ابتدا آپلود داده‌های محلی به سرور
      final uploadResult = await syncWithServer();
      print('نتیجه آپلود: ${uploadResult ? "موفق" : "ناموفق"}');

      // سپس دانلود اجباری از سرور
      final downloadResult = await downloadGradesFromServer();
      print('نتیجه دانلود: ${downloadResult ? "موفق" : "ناموفق"}');

      // بررسی تعداد رکوردها
      final box = await _gradeBox;
      print('تعداد کل رکوردهای عیار پس از همگام‌سازی: ${box.length}');

      return uploadResult && downloadResult;
    } catch (e) {
      print('خطا در همگام‌سازی اجباری: $e');
      return false;
    }
  }

  /// همگام‌سازی هوشمند داده‌ها (بهینه‌سازی شده)
  static Future<bool> smartSync() async {
    try {
      print('=== شروع همگام‌سازی هوشمند ===');

      // بررسی اتصال اینترنت
      final hasInternet = await _checkInternetConnection();
      if (!hasInternet) {
        print('❌ اتصال اینترنت موجود نیست');
        return false;
      }

      // آپلود داده‌های جدید محلی
      final allData = await getAllGradeData();
      final newData = allData.where((grade) {
        final daysSinceRecorded =
            DateTime.now().difference(grade.recordedAt).inDays;
        return daysSinceRecorded <= 7; // فقط داده‌های 7 روز اخیر
      }).toList();

      // آپلود رکوردهای جدید (فعال)
      if (newData.isNotEmpty) {
        print('آپلود ${newData.length} رکورد جدید به سرور');
        final uploadResult = await syncGrades(newData);
        print('نتیجه آپلود: ${uploadResult ? "موفق" : "ناموفق"}');
      }

      // دانلود داده‌های جدید از سرور
      final downloadResult = await downloadGradesFromServer();
      print('نتیجه دانلود: ${downloadResult ? "موفق" : "ناموفق"}');

      return downloadResult;
    } catch (e) {
      print('خطا در همگام‌سازی هوشمند: $e');
      return false;
    }
  }

  /// بررسی اتصال اینترنت بهینه‌سازی شده
  static Future<bool> _checkInternetConnection() async {
    try {
      // تست سریع‌تر با سرور اصلی
      final result = await http.head(Uri.parse('http://62.60.198.11')).timeout(
            const Duration(seconds: 2),
          );
      return result.statusCode < 500;
    } catch (e) {
      print('⚠️ خطا در تست اتصال: $e');
      return false;
    }
  }

  /// همگام‌سازی داده‌های محلی با سرور
  static Future<bool> syncGrades(List<GradeData> localGrades) async {
    try {
      print('=== شروع همگام‌سازی داده‌های محلی ===');
      print('تعداد داده‌های محلی: ${localGrades.length}');

      // بررسی وضعیت سرور
      final serverStatus = await checkServerStatus();
      final bool apiExists = serverStatus['api_exists'] == true;
      final bool apiTestOk = serverStatus['api_test_success'] == true;
      if (!apiExists && !apiTestOk) {
        print('❌ دسترسی به API تایید نشد (نه HEAD و نه download موفق نبود)');
        return false;
      }

      // آپلود رکوردهای جدید
      int successCount = 0;
      for (final grade in localGrades) {
        try {
          final result = await GradeApiService.uploadGrade(
            year: grade.year,
            month: grade.month,
            day: grade.day,
            shift: grade.shift,
            gradeType: grade.gradeType,
            gradeValue: grade.gradeValue,
            recordedBy: grade.recordedBy,
          );

          if (result['success']) {
            successCount++;
            print('✅ آپلود موفق: ${grade.gradeType} - ${grade.fullShamsiDate}');
          } else {
            print('❌ خطا در آپلود: ${result['message']}');
          }
        } catch (e) {
          print('❌ خطا در آپلود رکورد: $e');
        }
      }

      print('تعداد آپلودهای موفق: $successCount از ${localGrades.length}');
      return successCount > 0;
    } catch (e) {
      print('خطا در همگام‌سازی: $e');
      return false;
    }
  }

  /// بررسی اتصال به سرور
  static Future<bool> checkServerConnection() async {
    try {
      final isConnected = await GradeApiService.checkConnection();
      print('وضعیت اتصال به سرور: ${isConnected ? "متصل" : "قطع"}');
      return isConnected;
    } catch (e) {
      print('خطا در بررسی اتصال: $e');
      return false;
    }
  }

  /// دریافت عیار برای تاریخ مشخص
  static Future<double> getGradeForDate(String gradeType, DateTime date) async {
    try {
      final box = await _gradeBox;
      final year = date.year;
      final month = date.month;
      final day = date.day;

      // دریافت تمام عیارهای روز مشخص
      final dayGrades = box.values
          .where((grade) =>
              grade.year == year &&
              grade.month == month &&
              grade.day == day &&
              grade.gradeType == gradeType)
          .toList();

      if (dayGrades.isEmpty) {
        return 0.0;
      }

      // محاسبه میانگین عیارهای روز
      final totalGrade =
          dayGrades.fold<double>(0.0, (sum, grade) => sum + grade.gradeValue);
      return totalGrade / dayGrades.length;
    } catch (e) {
      print('خطا در دریافت عیار برای تاریخ ${date.toString()}: $e');
      return 0.0;
    }
  }

  /// دریافت عیار برای تاریخ و شیفت مشخص
  static Future<double> getGradeForDateAndShift(
      String gradeType, DateTime date, int shift) async {
    try {
      final box = await _gradeBox;
      final year = date.year;
      final month = date.month;
      final day = date.day;

      // دریافت عیار برای شیفت مشخص
      final shiftGrades = box.values
          .where((grade) =>
              grade.year == year &&
              grade.month == month &&
              grade.day == day &&
              grade.shift == shift &&
              grade.gradeType == gradeType)
          .toList();

      if (shiftGrades.isEmpty) {
        print(
            '⚠️ هیچ داده‌ای برای $gradeType در تاریخ ${year}/${month}/${day} شیفت $shift یافت نشد');
        return 0.0;
      }

      // محاسبه میانگین عیارهای شیفت
      final totalGrade =
          shiftGrades.fold<double>(0.0, (sum, grade) => sum + grade.gradeValue);
      final average = totalGrade / shiftGrades.length;

      print(
          '✅ $gradeType - تاریخ: ${year}/${month}/${day} شیفت $shift = ${average.toStringAsFixed(2)}%');
      return average;
    } catch (e) {
      print(
          'خطا در دریافت عیار برای تاریخ ${date.toString()} و شیفت $shift: $e');
      return 0.0;
    }
  }

  /// نمایش تمام داده‌های موجود در دیتابیس
  static Future<void> printAllGradeData() async {
    try {
      final box = await _gradeBox;
      final allGrades = box.values.toList();

      print('=== تمام داده‌های عیار موجود ===');
      print('تعداد کل رکوردها: ${allGrades.length}');

      if (allGrades.isEmpty) {
        print('❌ هیچ داده‌ای در دیتابیس موجود نیست');
        return;
      }

      // گروه‌بندی بر اساس تاریخ
      final groupedByDate = <String, List<GradeData>>{};
      for (final grade in allGrades) {
        final dateKey = '${grade.year}/${grade.month}/${grade.day}';
        groupedByDate.putIfAbsent(dateKey, () => []).add(grade);
      }

      // مرتب‌سازی تاریخ‌ها
      final sortedDates = groupedByDate.keys.toList();
      sortedDates.sort((a, b) {
        final partsA = a.split('/');
        final partsB = b.split('/');

        final yearA = int.parse(partsA[0]);
        final monthA = int.parse(partsA[1]);
        final dayA = int.parse(partsA[2]);

        final yearB = int.parse(partsB[0]);
        final monthB = int.parse(partsB[1]);
        final dayB = int.parse(partsB[2]);

        if (yearA != yearB) return yearB.compareTo(yearA);
        if (monthA != monthB) return monthB.compareTo(monthA);
        return dayB.compareTo(dayA);
      });

      // نمایش داده‌ها
      for (final dateKey in sortedDates.take(10)) {
        // فقط 10 روز آخر
        final grades = groupedByDate[dateKey]!;
        print('\n📅 تاریخ: $dateKey');

        // گروه‌بندی بر اساس شیفت
        final groupedByShift = <int, List<GradeData>>{};
        for (final grade in grades) {
          groupedByShift.putIfAbsent(grade.shift, () => []).add(grade);
        }

        for (final shift in [1, 2, 3]) {
          if (groupedByShift.containsKey(shift)) {
            final shiftGrades = groupedByShift[shift]!;
            print('  شیفت $shift:');
            for (final grade in shiftGrades) {
              print(
                  '    ${grade.gradeType}: ${grade.gradeValue.toStringAsFixed(2)}%');
            }
          }
        }
      }

      print('\n=== پایان نمایش داده‌ها ===');
    } catch (e) {
      print('خطا در نمایش داده‌ها: $e');
    }
  }

  /// دریافت عیار برای تاریخ شمسی و شیفت مشخص
  static Future<double> getGradeForShamsiDateAndShift(
      String gradeType, int year, int month, int day, int shift) async {
    try {
      final box = await _gradeBox;

      // دریافت عیار برای شیفت مشخص با تاریخ شمسی
      final shiftGrades = box.values
          .where((grade) =>
              grade.year == year &&
              grade.month == month &&
              grade.day == day &&
              grade.shift == shift &&
              grade.gradeType == gradeType)
          .toList();

      if (shiftGrades.isEmpty) {
        print(
            '⚠️ هیچ داده‌ای برای $gradeType در تاریخ شمسی ${year}/${month}/${day} شیفت $shift یافت نشد');
        return 0.0;
      }

      // محاسبه میانگین عیارهای شیفت
      final totalGrade =
          shiftGrades.fold<double>(0.0, (sum, grade) => sum + grade.gradeValue);
      final average = totalGrade / shiftGrades.length;

      print(
          '✅ $gradeType - تاریخ شمسی: ${year}/${month}/${day} شیفت $shift = ${average.toStringAsFixed(2)}% (${shiftGrades.length} رکورد)');
      return average;
    } catch (e) {
      print(
          'خطا در دریافت عیار برای تاریخ شمسی ${year}/${month}/${day} و شیفت $shift: $e');
      return 0.0;
    }
  }

  /// دریافت عیار ترکیبی (از سرور + CSV تاریخی)
  static Future<double> getCombinedGradeValue(
      String gradeType, DateTime date) async {
    try {
      print('=== دریافت عیار ترکیبی ===');
      print('نوع عیار: $gradeType');
      print('تاریخ: ${date.year}/${date.month}/${date.day}');

      // 1. ابتدا از سرور (CSV ترکیبی) جستجو
      final serverData = await getGradeFromServer(gradeType, date);
      if (serverData > 0) {
        print('✅ داده از سرور یافت شد: $serverData%');
        return serverData;
      }

      // 2. اگر پیدا نشد، از CSV تاریخی محلی استفاده
      final historicalData = await getGradeFromHistoricalCSV(gradeType, date);
      if (historicalData > 0) {
        print('✅ داده از CSV تاریخی یافت شد: $historicalData%');
        return historicalData;
      }

      print('❌ هیچ داده‌ای یافت نشد');
      return 0.0;
    } catch (e) {
      print('خطا در دریافت عیار ترکیبی: $e');
      return 0.0;
    }
  }

  /// دریافت عیار از سرور
  static Future<double> getGradeFromServer(
      String gradeType, DateTime date) async {
    try {
      final response = await http.get(
        Uri.parse(
            'http://62.60.198.11/grade_api.php?action=download&api_key=pmsech_grade_api_2024'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final List<dynamic> gradesList = data['data'];

          // جستجو در داده‌های سرور
          for (final grade in gradesList) {
            if (grade['grade_type'] == gradeType) {
              final gradeDate = grade['date'];
              final dateParts = gradeDate.split('/');
              if (dateParts.length == 3) {
                final year = int.parse(dateParts[0]);
                final month = int.parse(dateParts[1]);
                final day = int.parse(dateParts[2]);

                if (year == date.year &&
                    month == date.month &&
                    day == date.day) {
                  return grade['grade_value'].toDouble();
                }
              }
            }
          }
        }
      }
      return 0.0;
    } catch (e) {
      print('خطا در دریافت از سرور: $e');
      return 0.0;
    }
  }

  /// دریافت عیار از CSV تاریخی محلی
  static Future<double> getGradeFromHistoricalCSV(
      String gradeType, DateTime date) async {
    try {
      // خواندن فایل CSV تاریخی از assets
      final csvString = await rootBundle.loadString('real_grades.csv');
      final lines = csvString.split('\n');

      // حذف header
      final dataLines = lines.skip(1).where((line) => line.trim().isNotEmpty);

      for (final line in dataLines) {
        final fields = line.split(',');
        if (fields.length >= 6) {
          final day = int.parse(fields[0].trim());
          final month = int.parse(fields[1].trim());
          final year = int.parse(fields[2].trim());

          if (year == date.year && month == date.month && day == date.day) {
            switch (gradeType) {
              case 'خوراک':
                return double.tryParse(fields[3].trim()) ?? 0.0;
              case 'محصول':
                return double.tryParse(fields[4].trim()) ?? 0.0;
              case 'باطله':
                return double.tryParse(fields[5].trim()) ?? 0.0;
            }
          }
        }
      }
      return 0.0;
    } catch (e) {
      print('خطا در خواندن CSV تاریخی: $e');
      return 0.0;
    }
  }

  /// بررسی وضعیت سرور و کلید API
  static Future<Map<String, dynamic>> checkServerStatus() async {
    try {
      print('=== بررسی وضعیت سرور ===');

      // تست 1: بررسی وجود فایل API
      final apiUrl = 'http://62.60.198.11/grade_api.php';
      final apiResponse = await http.head(Uri.parse(apiUrl));
      print('وضعیت فایل API: ${apiResponse.statusCode}');

      // تست 2: بررسی کلید API با اکشن صحیح
      final testUrl =
          'http://62.60.198.11/grade_api.php?action=download&api_key=pmsech_grade_api_2024';
      final testResponse = await http.get(Uri.parse(testUrl));
      print('وضعیت تست API: ${testResponse.statusCode}');
      print('پاسخ تست: ${testResponse.body}');

      // تست 3: بررسی فایل CSV
      final csvUrl = 'http://62.60.198.11/real_grades.csv';
      final csvResponse = await http.head(Uri.parse(csvUrl));
      print('وضعیت فایل CSV: ${csvResponse.statusCode}');

      // برخی سرورها برای HEAD مقدار 401 می‌دهند اما فایل موجود است (نیازمند کلید)
      final bool headIndicatesExists =
          apiResponse.statusCode == 200 || apiResponse.statusCode == 401;

      return {
        'api_exists': headIndicatesExists,
        'api_test_success': testResponse.statusCode == 200,
        'csv_exists': csvResponse.statusCode == 200,
        'api_response': testResponse.body,
      };
    } catch (e) {
      print('خطا در بررسی سرور: $e');
      return {
        'api_exists': false,
        'api_test_success': false,
        'csv_exists': false,
        'error': e.toString(),
      };
    }
  }

  /// حذف عیار از دیتابیس محلی
  static Future<bool> deleteGrade(String gradeId) async {
    try {
      final box = await _gradeBox;
      await box.delete(gradeId);
      print('✅ عیار با شناسه $gradeId حذف شد');
      return true;
    } catch (e) {
      print('❌ خطا در حذف عیار: $e');
      return false;
    }
  }

  /// آپلود با کلید API جدید
  static Future<bool> uploadGradeWithNewKey(
      String date, String gradeType, double gradeValue, int workGroup) async {
    try {
      print('=== آپلود با کلید جدید ===');

      // کلید API جدید (ممکن است در سرور متفاوت باشد)
      const List<String> possibleKeys = [
        'pmsech_grade_api_2024',
        'pmsech_api_key_2024',
        'grade_api_key_2024',
        'pmsech_grade_key',
        'test_api_key',
      ];

      for (String apiKey in possibleKeys) {
        try {
          final url =
              'http://62.60.198.11/grade_api.php?action=upload&api_key=$apiKey';
          final data = {
            'date': date,
            'grade_type': gradeType,
            'grade_value': gradeValue,
            // 'work_group': workGroup, // موقتاً غیرفعال
          };

          print('تلاش با کلید: $apiKey');
          final response = await http.post(
            Uri.parse(url),
            body: data,
          );

          print('کد وضعیت: ${response.statusCode}');
          print('پاسخ: ${response.body}');

          if (response.statusCode == 200) {
            final result = jsonDecode(response.body);
            if (result['success'] == true) {
              print('✅ آپلود موفق با کلید: $apiKey');
              return true;
            }
          }
        } catch (e) {
          print('خطا با کلید $apiKey: $e');
          continue;
        }
      }

      print('❌ هیچ کلید API کار نکرد');
      return false;
    } catch (e) {
      print('خطا در آپلود: $e');
      return false;
    }
  }

  /// پاک کردن کامل کش عیارها و همگام‌سازی اجباری
  static Future<bool> forceClearAndSync() async {
    try {
      print('=== پاک کردن کامل کش و همگام‌سازی اجباری ===');

      // پاک کردن کامل باکس عیارها
      final box = await _gradeBox;
      await box.clear();
      print('✅ کش عیارها پاک شد');

      // دانلود اجباری از سرور
      final downloadResult = await downloadGradesFromServer();
      if (downloadResult) {
        print('✅ دانلود اجباری از سرور موفق');
        print('تعداد عیارهای جدید: ${box.length}');
        return true;
      } else {
        print('❌ دانلود اجباری ناموفق');
        return false;
      }
    } catch (e) {
      print('خطا در پاک کردن و همگام‌سازی: $e');
      return false;
    }
  }
}
