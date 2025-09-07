import 'package:flutter/material.dart';

import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';
import 'package:provider/provider.dart';
import 'package:hive/hive.dart';
import 'dart:io';
import '../services/production_analysis_service.dart';
import '../services/planning_calculation_service.dart';
import '../services/pdf_report_service.dart';
import '../services/pdf_report_service.dart' show ChartPoint;
import '../services/navigation_service.dart';
import '../models/production_data.dart';
import '../models/stop_data.dart';
import '../providers/data_provider.dart';
import '../widgets/summary_card.dart';
import '../widgets/pie_chart_widget.dart';
import '../widgets/page_header.dart';
import '../config/stop_colors.dart';
import '../config/app_colors.dart';
import 'pdf_preview_screen.dart';
import 'dart:ui';
import '../config/box_configs.dart';
import '../config/standard_page_config.dart';
import 'annual_plan_screen.dart';

class StopsScreen extends StatefulWidget {
  const StopsScreen({Key? key}) : super(key: key);

  @override
  State<StopsScreen> createState() => _StopsScreenState();
}

class _StopsScreenState extends State<StopsScreen> {
  DateTime? startDate;
  DateTime? endDate;
  String selectedTimeRange = 'روزانه'; // حالت پیش‌فرض روزانه
  List<String> selectedStopTypes = [];
  List<String> selectedEquipments = [];
  bool selectAllStopTypes = true;
  bool selectAllEquipments = true;
  bool isLoading = false;
  List<StopData> stopData = [];
  Map<String, int> stopsByType = {};
  Map<String, int> stopsByTypeDuration = {};
  int totalActualStops = 0;
  double totalPlannedStops = 0;
  String plannedStopsLabel = 'برنامه';
  double deviationPercentage = 0.0;
  bool _isFilterCollapsed = false;
  int _currentPageIndex = 0;
  final PageController _pageController = PageController();
  bool _areIconsEnabled = true; // کنترل فعال/غیرفعال بودن آیکن‌ها
  bool _showTimeRangeFilters = false; // کنترل نمایش فیلترهای بازه زمانی
  // اضافه کردن متغیر برای کنترل به‌روزرسانی FutureBuilder
  int _refreshKey = 0;

  final List<String> timeRanges = ['روزانه', 'شیفتی', 'ماهانه'];
  List<String> allStopTypes = [];
  List<String> allEquipments = [];

  double touchedIndex = -1;

