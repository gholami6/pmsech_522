import '../models/production_data.dart';
import '../models/stop_data.dart';

import '../models/grade_data.dart';
import '../services/grade_service.dart';
import 'package:shamsi_date/shamsi_date.dart' as shamsi;
import 'package:hive/hive.dart';

/// سرویس تحلیل صحیح داده‌های تولید
///
/// منطق مهم:
/// - هر ردیف در اکسل = یک توقف
/// - داده‌های تولید تکراری هستند (برای جلوگیری از خالی بودن سلول‌ها)
/// - برای تحلیل توقفات: تمام ردیف‌ها را در نظر می‌گیریم
/// - برای تحلیل تولید: فقط یک ردیف از هر شیفت را در نظر می‌گیریم
class ProductionAnalysisService {
  /// تست منطق گروه‌بندی - برای دیباگ
  static void testGroupingLogic(List<ProductionData> data) {
    // این تابع برای دیباگ استفاده می‌شود و print statements حذف شده‌اند
  }

  /// گروه‌بندی داده‌ها بر اساس شیفت (تاریخ + شیفت)
  static Map<String, List<ProductionData>> _groupByShift(
      List<ProductionData> data) {
    Map<String, List<ProductionData>> grouped = {};

    for (var item in data) {
      // کلید یکتا برای هر شیفت (فقط تاریخ + شیفت)
      String shiftKey = '${item.fullShamsiDate}_${item.shift}';

      if (!grouped.containsKey(shiftKey)) {
        grouped[shiftKey] = [];
      }
      grouped[shiftKey]!.add(item);
    }

    return grouped;
  }

  /// دریافت داده‌های تولید منحصر به فرد (بدون تکرار)
  /// از هر شیفت فقط یک رکورد را برمی‌گرداند
  static List<ProductionData> getUniqueProductionData(
      List<ProductionData> data) {
    // اصلاح: از همه رکوردها استفاده می‌کنیم، نه فقط رکوردهای بدون توقف
    // چون هر رکورد می‌تواند هم تولید هم توقف داشته باشد
    final allData = data;

    final shiftGroups = _groupByShift(allData);

    List<ProductionData> uniqueData = [];

    for (var shiftData in shiftGroups.values) {
      if (shiftData.isNotEmpty) {
        // رکوردی با بیشترین خوراک را انتخاب می‌کنیم (نماینده واقعی شیفت)
        var representative =
            shiftData.reduce((a, b) => a.inputTonnage > b.inputTonnage ? a : b);
        uniqueData.add(representative);
      }
    }

    return uniqueData;
  }

  /// دریافت تمام داده‌های توقف (بدون فیلتر)
  /// همه ردیف‌ها را برمی‌گرداند چون هر ردیف = یک توقف
  static List<ProductionData> getAllStopData(List<ProductionData> data) {
    // حذف شرط stopDurationMinutes > 0 - تمام ردیف‌ها باید لحاظ شوند
    final stopData = data.toList();
    return stopData;
  }

  /// دریافت داده‌های تولید با فیلتر تاریخ و شیفت
  static Future<List<ProductionData>> getProductionData({
    required DateTime startDate,
    required DateTime endDate,
    String? shift,
  }) async {
    try {
      // دریافت داده‌ها از دیتابیس محلی
      final box = await Hive.openBox<ProductionData>('productionData');
      final allData = box.values.toList();

      print('=== دیباگ getProductionData ===');
      print('تاریخ شروع: $startDate');
      print('تاریخ پایان: $endDate');
      print('شیفت انتخاب شده: $shift');
      print('تعداد کل داده‌ها: ${allData.length}');

      // نمایش نمونه داده‌های موجود در دیتابیس
      if (allData.isNotEmpty) {
        print('نمونه داده‌های موجود در دیتابیس:');
        for (int i = 0; i < (allData.length > 5 ? 5 : allData.length); i++) {
          final data = allData[i];
          print(
              '  ${i + 1}. ${data.year}/${data.month}/${data.day} - شیفت ${data.shift}');
        }
      }

      // فیلتر بر اساس تاریخ - ساده‌سازی شده
      final filteredData = allData.where((data) {
        // تبدیل تاریخ‌های ورودی میلادی به شمسی
        final startShamsi = shamsi.Jalali.fromDateTime(startDate);
        final endShamsi = shamsi.Jalali.fromDateTime(endDate);

        print('دیباگ فیلتر تاریخ:');
        print('  داده: ${data.year}/${data.month}/${data.day}');
        print(
            '  شروع: ${startShamsi.year}/${startShamsi.month}/${startShamsi.day}');
        print('  پایان: ${endShamsi.year}/${endShamsi.month}/${endShamsi.day}');

        // مقایسه ساده و مستقیم
        final dataDate = DateTime(data.year, data.month, data.day);
        final startDateShamsi =
            DateTime(startShamsi.year, startShamsi.month, startShamsi.day);
        final endDateShamsi =
            DateTime(endShamsi.year, endShamsi.month, endShamsi.day);

        final isInRange = dataDate
                .isAfter(startDateShamsi.subtract(const Duration(days: 1))) &&
            dataDate.isBefore(endDateShamsi.add(const Duration(days: 1)));

        print('  در محدوده: $isInRange');
        return isInRange;
      }).toList();

      print('تعداد داده‌های فیلتر شده بر اساس تاریخ: ${filteredData.length}');

      // فیلتر بر اساس شیفت (اگر مشخص شده باشد)
      List<ProductionData> finalData = filteredData;
      if (shift != null && shift != 'همه شیفت‌ها') {
        final shiftNumber = _getShiftNumber(shift);
        finalData =
            filteredData.where((data) => data.shift == shiftNumber).toList();
        print('تعداد داده‌های فیلتر شده بر اساس شیفت: ${finalData.length}');
      }

      if (finalData.isNotEmpty) {
        print('نمونه داده‌ها:');
        for (int i = 0;
            i < (finalData.length > 3 ? 3 : finalData.length);
            i++) {
          final data = finalData[i];
          print(
              '  ${i + 1}. ${data.year}/${data.month}/${data.day} - شیفت ${data.shift} - خوراک: ${data.inputTonnage}');
        }
      }
      print('===============================');

      return finalData;
    } catch (e) {
      print('خطا در دریافت داده‌های تولید: $e');
      return [];
    }
  }

  /// دریافت آخرین تاریخ دیتا در دیتابیس
  static Future<DateTime?> getLatestProductionDate() async {
    try {
      final box = await Hive.openBox<ProductionData>('productionData');
      final allData = box.values.toList();

      if (allData.isEmpty) {
        return null;
      }

      // پیدا کردن آخرین تاریخ
      DateTime? latestDate;
      for (final data in allData) {
        final date = DateTime(data.year, data.month, data.day);
        if (latestDate == null || date.isAfter(latestDate)) {
          latestDate = date;
        }
      }

      return latestDate;
    } catch (e) {
      print('خطا در دریافت آخرین تاریخ: $e');
      return null;
    }
  }

  /// تبدیل نام شیفت به شماره
  static int _getShiftNumber(String shiftName) {
    switch (shiftName) {
      case 'شیفت صبح':
        return 1;
      case 'شیفت عصر':
        return 2;
      case 'شیفت شب':
        return 3;
      default:
        return 0;
    }
  }

  /// محاسبه آمار صحیح تولید
  static Map<String, dynamic> calculateProductionStatistics(
      List<ProductionData> data) {
    // استفاده از داده‌های منحصر به فرد برای تولید
    final uniqueData = getUniqueProductionData(data);

    if (uniqueData.isEmpty) {
      return {
        'totalInputTonnage': 0.0,
        'totalProducedProduct': 0.0,
        'totalWaste': 0.0,
        'totalServiceCount': 0,
        'directFeedCount': 0,
        'enrichmentCount': 0,
        'averageEfficiency': 0.0,
        'shiftsCount': 0,
      };
    }

    double totalInputTonnage = 0;
    double totalProducedProduct = 0;
    double totalWaste = 0;
    int totalServiceCount = 0;
    int directFeedCount = 0;
    int enrichmentCount = 0;

    for (int i = 0; i < uniqueData.length; i++) {
      var item = uniqueData[i];
      totalInputTonnage += item.inputTonnage;
      totalProducedProduct += item.producedProduct;
      totalWaste += item.waste;
      totalServiceCount += item.serviceCount;

      if (item.directFeed == 1) {
        directFeedCount++;
      } else {
        enrichmentCount++;
      }
    }

    double averageEfficiency = 0.0;
    if (totalInputTonnage > 0) {
      averageEfficiency = (totalProducedProduct / totalInputTonnage) * 100;
    }

    return {
      'totalInputTonnage': totalInputTonnage,
      'totalProducedProduct': totalProducedProduct,
      'totalWaste': totalWaste,
      'totalServiceCount': totalServiceCount,
      'directFeedCount': directFeedCount,
      'enrichmentCount': enrichmentCount,
      'averageEfficiency': averageEfficiency,
      'shiftsCount': uniqueData.length,
    };
  }

  /// محاسبه آمار صحیح توقفات
  static Map<String, dynamic> calculateStopStatistics(
      List<ProductionData> data) {
    // استفاده از تمام داده‌ها برای توقفات
    final stopData = getAllStopData(data);

    print('=== دیباگ محاسبه توقفات ===');
    print('تعداد کل داده‌های ورودی: ${data.length}');
    print('تعداد داده‌های توقف: ${stopData.length}');

    if (stopData.isEmpty) {
      return {
        'totalStops': 0,
        'totalStopDuration': 0,
        'emergencyStops': 0,
        'technicalStops': 0,
        'plannedStops': 0,
        'averageStopDuration': 0.0,
        'stopsByType': <String, int>{},
        'stopsByTypeDuration': <String, int>{},
        'stopsByEquipment': <String, int>{},
      };
    }

    int totalStops = 0;
    int totalStopDuration = 0;
    int emergencyStops = 0;
    int technicalStops = 0;
    int plannedStops = 0;
    Map<String, int> stopsByType = {};
    Map<String, int> stopsByTypeDuration = {};
    Map<String, int> stopsByEquipment = {};

    for (var item in stopData) {
      // فیلتر: فقط رکوردهای با stopType غیرخالی و stopDuration > 0
      if (item.stopType.isEmpty || item.stopDurationMinutes <= 0) {
        continue;
      }

      totalStops++;
      totalStopDuration += item.stopDurationMinutes;

      // شمارش انواع توقف
      if (item.isEmergencyStop) emergencyStops++;
      if (item.isTechnicalStop) technicalStops++;
      if (item.stopType == 'برنامه‌ای') plannedStops++;

      // گروه‌بندی بر اساس نوع توقف (تعداد)
      stopsByType[item.stopType] = (stopsByType[item.stopType] ?? 0) + 1;

      // گروه‌بندی بر اساس نوع توقف (مدت)
      stopsByTypeDuration[item.stopType] =
          (stopsByTypeDuration[item.stopType] ?? 0) + item.stopDurationMinutes;

      // گروه‌بندی بر اساس تجهیز
      stopsByEquipment[item.equipmentName] =
          (stopsByEquipment[item.equipmentName] ?? 0) + 1;
    }

    double averageStopDuration =
        totalStops > 0 ? totalStopDuration / totalStops : 0.0;

    return {
      'totalStops': totalStops,
      'totalStopDuration': totalStopDuration,
      'emergencyStops': emergencyStops,
      'technicalStops': technicalStops,
      'plannedStops': plannedStops,
      'averageStopDuration': averageStopDuration,
      'stopsByType': stopsByType,
      'stopsByTypeDuration': stopsByTypeDuration,
      'stopsByEquipment': stopsByEquipment,
    };
  }