  @override
  void initState() {
    super.initState();
    _initializeDefaultDates();
    // حذف غیرفعال کردن آیکن‌ها در ابتدا
    // _areIconsEnabled = false;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // تابع به‌روزرسانی باکس اطلاعات کلی توقفات ماه جاری
  void _refreshCurrentMonthData() {
    setState(() {
      _refreshKey++;
    });
  }

  void _initializeDefaultDates() async {
    // تنظیم تاریخ‌های پیش‌فرض برای ماه جاری
    final now = Jalali.now();
    final currentMonthStart = Jalali(now.year, now.month, 1);
    final currentMonthEnd =
        Jalali(now.year, now.month, currentMonthStart.monthLength);

    setState(() {
      startDate = currentMonthStart.toDateTime();
      endDate = currentMonthEnd.toDateTime();
    });

    await _loadFilterOptions();
    // بارگذاری داده‌ها با تاریخ‌های پیش‌فرض
    await _loadStopData();
  }

  Future<void> _loadFilterOptions() async {
    try {
      // بررسی وضعیت دیتابیس‌ها
      final dbStatus = await ProductionAnalysisService.checkDatabaseStatus();
      print('=== وضعیت دیتابیس‌ها ===');
      print(
          'StopData: ${dbStatus['stopData']['count']} رکورد - قابل دسترسی: ${dbStatus['stopData']['accessible']}');
      print(
          'ProductionData: ${dbStatus['productionData']['count']} رکورد - قابل دسترسی: ${dbStatus['productionData']['accessible']}');
      print('========================');

      // استخراج انواع توقف از ستون 13 دیتابیس اصلی (stop_type)
      List<String> stopTypes = await _getStopTypesFromDatabase();
      print('انواع توقف از دیتابیس: $stopTypes');

      // استخراج نام‌های تجهیزات از ستون هفتم دیتابیس اصلی (equipment_name)
      List<String> equipmentNames = await _getEquipmentNamesFromDatabase();
      print('نام‌های تجهیزات از دیتابیس: $equipmentNames');

      setState(() {
        allStopTypes = stopTypes;
        allEquipments = equipmentNames;
      });

      print('=== نتیجه نهایی فیلترها ===');
      print('allStopTypes: $allStopTypes');
      print('allEquipments: $allEquipments');
      print('==========================');
    } catch (e) {
      print('خطا در بارگذاری گزینه‌های فیلتر: $e');
    }
  }

  /// استخراج انواع توقف از ستون 13 دیتابیس اصلی (stop_type)
  Future<List<String>> _getStopTypesFromDatabase() async {
    try {
      final stopBox = await Hive.openBox<StopData>('stopData');

      Set<String> uniqueStopTypes = {};

      for (var stopData in stopBox.values) {
        if (stopData.stopType.isNotEmpty) {
          uniqueStopTypes.add(stopData.stopType);
        }
      }

      final result = uniqueStopTypes.toList()..sort();
      print('تعداد انواع توقف یافت شده: ${result.length}');
      return result;
    } catch (e) {
      print('خطا در استخراج انواع توقف: $e');
      return [];
    }
  }

  /// استخراج نام‌های تجهیزات از ستون آخر StopData
  Future<List<String>> _getEquipmentNamesFromDatabase() async {
    try {
      final stopBox = await Hive.openBox<StopData>('stopData');
      Set<String> uniqueEquipmentNames = {};

      print('=== بررسی 10 ردیف اول ستون equipmentName ===');
      int count = 0;

      for (var stopData in stopBox.values) {
        if (count < 10) {
          print(
              'ردیف ${count + 1}: equipmentName = "${stopData.equipmentName}" | equipment = "${stopData.equipment}"');
          count++;
        }

        if (stopData.equipmentName == null) {
          // استفاده از equipment اگر equipmentName null باشد
          if (stopData.equipment.isNotEmpty) {
            uniqueEquipmentNames.add(stopData.equipment);
          }
        } else if (stopData.equipmentName!.isEmpty) {
          // استفاده از equipment اگر equipmentName خالی باشد
          if (stopData.equipment.isNotEmpty) {
            uniqueEquipmentNames.add(stopData.equipment);
          }
        } else {
          uniqueEquipmentNames.add(stopData.equipmentName!);
        }
      }

      print('==========================================');

      final result = uniqueEquipmentNames.toList()..sort();
      return result;
    } catch (e) {
      print('خطا در استخراج نام‌های تجهیزات: $e');
      return [];
    }
  }

  Future<void> _loadStopData() async {
    if (startDate == null || endDate == null) {
      setState(() {
        isLoading = false;
        stopData = [];
        stopsByType = {};
        stopsByTypeDuration = {};
        totalActualStops = 0;
        totalPlannedStops = 0;
        deviationPercentage = 0.0;
      });
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // دریافت DataProvider
      final dataProvider = Provider.of<DataProvider>(context, listen: false);

      // دریافت تمام داده‌های توقف در بازه زمانی
      final allStopData =
          dataProvider.getStopDataByDateRange(startDate!, endDate!);

      // اعمال فیلتر نوع توقف
      List<StopData> filteredByStopType = allStopData;
      if (!selectAllStopTypes && selectedStopTypes.isNotEmpty) {
        filteredByStopType = allStopData
            .where((data) => selectedStopTypes.contains(data.stopType))
            .toList();
      }

      // اعمال فیلتر تجهیز
      List<StopData> filteredByEquipment = filteredByStopType;
      if (!selectAllEquipments && selectedEquipments.isNotEmpty) {
        filteredByEquipment = filteredByStopType.where((data) {
          // اول از equipmentName استفاده کن، اگر نبود از equipment
          String equipmentName = data.equipmentName ?? data.equipment;
          return selectedEquipments.contains(equipmentName);
        }).toList();
      }

      print('=== دیباگ فیلترها ===');
      print('کل داده‌های توقف: ${allStopData.length}');
      print('بعد از فیلتر نوع توقف: ${filteredByStopType.length}');
      print('بعد از فیلتر تجهیز: ${filteredByEquipment.length}');
      print('========================');

      double totalActualStopsMinutes = 0;
      Map<String, int> stopsByType = {};
      Map<String, int> stopsByTypeDuration = {};

      for (final stopData in filteredByEquipment) {
        totalActualStopsMinutes += stopData.stopDuration;
        stopsByType[stopData.stopType] =
            (stopsByType[stopData.stopType] ?? 0) + 1;
        stopsByTypeDuration[stopData.stopType] =
            (stopsByTypeDuration[stopData.stopType] ?? 0) +
                stopData.stopDuration.toInt();
      }

      // محاسبه برنامه توقفات
      Map<String, dynamic> plannedStopsResult = await _calculatePlannedStops();
      double totalPlannedStopsMinutes = plannedStopsResult['minutes'];
      String plannedStopsLabel = plannedStopsResult['label'];

      // محاسبه انحراف از برنامه
      // اگر توقفات واقعی > توقفات برنامه → انحراف منفی (بدتر)
      // اگر توقفات واقعی < توقفات برنامه → انحراف مثبت (بهتر)
      double deviation = 0.0;
      if (totalPlannedStopsMinutes > 0) {
        deviation = ((totalActualStopsMinutes - totalPlannedStopsMinutes) /
                totalPlannedStopsMinutes) *
            100;
      }

      setState(() {
        this.stopData = filteredByEquipment;
        this.stopsByType = stopsByType;
        this.stopsByTypeDuration = stopsByTypeDuration;
        this.totalActualStops = totalActualStopsMinutes.toInt();
        this.totalPlannedStops = totalPlannedStopsMinutes;
        this.plannedStopsLabel = plannedStopsLabel;
        this.deviationPercentage = deviation;
        isLoading = false;
      });

      // لاگ برای دیباگ
      print('=== دیباگ محاسبات توقفات ===');
      print(
          'توقفات واقعی: ${(totalActualStopsMinutes / 60).toStringAsFixed(2)} ساعت');
      print(
          'توقفات برنامه: ${(totalPlannedStopsMinutes / 60).toStringAsFixed(2)} ساعت');
      print('انحراف: ${deviation.toStringAsFixed(2)}%');
      print('============================');
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('خطا در بارگذاری داده‌ها: $e');
    }
  }

  Future<void> _selectDateRange() async {
    // استفاده از تقویم شمسی
    final now = Jalali.now();
    // محاسبه 30 روز قبل با بررسی محدوده معتبر
    DateTime thirtyDaysAgo;
    if (now.day > 30) {
      // اگر روز بیشتر از 30 است، به ماه قبل برو
      final prevMonth = now.month > 1 ? now.month - 1 : 12;
      final prevYear = now.month > 1 ? now.year : now.year - 1;
      thirtyDaysAgo = Jalali(prevYear, prevMonth, 1).toDateTime();
    } else {
      thirtyDaysAgo = Jalali(now.year, now.month, 1).toDateTime();
    }

    // بررسی محدوده معتبر برای تقویم شمسی
    final currentJalali = Jalali.now();
    final firstDate = Jalali(1400, 1, 1);
    final lastDate = Jalali(currentJalali.year + 1, 12, 29); // محدوده گسترده‌تر

    // تنظیم initialDateRange با بررسی محدوده معتبر
    JalaliRange? initialRange;
    if (startDate != null && endDate != null) {
      final startJalali = Jalali.fromDateTime(startDate!);
      final endJalali = Jalali.fromDateTime(endDate!);

      // بررسی اینکه تاریخ‌ها در محدوده معتبر باشند
      if (startJalali.isAfter(firstDate) && endJalali.isBefore(lastDate)) {
        initialRange = JalaliRange(start: startJalali, end: endJalali);
      }
    }

    // اگر initialRange معتبر نباشد، از تاریخ پیش‌فرض استفاده کن
    if (initialRange == null) {
      final now = DateTime.now();
      final defaultStart =
          Jalali.fromDateTime(now.subtract(const Duration(days: 30)));
      final defaultEnd = Jalali.fromDateTime(now);
      initialRange = JalaliRange(start: defaultStart, end: defaultEnd);
    }

    final picked = await showPersianDateRangePicker(
      context: context,
      firstDate: firstDate,
      lastDate: lastDate,
      initialDateRange: initialRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  onSurface: Colors.black,
                  onPrimary: Colors.black,
                  onSecondary: Colors.black,
                ),
            textTheme: Theme.of(context).textTheme.copyWith(
                  bodyLarge: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.black,
                      ),
                  bodyMedium: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.black,
                      ),
                  titleMedium:
                      Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.black,
                          ),
                ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        startDate = picked.start.toDateTime();
        endDate = picked.end.toDateTime();
      });

      // بارگذاری داده‌ها بعد از انتخاب تاریخ
      await _loadStopData();
    }
  }

  /// محاسبه برنامه توقفات برای بازه زمانی انتخابی
  Future<Map<String, dynamic>> _calculatePlannedStops() async {
    if (startDate == null || endDate == null)
      return {'minutes': 0.0, 'label': 'برنامه'};

    // بررسی آیا فیلتر تجهیز اعمال شده است
    bool hasEquipmentFilter =
        !selectAllEquipments && selectedEquipments.isNotEmpty;

    if (hasEquipmentFilter) {
      // حالت دوم: فیلتر تجهیز اعمال شده - استفاده از داده‌های سال گذشته
      return await _calculatePreviousYearStops();
    } else {
      // حالت اول: هیچ فیلتر تجهیز - استفاده از برنامه سالانه
      return await _calculateAnnualPlanStops();
    }
  }

  /// محاسبه توقفات سال گذشته (وقتی فیلتر تجهیز اعمال شده)
  Future<Map<String, dynamic>> _calculatePreviousYearStops() async {
    try {
      final startShamsi = Jalali.fromDateTime(startDate!);
      final endShamsi = Jalali.fromDateTime(endDate!);

      // سال گذشته
      final previousYear = startShamsi.year - 1;

      // دریافت DataProvider
      final dataProvider = Provider.of<DataProvider>(context, listen: false);

      // فیلترهای اعمال شده (به جز سال)
      List<StopData> allPreviousYearData = [];

      // دریافت تمام داده‌های سال گذشته
      final allData = dataProvider.getStopData();

      for (var data in allData) {
        // فیلتر سال گذشته
        if (data.year != previousYear) continue;

        // فیلتر ماه
        if (data.month < startShamsi.month || data.month > endShamsi.month)
          continue;

        // فیلتر روز
        if (data.month == startShamsi.month && data.day < startShamsi.day)
          continue;
        if (data.month == endShamsi.month && data.day > endShamsi.day) continue;

        // فیلتر نوع توقف
        if (!selectAllStopTypes && selectedStopTypes.isNotEmpty) {
          if (!selectedStopTypes.contains(data.stopType)) continue;
        }

        // فیلتر تجهیز
        String equipmentName = data.equipmentName ?? data.equipment;
        if (!selectedEquipments.contains(equipmentName)) continue;

        allPreviousYearData.add(data);
      }

      // محاسبه مجموع مدت توقفات
      double totalMinutes = 0.0;
      for (var data in allPreviousYearData) {
        totalMinutes += data.stopDuration;
      }

      print('=== دیباگ محاسبه سال گذشته ===');
      print('سال گذشته: $previousYear');
      print('تعداد رکوردهای فیلتر شده: ${allPreviousYearData.length}');
      print('مجموع دقیقه: $totalMinutes');
      print('تبدیل به ساعت: ${(totalMinutes / 60).toStringAsFixed(2)} ساعت');
      print('===============================');

      return {'minutes': totalMinutes, 'label': 'سال گذشته'};
    } catch (e) {
      print('خطا در محاسبه سال گذشته: $e');
      return {'minutes': 0.0, 'label': 'سال گذشته'};
    }
  }

  /// محاسبه برنامه سالانه (وقتی هیچ فیلتر تجهیز اعمال نشده)
  Future<Map<String, dynamic>> _calculateAnnualPlanStops() async {
    // انتخاب منطق محاسبات بر اساس نوع بازه
    switch (selectedTimeRange) {
      case 'شیفتی':
        return await _calculateShiftPlannedStops();
      case 'ماهانه':
        return await _calculateMonthlyPlannedStops();
      case 'روزانه':
      default:
        return await _calculateDailyPlannedStopsAsync();
    }
  }

  /// محاسبه برنامه روزانه
  Future<Map<String, dynamic>> _calculateDailyPlannedStopsAsync() async {
    // استفاده از داده‌های برنامه سالانه از annual_plan_screen.dart
    final monthlyStopsPlan = AnnualPlanData.getStopsPlan();

    final startShamsi = Jalali.fromDateTime(startDate!);
    final endShamsi = Jalali.fromDateTime(endDate!);

    print('=== دیباگ محاسبه برنامه توقفات روزانه ===');
    print(
        'تاریخ شروع: ${startShamsi.year}/${startShamsi.month}/${startShamsi.day}');
    print('تاریخ پایان: ${endShamsi.year}/${endShamsi.month}/${endShamsi.day}');
    print('=====================================');

    // محاسبه برای هر روز در بازه زمانی
    double totalPlannedMinutes = 0.0;
    int totalDays = 0;

    // محاسبه تعداد روزها
    DateTime currentDate = startDate!;
    while (currentDate.isBefore(endDate!.add(const Duration(days: 1)))) {
      final currentShamsi = Jalali.fromDateTime(currentDate);
      final month = currentShamsi.month;
      final daysInMonth = Jalali(currentShamsi.year, month, 1).monthLength;

      // محاسبه برنامه روزانه برای این ماه (کل توقفات برنامه سالانه)
      double totalPlannedDays = 0.0;
      for (List<double> monthlyValues in monthlyStopsPlan.values) {
        totalPlannedDays += monthlyValues[month - 1];
      }

      // برنامه روزانه = برنامه ماهانه / تعداد روزهای ماه
      final dailyPlannedHours = totalPlannedDays / daysInMonth;
      final dailyPlannedMinutes =
          dailyPlannedHours * 24 * 60; // تبدیل به دقیقه (24 ساعت × 60 دقیقه)

      totalPlannedMinutes += dailyPlannedMinutes;
      totalDays++;

      print(
          'روز ${currentShamsi.day}/${currentShamsi.month}: ${dailyPlannedMinutes.toStringAsFixed(0)} دقیقه');

      currentDate = currentDate.add(const Duration(days: 1));
    }

    print('کل روزها: $totalDays');
    print('کل برنامه (دقیقه): ${totalPlannedMinutes.toStringAsFixed(0)}');
    print('کل برنامه (ساعت): ${(totalPlannedMinutes / 60).toStringAsFixed(2)}');
    print('=====================================');

    return {'minutes': totalPlannedMinutes, 'label': 'برنامه روزانه'};
  }

  /// محاسبه برنامه شیفتی
  Future<Map<String, dynamic>> _calculateShiftPlannedStops() async {
    // محاسبه تعداد روزها در بازه زمانی
    final days = endDate!.difference(startDate!).inDays + 1;
    final totalShifts = days * 3; // 3 شیفت در هر روز

    // استفاده از منطق روزانه و تقسیم بر تعداد کل شیفت‌ها
    final dailyResult = await _calculateDailyPlannedStopsAsync();
    final shiftMinutes = dailyResult['minutes'] / totalShifts;

    print('=== دیباگ محاسبه برنامه توقفات شیفتی ===');
    print('تعداد روزها: $days');
    print('تعداد کل شیفت‌ها: $totalShifts');
    print('برنامه روزانه: ${dailyResult['minutes']} دقیقه');
    print('برنامه شیفتی: ${shiftMinutes.toStringAsFixed(0)} دقیقه');
    print('=====================================');

    return {'minutes': shiftMinutes, 'label': 'برنامه شیفتی'};
  }

  /// محاسبه برنامه ماهانه
  Future<Map<String, dynamic>> _calculateMonthlyPlannedStops() async {
    // داده‌های برنامه ماهانه (از annual_plan_screen.dart)
    const Map<String, List<double>> monthlyStopsPlan = {
      'برنامه ای': [3.0, 3.0, 3.0, 3.0, 3.0, 8.0, 3.0, 3.0, 3.0, 3.0, 3.0, 8.0],
      'مکانیکی': [1.6, 1.6, 1.6, 1.6, 1.6, 1.6, 1.6, 1.6, 1.6, 1.6, 1.6, 1.5],
      'برقی': [0.4, 0.4, 0.4, 0.4, 0.4, 0.4, 0.4, 0.4, 0.4, 0.4, 0.4, 0.4],
      'تاسیساتی': [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
      'بهره برداری': [
        1.3,
        1.3,
        1.3,
        1.3,
        1.3,
        1.3,
        1.3,
        1.3,
        1.3,
        1.3,
        1.3,
        1.3
      ],
      'معدنی': [0.7, 0.7, 0.7, 0.7, 0.7, 0.7, 0.7, 0.7, 0.7, 0.7, 0.7, 0.7],
      'عمومی': [3.1, 0.5, 0.5, 2.5, 0.5, 0.5, 0.5, 0.5, 0.5, 1.0, 1.0, 3.9],
      'مجاز': [4.8, 4.8, 4.8, 4.8, 4.8, 4.8, 4.6, 4.6, 4.6, 4.6, 4.6, 4.5],
      'بارگیری': [0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2],
    };

    final startShamsi = Jalali.fromDateTime(startDate!);
    final endShamsi = Jalali.fromDateTime(endDate!);

    print('=== دیباگ محاسبه برنامه توقفات ماهانه ===');
    print(
        'تاریخ شروع: ${startShamsi.year}/${startShamsi.month}/${startShamsi.day}');
    print('تاریخ پایان: ${endShamsi.year}/${endShamsi.month}/${endShamsi.day}');
    print('=====================================');

    // محاسبه برای هر روز در بازه زمانی
    double totalPlannedMinutes = 0.0;
    int totalDays = 0;

    // محاسبه تعداد روزها
    DateTime currentDate = startDate!;
    while (currentDate.isBefore(endDate!.add(const Duration(days: 1)))) {
      final currentShamsi = Jalali.fromDateTime(currentDate);
      final month = currentShamsi.month;
      final daysInMonth = Jalali(currentShamsi.year, month, 1).monthLength;

      // محاسبه برنامه روزانه برای این ماه
      double totalPlannedDays = 0.0;
      for (List<double> monthlyValues in monthlyStopsPlan.values) {
        totalPlannedDays += monthlyValues[month - 1];
      }

      // برنامه روزانه = برنامه ماهانه / تعداد روزهای ماه
      final dailyPlannedHours = totalPlannedDays / daysInMonth;
      final dailyPlannedMinutes = dailyPlannedHours * 60; // تبدیل به دقیقه

      totalPlannedMinutes += dailyPlannedMinutes;
      totalDays++;

      print(
          'روز ${currentShamsi.day}/${currentShamsi.month}: ${dailyPlannedMinutes.toStringAsFixed(0)} دقیقه');

      currentDate = currentDate.add(const Duration(days: 1));
    }

    print('کل روزها: $totalDays');
    print('کل برنامه (دقیقه): ${totalPlannedMinutes.toStringAsFixed(0)}');
    print('کل برنامه (ساعت): ${(totalPlannedMinutes / 60).toStringAsFixed(2)}');
    print('=====================================');

    return {'minutes': totalPlannedMinutes, 'label': 'برنامه ماهانه'};
  }

  String _formatPersianDate(DateTime date) {
    final j = Jalali.fromDateTime(date);
    return '${j.year}/${j.month.toString().padLeft(2, '0')}/${j.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DataProvider>(
      builder: (context, dataProvider, child) {
        // گوش دادن به تغییرات DataProvider و به‌روزرسانی باکس
        WidgetsBinding.instance.addPostFrameCallback((_) {
          // اگر همگام‌سازی تمام شده و داده‌های توقف موجود است، به‌روزرسانی کن
          if (!dataProvider.isLoading &&
              dataProvider.simpleDataSyncService.getStopData().isNotEmpty &&
              _refreshKey == 0) {
            _refreshCurrentMonthData();
          }
        });

        return StandardPageConfig.buildStandardPage(
          title: 'مدیریت توقفات',
          content: _buildContent(),
          filterSection: _buildFilterSection(),
          isFilterCollapsed: _isFilterCollapsed,
        );
      },
    );
  }

  Widget _buildFilterSection() {
    final dateRangeConfig = BoxConfigs.dateRange;
    if (_isFilterCollapsed) {
      // حالت جمع شده با انیمیشن
      return AnimatedContainer(
        duration: dateRangeConfig.animationDuration,
        curve: dateRangeConfig.animationCurve,
        margin: EdgeInsets.all(dateRangeConfig.margin),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(dateRangeConfig.padding),
          decoration: BoxDecoration(
            color: dateRangeConfig.backgroundColorCollapsed,
            borderRadius: BorderRadius.circular(dateRangeConfig.borderRadius),
            boxShadow: [
              BoxShadow(
                color: dateRangeConfig.boxShadowColor,
                spreadRadius: 1,
                blurRadius: dateRangeConfig.boxShadowBlur,
                offset: dateRangeConfig.boxShadowOffset,
              ),
            ],
            border: Border.all(
              color: dateRangeConfig.borderColor,
              width: dateRangeConfig.borderWidth,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  if (_areIconsEnabled)
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _isFilterCollapsed = false;
                        });
                      },
                      icon: Icon(Icons.expand_more,
                          color: dateRangeConfig.iconColor,
                          size: dateRangeConfig.iconSize),
                    ),
                  const Spacer(),
                  Text(
                    'ویرایش بازه زمانی',
                    style: TextStyle(
                      fontSize: dateRangeConfig.titleFontSize,
                      fontWeight: dateRangeConfig.titleFontWeight,
                      color: dateRangeConfig.titleColor,
                      shadows: [
                        Shadow(
                          offset: const Offset(0, 1),
                          blurRadius: 3,
                          color: Colors.black.withOpacity(0.15),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () {
                      setState(() {
                        _isFilterCollapsed = false;
                      });
                    },
                    child: Icon(Icons.edit,
                        color: dateRangeConfig.editIconColor,
                        size: dateRangeConfig.editIconSize),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Spacer(),
                  Text(
                    selectedTimeRange,
                    style: TextStyle(
                      fontSize: dateRangeConfig.valueFontSize,
                      color: dateRangeConfig.valueColor,
                      shadows: [
                        Shadow(
                          offset: const Offset(0, 1),
                          blurRadius: 2,
                          color: Colors.black.withOpacity(0.1),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '-',
                    style: TextStyle(
                      fontSize: dateRangeConfig.valueFontSize,
                      color: dateRangeConfig.valueColor,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    startDate != null && endDate != null
                        ? '${_formatPersianDate(startDate!)} تا ${_formatPersianDate(endDate!)}'
                        : 'بازه زمانی برای گزارش را انتخاب کنید',
                    style: TextStyle(
                      fontSize: dateRangeConfig.valueFontSize,
                      color: dateRangeConfig.valueColor,
                      fontWeight: dateRangeConfig.valueFontWeight,
                      shadows: [
                        Shadow(
                          offset: const Offset(0, 1),
                          blurRadius: 2,
                          color: Colors.black.withOpacity(0.1),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Spacer(),
                  if (!selectAllStopTypes && selectedStopTypes.isNotEmpty)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: dateRangeConfig.tagBackgroundColor,
                        borderRadius: BorderRadius.circular(
                            dateRangeConfig.tagBorderRadius),
                      ),
                      child: Text(
                        'توقف: ${selectedStopTypes.length} انتخاب',
                        style: TextStyle(
                          fontSize: dateRangeConfig.tagFontSize,
                          color: dateRangeConfig.tagTextColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  if (!selectAllStopTypes &&
                      selectedStopTypes.isNotEmpty &&
                      !selectAllEquipments &&
                      selectedEquipments.isNotEmpty)
                    const SizedBox(width: 4),
                  if (!selectAllEquipments && selectedEquipments.isNotEmpty)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green[100],
                        borderRadius: BorderRadius.circular(
                            dateRangeConfig.tagBorderRadius),
                      ),
                      child: Text(
                        'تجهیز: ${selectedEquipments.length} انتخاب',
                        style: TextStyle(
                          fontSize: dateRangeConfig.tagFontSize,
                          color: Colors.green[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    // حالت باز شده با انیمیشن
    return AnimatedContainer(
      duration: dateRangeConfig.animationDuration,
      curve: dateRangeConfig.animationCurve,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(dateRangeConfig.padding),
        child: Column(
          children: [
            // باکس اطلاعات کلی توقفات ماه جاری (قبل از تولید گزارش)
            _buildStopsCurrentMonthInfoBoxStyled(),

            const SizedBox(height: 12),

            // باکس بازه زمانی در بالای صفحه
            Container(
              width: double.infinity,
              margin: EdgeInsets.symmetric(horizontal: 6),
              padding: EdgeInsets.all(dateRangeConfig.padding),
              decoration: BoxDecoration(
                color: dateRangeConfig.backgroundColorExpanded,
                borderRadius:
                    BorderRadius.circular(dateRangeConfig.borderRadius),
                boxShadow: [
                  BoxShadow(
                    color: dateRangeConfig.boxShadowColor,
                    spreadRadius: 1,
                    blurRadius: dateRangeConfig.boxShadowBlur,
                    offset: dateRangeConfig.boxShadowOffset,
                  ),
                ],
                border: Border.all(
                  color: dateRangeConfig.borderColor,
                  width: dateRangeConfig.borderWidth,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'بازه زمانی',
                    style: TextStyle(
                      fontSize: dateRangeConfig.titleFontSize,
                      fontWeight: dateRangeConfig.titleFontWeight,
                      color: dateRangeConfig.titleColor,
                      shadows: [
                        Shadow(
                          offset: const Offset(0, 1),
                          blurRadius: 3,
                          color: Colors.black.withOpacity(0.15),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  InkWell(
                    onTap: _selectDateRange,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.arrow_drop_down,
                              color: dateRangeConfig.iconColor),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              startDate != null && endDate != null
                                  ? '${_formatPersianDate(startDate!)} تا ${_formatPersianDate(endDate!)}'
                                  : 'بازه زمانی برای گزارش را انتخاب کنید',
                              style:
                                  TextStyle(color: dateRangeConfig.valueColor),
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.right,
                            ),
                          ),
                          Icon(Icons.calendar_today,
                              color: dateRangeConfig.iconColor),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),
            // ردیف دوم: فیلترهای توقف و تجهیز
            Column(
              children: [
                // باکس‌های فیلتر در کنار هم
                Row(
                  children: [
                    // باکس نوع توقف
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: const Color(0x4D9E9E9E),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0x1A000000),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'فیلتر نوع توقف',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[800],
                                fontFamily: 'Vazirmatn',
                                shadows: [
                                  Shadow(
                                    offset: const Offset(0, 1),
                                    blurRadius: 3,
                                    color: Colors.black.withOpacity(0.15),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 6),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Colors.grey[300]!,
                                  width: 1,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                color: Colors.grey[50],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  // نمایش انتخاب‌های فعلی
                                  if (selectedStopTypes.isNotEmpty)
                                    Wrap(
                                      spacing: 4,
                                      runSpacing: 4,
                                      children:
                                          selectedStopTypes.toSet().map((type) {
                                        return Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color:
                                                StopColors.getColorForStopType(
                                                    type),
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                type,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w500,
                                                  fontFamily: 'Vazirmatn',
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              GestureDetector(
                                                onTap: () {
                                                  setState(() {
                                                    selectedStopTypes
                                                        .remove(type);
                                                    if (selectedStopTypes
                                                        .isEmpty) {
                                                      selectAllStopTypes = true;
                                                    }
                                                  });
                                                },
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.all(2),
                                                  child: const Icon(
                                                    Icons.close,
                                                    color: Colors.white,
                                                    size: 16,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  // دکمه انتخاب
                                  InkWell(
                                    onTap: () {
                                      _showStopTypeSelector();
                                    },
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          selectAllStopTypes
                                              ? 'همه توقفات'
                                              : selectedStopTypes.isEmpty
                                                  ? 'انتخاب نوع توقف'
                                                  : '${selectedStopTypes.length} انتخاب',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 10,
                                            fontFamily: 'Vazirmatn',
                                          ),
                                        ),
                                        Icon(
                                          Icons.arrow_drop_down,
                                          color: Colors.grey[600],
                                          size: 16,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // باکس تجهیزات
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: const Color(0x4D9E9E9E),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0x1A000000),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'فیلتر تجهیزات',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[800],
                                fontFamily: 'Vazirmatn',
                                shadows: [
                                  Shadow(
                                    offset: const Offset(0, 1),
                                    blurRadius: 3,
                                    color: Colors.black.withOpacity(0.15),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 6),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Colors.grey[300]!,
                                  width: 1,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                color: Colors.grey[50],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  // نمایش انتخاب‌های فعلی
                                  if (selectedEquipments.isNotEmpty)
                                    Wrap(
                                      spacing: 4,
                                      runSpacing: 4,
                                      children: selectedEquipments
                                          .toSet()
                                          .map((equipment) {
                                        return Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.blue[600],
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                equipment,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w500,
                                                  fontFamily: 'Vazirmatn',
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              GestureDetector(
                                                onTap: () {
                                                  setState(() {
                                                    selectedEquipments
                                                        .remove(equipment);
                                                    if (selectedEquipments
                                                        .isEmpty) {
                                                      selectAllEquipments =
                                                          true;
                                                    }
                                                  });
                                                },
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.all(2),
                                                  child: const Icon(
                                                    Icons.close,
                                                    color: Colors.white,
                                                    size: 16,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  // دکمه انتخاب
                                  InkWell(
                                    onTap: () {
                                      _showEquipmentSelector();
                                    },
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          selectAllEquipments
                                              ? 'همه تجهیزات'
                                              : selectedEquipments.isEmpty
                                                  ? 'انتخاب تجهیزات'
                                                  : '${selectedEquipments.length} انتخاب',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 10,
                                            fontFamily: 'Vazirmatn',
                                          ),
                                        ),
                                        Icon(
                                          Icons.arrow_drop_down,
                                          color: Colors.grey[600],
                                          size: 16,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),

            // حذف باکس «نوع بازه» طبق درخواست

            // دکمه نمایش گزارش
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _isFilterCollapsed = true; // جمع کردن فیلترها
                      _areIconsEnabled = false; // غیرفعال کردن آیکن‌ها
                      _showTimeRangeFilters =
                          true; // فعال کردن فیلترهای بازه زمانی
                    });
                    _loadStopData();
                  },
                  icon: const Icon(Icons.analytics),
                  label: const Text('نمایش گزارش'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.stopsAccentOrange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return GestureDetector(
      onTap: () {
        // حذف فیلتر با کلیک در جای دیگر صفحه
        if (_filteredStopType != null || _filteredEquipment != null) {
          setState(() {
            _filteredStopType = null;
            _filteredEquipment = null;
          });
        }
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // SummaryCards with animation
            AnimatedContainer(
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutBack,
              child: _buildSummaryCards(),
            ),
            const SizedBox(height: 12),

            // فیلترهای بازه زمانی (فقط بعد از تولید گزارش)
            if (_showTimeRangeFilters)
              AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
                child: _buildTimeRangeFilters(),
              ),
            if (_showTimeRangeFilters) const SizedBox(height: 12),

            // PageView برای نمودارها با انیمیشن
            AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
              height: 400,
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPageIndex = index;
                  });
                },
                children: [
                  // نمودار بر اساس نوع بازه انتخاب شده
                  _buildDynamicChart(),
                  // ۲. نمودار دایره‌ای (محور افقی ثابت)
                  _buildChart(),
                  // ۳. نمودار ستونی (محور افقی ثابت)
                  _buildNewChart(),
                ],
              ),
            ),

            // نشانگر صفحات و دکمه‌های ناوبری
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // دکمه قبلی با انیمیشن
                  if (_areIconsEnabled)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      child: IconButton(
                        onPressed: _currentPageIndex > 0
                            ? () {
                                _pageController.previousPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              }
                            : null,
                        icon: Icon(
                          Icons.arrow_back_ios,
                          color: _currentPageIndex > 0
                              ? AppColors.stopsAccentBlue
                              : Colors.grey[300],
                        ),
                      ),
                    ),

                  // نشانگر صفحات با انیمیشن
                  Row(
                    children: [
                      for (int i = 0; i < 3; i++)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          width: _currentPageIndex == i ? 24 : 8,
                          height: 8,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(
                                _currentPageIndex == i ? 4 : 4),
                            color: _currentPageIndex == i
                                ? AppColors.stopsAccentBlue
                                : Colors.grey[300],
                          ),
                        ),
                    ],
                  ),

                  // دکمه بعدی با انیمیشن
                  if (_areIconsEnabled)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      child: IconButton(
                        onPressed: _currentPageIndex < 2
                            ? () {
                                _pageController.nextPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              }
                            : null,
                        icon: Icon(
                          Icons.arrow_forward_ios,
                          color: _currentPageIndex < 2
                              ? AppColors.stopsAccentBlue
                              : Colors.grey[300],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // جدول داده‌ها با انیمیشن
            AnimatedContainer(
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutBack,
              child: _buildDataTable(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChart() {
    return PieChartWidget(
      stopsByTypeDuration: stopsByTypeDuration,
      totalActualStops: totalActualStops,
      onSliceTap: (stopType) {
        // نمایش جزئیات توقفات در جدول
        _showStopDetails(stopType);
      },
      onLegendTap: (stopType) {
        // فیلتر کردن جدول بر اساس نوع توقف
        _filterTableByStopType(stopType);
      },
    );
  }

  Widget _buildNewChart() {
    // نمودار ستونی توقفات بر اساس نوع
    if (stopsByTypeDuration.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'نمودار ستونی توقفات',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
                fontFamily: 'Vazirmatn',
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: const Center(
                child: Text(
                  'داده‌ای برای نمایش وجود ندارد',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontFamily: 'Vazirmatn',
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // مرتب‌سازی داده‌ها از بزرگترین به کوچکترین
    final sortedData = stopsByTypeDuration.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // محاسبه حداکثر مقدار برای مقیاس محور Y
    final maxHours = sortedData.isNotEmpty
        ? (sortedData.first.value / 60).ceil().toDouble()
        : 1.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'نمودار ستونی توقفات',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
              fontFamily: 'Vazirmatn',
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 240,
            padding:
                const EdgeInsets.only(top: 24, bottom: 12, left: 8, right: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.withOpacity(0.10),
                  blurRadius: 16,
                  spreadRadius: 2,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxHours,
                minY: 0,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    tooltipBgColor: Colors.black87,
                    tooltipRoundedRadius: 8,
                    tooltipPadding: const EdgeInsets.all(8),
                    tooltipMargin: 8,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final stopType = sortedData[groupIndex].key;
                      final hours = rod.toY;
                      final minutes = (rod.toY * 60).round();
                      return BarTooltipItem(
                        '$stopType\n${hours.toStringAsFixed(1)} ساعت\n(${minutes} دقیقه)',
                        const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Vazirmatn',
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 &&
                            value.toInt() < sortedData.length) {
                          final stopType = sortedData[value.toInt()].key;
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              stopType,
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey,
                                fontFamily: 'Vazirmatn',
                              ),
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                      reservedSize: 40,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 35,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey,
                            fontFamily: 'Vazirmatn',
                          ),
                        );
                      },
                      interval:
                          maxHours > 10 ? (maxHours / 5).ceil().toDouble() : 1,
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border(
                    bottom: BorderSide(color: Colors.grey[300]!, width: 1),
                    left: BorderSide(color: Colors.grey[300]!, width: 1),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval:
                      maxHours > 10 ? (maxHours / 5).ceil().toDouble() : 1,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey[200]!,
                      strokeWidth: 1,
                    );
                  },
                ),
                barGroups: sortedData.asMap().entries.map((entry) {
                  final index = entry.key;
                  final stopType = entry.value.key;
                  final duration = entry.value.value;
                  final hours = duration / 60;
                  final color = StopColors.getColorForStopType(stopType);

                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: hours,
                        color: color,
                        width: 20,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(2),
                          topRight: Radius.circular(2),
                        ),
                        rodStackItems: [
                          BarChartRodStackItem(
                              0, hours, color.withOpacity(0.7)),
                        ],
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDynamicChart() {
    // انتخاب نمودار بر اساس نوع بازه
    switch (selectedTimeRange) {
      case 'شیفتی':
        return _buildShiftLineChart();
      case 'ماهانه':
        return _buildMonthlyStopsChart();
      case 'روزانه':
      default:
        return _buildDailyStopsChart();
    }
  }

  Widget _buildDailyStopsChart() {
    // بررسی وجود تاریخ‌های انتخاب شده
    if (startDate == null || endDate == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'نمودار خطی توقفات روزانه',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
                fontFamily: 'Vazirmatn',
              ),
            ),
            const SizedBox(height: 12),
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: const Center(
                child: Text(
                  'لطفاً بازه زمانی را انتخاب کنید',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontFamily: 'Vazirmatn',
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // محاسبه تعداد روزها
    final days = endDate!.difference(startDate!).inDays + 1;
    final dayNumbers = List.generate(days, (index) => index + 1);

    // محاسبه توقفات واقعی روزانه از جدول جزئیات
    final dailyActualStops = <int, double>{};
    print('=== دیباگ نمودار خطی ===');
    print('تعداد روزها: $days');
    print('تعداد توقفات در جدول: ${stopData.length}');

    // نمایش چند نمونه از داده‌های توقف
    if (stopData.isNotEmpty) {
      print('نمونه داده‌های توقف:');
      for (int i = 0; i < stopData.length && i < 5; i++) {
        final stop = stopData[i];
        final stopDate = DateTime(stop.year, stop.month, stop.day);
        final stopDateShamsi = Jalali.fromDateTime(stopDate);
        print(
            'توقف $i: میلادی ${stop.year}/${stop.month}/${stop.day} -> شمسی ${stopDateShamsi.year}/${stopDateShamsi.month}/${stopDateShamsi.day} - مدت: ${stop.stopDuration} دقیقه');
      }
    }

    for (int day = 1; day <= days; day++) {
      final currentDate = startDate!.add(Duration(days: day - 1));
      double totalMinutes = 0;

      for (final stop in stopData) {
        final currentDateShamsi = Jalali.fromDateTime(currentDate);

        // استفاده مستقیم از ستون‌های جداگانه
        if (stop.year == currentDateShamsi.year &&
            stop.month == currentDateShamsi.month &&
            stop.day == currentDateShamsi.day) {
          totalMinutes += stop.stopDuration;
          // فقط برای دیباگ اولیه
          if (day == 1) {
            print(
                'تطبیق یافت! توقف ${stop.year}/${stop.month}/${stop.day} - مدت: ${stop.stopDuration} دقیقه');
          }
        }
      }
      dailyActualStops[day] = totalMinutes / 60; // تبدیل به ساعت
      print('روز $day: ${dailyActualStops[day]} ساعت');
    }
    print('========================');

    // محاسبه توقفات برنامه‌ای روزانه
    final dailyPlannedStops = <int, double>{};
    print('=== دیباگ توقفات برنامه‌ای ===');

    for (int day = 1; day <= days; day++) {
      final currentDate = startDate!.add(Duration(days: day - 1));
      // تبدیل تاریخ میلادی به شمسی
      final jalaliDate = Jalali.fromDateTime(currentDate);
      final month = jalaliDate.month;
      final year = jalaliDate.year;

      final plannedForDay = _calculateDailyPlannedStopsForDay(year, month, day);
      dailyPlannedStops[day] = plannedForDay / 60; // تبدیل به ساعت
      print(
          'روز $day (${jalaliDate.year}/${jalaliDate.month}/${jalaliDate.day}): ${dailyPlannedStops[day]} ساعت');
    }
    print('================================');

    // محاسبه حداکثر مقدار برای محور Y
    final maxActual = dailyActualStops.values.isNotEmpty
        ? dailyActualStops.values.reduce((a, b) => a > b ? a : b)
        : 1.0;
    final maxPlanned = dailyPlannedStops.values.isNotEmpty
        ? dailyPlannedStops.values.reduce((a, b) => a > b ? a : b)
        : 1.0;
    final maxY = (maxActual > maxPlanned ? maxActual : maxPlanned) * 1.2;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'نمودار خطی توقفات روزانه',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
              fontFamily: 'Vazirmatn',
            ),
          ),
          const SizedBox(height: 12),
          Container(
            height: 250,
            padding: const EdgeInsets.all(16),
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  horizontalInterval:
                      maxY > 10 ? (maxY / 5).ceil().toDouble() : 1,
                  verticalInterval: 1,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey[200]!,
                      strokeWidth: 1,
                    );
                  },
                  getDrawingVerticalLine: (value) {
                    return FlLine(
                      color: Colors.grey[200]!,
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey,
                            fontFamily: 'Vazirmatn',
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      interval: maxY > 10 ? (maxY / 5).ceil().toDouble() : 1,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey,
                            fontFamily: 'Vazirmatn',
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: Colors.grey[300]!),
                ),
                minX: 1,
                maxX: days.toDouble(),
                minY: 0,
                maxY: maxY,
                lineBarsData: [
                  // خط توقفات واقعی
                  LineChartBarData(
                    spots: dayNumbers.map((day) {
                      return FlSpot(day.toDouble(), dailyActualStops[day] ?? 0);
                    }).toList(),
                    isCurved: true,
                    color: AppColors.stopsAccentBlue,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: AppColors.stopsAccentBlue,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.blue[600]!.withOpacity(0.1),
                    ),
                  ),
                  // خط توقفات برنامه‌ای
                  LineChartBarData(
                    spots: dayNumbers.map((day) {
                      return FlSpot(
                          day.toDouble(), dailyPlannedStops[day] ?? 0);
                    }).toList(),
                    isCurved: true,
                    color: AppColors.stopsAccentOrange,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: AppColors.stopsAccentOrange,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.orange[600]!.withOpacity(0.1),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    tooltipBgColor: Colors.black87,
                    tooltipRoundedRadius: 8,
                    tooltipPadding: const EdgeInsets.all(8),
                    tooltipMargin: 8,
                    getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                      return touchedBarSpots.map((barSpot) {
                        final day = barSpot.x.toInt();
                        final hours = barSpot.y;
                        final isActual = barSpot.barIndex == 0;
                        final type = isActual ? 'واقعی' : 'برنامه';
                        final color = isActual
                            ? AppColors.stopsAccentBlue
                            : AppColors.stopsAccentOrange;

                        return LineTooltipItem(
                          'روز $day\n$type: ${hours.toStringAsFixed(1)} ساعت',
                          TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Vazirmatn',
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
          // راهنما
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: AppColors.stopsAccentBlue,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'واقعی',
                    style: TextStyle(
                      fontSize: 10,
                      fontFamily: 'Vazirmatn',
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: AppColors.stopsAccentOrange,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'برنامه',
                    style: TextStyle(
                      fontSize: 10,
                      fontFamily: 'Vazirmatn',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showStopDetails(String stopType) {
    // نمایش جزئیات توقفات در جدول با انیمیشن
    setState(() {
      _filteredStopType = stopType;
      _filteredEquipment = null; // حذف فیلتر تجهیز
      _sortColumn = null; // حذف مرتب‌سازی
    });
  }

  void _filterTableByStopType(String stopType) {
    // فیلتر کردن جدول بر اساس نوع توقف از لجند
    setState(() {
      _filteredStopType = stopType;
      _filteredEquipment = null;
    });
  }

  void _scrollToTable() {
    // اسکرول به جدول جزئیات
    // این متد را بعداً پیاده‌سازی می‌کنیم
  }

  // متغیرهای مرتب‌سازی و فیلتر
  String? _sortColumn;
  bool _sortAscending = true;
  String? _filteredStopType;
  String? _filteredEquipment;

  Widget _buildDataTable() {
    if (stopData.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Center(
          child: Text(
            'داده‌ای برای نمایش وجود ندارد',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      );
    }

    // فیلتر کردن داده‌ها
    List<StopData> filteredData = stopData;
    if (_filteredStopType != null) {
      filteredData = filteredData
          .where((data) => data.stopType == _filteredStopType)
          .toList();
    }
    if (_filteredEquipment != null) {
      filteredData = filteredData
          .where((data) => data.equipment == _filteredEquipment)
          .toList();
    }

    // مرتب‌سازی داده‌ها
    if (_sortColumn != null) {
      filteredData.sort((a, b) {
        int comparison = 0;
        switch (_sortColumn) {
          case 'تاریخ':
            comparison = DateTime(a.year, a.month, a.day)
                .compareTo(DateTime(b.year, b.month, b.day));
            break;
          case 'شیفت':
            comparison = a.shift.compareTo(b.shift);
            break;
          case 'نوع توقف':
            comparison = a.stopType.compareTo(b.stopType);
            break;
          case 'نام تجهیز':
            comparison = a.equipment.compareTo(b.equipment);
            break;
          case 'مدت (دقیقه)':
            comparison = a.stopDuration.compareTo(b.stopDuration);
            break;
          case 'مدت (ساعت)':
            comparison = (a.stopDuration / 60).compareTo(b.stopDuration / 60);
            break;
        }
        return _sortAscending ? comparison : -comparison;
      });
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF1976D2),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Row(
              children: [
                // دکمه حذف فیلتر
                if ((_filteredStopType != null || _filteredEquipment != null) &&
                    _areIconsEnabled)
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _filteredStopType = null;
                        _filteredEquipment = null;
                      });
                    },
                    icon: const Icon(Icons.clear, color: Colors.white),
                    tooltip: 'حذف فیلتر',
                  ),
                const Spacer(),
                const Text(
                  'جزئیات توقفات',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.table_chart, color: Colors.white),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: [
                _buildSortableColumn('تاریخ'),
                _buildSortableColumn('شیفت'),
                _buildSortableColumn('نوع توقف'),
                _buildEquipmentColumn(),
                _buildSortableColumn('مدت'),
              ],
              rows: filteredData.map((data) {
                // رنگ پس‌زمینه بر اساس نوع توقف
                final stopColor = StopColors.getColorForStopType(data.stopType);
                final backgroundColor = stopColor.withOpacity(0.1);

                return DataRow(
                  color: MaterialStateProperty.resolveWith<Color?>(
                    (Set<MaterialState> states) {
                      return backgroundColor;
                    },
                  ),
                  cells: [
                    DataCell(
                      Container(
                        constraints: const BoxConstraints(maxWidth: 80),
                        child: Text(
                          _formatDateForTable(data),
                          style: const TextStyle(fontSize: 11),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    DataCell(
                      Container(
                        constraints: const BoxConstraints(maxWidth: 60),
                        child: Text(
                          data.shift.toString(),
                          style: const TextStyle(fontSize: 11),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    DataCell(
                      Container(
                        constraints: const BoxConstraints(maxWidth: 120),
                        child: Text(
                          data.stopType,
                          style: const TextStyle(fontSize: 11),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    DataCell(
                      Container(
                        constraints: const BoxConstraints(maxWidth: 150),
                        child: Text(
                          data.equipmentName ?? data.equipment,
                          style: const TextStyle(fontSize: 11),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    DataCell(
                      Container(
                        constraints: const BoxConstraints(maxWidth: 80),
                        child: Text(
                          _formatDurationHHMM(data.stopDuration),
                          style: TextStyle(
                            fontSize: 11,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
              dataRowMinHeight: 28,
              dataRowMaxHeight: 32,
              columnSpacing: 8,
              horizontalMargin: 4,
              headingRowHeight: 28,
            ),
          ),
        ],
      ),
    );
  }

  DataColumn _buildSortableColumn(String title) {
    return DataColumn(
      label: Container(
        constraints: BoxConstraints(
          maxWidth: title == 'تاریخ'
              ? 80
              : title == 'شیفت'
                  ? 60
                  : title == 'نوع توقف'
                      ? 120
                      : title == 'مدت'
                          ? 80
                          : 100,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                title,
                style:
                    const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
            if (_sortColumn == title)
              Icon(
                _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                size: 12,
                color: Colors.white,
              ),
          ],
        ),
      ),
      onSort: (columnIndex, ascending) {
        setState(() {
          if (_sortColumn == title) {
            _sortAscending = !_sortAscending;
          } else {
            _sortColumn = title;
            _sortAscending = ascending;
          }
        });
      },
    );
  }

  DataColumn _buildEquipmentColumn() {
    return DataColumn(
      label: Container(
        constraints: const BoxConstraints(maxWidth: 150),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: const Text(
                'نام تجهیز',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
            if (_filteredEquipment != null)
              const Icon(Icons.filter_list, size: 12, color: Colors.white),
          ],
        ),
      ),
      onSort: (columnIndex, ascending) {
        // فیلتر تجهیزات حالا از طریق dropdown انجام می‌شود
      },
    );
  }

  Future<void> _printReport() async {
    if (stopData.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ابتدا داده‌ها را بارگذاری کنید'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final pdfFile = await PdfReportService.generateStopsReportFromStopData(
        stopData: stopData,
        startDate: startDate!,
        endDate: endDate!,
        stopsByType: stopsByType,
        stopsByTypeDuration: stopsByTypeDuration,
        totalActualStops: totalActualStops,
        totalPlannedStops: totalPlannedStops.toInt(),
        deviationPercentage: deviationPercentage,
        chartData: stopsByTypeDuration.entries
            .map((e) => ChartPoint(e.value.toDouble(), e.value.toDouble()))
            .toList(),
      );

      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => PdfPreviewScreen(
              pdfFile: pdfFile,
              title: 'پرینت گزارش توقفات',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطا در تولید PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _downloadPdfReport() async {
    if (stopData.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ابتدا داده‌ها را بارگذاری کنید'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final pdfFile = await PdfReportService.generateStopsReportFromStopData(
        stopData: stopData,
        startDate: startDate!,
        endDate: endDate!,
        stopsByType: stopsByType,
        stopsByTypeDuration: stopsByTypeDuration,
        totalActualStops: totalActualStops,
        totalPlannedStops: totalPlannedStops.toInt(),
        deviationPercentage: deviationPercentage,
        chartData: stopsByTypeDuration.entries
            .map((e) => ChartPoint(e.value.toDouble(), e.value.toDouble()))
            .toList(),
      );

      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => PdfPreviewScreen(
              pdfFile: pdfFile,
              title: 'گزارش توقفات',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطا در تولید PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  String _formatDateForTable(StopData data) {
    // اگر بازه ماهانه انتخاب شده باشد
    if (selectedTimeRange == 'ماهانه') {
      // نمایش دو رقم سال و دو رقم ماه
      final yearShort = (data.year % 100).toString().padLeft(2, '0');
      final month = data.month.toString().padLeft(2, '0');
      return '$yearShort/$month';
    } else if (selectedTimeRange == 'شیفتی') {
      // برای بازه شیفتی، روز و ماه و شیفت نمایش داده شود
      final month = data.month.toString().padLeft(2, '0');
      final day = data.day.toString().padLeft(2, '0');
      final shift = data.shift;
      return '$month/$day شیفت $shift';
    } else {
      // برای بازه روزانه، فقط روز و ماه نمایش داده شود
      final month = data.month.toString().padLeft(2, '0');
      final day = data.day.toString().padLeft(2, '0');
      return '$month/$day';
    }
  }

  String _formatDurationHHMM(double minutes) {
    final int min = minutes.round();
    final int h = min ~/ 60;
    final int m = min % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  // باکس اطلاعات کلی توقفات ماه جاری با استایل هماهنگ با صفحه تولید
  Widget _buildStopsCurrentMonthInfoBoxStyled() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey[400]!, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
            spreadRadius: 1,
          ),
        ],
      ),
      child: FutureBuilder<Map<String, dynamic>>(
        key: ValueKey(_refreshKey), // اضافه کردن key برای به‌روزرسانی
        future: _calculateCurrentMonthStopData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return const SizedBox.shrink();
          }

          final data = snapshot.data!;
          final Map<String, Map<String, dynamic>> stopTypes = data['stopTypes'];
          final String startRange = data['startDate'] ?? '';
          final String endRange = data['endDate'] ?? '';

          return Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text(
                    'اطلاعات کلی توقفات ماه جاری',
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                (startRange.isNotEmpty && endRange.isNotEmpty)
                    ? 'از تاریخ $startRange الی $endRange'
                    : 'ماه جاری (داده‌ای موجود نیست)',
                style: const TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 20),
              _buildStopsCurrentMonthTable(stopTypes),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStopsCurrentMonthTable(
      Map<String, Map<String, dynamic>> stopTypes) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            padding: const EdgeInsets.all(12),
            child: const Row(
              children: [
                Expanded(
                  flex: 1,
                  child: Text(
                    'انحراف',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'برنامه',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'واقعی',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'نوع توقف',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ...stopTypes.entries.map((entry) {
            final stopType = entry.key;
            final stopData = entry.value;
            final actual = stopData['actual'] as double;
            final planned = stopData['planned'] as double;
            final deviation = stopData['deviation'] as double;

            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey[300]!),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: _buildStopsDeviationText(deviation),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      _formatDurationHHMM(planned),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      _formatDurationHHMM(actual),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      stopType,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildStopsDeviationText(double deviation) {
    final isPositive = deviation >= 0;
    final color = isPositive ? Colors.green : Colors.red;
    final icon = isPositive ? Icons.arrow_upward : Icons.arrow_downward;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: color,
          size: 12,
        ),
        const SizedBox(width: 2),
        Flexible(
          child: Text(
            '${deviation.abs().toStringAsFixed(1)}%',
            style: TextStyle(
              fontFamily: 'Vazirmatn',
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  void _showStopTypeSelector() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'انتخاب نوع توقف',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              fontFamily: 'Vazirmatn',
            ),
          ),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setDialogState) {
              return Container(
                width: double.maxFinite,
                constraints: const BoxConstraints(maxHeight: 400),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // گزینه "همه توقفات"
                    ListTile(
                      dense: true,
                      leading: SizedBox(
                        width: 20,
                        height: 20,
                        child: Checkbox(
                          value: selectAllStopTypes,
                          onChanged: (bool? value) {
                            setDialogState(() {
                              selectAllStopTypes = value ?? true;
                              if (selectAllStopTypes) {
                                selectedStopTypes.clear();
                              }
                            });
                          },
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                      title: const Text(
                        'همه توقفات',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Vazirmatn',
                        ),
                      ),
                    ),
                    const Divider(height: 1),
                    // گزینه‌های انواع توقف با اسکرول
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: allStopTypes.map((type) {
                            return ListTile(
                              dense: true,
                              leading: SizedBox(
                                width: 20,
                                height: 20,
                                child: Checkbox(
                                  value: selectedStopTypes.contains(type),
                                  onChanged: (bool? value) {
                                    setDialogState(() {
                                      selectAllStopTypes = false;
                                      if (value == true) {
                                        selectedStopTypes.add(type);
                                      } else {
                                        selectedStopTypes.remove(type);
                                      }
                                      if (selectedStopTypes.isEmpty) {
                                        selectAllStopTypes = true;
                                      }
                                    });
                                  },
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                              title: Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color:
                                          StopColors.getColorForStopType(type),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    type,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontFamily: 'Vazirmatn',
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  // به‌روزرسانی UI بعد از بستن dialog
                });
                Navigator.of(context).pop();
              },
              child: const Text(
                'تأیید',
                style: TextStyle(
                  fontSize: 12,
                  fontFamily: 'Vazirmatn',
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showEquipmentSelector() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'انتخاب تجهیزات',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              fontFamily: 'Vazirmatn',
            ),
          ),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setDialogState) {
              return Container(
                width: double.maxFinite,
                constraints: const BoxConstraints(maxHeight: 400),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // گزینه "همه تجهیزات"
                    ListTile(
                      dense: true,
                      leading: SizedBox(
                        width: 20,
                        height: 20,
                        child: Checkbox(
                          value: selectAllEquipments,
                          onChanged: (bool? value) {
                            setDialogState(() {
                              selectAllEquipments = value ?? true;
                              if (selectAllEquipments) {
                                selectedEquipments.clear();
                              }
                            });
                          },
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                      title: const Text(
                        'همه تجهیزات',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Vazirmatn',
                        ),
                      ),
                    ),
                    const Divider(height: 1),
                    // گزینه‌های تجهیزات با اسکرول
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: allEquipments.map((equipment) {
                            return ListTile(
                              dense: true,
                              leading: SizedBox(
                                width: 20,
                                height: 20,
                                child: Checkbox(
                                  value: selectedEquipments.contains(equipment),
                                  onChanged: (bool? value) {
                                    setDialogState(() {
                                      selectAllEquipments = false;
                                      if (value == true) {
                                        selectedEquipments.add(equipment);
                                      } else {
                                        selectedEquipments.remove(equipment);
                                      }
                                      if (selectedEquipments.isEmpty) {
                                        selectAllEquipments = true;
                                      }
                                    });
                                  },
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                              title: Row(
                                children: [
                                  Icon(
                                    Icons.build,
                                    size: 16,
                                    color: Colors.blue[600],
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      equipment,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontFamily: 'Vazirmatn',
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  // به‌روزرسانی UI بعد از بستن dialog
                });
                Navigator.of(context).pop();
              },
              child: const Text(
                'تأیید',
                style: TextStyle(
                  fontSize: 12,
                  fontFamily: 'Vazirmatn',
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  double _calculateDailyPlannedStopsForDay(int year, int month, int day) {
    // محاسبه برنامه سالانه برای روز مشخص
    if (year == 1404) {
      // برنامه سالانه 1404 - استفاده از داده‌های برنامه سالانه
      const Map<String, List<double>> monthlyStopsPlan = {
        'برنامه ای': [
          3.0,
          3.0,
          3.0,
          3.0,
          3.0,
          8.0,
          3.0,
          3.0,
          3.0,
          3.0,
          3.0,
          8.0
        ],
        'مکانیکی': [1.6, 1.6, 1.6, 1.6, 1.6, 1.6, 1.6, 1.6, 1.6, 1.6, 1.6, 1.5],
        'برقی': [0.4, 0.4, 0.4, 0.4, 0.4, 0.4, 0.4, 0.4, 0.4, 0.4, 0.4, 0.4],
        'تاسیساتی': [
          0.0,
          0.0,
          0.0,
          0.0,
          0.0,
          0.0,
          0.0,
          0.0,
          0.0,
          0.0,
          0.0,
          0.0
        ],
        'بهره برداری': [
          1.3,
          1.3,
          1.3,
          1.3,
          1.3,
          1.3,
          1.3,
          1.3,
          1.3,
          1.3,
          1.3,
          1.3
        ],
        'معدنی': [0.7, 0.7, 0.7, 0.7, 0.7, 0.7, 0.7, 0.7, 0.7, 0.7, 0.7, 0.7],
        'عمومی': [3.1, 0.5, 0.5, 2.5, 0.5, 0.5, 0.5, 0.5, 0.5, 1.0, 1.0, 3.9],
        'مجاز': [4.8, 4.8, 4.8, 4.8, 4.8, 4.8, 4.6, 4.6, 4.6, 4.6, 4.6, 4.5],
        'بارگیری': [0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2],
      };

      // محاسبه کل برنامه ماهانه
      double totalMonthlyPlan = 0.0;
      for (List<double> monthlyValues in monthlyStopsPlan.values) {
        totalMonthlyPlan += monthlyValues[month - 1];
      }

      final daysInMonth = _getDaysInMonth(year, month);
      final dailyMinutes =
          totalMonthlyPlan * 24 * 60 / daysInMonth; // تبدیل به دقیقه روزانه
      return dailyMinutes;
    }
    return 0.0;
  }

  int _getDaysInMonth(int year, int month) {
    // تعداد روزهای ماه شمسی
    return Jalali(year, month, 1).monthLength;
  }

  String _formatDuration(num minutes) {
    return (minutes / 60).toStringAsFixed(1);
  }

  Widget _buildCurrentMonthStopInfoBox() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _calculateCurrentMonthStopData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final data = snapshot.data!;
        final Map<String, Map<String, dynamic>> stopTypes = data['stopTypes'];
        final String dateRange = data['dateRange'];

        return Card(
          elevation: 2,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: const Color(0xFFCFD8DC),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: Color(0xFF1976D2),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(8),
                      topRight: Radius.circular(8),
                    ),
                  ),
                  child: Text(
                    'اطلاعات کلی توقفات ماه جاری ($dateRange)',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Vazirmatn',
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Table(
                    border: TableBorder.all(
                      color: Colors.grey.shade400,
                      width: 1,
                    ),
                    columnWidths: const {
                      0: FlexColumnWidth(2),
                      1: FlexColumnWidth(1.5),
                      2: FlexColumnWidth(1.5),
                      3: FlexColumnWidth(1.5),
                    },
                    children: [
                      // Header row
                      TableRow(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                        ),
                        children: const [
                          Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text(
                              'نوع توقف',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                fontFamily: 'Vazirmatn',
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text(
                              'محقق شده',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                fontFamily: 'Vazirmatn',
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text(
                              'برنامه',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                fontFamily: 'Vazirmatn',
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text(
                              'درصد انحراف',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                fontFamily: 'Vazirmatn',
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                      // مرتب‌سازی توقفات بر اساس مدت زمان واقعی (از بیشترین به کمترین)
                      ...(() {
                        final sortedEntries = stopTypes.entries.toList()
                          ..sort((a, b) => (b.value['actual'] as double)
                              .compareTo(a.value['actual'] as double));

                        return sortedEntries.map((entry) {
                          final stopType = entry.key;
                          final stopData = entry.value;
                          final actual = stopData['actual'] as double;
                          final planned = stopData['planned'] as double;
                          final deviation = stopData['deviation'] as double;

                          return TableRow(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  stopType,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontFamily: 'Vazirmatn',
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  _formatDurationHHMM(actual),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontFamily: 'Vazirmatn',
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  _formatDurationHHMM(planned),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontFamily: 'Vazirmatn',
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  '${deviation.toStringAsFixed(1)}%',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontFamily: 'Vazirmatn',
                                    color: deviation > 0
                                        ? Colors.red
                                        : Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          );
                        });
                      })(),
                      // ردیف مجموع کل
                      TableRow(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              'مجموع کل',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                fontFamily: 'Vazirmatn',
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              _formatDurationHHMM(stopTypes.values.fold(
                                  0.0,
                                  (sum, data) =>
                                      sum + (data['actual'] as double))),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                fontFamily: 'Vazirmatn',
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              _formatDurationHHMM(stopTypes.values.fold(
                                  0.0,
                                  (sum, data) =>
                                      sum + (data['planned'] as double))),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                fontFamily: 'Vazirmatn',
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              '${_calculateTotalDeviation(stopTypes).toStringAsFixed(1)}%',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                fontFamily: 'Vazirmatn',
                                color: _calculateTotalDeviation(stopTypes) > 0
                                    ? Colors.red
                                    : Colors.green,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<Map<String, dynamic>> _calculateCurrentMonthStopData() async {
    try {
      // دریافت آخرین داده موجود
      final provider = Provider.of<DataProvider>(context, listen: false);
      final allStops = provider.getStopData();

      print('=== دیباگ باکس اطلاعات کلی توقفات ماه جاری ===');
      print('کل رکوردهای توقف: ${allStops.length}');

      // بررسی توزیع ماه‌ها در داده‌های موجود
      final Map<String, int> monthDistribution = {};
      for (final stop in allStops) {
        final key = '${stop.year}/${stop.month}';
        monthDistribution[key] = (monthDistribution[key] ?? 0) + 1;
      }

      print('توزیع ماه‌ها در داده‌های توقف:');
      monthDistribution.forEach((key, count) {
        print('  $key: $count رکورد');
      });

      if (allStops.isEmpty) {
        print('❌ هیچ رکورد توقفی موجود نیست');
        return {'stopTypes': <String, Map<String, dynamic>>{}, 'dateRange': ''};
      }

      // پیدا کردن آخرین تاریخ دارای داده
      final sortedStops = allStops.toList()
        ..sort((a, b) => DateTime(a.year, a.month, a.day)
            .compareTo(DateTime(b.year, b.month, b.day)));

      final latestStop = sortedStops.last;
      print(
          'آخرین رکورد توقف: ${latestStop.year}/${latestStop.month}/${latestStop.day}');
      print('نوع توقف آخرین رکورد: ${latestStop.stopType}');
      print('مدت توقف آخرین رکورد: ${latestStop.stopDuration} دقیقه');

      // تبدیل تاریخ شمسی به میلادی برای محاسبات
      final latestJalali =
          Jalali(latestStop.year, latestStop.month, latestStop.day);
      final latestDate = latestJalali.toDateTime();

      // اول ماه آخرین داده (شمسی) - استفاده از کل ماه
      final firstDayOfMonthJalali =
          Jalali(latestStop.year, latestStop.month, 1);
      final lastDayOfMonthJalali = Jalali(latestStop.year, latestStop.month,
          _getDaysInMonth(latestStop.year, latestStop.month));
      final firstDayOfMonth = firstDayOfMonthJalali.toDateTime();
      final lastDayOfMonth = lastDayOfMonthJalali.toDateTime();

      print(
          'بازه زمانی: از ${_formatPersianDate(firstDayOfMonth)} تا ${_formatPersianDate(lastDayOfMonth)}');

      // فیلتر کردن داده‌های بازه زمانی (کل ماه)
      final monthStops = allStops.where((stop) {
        // تبدیل تاریخ شمسی به میلادی برای مقایسه
        final stopJalali = Jalali(stop.year, stop.month, stop.day);
        final stopDate = stopJalali.toDateTime();

        return stopDate
                .isAfter(firstDayOfMonth.subtract(const Duration(days: 1))) &&
            stopDate.isBefore(lastDayOfMonth.add(const Duration(days: 1)));
      }).toList();

      print('رکوردهای فیلتر شده در بازه: ${monthStops.length}');

      // گروه‌بندی بر اساس نوع توقف
      final Map<String, List<StopData>> groupedStops = {};
      for (final stop in monthStops) {
        if (!groupedStops.containsKey(stop.stopType)) {
          groupedStops[stop.stopType] = [];
        }
        groupedStops[stop.stopType]!.add(stop);
      }

      print('انواع توقف موجود: ${groupedStops.keys.toList()}');
      for (final entry in groupedStops.entries) {
        final totalDuration =
            entry.value.fold(0.0, (sum, stop) => sum + stop.stopDuration);
        print(
            '${entry.key}: ${entry.value.length} رکورد، مجموع ${totalDuration} دقیقه');
      }

      // برنامه سالانه 1404 (مطابق با منطق موجود)
      const Map<String, List<double>> monthlyStopsPlan = {
        'برنامه ای': [
          3.0,
          3.0,
          3.0,
          3.0,
          3.0,
          8.0,
          3.0,
          3.0,
          3.0,
          3.0,
          3.0,
          8.0
        ],
        'مکانیکی': [1.6, 1.6, 1.6, 1.6, 1.6, 1.6, 1.6, 1.6, 1.6, 1.6, 1.6, 1.5],
        'برقی': [0.4, 0.4, 0.4, 0.4, 0.4, 0.4, 0.4, 0.4, 0.4, 0.4, 0.4, 0.4],
        'تاسیساتی': [
          0.0,
          0.0,
          0.0,
          0.0,
          0.0,
          0.0,
          0.0,
          0.0,
          0.0,
          0.0,
          0.0,
          0.0
        ],
        'بهره برداری': [
          1.3,
          1.3,
          1.3,
          1.3,
          1.3,
          1.3,
          1.3,
          1.3,
          1.3,
          1.3,
          1.3,
          1.3
        ],
        'معدنی': [0.7, 0.7, 0.7, 0.7, 0.7, 0.7, 0.7, 0.7, 0.7, 0.7, 0.7, 0.7],
        'عمومی': [3.1, 0.5, 0.5, 2.5, 0.5, 0.5, 0.5, 0.5, 0.5, 1.0, 1.0, 3.9],
        'مجاز': [4.8, 4.8, 4.8, 4.8, 4.8, 4.8, 4.6, 4.6, 4.6, 4.6, 4.6, 4.5],
        'بارگیری': [0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2],
      };

      print('کلیدهای برنامه موجود: ${monthlyStopsPlan.keys.toList()}');
      print('=== مقایسه برچسب‌ها ===');
      for (final actualKey in groupedStops.keys) {
        final isInPlan = monthlyStopsPlan.containsKey(actualKey);
        print('"$actualKey" در برنامه موجود: $isInPlan');
        if (!isInPlan) {
          // پیدا کردن نزدیک‌ترین کلید برنامه
          String? closestKey;
          int minDistance = 999;
          for (final planKey in monthlyStopsPlan.keys) {
            final distance = _calculateStringDistance(actualKey, planKey);
            if (distance < minDistance) {
              minDistance = distance;
              closestKey = planKey;
            }
          }
          print(
              '  نزدیک‌ترین کلید برنامه: "$closestKey" (فاصله: $minDistance)');
        }
      }
      print('========================');

      // محاسبه داده‌های هر نوع توقف
      final Map<String, Map<String, dynamic>> stopTypes = {};

      // تعداد روزهای ماه و تعداد روزهای انتخاب شده (کل ماه)
      final daysInMonth = _getDaysInMonth(latestStop.year, latestStop.month);
      final selectedDays = daysInMonth; // کل ماه

      print('تعداد روزهای ماه: $daysInMonth');
      print('تعداد روزهای انتخاب شده: $selectedDays');

      for (final stopType in monthlyStopsPlan.keys) {
        // محاسبه داده‌های محقق شده
        double actualMinutes = 0.0;
        if (groupedStops.containsKey(stopType)) {
          for (final stop in groupedStops[stopType]!) {
            actualMinutes += stop.stopDuration;
          }
        }

        // محاسبه برنامه برای بازه انتخابی (فرمول: (تعداد روزهای انتخابی ÷ کل روزهای ماه) × مقدار برنامه‌ای ماه)
        final monthlyPlanDays =
            monthlyStopsPlan[stopType]![latestStop.month - 1];
        final plannedMinutes =
            (selectedDays / daysInMonth) * monthlyPlanDays * 24 * 60;

        // محاسبه درصد انحراف
        double deviation = 0.0;
        if (plannedMinutes > 0) {
          deviation = ((actualMinutes - plannedMinutes) / plannedMinutes) * 100;
        }

        print(
            '$stopType: واقعی=${actualMinutes} دقیقه، برنامه=${plannedMinutes.toStringAsFixed(0)} دقیقه، انحراف=${deviation.toStringAsFixed(1)}%');

        stopTypes[stopType] = {
          'actual': actualMinutes,
          'planned': plannedMinutes,
          'deviation': deviation,
        };
      }

      // ساخت dateRange برای نمایش
      final startDateStr = _formatPersianDate(firstDayOfMonth);
      final endDateStr = _formatPersianDate(lastDayOfMonth);
      final dateRange = 'از تاریخ $startDateStr الی $endDateStr';

      print('=====================================');

      return {
        'stopTypes': stopTypes,
        'startDate': startDateStr,
        'endDate': endDateStr,
        'dateRange': dateRange,
      };
    } catch (e) {
      print('خطا در محاسبه داده‌های توقفات ماه جاری: $e');
      return {
        'stopTypes': <String, Map<String, dynamic>>{},
        'startDate': '',
        'endDate': ''
      };
    }
  }

  double _calculateDeviationPercentage() {
    if (totalPlannedStops == 0) return 0;
    return ((totalActualStops - totalPlannedStops) / totalPlannedStops * 100);
  }

  // تابع محاسبه درصد انحراف کل
  double _calculateTotalDeviation(Map<String, Map<String, dynamic>> stopTypes) {
    final totalActual = stopTypes.values
        .fold(0.0, (sum, data) => sum + (data['actual'] as double));
    final totalPlanned = stopTypes.values
        .fold(0.0, (sum, data) => sum + (data['planned'] as double));

    if (totalPlanned == 0) return 0.0;
    return ((totalActual - totalPlanned) / totalPlanned) * 100;
  }

  Color _getDeviationColor() {
    final deviation = _calculateDeviationPercentage();
    if (deviation < 0) {
      return Colors.red;
    } else if (deviation == 0) {
      return Colors.grey[700]!;
    } else {
      return Colors.green;
    }
  }

  Widget _buildTimeRangeFilters() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: timeRanges.map((timeRange) {
          final isSelected = selectedTimeRange == timeRange;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  selectedTimeRange = timeRange;
                });
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.stopsAccentBlue : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.stopsAccentBlue
                        : Colors.grey[300]!,
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  timeRange,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? Colors.white : Colors.grey[700],
                    fontFamily: 'Vazirmatn',
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSummaryCards() {
    final plannedConfig = BoxConfigs.planned;
    final actualConfig = BoxConfigs.actual;
    final deviationConfig = BoxConfigs.deviation;
    return Container(
      margin: const EdgeInsets.all(12),
      child: Column(
        children: [
          // عنوان با تاریخ‌های انتخاب شده
          if (startDate != null && endDate != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.calendar_today,
                      color: Colors.blue.shade700, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'اطلاعات کلی توقفات: ${_formatPersianDate(startDate!)} تا ${_formatPersianDate(endDate!)}',
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          // ردیف اول: کارت‌های واقعی و برنامه
          Row(
            children: [
              Expanded(
                child: AnimatedContainer(
                  duration: actualConfig.animationDuration,
                  curve: actualConfig.animationCurve,
                  child: SummaryCard(
                    title: 'واقعی',
                    value: '${_formatDuration(totalActualStops)} ساعت',
                    icon: actualConfig.icon,
                    backgroundColor: actualConfig.backgroundColor,
                    textColor: actualConfig.textColor,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AnimatedContainer(
                  duration: plannedConfig.animationDuration,
                  curve: plannedConfig.animationCurve,
                  child: SummaryCard(
                    title: 'برنامه',
                    value: '${_formatDuration(totalPlannedStops)} ساعت',
                    icon: plannedConfig.icon,
                    backgroundColor: plannedConfig.backgroundColor,
                    textColor: plannedConfig.textColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // ردیف دوم: انحراف از برنامه
          AnimatedContainer(
            duration: deviationConfig.percentAnimationDuration,
            curve: deviationConfig.percentAnimationCurve,
            width: double.infinity,
            padding: EdgeInsets.all(deviationConfig.padding),
            decoration: BoxDecoration(
              color: Colors.white, // پس‌زمینه همیشه سفید
              borderRadius: BorderRadius.circular(deviationConfig.borderRadius),
              border: Border.all(
                color:
                    _getDeviationOutlineColor(_calculateDeviationPercentage()),
                width: deviationConfig.borderWidth * 3, // ضخامت سه برابر
              ),
              boxShadow: [
                BoxShadow(
                  color:
                      _getDeviationOutlineColor(_calculateDeviationPercentage())
                          .withOpacity(0.18),
                  spreadRadius: 1,
                  blurRadius: deviationConfig.boxShadowBlur,
                  offset: deviationConfig.boxShadowOffset,
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      deviationConfig.icon,
                      color: deviationConfig.textColor,
                      size: deviationConfig.iconSize,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'انحراف از برنامه',
                      style: TextStyle(
                        color: deviationConfig.textColor,
                        fontSize: deviationConfig.titleFontSize,
                        fontWeight: deviationConfig.titleFontWeight,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // نمایش درصد انحراف
                TweenAnimationBuilder<double>(
                  duration: deviationConfig.percentAnimationDuration,
                  curve: deviationConfig.percentAnimationCurve,
                  tween:
                      Tween(begin: 0.0, end: _calculateDeviationPercentage()),
                  builder: (context, value, child) {
                    return Text(
                      '${value.toStringAsFixed(2)}%',
                      style: TextStyle(
                        color: _getDeviationColor(),
                        fontSize: deviationConfig.percentFontSize,
                        fontWeight: deviationConfig.percentFontWeight,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 4),
                // نمایش اختلاف زمانی
                TweenAnimationBuilder<double>(
                  duration: deviationConfig.diffAnimationDuration,
                  curve: deviationConfig.diffAnimationCurve,
                  tween: Tween(
                      begin: 0.0,
                      end: (totalActualStops - totalPlannedStops) / 60.0),
                  builder: (context, value, child) {
                    final difference = totalActualStops - totalPlannedStops;
                    final differenceHours = difference / 60.0;
                    final sign = difference > 0 ? '+' : '';
                    return Text(
                      '$sign${differenceHours.toStringAsFixed(1)} ساعت',
                      style: TextStyle(
                        color: _getDeviationColor(),
                        fontSize: deviationConfig.diffFontSize,
                        fontWeight: deviationConfig.diffFontWeight,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getDeviationOutlineColor(double deviation) {
    if (deviation < 0) {
      return Colors.red;
    } else if (deviation > 0) {
      return Colors.green;
    } else {
      return Colors.grey[300]!;
    }
  }

  // تابع کمکی برای ساخت داده‌های شیفتی
  List<Map<String, dynamic>> buildShiftChartData({
    required DateTime startDate,
    required DateTime endDate,
    required List<StopData> stopData,
  }) {
    final days = endDate.difference(startDate).inDays + 1;
    final List<Map<String, dynamic>> chartData = [];
    for (int i = 0; i < days; i++) {
      final currentDate = startDate.add(Duration(days: i));
      final jalali = Jalali.fromDateTime(currentDate);
      final dayLabel = '${jalali.day} ${_getPersianMonthName(jalali.month)}';
      for (int shift = 1; shift <= 3; shift++) {
        // مجموع توقفات این روز و شیفت
        double totalMinutes = 0;
        for (final stop in stopData) {
          if (stop.year == jalali.year &&
              stop.month == jalali.month &&
              stop.day == jalali.day &&
              stop.shift == shift.toString()) {
            totalMinutes += stop.stopDuration;
          }
        }
        chartData.add({
          'xLabel': '${jalali.day}-$shift',
          'dayLabel': dayLabel,
          'shift': shift,
          'day': jalali.day,
          'month': jalali.month,
          'year': jalali.year, // اضافه شد
          'value': totalMinutes / 60, // ساعت
          'groupIndex': i, // برای تمایز رنگی
        });
      }
    }
    return chartData;
  }

  String _getPersianMonthName(int month) {
    const months = [
      '',
      'فروردین',
      'اردیبهشت',
      'خرداد',
      'تیر',
      'مرداد',
      'شهریور',
      'مهر',
      'آبان',
      'آذر',
      'دی',
      'بهمن',
      'اسفند',
    ];
    return months[month];
  }

  Widget _buildMonthlyStopsChart() {
    // بررسی وجود تاریخ‌های انتخاب شده
    if (startDate == null || endDate == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'نمودار خطی توقفات ماهانه',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
                fontFamily: 'Vazirmatn',
              ),
            ),
            const SizedBox(height: 12),
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: const Center(
                child: Text(
                  'لطفاً بازه زمانی را انتخاب کنید',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontFamily: 'Vazirmatn',
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // محاسبه تعداد ماه‌ها
    final months = _getMonthsBetween(startDate!, endDate!);
    final monthLabels = months.map((date) {
      final jalali = Jalali.fromDateTime(date);
      return '${jalali.month}/${jalali.year}';
    }).toList();

    // محاسبه توقفات واقعی ماهانه
    final monthlyActualStops = <String, double>{};
    final monthlyPlannedStops = <String, double>{};

    for (final monthDate in months) {
      final jalali = Jalali.fromDateTime(monthDate);
      final monthKey = '${jalali.month}/${jalali.year}';

      double totalMinutes = 0;
      for (final stop in stopData) {
        if (stop.year == jalali.year && stop.month == jalali.month) {
          totalMinutes += stop.stopDuration;
        }
      }
      monthlyActualStops[monthKey] = totalMinutes / 60; // تبدیل به ساعت

      // محاسبه برنامه ماهانه
      monthlyPlannedStops[monthKey] =
          _calculateMonthlyPlannedStopsForChart(jalali.year, jalali.month);
    }

    // محاسبه حداکثر مقدار برای محور Y
    final maxActual = monthlyActualStops.values.isNotEmpty
        ? monthlyActualStops.values.reduce((a, b) => a > b ? a : b)
        : 1.0;
    final maxPlanned = monthlyPlannedStops.values.isNotEmpty
        ? monthlyPlannedStops.values.reduce((a, b) => a > b ? a : b)
        : 1.0;
    final maxY = (maxActual > maxPlanned ? maxActual : maxPlanned) * 1.2;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'نمودار خطی توقفات ماهانه',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
              fontFamily: 'Vazirmatn',
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 300,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  horizontalInterval: maxY / 5,
                  verticalInterval: 1,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey[300]!,
                      strokeWidth: 1,
                    );
                  },
                  getDrawingVerticalLine: (value) {
                    return FlLine(
                      color: Colors.grey[300]!,
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        if (value.toInt() < monthLabels.length) {
                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            child: Text(
                              monthLabels[value.toInt()],
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                                fontSize: 10,
                                fontFamily: 'Vazirmatn',
                              ),
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: maxY / 5,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        return Text(
                          value.toStringAsFixed(1),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                            fontSize: 10,
                            fontFamily: 'Vazirmatn',
                          ),
                        );
                      },
                      reservedSize: 40,
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: Colors.grey[300]!),
                ),
                minX: 0,
                maxX: (monthLabels.length - 1).toDouble(),
                minY: 0,
                maxY: maxY,
                lineBarsData: [
                  // خط واقعی
                  LineChartBarData(
                    spots: monthLabels.asMap().entries.map((entry) {
                      final index = entry.key;
                      final monthKey = entry.value;
                      return FlSpot(
                          index.toDouble(), monthlyActualStops[monthKey] ?? 0);
                    }).toList(),
                    isCurved: true,
                    gradient: LinearGradient(
                      colors: [Colors.black, Colors.black.withOpacity(0.8)],
                    ),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: Colors.black,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withOpacity(0.3),
                          Colors.black.withOpacity(0.1),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  // خط برنامه
                  LineChartBarData(
                    spots: monthLabels.asMap().entries.map((entry) {
                      final index = entry.key;
                      final monthKey = entry.value;
                      return FlSpot(
                          index.toDouble(), monthlyPlannedStops[monthKey] ?? 0);
                    }).toList(),
                    isCurved: true,
                    gradient: LinearGradient(
                      colors: [Colors.orange, Colors.orange.withOpacity(0.8)],
                    ),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: Colors.orange,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          Colors.orange.withOpacity(0.3),
                          Colors.orange.withOpacity(0.1),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // راهنما
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Container(
                    width: 16,
                    height: 4,
                    color: Colors.black,
                  ),
                  const SizedBox(width: 4),
                  const Text('واقعی', style: TextStyle(color: Colors.black)),
                ],
              ),
              const SizedBox(width: 16),
              Row(
                children: [
                  Container(
                    width: 16,
                    height: 4,
                    color: Colors.orange,
                  ),
                  const SizedBox(width: 4),
                  const Text('برنامه', style: TextStyle(color: Colors.orange)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShiftLineChart() {
    if (startDate == null || endDate == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'نمودار خطی توقفات شیفتی',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
                fontFamily: 'Vazirmatn',
              ),
            ),
            const SizedBox(height: 12),
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: const Center(
                child: Text(
                  'لطفاً بازه زمانی را انتخاب کنید',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontFamily: 'Vazirmatn',
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final chartData = buildShiftChartData(
      startDate: startDate!,
      endDate: endDate!,
      stopData: stopData,
    );

    // محاسبه مقادیر برنامه‌ای برای هر شیفت
    final plannedChartData = <double>[];
    for (var entry in chartData) {
      final year = entry['year'] as int; // اصلاح: سال شمسی از entry
      final month = entry['month'] as int;
      final day = entry['day'] as int;
      final shift = entry['shift'] as int;
      // تابع محاسبه برنامه برای یک شیفت خاص
      final plannedValue = _calculatePlannedShiftStop(year, month, day, shift);
      plannedChartData.add(plannedValue);
    }

    final maxY = [
          ...chartData.map((e) => e['value'] as double),
          ...plannedChartData
        ].reduce((a, b) => a > b ? a : b) *
        1.2;

    // ساخت لیست برچسب‌های محور X و گروه‌بندی برای تمایز رنگی
    final xLabels = chartData.map((e) => e['xLabel'] as String).toList();
    final dayLabels = chartData.map((e) => e['dayLabel'] as String).toList();
    final groupIndices = chartData.map((e) => e['groupIndex'] as int).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.10),
            blurRadius: 16,
            spreadRadius: 2,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'نمودار خطی توقفات شیفتی',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
              fontFamily: 'Vazirmatn',
            ),
          ),
          const SizedBox(height: 12),
          // واحد ساعت بالای محور Y
          Row(
            children: [
              const SizedBox(width: 8),
              Column(
                children: [
                  const Text(
                    'ساعت',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      fontFamily: 'Vazirmatn',
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
              ),
            ],
          ),
          Container(
            height: 250,
            child: Stack(
              children: [
                // رنگ پس‌زمینه ملایم برای هر روز
                Positioned.fill(
                  child: Row(
                    children: List.generate(chartData.length, (i) {
                      final isFirstOfDay = i % 3 == 0;
                      return Expanded(
                        flex: 1,
                        child: Container(
                          decoration: BoxDecoration(
                            color: isFirstOfDay
                                ? Colors.blue[50]
                                : Colors.transparent,
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                // برچسب روز بالای هر سه قسمت
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Row(
                    children: List.generate(chartData.length ~/ 3, (g) {
                      return Expanded(
                        flex: 3,
                        child: Center(
                          child: Text(
                            chartData[g * 3]['dayLabel'],
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                              fontFamily: 'Vazirmatn',
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                // نمودار خطی
                Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: LineChart(
                    LineChartData(
                      minX: 0,
                      maxX: (chartData.length - 1).toDouble(),
                      minY: 1, // از ۱ شروع شود
                      maxY: maxY,
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: true,
                        horizontalInterval:
                            maxY > 10 ? (maxY / 5).ceil().toDouble() : 1,
                        verticalInterval: 1,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: Colors.grey[300]!,
                            strokeWidth: 1,
                          );
                        },
                        getDrawingVerticalLine: (value) {
                          return FlLine(
                            color: Colors.grey[300]!,
                            strokeWidth: 1,
                          );
                        },
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 36,
                            interval: 1,
                            getTitlesWidget: (value, meta) {
                              final idx = value.toInt();
                              if (idx >= 0 && idx < xLabels.length) {
                                return Text(
                                  xLabels[idx],
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black,
                                    fontFamily: 'Vazirmatn',
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            interval:
                                maxY > 10 ? (maxY / 5).ceil().toDouble() : 1,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                value.toInt().toString(),
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black,
                                  fontFamily: 'Vazirmatn',
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(
                        show: true,
                        border: Border.all(color: Colors.black, width: 1.5),
                      ),
                      lineBarsData: [
                        // خط واقعی (همان قبلی)
                        LineChartBarData(
                          spots: List.generate(
                              chartData.length,
                              (i) => FlSpot(i.toDouble(),
                                  chartData[i]['value'] as double)),
                          isCurved: true,
                          color: Colors.black, // واقعی مشکی
                          barWidth: 4,
                          isStrokeCapRound: true,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, barData, index) {
                              final isTouched = spot.x == touchedIndex;
                              return FlDotCirclePainter(
                                radius: isTouched ? 8 : 6,
                                color: isTouched ? Colors.orange : Colors.black,
                                strokeWidth: 3,
                                strokeColor: Colors.white,
                              );
                            },
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              colors: [
                                Colors.orange.withOpacity(0.15),
                                Colors.blue.withOpacity(0.10)
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                        // خط برنامه‌ای (جدید)
                        LineChartBarData(
                          spots: List.generate(chartData.length,
                              (i) => FlSpot(i.toDouble(), plannedChartData[i])),
                          isCurved: true,
                          color: Colors.orange, // برنامه نارنجی
                          barWidth: 2,
                          isStrokeCapRound: true,
                          dotData: FlDotData(show: false),
                          belowBarData: BarAreaData(show: false),
                        ),
                      ],
                      lineTouchData: LineTouchData(
                        enabled: true,
                        touchCallback: (event, response) {
                          if (response != null &&
                              response.lineBarSpots != null &&
                              response.lineBarSpots!.isNotEmpty) {
                            setState(() {
                              touchedIndex = response.lineBarSpots!.first.x;
                            });
                          } else {
                            setState(() {
                              touchedIndex = -1;
                            });
                          }
                        },
                        touchTooltipData: LineTouchTooltipData(
                          tooltipBgColor: Colors.black87,
                          tooltipRoundedRadius: 8,
                          tooltipPadding: const EdgeInsets.all(8),
                          tooltipMargin: 8,
                          getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                            return touchedBarSpots.map((barSpot) {
                              final idx = barSpot.x.toInt();
                              final hours = barSpot.y;
                              return LineTooltipItem(
                                '${xLabels[idx]}\n${hours.toStringAsFixed(2)} ساعت',
                                const TextStyle(
                                  color: Colors.orange,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Vazirmatn',
                                ),
                              );
                            }).toList();
                          },
                        ),
                      ),
                    ),
                  ),
                ),
                // نمایش مقدار هر نقطه بالای دایره
                Positioned.fill(
                  child: IgnorePointer(
                    child: Row(
                      children: List.generate(chartData.length, (i) {
                        return Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if ((chartData[i]['value'] as double) > 0)
                                AnimatedOpacity(
                                  opacity:
                                      touchedIndex == i.toDouble() ? 1.0 : 0.7,
                                  duration: const Duration(milliseconds: 200),
                                  child: Padding(
                                    padding: const EdgeInsets.only(bottom: 210),
                                    child: Text(
                                      (chartData[i]['value'] as double)
                                          .toStringAsFixed(2),
                                      style: TextStyle(
                                        color: touchedIndex == i.toDouble()
                                            ? Colors.orange
                                            : Colors.black,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                        fontFamily: 'Vazirmatn',
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // راهنما
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Container(
                    width: 16,
                    height: 4,
                    color: Colors.black, // واقعی مشکی
                  ),
                  const SizedBox(width: 4),
                  const Text('واقعی', style: TextStyle(color: Colors.black)),
                ],
              ),
              const SizedBox(width: 16),
              Row(
                children: [
                  Container(
                    width: 16,
                    height: 4,
                    color: Colors.orange, // برنامه نارنجی
                  ),
                  const SizedBox(width: 4),
                  const Text('برنامه', style: TextStyle(color: Colors.orange)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // تابع محاسبه مقدار برنامه‌ای برای یک شیفت خاص
  // فرض: منطق مشابه روزانه اما تقسیم بر 3 برای هر شیفت
  // اگر منطق دقیق‌تری مدنظر است، لطفاً اعلام کن

  double _calculatePlannedShiftStop(int year, int month, int day, int shift) {
    final dailyPlan = _calculateDailyPlannedStopsForDay(year, month, day);
    print(
        'دیباگ برنامه شیفتی: year=$year, month=$month, day=$day, shift=$shift, dailyPlan=$dailyPlan');
    return dailyPlan / 3 / 60; // تبدیل به ساعت
  }

  // تابع محاسبه برنامه ماهانه برای نمودار
  double _calculateMonthlyPlannedStopsForChart(int year, int month) {
    if (year == 1404) {
      const Map<String, List<double>> monthlyStopsPlan = {
        'برنامه ای': [
          3.0,
          3.0,
          3.0,
          3.0,
          3.0,
          8.0,
          3.0,
          3.0,
          3.0,
          3.0,
          3.0,
          8.0
        ],
        'مکانیکی': [1.6, 1.6, 1.6, 1.6, 1.6, 1.6, 1.6, 1.6, 1.6, 1.6, 1.6, 1.5],
        'برقی': [0.4, 0.4, 0.4, 0.4, 0.4, 0.4, 0.4, 0.4, 0.4, 0.4, 0.4, 0.4],
        'تاسیساتی': [
          0.0,
          0.0,
          0.0,
          0.0,
          0.0,
          0.0,
          0.0,
          0.0,
          0.0,
          0.0,
          0.0,
          0.0
        ],
        'بهره برداری': [
          1.3,
          1.3,
          1.3,
          1.3,
          1.3,
          1.3,
          1.3,
          1.3,
          1.3,
          1.3,
          1.3,
          1.3
        ],
        'معدنی': [0.7, 0.7, 0.7, 0.7, 0.7, 0.7, 0.7, 0.7, 0.7, 0.7, 0.7, 0.7],
        'عمومی': [3.1, 0.5, 0.5, 2.5, 0.5, 0.5, 0.5, 0.5, 0.5, 1.0, 1.0, 3.9],
        'مجاز': [4.8, 4.8, 4.8, 4.8, 4.8, 4.8, 4.6, 4.6, 4.6, 4.6, 4.6, 4.5],
        'بارگیری': [0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2],
      };

      // محاسبه کل برنامه ماهانه
      double totalMonthlyPlan = 0.0;
      for (List<double> monthlyValues in monthlyStopsPlan.values) {
        totalMonthlyPlan += monthlyValues[month - 1];
      }

      return totalMonthlyPlan * 24; // تبدیل به ساعت ماهانه
    }
    return 0.0;
  }

  // تابع محاسبه لیست ماه‌ها بین دو تاریخ
  List<DateTime> _getMonthsBetween(DateTime start, DateTime end) {
    final months = <DateTime>[];
    DateTime current = DateTime(start.year, start.month, 1);
    final endMonth = DateTime(end.year, end.month, 1);

    while (current.isBefore(endMonth) || current.isAtSameMomentAs(endMonth)) {
      months.add(current);
      current = DateTime(current.year, current.month + 1, 1);
    }

    return months;
  }

  int _calculateStringDistance(String a, String b) {
    final List<List<int>> dp =
        List.generate(a.length + 1, (_) => List.filled(b.length + 1, 0));
    for (int i = 0; i <= a.length; i++) {
      for (int j = 0; j <= b.length; j++) {
        if (i == 0 || j == 0) {
          dp[i][j] = i + j;
        } else if (a[i - 1] == b[j - 1]) {
          dp[i][j] = dp[i - 1][j - 1];
        } else {
          dp[i][j] =
              1 + (dp[i - 1][j] < dp[i][j - 1] ? dp[i - 1][j] : dp[i][j - 1]);
        }
      }
    }
    return dp[a.length][b.length];
  }
}