  /// محاسبه آمار ترکیبی (تولید + توقف)
  static Map<String, dynamic> calculateCombinedStatistics(
      List<ProductionData> data) {
    final productionStats = calculateProductionStatistics(data);
    final stopStats = calculateStopStatistics(data);

    return {
      'production': productionStats,
      'stops': stopStats,
      'summary': {
        'totalRecords': data.length,
        'uniqueShifts': productionStats['shiftsCount'],
        'totalStops': stopStats['totalStops'],
        'productionEfficiency': productionStats['averageEfficiency'],
        'averageStopDuration': stopStats['averageStopDuration'],
      }
    };
  }

  /// آمار روزانه
  static Map<String, dynamic> getDailyStatistics(
      List<ProductionData> data, String date) {
    final dailyData =
        data.where((item) => item.fullShamsiDate == date).toList();
    return calculateCombinedStatistics(dailyData);
  }

  /// آمار تجهیز
  static Map<String, dynamic> getEquipmentStatistics(
      List<ProductionData> data, String equipmentName) {
    final equipmentData =
        data.where((item) => item.equipmentName == equipmentName).toList();
    return calculateCombinedStatistics(equipmentData);
  }

  /// آمار شیفت
  static Map<String, dynamic> getShiftStatistics(
      List<ProductionData> data, int shift) {
    final shiftData = data.where((item) => item.shift == shift).toList();
    return calculateCombinedStatistics(shiftData);
  }

  /// دریافت برترین تجهیزات بر اساس تولید
  static List<Map<String, dynamic>> getTopEquipmentsByProduction(
      List<ProductionData> data) {
    final uniqueData = getUniqueProductionData(data);
    Map<String, double> equipmentProduction = {};

    for (var item in uniqueData) {
      equipmentProduction[item.equipmentName] =
          (equipmentProduction[item.equipmentName] ?? 0) + item.producedProduct;
    }

    final sorted = equipmentProduction.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted
        .map((entry) => {
              'equipment': entry.key,
              'production': entry.value,
            })
        .toList();
  }

  /// دریافت تجهیزات با بیشترین توقف
  static List<Map<String, dynamic>> getTopEquipmentsByStops(
      List<ProductionData> data) {
    final stopData = getAllStopData(data);
    Map<String, int> equipmentStops = {};

    for (var item in stopData) {
      equipmentStops[item.equipmentName] =
          (equipmentStops[item.equipmentName] ?? 0) + 1;
    }

    final sorted = equipmentStops.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted
        .map((entry) => {
              'equipment': entry.key,
              'stops': entry.value,
            })
        .toList();
  }

  /// تبدیل دقیقه به فرمت ساعت:دقیقه
  static String formatDuration(int minutes) {
    if (minutes == 0) return '00:00';

    int hours = minutes ~/ 60;
    int mins = minutes % 60;

    return '${hours.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')}';
  }

  /// تبدیل عدد به فرمت فارسی با جداکننده
  static String formatNumber(dynamic number) {
    if (number == null) return '0';

    String numStr = number.toString();
    if (numStr.contains('.')) {
      List<String> parts = numStr.split('.');
      parts[0] = parts[0].replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (Match match) => '${match[1]},');
      return parts.join('.');
    }

    return numStr.replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (Match match) => '${match[1]},');
  }

  /// محاسبه دسترسی کل تجهیزات بر اساس فرمول
  /// دسترسی کل = (زمان کل در دسترس - زمان کل توقفات) / زمان کل در دسترس × 100
  static double calculateTotalAvailability(
      List<ProductionData> data, int totalDays) {
    if (totalDays <= 0) return 0.0;

    // محاسبه شیفت‌های کاری واقعی (3 شیفت در روز، 8 ساعت هر شیفت)
    final totalWorkingHours = totalDays * 3 * 8.0; // 3 شیفت × 8 ساعت
    final totalStopData = getAllStopData(data);

    double totalStopHours = 0.0;
    for (var item in totalStopData) {
      final stopHours = item.stopDurationMinutes / 60.0;
      totalStopHours += stopHours;
    }

    if (totalWorkingHours == 0) return 0.0;

    final availability =
        ((totalWorkingHours - totalStopHours) / totalWorkingHours) * 100;

    return availability.clamp(0.0, 100.0);
  }

  /// محاسبه دسترسی کل از لیست توقفات ترکیب شده
  /// دسترسی کل = (زمان کل در دسترس - زمان کل توقفات) / زمان کل در دسترس × 100
  static double calculateTotalAvailabilityFromStopData(
      List<ProductionData> stopData, int totalDays) {
    if (totalDays <= 0) return 0.0;

    // محاسبه شیفت‌های کاری واقعی (3 شیفت در روز، 8 ساعت هر شیفت)
    final totalWorkingHours = totalDays * 3 * 8.0; // 3 شیفت × 8 ساعت

    double totalStopHours = 0.0;
    for (var item in stopData) {
      final stopHours = item.stopDurationMinutes / 60.0;
      totalStopHours += stopHours;
    }

    print('مجموع ساعات توقف: ${totalStopHours.toStringAsFixed(2)}');

    if (totalWorkingHours == 0) return 0.0;

    final availability =
        ((totalWorkingHours - totalStopHours) / totalWorkingHours) * 100;

    print('دسترسی کل محاسبه شده: ${availability.toStringAsFixed(2)}%');
    print('===================================');

    return availability.clamp(0.0, 100.0);
  }

  /// محاسبه دسترسی تجهیزات بر اساس فرمول
  /// دسترسی تجهیزات = (کل زمان در دسترس - مجموع کل توقفات) / (زمان کل در دسترس - توقفات غیرفنی) × 100
  static double calculateEquipmentAvailability(
      List<ProductionData> data, int totalDays) {
    if (totalDays <= 0) return 0.0;

    // محاسبه شیفت‌های کاری واقعی (3 شیفت در روز، 8 ساعت هر شیفت)
    final totalWorkingHours = totalDays * 3 * 8.0; // 3 شیفت × 8 ساعت
    final stopData = getAllStopData(data);

    print('=== دیباگ محاسبه دسترسی تجهیزات ===');
    print('ساعات کاری کل: $totalWorkingHours');

    double totalStopHours = 0.0;
    double nonTechnicalStopHours = 0.0;

    // انواع توقفات غیرفنی
    final nonTechnicalStopTypes = [
      'معدنی',
      'بهره برداری',
      'عمومی',
      'بارگیری',
      'مجاز'
    ];

    for (var item in stopData) {
      final stopHours = item.stopDurationMinutes / 60.0;
      totalStopHours += stopHours;

      if (nonTechnicalStopTypes.contains(item.stopType)) {
        nonTechnicalStopHours += stopHours;
      }
    }

    print(
        'مجموع توقفات غیرفنی: ${nonTechnicalStopHours.toStringAsFixed(2)} ساعت');
    print('مجموع کل توقفات: ${totalStopHours.toStringAsFixed(2)} ساعت');

    // محاسبه زمان در دسترس فنی
    final availableForTechnicalWork = totalWorkingHours - nonTechnicalStopHours;

    print(
        'زمان در دسترس فنی: ${availableForTechnicalWork.toStringAsFixed(2)} ساعت');

    if (availableForTechnicalWork <= 0) return 0.0;

    // اصلاح فرمول: (زمان فنی - کل توقفات) / زمان فنی
    final technicalStopHours = totalStopHours - nonTechnicalStopHours;
    final equipmentAvailability =
        ((availableForTechnicalWork - technicalStopHours) /
                availableForTechnicalWork) *
            100;

    print('توقفات فنی: ${technicalStopHours.toStringAsFixed(2)} ساعت');
    print(
        'دسترسی تجهیزات محاسبه شده: ${equipmentAvailability.toStringAsFixed(2)}%');
    print('=========================================');

    return equipmentAvailability.clamp(0.0, 100.0);
  }

  /// محاسبه دسترسی تجهیزات از لیست توقفات ترکیب شده
  /// دسترسی تجهیزات = (کل زمان در دسترس - مجموع کل توقفات) / (زمان کل در دسترس - توقفات غیرفنی) × 100
  static double calculateEquipmentAvailabilityFromStopData(
      List<ProductionData> stopData, int totalDays) {
    if (totalDays <= 0) return 0.0;

    // محاسبه شیفت‌های کاری واقعی (3 شیفت در روز، 8 ساعت هر شیفت)
    final totalWorkingHours = totalDays * 3 * 8.0; // 3 شیفت × 8 ساعت

    print('=== دیباگ محاسبه دسترسی تجهیزات از توقفات ===');
    print('ساعات کاری کل: $totalWorkingHours');

    double totalStopHours = 0.0;
    double nonTechnicalStopHours = 0.0;

    // انواع توقفات غیرفنی
    final nonTechnicalStopTypes = [
      'معدنی',
      'بهره برداری',
      'عمومی',
      'بارگیری',
      'مجاز'
    ];

    for (var item in stopData) {
      final stopHours = item.stopDurationMinutes / 60.0;
      totalStopHours += stopHours;

      if (nonTechnicalStopTypes.contains(item.stopType)) {
        nonTechnicalStopHours += stopHours;
      }
    }

    print(
        'مجموع توقفات غیرفنی: ${nonTechnicalStopHours.toStringAsFixed(2)} ساعت');
    print('مجموع کل توقفات: ${totalStopHours.toStringAsFixed(2)} ساعت');

    // محاسبه زمان در دسترس فنی
    final availableForTechnicalWork = totalWorkingHours - nonTechnicalStopHours;

    print(
        'زمان در دسترس فنی: ${availableForTechnicalWork.toStringAsFixed(2)} ساعت');

    if (availableForTechnicalWork <= 0) return 0.0;

    // اصلاح فرمول: (زمان فنی - کل توقفات) / زمان فنی
    final technicalStopHours = totalStopHours - nonTechnicalStopHours;
    final equipmentAvailability =
        ((availableForTechnicalWork - technicalStopHours) /
                availableForTechnicalWork) *
            100;

    print('توقفات فنی: ${technicalStopHours.toStringAsFixed(2)} ساعت');
    print(
        'دسترسی تجهیزات محاسبه شده: ${equipmentAvailability.toStringAsFixed(2)}%');
    print('=========================================');

    return equipmentAvailability.clamp(0.0, 100.0);
  }

  /// محاسبه نرخ تناژ (تن در ساعت)
  /// نرخ تناژ = تناژ خوراک ÷ (زمان کل در دسترس - زمان کل توقفات)
  static double calculateTonnageRate(List<ProductionData> data, int totalDays) {
    if (totalDays <= 0) return 0.0;

    final uniqueData = getUniqueProductionData(data);
    double totalInputTonnage = 0.0;

    for (var item in uniqueData) {
      totalInputTonnage += item.inputTonnage;
    }

    // محاسبه زمان کل در دسترس
    final totalWorkingHours = totalDays * 3 * 8.0; // 3 شیفت × 8 ساعت

    // محاسبه زمان کل توقفات
    final totalStopData = getAllStopData(data);
    double totalStopHours = 0.0;
    for (var item in totalStopData) {
      totalStopHours += item.stopDurationMinutes / 60.0;
    }

    // محاسبه زمان کاری واقعی
    final actualWorkingHours = totalWorkingHours - totalStopHours;

    print('=== دیباگ محاسبه نرخ تناژ ===');
    print('تعداد روزها: $totalDays');
    print('تناژ خوراک کل: $totalInputTonnage تن');
    print('زمان کل در دسترس: $totalWorkingHours ساعت');
    print('زمان کل توقفات: ${totalStopHours.toStringAsFixed(2)} ساعت');
    print('زمان کاری واقعی: ${actualWorkingHours.toStringAsFixed(2)} ساعت');

    final tonnageRate =
        actualWorkingHours > 0 ? totalInputTonnage / actualWorkingHours : 0.0;

    print('نرخ تناژ محاسبه شده: ${tonnageRate.toStringAsFixed(2)} تن/ساعت');
    print('===================================');

    return tonnageRate;
  }

  /// محاسبه عیارهای واقعی از دیتابیس عیار
  static Future<Map<String, double>> calculateActualGrades(
      DateTime startDate, DateTime endDate) async {
    try {
      // عیارهای ماهیانه دستی (میانگین ماهیانه)
      // فرمت: 'سال/ماه' -> {'feedGrade': عیار_خوراک, 'productGrade': عیار_محصول, 'wasteGrade': عیار_باطله}
      final Map<String, Map<String, double>> monthlyGrades = {
        // سال 1402 - میانگین ماهیانه کل سال
        '1402/1': {
          'feedGrade': 30.93,
          'productGrade': 37.69,
          'wasteGrade': 13.5
        }, // فروردین
        '1402/2': {
          'feedGrade': 31.44,
          'productGrade': 38.01,
          'wasteGrade': 13.28
        }, // اردیبهشت
        '1402/3': {
          'feedGrade': 30.61,
          'productGrade': 36.65,
          'wasteGrade': 12.51
        }, // خرداد
        '1402/4': {
          'feedGrade': 30.04,
          'productGrade': 37.17,
          'wasteGrade': 12.80
        }, // تیر
        '1402/5': {
          'feedGrade': 32.25,
          'productGrade': 38.64,
          'wasteGrade': 14.44
        }, // مرداد
        '1402/6': {
          'feedGrade': 31.47,
          'productGrade': 39.02,
          'wasteGrade': 13.77
        }, // شهریور
        '1402/7': {
          'feedGrade': 29.09,
          'productGrade': 36.49,
          'wasteGrade': 11.20
        }, // مهر
        '1402/8': {
          'feedGrade': 30.37,
          'productGrade': 38.11,
          'wasteGrade': 11.95
        }, // آبان
        '1402/9': {
          'feedGrade': 30.84,
          'productGrade': 37.91,
          'wasteGrade': 15.07
        }, // آذر
        '1402/10': {
          'feedGrade': 31.07,
          'productGrade': 39.52,
          'wasteGrade': 12.55
        }, // دی
        '1402/11': {
          'feedGrade': 32.56,
          'productGrade': 37.52,
          'wasteGrade': 12.12
        }, // بهمن
        '1402/12': {
          'feedGrade': 28.01,
          'productGrade': 35.53,
          'wasteGrade': 7.32
        }, // اسفند

        // سال 1403 - میانگین ماهیانه تا آذر (از دی به بعد روزانه داریم)
        '1403/1': {
          'feedGrade': 28.96,
          'productGrade': 37.53,
          'wasteGrade': 12.35
        }, // فروردین
        '1403/2': {
          'feedGrade': 28.63,
          'productGrade': 36.99,
          'wasteGrade': 10.37
        }, // اردیبهشت
        '1403/3': {
          'feedGrade': 29.28,
          'productGrade': 37.16,
          'wasteGrade': 9.76
        }, // خرداد
        '1403/4': {
          'feedGrade': 27.85,
          'productGrade': 35.33,
          'wasteGrade': 7.89
        }, // تیر
        '1403/5': {
          'feedGrade': 27.30,
          'productGrade': 36.75,
          'wasteGrade': 7.94
        }, // مرداد
        '1403/6': {
          'feedGrade': 28.02,
          'productGrade': 36.21,
          'wasteGrade': 11.21
        }, // شهریور
        '1403/7': {
          'feedGrade': 33.13,
          'productGrade': 37.40,
          'wasteGrade': 11.24
        }, // مهر
        '1403/8': {
          'feedGrade': 36.93,
          'productGrade': 39.48,
          'wasteGrade': 10.10
        }, // آبان
        '1403/9': {
          'feedGrade': 32.60,
          'productGrade': 41.24,
          'wasteGrade': 11.19
        }, // آذر

        // سال 1404 - ماه‌هایی که روزانه نداریم از عیارهای ماهیانه استفاده می‌کنیم
        '1404/1': {
          'feedGrade': 31.44,
          'productGrade': 38.01,
          'wasteGrade': 13.28
        }, // فروردین (از عیارهای برنامه)
        '1404/2': {
          'feedGrade': 31.44,
          'productGrade': 38.01,
          'wasteGrade': 13.28
        }, // اردیبهشت (از عیارهای برنامه)
        '1404/3': {
          'feedGrade': 31.44,
          'productGrade': 38.01,
          'wasteGrade': 13.28
        }, // خرداد (از عیارهای برنامه)
      };

      // تبدیل تاریخ میلادی به شمسی برای جستجو
      final startShamsi = shamsi.Jalali.fromDateTime(startDate);
      final endShamsi = shamsi.Jalali.fromDateTime(endDate);

      // بررسی آیا بازه تاریخ در یک ماه خاص قرار دارد
      if (startShamsi.year == endShamsi.year &&
          startShamsi.month == endShamsi.month) {
        String monthKey = '${startShamsi.year}/${startShamsi.month}';
        if (monthlyGrades.containsKey(monthKey)) {
          print('=== استفاده از عیار ماهیانه دستی ===');
          print('ماه: $monthKey');
          print('عیار خوراک: ${monthlyGrades[monthKey]!['feedGrade']}%');
          print('عیار محصول: ${monthlyGrades[monthKey]!['productGrade']}%');
          print('عیار باطله: ${monthlyGrades[monthKey]!['wasteGrade']}%');
          print('===================================');

          return monthlyGrades[monthKey]!;
        }
      }

      // دریافت همه داده‌های عیار
      final allGradeData = await GradeService.getAllGradeData();

      // فیلتر بر اساس بازه تاریخ شمسی
      final filteredGradeData = allGradeData.where((grade) {
        final gradeDate = shamsi.Jalali(grade.year, grade.month, grade.day);
        return gradeDate >= startShamsi && gradeDate <= endShamsi;
      }).toList();

      // بررسی محدوده معتبر تاریخ
      final firstDataDate = shamsi.Jalali(1402, 1, 1); // ابتدای 1402

      // بررسی تاریخ‌های قبل از 1402
      if (endShamsi < firstDataDate) {
        print(
            'تاریخ درخواستی: ${endShamsi.year}/${endShamsi.month}/${endShamsi.day}');
        print(
            'ابتدای داده‌ها: ${firstDataDate.year}/${firstDataDate.month}/${firstDataDate.day}');
        throw Exception('داده‌ها از ابتدای سال 1402 به بعد وارد شده‌اند');
      }

      // تعیین آخرین تاریخ آپدیت از دیتابیس
      shamsi.Jalali? lastUpdateDate;
      if (allGradeData.isNotEmpty) {
        // پیدا کردن آخرین تاریخ موجود در دیتابیس
        final latestGrade = allGradeData.reduce((a, b) {
          final dateA = shamsi.Jalali(a.year, a.month, a.day);
          final dateB = shamsi.Jalali(b.year, b.month, b.day);
          return dateA > dateB ? a : b;
        });
        lastUpdateDate =
            shamsi.Jalali(latestGrade.year, latestGrade.month, latestGrade.day);
      } else {
        // اگر دیتابیس خالی است، از تاریخ پیش‌فرض استفاده می‌کنیم
        lastUpdateDate = shamsi.Jalali(1404, 4, 10);
      }

      // بررسی تاریخ‌های بعد از آخرین آپدیت
      if (startShamsi > lastUpdateDate) {
        print(
            'آخرین تاریخ آپدیت: ${lastUpdateDate.year}/${lastUpdateDate.month}/${lastUpdateDate.day}');
        print(
            'تاریخ درخواستی: ${startShamsi.year}/${startShamsi.month}/${startShamsi.day}');
        throw Exception(
            'تاریخی که وارد کرده‌اید، از تاریخ آخرین آپدیت برنامه خارج است');
      }

      if (filteredGradeData.isEmpty) {
        // اگر در بازه تاریخ داده‌ای نیست، خطا برمی‌گردانیم
        throw Exception('هیچ داده عیاری در بازه تاریخ انتخابی یافت نشد. '
            'لطفاً مطمئن شوید که داده‌های عیار برای این بازه تاریخ وارد شده باشد.');
      }

      // گروه‌بندی بر اساس نوع عیار
      final Map<String, List<double>> gradesByType = {
        'خوراک': [],
        'محصول': [],
        'باطله': [],
      };

      for (final grade in filteredGradeData) {
        if (gradesByType.containsKey(grade.gradeType)) {
          gradesByType[grade.gradeType]!.add(grade.gradeValue);
        }
      }

      // بررسی اینکه تمام انواع عیار موجود باشند
      final Map<String, double> averageGrades = {};
      for (final entry in gradesByType.entries) {
        if (entry.value.isNotEmpty) {
          final sum = entry.value.reduce((a, b) => a + b);
          averageGrades[entry.key] = sum / entry.value.length;
        } else {
          // اگر نوع عیاری موجود نباشد، خطا برمی‌گردانیم
          throw Exception(
              'داده عیار ${entry.key} در بازه تاریخ انتخابی یافت نشد. '
              'لطفاً مطمئن شوید که تمام انواع عیار وارد شده باشند.');
        }
      }

      print('=== عیارهای محاسبه شده ===');
      print(
          'بازه تاریخ: ${startShamsi.year}/${startShamsi.month}/${startShamsi.day} تا ${endShamsi.year}/${endShamsi.month}/${endShamsi.day}');
      print(
          'آخرین تاریخ آپدیت: ${lastUpdateDate?.year}/${lastUpdateDate?.month}/${lastUpdateDate?.day}');
      print('تعداد داده‌های عیار: ${filteredGradeData.length}');
      print('عیار خوراک: ${averageGrades['خوراک']?.toStringAsFixed(2)}%');
      print('عیار محصول: ${averageGrades['محصول']?.toStringAsFixed(2)}%');
      print('عیار باطله: ${averageGrades['باطله']?.toStringAsFixed(2)}%');
      print('===========================');

      return {
        'feedGrade': averageGrades['خوراک'] ?? 0.0,
        'productGrade': averageGrades['محصول'] ?? 0.0,
        'wasteGrade': averageGrades['باطله'] ?? 0.0,
      };
    } catch (e) {
      print('خطا در محاسبه عیارهای واقعی: $e');
      // بازگرداندن خطا برای نمایش به کاربر
      rethrow;
    }
  }

  /// محاسبه ریکاوری وزنی
  /// ریکاوری وزنی = (تناژ محصول / تناژ خوراک) × 100
  static double calculateWeightRecovery(double totalProduct, double totalFeed) {
    if (totalFeed == 0) return 0.0;
    return (totalProduct / totalFeed) * 100;
  }

  /// محاسبه ریکاوری فلزی
  /// ریکاوری فلزی = (تناژ محصول × عیار محصول) / (تناژ خوراک × عیار خوراک) × 100
  static double calculateMetalRecovery(double totalProduct, double totalFeed,
      double productGrade, double feedGrade) {
    if (totalFeed == 0 || feedGrade == 0) return 0.0;

    final productMetal = totalProduct * (productGrade / 100);
    final feedMetal = totalFeed * (feedGrade / 100);

    return (productMetal / feedMetal) * 100;
  }

  /// محاسبه آمار پیشرفته شامل تمام KPI ها
  static Future<Map<String, dynamic>> calculateAdvancedStatistics(
    List<ProductionData> data,
    int totalDays,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final productionStats = calculateProductionStatistics(data);

    // استفاده فقط از داده‌های توقف از ProductionData
    final allStopData = getAllStopData(data);

    print('=== دیباگ توقفات ===');
    print('تعداد توقفات از ProductionData: ${allStopData.length}');
    print('=============================');

    final stopStats = calculateStopStatistics(allStopData);

    // محاسبه دسترسی‌ها - استفاده از تمام داده‌های توقف
    final totalAvailability =
        calculateTotalAvailabilityFromStopData(allStopData, totalDays);
    final equipmentAvailability =
        calculateEquipmentAvailabilityFromStopData(allStopData, totalDays);
    final tonnageRate = calculateTonnageRate(data, totalDays);

    // محاسبه عیارهای واقعی
    Map<String, double> actualGrades;
    try {
      actualGrades = await calculateActualGrades(startDate, endDate);
    } catch (e) {
      // در صورت خطا، از عیارهای ماهیانه استفاده می‌کنیم
      print('خطا در محاسبه عیارهای روزانه: $e');
      print('استفاده از عیارهای ماهیانه...');

      // تبدیل تاریخ میلادی به شمسی
      final startShamsi = shamsi.Jalali.fromDateTime(startDate);
      final endShamsi = shamsi.Jalali.fromDateTime(endDate);

      // استفاده از عیارهای ماهیانه برای ماه وسط بازه
      final middleMonth = startShamsi.month;
      final year = startShamsi.year;
      String monthKey = '$year/$middleMonth';

      // عیارهای ماهیانه ثابت
      final Map<String, Map<String, double>> monthlyGrades = {
        '1402/4': {
          'feedGrade': 30.04,
          'productGrade': 37.17,
          'wasteGrade': 12.80
        },
        '1403/4': {
          'feedGrade': 27.85,
          'productGrade': 35.33,
          'wasteGrade': 7.89
        },
        '1404/4': {
          'feedGrade': 30.00,
          'productGrade': 37.00,
          'wasteGrade': 12.00
        },
      };

      if (monthlyGrades.containsKey(monthKey)) {
        actualGrades = monthlyGrades[monthKey]!;
        print('استفاده از عیارهای ماهیانه برای $monthKey');
      } else {
        // مقادیر پیش‌فرض
        actualGrades = {
          'feedGrade': 30.0,
          'productGrade': 37.0,
          'wasteGrade': 12.0,
        };
        print('استفاده از عیارهای پیش‌فرض');
      }
    }

    // محاسبه ریکاوری‌ها
    final weightRecovery = calculateWeightRecovery(
        productionStats['totalProducedProduct'],
        productionStats['totalInputTonnage']);

    final metalRecovery = calculateMetalRecovery(
        productionStats['totalProducedProduct'],
        productionStats['totalInputTonnage'],
        actualGrades['productGrade']!,
        actualGrades['feedGrade']!);

    return {
      'production': productionStats,
      'stops': stopStats,
      'availability': {
        'totalAvailability': totalAvailability,
        'equipmentAvailability': equipmentAvailability,
        'tonnageRate': tonnageRate,
      },
      'grades': actualGrades,
      'recovery': {
        'weightRecovery': weightRecovery,
        'metalRecovery': metalRecovery,
      },
      'summary': {
        'totalRecords': data.length,
        'uniqueShifts': productionStats['shiftsCount'],
        'totalStops': stopStats['totalStops'],
        'totalDays': totalDays,
      }
    };
  }

  /// دریافت تمام انواع توقف موجود در دیتابیس
  static Future<List<String>> getAllStopTypes() async {
    try {
      final box = await Hive.openBox<StopData>('stopData');
      final allData = box.values.toList();

      Set<String> stopTypes = {};
      for (var data in allData) {
        if (data.stopType.isNotEmpty) {
          stopTypes.add(data.stopType);
        }
      }

      return stopTypes.toList()..sort();
    } catch (e) {
      print('خطا در دریافت انواع توقف: $e');
      return [];
    }
  }

  /// بررسی وضعیت دیتابیس‌ها
  static Future<Map<String, dynamic>> checkDatabaseStatus() async {
    Map<String, dynamic> status = {
      'stopData': {'count': 0, 'accessible': false},
      'productionData': {'count': 0, 'accessible': false},
    };

    try {
      // بررسی StopData
      final stopBox = await Hive.openBox<StopData>('stopData');
      status['stopData']['count'] = stopBox.length;
      status['stopData']['accessible'] = true;
      print('StopData: ${stopBox.length} رکورد');
    } catch (e) {
      print('خطا در دسترسی به StopData: $e');
    }

    try {
      // بررسی ProductionData
      final productionBox =
          await Hive.openBox<ProductionData>('productionData');
      status['productionData']['count'] = productionBox.length;
      status['productionData']['accessible'] = true;
      print('ProductionData: ${productionBox.length} رکورد');
    } catch (e) {
      print('خطا در دسترسی به ProductionData: $e');
    }

    return status;
  }

  /// دریافت تمام تجهیزات موجود در دیتابیس
  static Future<List<String>> getAllEquipments() async {
    try {
      print('=== شروع getAllEquipments ===');

      // ابتدا از StopData تلاش می‌کنیم
      final stopBox = await Hive.openBox<StopData>('stopData');
      final stopData = stopBox.values.toList();
      print('تعداد رکوردهای StopData: ${stopData.length}');

      Set<String> equipments = {};
      for (var data in stopData) {
        print(
            'رکورد: سال=${data.year}, ماه=${data.month}, تجهیز="${data.equipment}", نام تجهیز="${data.equipmentName ?? "نام موجود نیست"}"');

        // اول از نام تجهیز استفاده کن، اگر نبود از کد تجهیز
        String equipmentName = data.equipmentName ?? data.equipment;
        if (equipmentName.isNotEmpty) {
          equipments.add(equipmentName);
        }
      }
      print('تجهیزات از StopData: $equipments');

      // اگر تجهیزاتی از StopData پیدا نشد، از ProductionData استفاده کن
      if (equipments.isEmpty) {
        print('هیچ تجهیزی در StopData یافت نشد، تلاش از ProductionData...');
        final productionBox =
            await Hive.openBox<ProductionData>('productionData');
        final productionData = productionBox.values.toList();
        print('تعداد رکوردهای ProductionData: ${productionData.length}');

        for (var data in productionData) {
          print('رکورد ProductionData: تجهیز="${data.equipmentName}"');
          if (data.equipmentName.isNotEmpty) {
            equipments.add(data.equipmentName);
          }
        }
        print('تجهیزات از ProductionData: $equipments');
      }

      final result = equipments.toList()..sort();
      print('نتیجه نهایی تجهیزات: $result');
      print('تعداد تجهیزات نهایی: ${result.length}');
      print('=== پایان getAllEquipments ===');
      return result;
    } catch (e) {
      print('خطا در دریافت تجهیزات: $e');

      // تلاش از ProductionData به عنوان جایگزین
      try {
        print('تلاش جایگزین از ProductionData...');
        final productionBox =
            await Hive.openBox<ProductionData>('productionData');
        final productionData = productionBox.values.toList();

        Set<String> equipments = {};
        for (var data in productionData) {
          if (data.equipmentName.isNotEmpty) {
            equipments.add(data.equipmentName);
          }
        }

        final result = equipments.toList()..sort();
        print('تجهیزات از ProductionData (جایگزین): $result');
        return result;
      } catch (e2) {
        print('خطا در دریافت تجهیزات از ProductionData: $e2');
        return [];
      }
    }
  }

  /// دریافت داده‌های توقف با فیلتر تجهیز و نوع توقف
  static Future<List<StopData>> getStopDataWithEquipment({
    required DateTime startDate,
    required DateTime endDate,
    String? stopType,
    String? equipment,
  }) async {
    try {
      final box = await Hive.openBox<StopData>('stopData');
      final allData = box.values.toList();

      List<StopData> filteredData = [];

      for (var data in allData) {
        // فیلتر تاریخ
        final dataDate = DateTime(data.year, data.month, data.day);
        if (dataDate.isBefore(startDate) || dataDate.isAfter(endDate)) {
          continue;
        }

        // فیلتر نوع توقف
        if (stopType != null && data.stopType != stopType) {
          continue;
        }

        // فیلتر تجهیز
        if (equipment != null && data.equipment != equipment) {
          continue;
        }

        filteredData.add(data);
      }

      return filteredData;
    } catch (e) {
      print('خطا در دریافت داده‌های توقف: $e');
      return [];
    }
  }

  /// دریافت تولید ماه جاری - نسخه بهینه شده
  static Future<double> getCurrentMonthProduction() async {
    try {
      // استفاده از ماه شمسی فعلی (1404/4)
      final currentYear = 1404;
      final currentMonth = 4;

      final box = await Hive.openBox<ProductionData>('productionData');
      final allData = box.values.toList();

      // فیلتر مستقیم بر اساس سال و ماه شمسی
      final monthlyData = allData.where((data) {
        return data.year == currentYear && data.month == currentMonth;
      }).toList();

      // محاسبه سریع با گروه‌بندی بر اساس شیفت
      final processedShifts = <String>{};
      double totalProduction = 0.0;

      for (var data in monthlyData) {
        if (data.inputTonnage > 0) {
          final shiftKey =
              '${data.year}/${data.month}/${data.day}/${data.shift}';
          if (!processedShifts.contains(shiftKey)) {
            totalProduction += data.producedProduct;
            processedShifts.add(shiftKey);
          }
        }
      }

      return totalProduction;
    } catch (e) {
      print('خطا در دریافت تولید ماه جاری: $e');
      return 0.0;
    }
  }
}
