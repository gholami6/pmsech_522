import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';
import '../providers/data_provider.dart';
import '../services/production_analysis_service.dart';
import '../services/number_format_service.dart';
import '../widgets/page_header.dart';
import 'pdf_preview_screen.dart';
import '../services/pdf_report_service.dart';
import '../config/stop_colors.dart';
import '../models/stop_data.dart';
import 'package:hive/hive.dart';
import '../config/app_colors.dart';
import '../widgets/general_box_widget.dart';

class GeneralReportScreen extends StatefulWidget {
  const GeneralReportScreen({super.key});

  @override
  State<GeneralReportScreen> createState() => _GeneralReportScreenState();
}

class _GeneralReportScreenState extends State<GeneralReportScreen> {
  Map<String, dynamic> _reportData = {};
  List<Map<String, dynamic>> _sortedStops = [];
  bool _isLoading = false;
  bool _hasGeneratedReport = false;

  // متغیرهای تاریخ
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final now = Jalali.now();
    final firstDate = Jalali(1400, 1, 1);
    final lastDate = Jalali(now.year + 1, 12, 29);
    JalaliRange? initialRange;
    if (_startDate != null && _endDate != null) {
      final startJalali = Jalali.fromDateTime(_startDate!);
      final endJalali = Jalali.fromDateTime(_endDate!);
      if (startJalali.compareTo(firstDate) >= 0 &&
          endJalali.compareTo(lastDate) <= 0) {
        initialRange = JalaliRange(start: startJalali, end: endJalali);
      }
    }
    if (initialRange == null) {
      final defaultStart = Jalali(now.year, now.month, 1);
      final defaultEnd = now;
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
        _startDate = picked.start.toDateTime();
        _endDate = picked.end.toDateTime();
      });
    }
  }

  Future<void> _generateReport() async {
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'لطفاً تاریخ شروع و پایان را انتخاب کنید',
            style: TextStyle(fontFamily: 'Vazirmatn'),
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_startDate!.isAfter(_endDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'تاریخ شروع نمی‌تواند بعد از تاریخ پایان باشد',
            style: TextStyle(fontFamily: 'Vazirmatn'),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final dataProvider = Provider.of<DataProvider>(context, listen: false);
      final allProductionData = dataProvider.getProductionData();

      if (allProductionData.isEmpty) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'داده‌ای برای نمایش موجود نیست',
              style: TextStyle(fontFamily: 'Vazirmatn'),
            ),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // فیلتر کردن داده‌ها بر اساس بازه زمانی انتخابی
      final startDateShamsi = _formatPersianDate(_startDate!);
      final endDateShamsi = _formatPersianDate(_endDate!);

      print('=== دیباگ فیلتر تاریخ‌ها ===');
      print('تاریخ شروع: $startDateShamsi');
      print('تاریخ پایان: $endDateShamsi');
      print('تعداد کل داده‌ها: ${allProductionData.length}');

      // نمونه چند تاریخ از دیتا
      print('نمونه تاریخ‌ها از دیتا:');
      for (int i = 0;
          i < (allProductionData.length > 5 ? 5 : allProductionData.length);
          i++) {
        print('  ${i + 1}: ${allProductionData[i].fullShamsiDate}');
      }

      // بررسی داده‌های سال 1404
      final data1404 =
          allProductionData.where((data) => data.year == 1404).toList();
      print('تعداد داده‌های سال 1404: ${data1404.length}');

      if (data1404.isNotEmpty) {
        print('نمونه داده‌های سال 1404:');
        for (int i = 0; i < (data1404.length > 3 ? 3 : data1404.length); i++) {
          final data = data1404[i];
          print(
              '  ${i + 1}: ${data.year}/${data.month}/${data.day} - ${data.stopType} - ${data.stopDuration}');
        }
      }

      final filteredData = allProductionData.where((data) {
        final dateShamsi = data.fullShamsiDate;
        final isInRange =
            _isDateInRange(dateShamsi, startDateShamsi, endDateShamsi);
        if (dateShamsi.startsWith('1404/4')) {
          // فقط برای ماه 4 سال 1404 لاگ کن
          print('بررسی تاریخ: $dateShamsi - ${isInRange ? "✓" : "✗"}');
        }
        return isInRange;
      }).toList();

      print('تعداد داده‌های فیلتر شده: ${filteredData.length}');
      print('===========================');

      // محاسبه تعداد روزهای مختلف در بازه انتخابی
      final uniqueDays = <String>{};
      for (var data in filteredData) {
        uniqueDays.add(data.fullShamsiDate);
      }

      // محاسبه تعداد روزهای بازه انتخابی (نه روزهای موجود در داده‌ها)
      final startShamsi = Jalali.fromDateTime(_startDate!);
      final endShamsi = Jalali.fromDateTime(_endDate!);
      int totalDays = 0;

      // اگر در یک ماه باشد
      if (startShamsi.year == endShamsi.year &&
          startShamsi.month == endShamsi.month) {
        totalDays = endShamsi.day - startShamsi.day + 1;
      } else {
        // محاسبه برای بازه چندماهه
        DateTime currentDate = _startDate!;
        while (currentDate.isBefore(_endDate!.add(const Duration(days: 1)))) {
          totalDays++;
          currentDate = currentDate.add(const Duration(days: 1));
        }
      }

      print('=== دیباگ محاسبه تعداد روزها ===');
      print(
          'بازه انتخابی: ${startShamsi.year}/${startShamsi.month}/${startShamsi.day} تا ${endShamsi.year}/${endShamsi.month}/${endShamsi.day}');
      print('تعداد روزهای بازه: $totalDays');
      print('تعداد روزهای موجود در داده‌ها: ${uniqueDays.length}');
      print('روزهای موجود در داده‌ها: $uniqueDays');
      print('=====================================');

      // محاسبه آمار پیشرفته شامل تمام KPI ها
      Map<String, dynamic> advancedStats;
      try {
        advancedStats =
            await ProductionAnalysisService.calculateAdvancedStatistics(
                filteredData, totalDays, _startDate!, _endDate!);
        print('محاسبات آمار پیشرفته موفقیت‌آمیز بود');
      } catch (e) {
        print('خطا در محاسبه آمار پیشرفته: $e');
        // مقادیر پیش‌فرض برای جلوگیری از کرش
        advancedStats = {
          'production': {
            'totalInputTonnage': 0.0,
            'totalProducedProduct': 0.0,
            'totalWaste': 0.0,
          },
          'stops': {
            'stopsByType': <String, int>{},
            'stopsByTypeDuration': <String, int>{}
          },
          'availability': {
            'totalAvailability': 0.0,
            'equipmentAvailability': 0.0,
            'tonnageRate': 0.0,
          },
          'grades': {
            'feedGrade': 0.0,
            'productGrade': 0.0,
            'wasteGrade': 0.0,
          },
          'recovery': {
            'weightRecovery': 0.0,
            'metalRecovery': 0.0,
          },
        };
      }

      // محاسبه توقفات از StopData (دیتابیس جداگانه توقفات)
      final calculatedStopStats =
          await _calculateStopsFromStopData(_startDate!, _endDate!);
      advancedStats['stops'] = calculatedStopStats;

      final productionStats = advancedStats['production'];
      final stopStats = advancedStats['stops'];
      final availabilityStats = advancedStats['availability'];
      final gradeStats = advancedStats['grades'];
      final recoveryStats = advancedStats['recovery'];

      // مرتب‌سازی توقفات بر اساس تعداد
      _sortedStops = _getSortedStops(
          stopStats['stopsByType'], stopStats['stopsByTypeDuration']);

      // محاسبه برنامه بر اساس روزهای واقعی و برنامه سالانه
      final Map<String, double> plannedValues =
          await _calculatePlannedValues(totalDays, _startDate!, _endDate!);

      final plannedFeed = plannedValues['feed']!;
      final plannedProduct = plannedValues['product']!;
      final plannedWaste = plannedValues['waste']!;
      final plannedFeedGrade = plannedValues['feedGrade']!;
      final plannedProductGrade = plannedValues['productGrade']!;
      final plannedWasteGrade = plannedValues['wasteGrade']!;

      // ریکاوری برنامه
      final plannedWeightRecovery = 72.0;

      // محاسبه ریکاوری فلزی برنامه بر اساس فرمول
      final plannedMetalRecovery = (plannedProductGrade * plannedProduct) /
          (plannedFeedGrade * plannedFeed) *
          100;

      // دسترسی برنامه (محاسبه شده بر اساس میانگین وزنی ماهانه)
      final plannedTotalAvailability = plannedValues['totalAvailability']!;
      final plannedEquipmentAvailability =
          plannedValues['equipmentAvailability']!;
      // نرخ تناژ برنامه سالانه 1404
      final plannedTonnageRate = plannedValues['tonnageRate']!; // تن بر ساعت

      // توقفات برنامه
      final plannedMineralStops = plannedValues['معدنی']!;
      final plannedMechanicalStops = plannedValues['مکانیکی']!;
      final plannedElectricalStops = plannedValues['برقی']!;
      final plannedFacilityStops = plannedValues['تاسیساتی']!;
      final plannedOperationalStops = plannedValues['بهره برداری']!;
      final plannedPlannedStops = plannedValues['برنامه ای']!;
      final plannedLoadingStops = plannedValues['بارگیری']!;
      final plannedGeneralStops = plannedValues['عمومی']!;
      final plannedPermittedStops = plannedValues['مجاز']!;

      // محاسبه انحراف از برنامه
      final feedDeviation = _calculateDeviation(
          productionStats['totalInputTonnage'], plannedFeed);
      final productDeviation = _calculateDeviation(
          productionStats['totalProducedProduct'], plannedProduct);
      final wasteDeviation =
          _calculateDeviation(productionStats['totalWaste'], plannedWaste);

      final feedGradeDeviation =
          _calculateDeviation(gradeStats['feedGrade'], plannedFeedGrade);
      final productGradeDeviation =
          _calculateDeviation(gradeStats['productGrade'], plannedProductGrade);
      final wasteGradeDeviation =
          _calculateDeviation(gradeStats['wasteGrade'], plannedWasteGrade);

      final weightRecoveryDeviation = _calculateDeviation(
          recoveryStats['weightRecovery'], plannedWeightRecovery);
      final metalRecoveryDeviation = _calculateDeviation(
          recoveryStats['metalRecovery'], plannedMetalRecovery);

      final totalAvailabilityDeviation = _calculateDeviation(
          availabilityStats['totalAvailability'], plannedTotalAvailability);
      final equipmentAvailabilityDeviation = _calculateDeviation(
          availabilityStats['equipmentAvailability'],
          plannedEquipmentAvailability);
      // محاسبه نرخ تناژ واقعی
      final actualTonnageRate = _calculateActualTonnageRate(
          productionStats['totalInputTonnage'],
          totalDays,
          stopStats['totalStopDuration']);
      final tonnageRateDeviation =
          _calculateDeviation(actualTonnageRate, plannedTonnageRate);

      setState(() {
        _reportData = {
          'startDate': startDateShamsi,
          'endDate': endDateShamsi,
          'totalDays': totalDays,
          // تولیدات
          'actualFeed': productionStats['totalInputTonnage'],
          'actualProduct': productionStats['totalProducedProduct'],
          'actualWaste': productionStats['totalWaste'],
          'plannedFeed': plannedFeed,
          'plannedProduct': plannedProduct,
          'plannedWaste': plannedWaste,
          'feedDeviation': feedDeviation,
          'productDeviation': productDeviation,
          'wasteDeviation': wasteDeviation,
          // عیارها
          'actualFeedGrade': gradeStats['feedGrade'],
          'actualProductGrade': gradeStats['productGrade'],
          'actualWasteGrade': gradeStats['wasteGrade'],
          'plannedFeedGrade': plannedFeedGrade,
          'plannedProductGrade': plannedProductGrade,
          'plannedWasteGrade': plannedWasteGrade,
          'feedGradeDeviation': feedGradeDeviation,
          'productGradeDeviation': productGradeDeviation,
          'wasteGradeDeviation': wasteGradeDeviation,
          // ریکاوری
          'actualWeightRecovery': recoveryStats['weightRecovery'],
          'actualMetalRecovery': recoveryStats['metalRecovery'],
          'plannedWeightRecovery': plannedWeightRecovery,
          'plannedMetalRecovery': plannedMetalRecovery,
          'weightRecoveryDeviation': weightRecoveryDeviation,
          'metalRecoveryDeviation': metalRecoveryDeviation,
          // دسترسی
          'actualTotalAvailability': availabilityStats['totalAvailability'],
          'actualEquipmentAvailability':
              availabilityStats['equipmentAvailability'],
          'actualTonnageRate': actualTonnageRate,
          'plannedTotalAvailability': plannedTotalAvailability,
          'plannedEquipmentAvailability': plannedEquipmentAvailability,
          'plannedTonnageRate': plannedTonnageRate,
          'totalAvailabilityDeviation': totalAvailabilityDeviation,
          'equipmentAvailabilityDeviation': equipmentAvailabilityDeviation,
          'tonnageRateDeviation': tonnageRateDeviation,
          // توقفات برنامه
          'plannedMineralStops': plannedMineralStops,
          'plannedMechanicalStops': plannedMechanicalStops,
          'plannedElectricalStops': plannedElectricalStops,
          'plannedFacilityStops': plannedFacilityStops,
          'plannedOperationalStops': plannedOperationalStops,
          'plannedPlannedStops': plannedPlannedStops,
          'plannedLoadingStops': plannedLoadingStops,
          'plannedGeneralStops': plannedGeneralStops,
          'plannedPermittedStops': plannedPermittedStops,
          // توقفات
          'totalStops': stopStats['totalStops'],
          'totalStopDuration': stopStats['totalStopDuration'],
          'averageEfficiency': productionStats['averageEfficiency'],
          'shiftsCount': productionStats['shiftsCount'],
        };
        _isLoading = false;
        _hasGeneratedReport = true;
      });

      // نمایش لاگ برای دیباگ
      print('=== لاگ گزارش تولید شده ===');
      print('بازه زمانی: $startDateShamsi تا $endDateShamsi');
      print('تعداد روزها: $totalDays');
      print('تعداد رکوردهای فیلتر شده: ${filteredData.length}');
      print('تناژ خوراک واقعی: ${productionStats['totalInputTonnage']}');
      print('تناژ محصول واقعی: ${productionStats['totalProducedProduct']}');
      print('تعداد کل توقفات: ${stopStats['totalStops']}');
      print('مدت کل توقفات: ${stopStats['totalStopDuration']} دقیقه');
      print('توقفات بر اساس نوع: ${stopStats['stopsByType']}');
      print('مدت توقفات بر اساس نوع: ${stopStats['stopsByTypeDuration']}');
      print(
          'دسترسی کل: ${availabilityStats['totalAvailability'].toStringAsFixed(1)}%');
      print(
          'دسترسی تجهیزات: ${availabilityStats['equipmentAvailability'].toStringAsFixed(1)}%');
      print('عیار خوراک: ${gradeStats['feedGrade'].toStringAsFixed(2)}%');
      print('عیار محصول: ${gradeStats['productGrade'].toStringAsFixed(2)}%');
      print(
          'ریکاوری وزنی: ${recoveryStats['weightRecovery'].toStringAsFixed(1)}%');
      print(
          'ریکاوری فلزی: ${recoveryStats['metalRecovery'].toStringAsFixed(1)}%');
      print('==============================');
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'خطا در تولید گزارش: ${e.toString()}',
            style: const TextStyle(fontFamily: 'Vazirmatn'),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  bool _isDateInRange(
      String dateShamsi, String startDateShamsi, String endDateShamsi) {
    try {
      // تبدیل تاریخ‌ها به فرمت استاندارد YYYY/MM/DD
      String normalizeDate(String date) {
        final parts = date.split('/');
        if (parts.length != 3) return date;

        final year = parts[0].padLeft(4, '0');
        final month = parts[1].padLeft(2, '0');
        final day = parts[2].padLeft(2, '0');

        return '$year/$month/$day';
      }

      final normalizedDate = normalizeDate(dateShamsi);
      final normalizedStart = normalizeDate(startDateShamsi);
      final normalizedEnd = normalizeDate(endDateShamsi);

      // تبدیل به اعداد برای مقایسه (YYYYMMDD)
      final dateInt = int.parse(normalizedDate.replaceAll('/', ''));
      final startInt = int.parse(normalizedStart.replaceAll('/', ''));
      final endInt = int.parse(normalizedEnd.replaceAll('/', ''));

      final result = dateInt >= startInt && dateInt <= endInt;

      // debug برای مشکل‌یابی
      if (dateShamsi.startsWith('1404/4')) {
        print('  -> تاریخ اصلی: $dateShamsi');
        print('  -> تاریخ نرمال: $normalizedDate ($dateInt)');
        print(
            '  -> بازه: $normalizedStart ($startInt) تا $normalizedEnd ($endInt)');
        print('  -> نتیجه: $result');
        print('  ---------------------');
      }

      return result;
    } catch (e) {
      print('خطا در پردازش تاریخ: $dateShamsi - $e');
      return false;
    }
  }

  List<Map<String, dynamic>> _getSortedStops(
      Map<String, int> stopsByType, Map<String, int> stopsByTypeDuration) {
    List<String> allStopTypes = [
      'برنامه ای',
      'برقی',
      'مکانیکی',
      'تاسیساتی',
      'معدنی',
      'بهره برداری',
      'بارگیری',
      'عمومی',
      'مجاز',
    ];

    List<Map<String, dynamic>> allStops = [];

    // همه نوع‌های توقف را اضافه کن (حتی با مقدار صفر)
    for (String type in allStopTypes) {
      final count = stopsByType[type] ?? 0;
      final duration = stopsByTypeDuration[type] ?? 0;

      allStops.add({
        'type': type,
        'count': count,
        'duration': duration,
      });
    }

    // اضافه کردن نوع‌های توقف که در لیست ثابت نیستند
    for (String type in stopsByType.keys) {
      if (!allStopTypes.contains(type)) {
        allStops.add({
          'type': type,
          'count': stopsByType[type] ?? 0,
          'duration': stopsByTypeDuration[type] ?? 0,
        });
      }
    }

    // مرتب‌سازی بر اساس مدت توقف (نزولی) و سپس نام
    allStops.sort((a, b) {
      int durationA = a['duration'] as int;
      int durationB = b['duration'] as int;

      if (durationA != durationB) {
        return durationB.compareTo(durationA);
      } else {
        return (a['type'] as String).compareTo(b['type'] as String);
      }
    });

    // دیباگ مرتب‌سازی
    print('=== دیباگ مرتب‌سازی توقفات ===');
    for (int i = 0; i < allStops.length; i++) {
      final stop = allStops[i];
      final hours = (stop['duration'] as int) ~/ 60;
      final minutes = (stop['duration'] as int) % 60;
      print(
          '${i + 1}. ${stop['type']}: ${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')} (${stop['duration']} دقیقه)');
    }
    print('===============================');

    return allStops;
  }

  Color _getStopRowColor(String stopType) {
    return StopColors.getColorForStopType(stopType);
  }

  String _formatTotalStopDuration(int totalMinutes) {
    int hours = totalMinutes ~/ 60;
    int minutes = totalMinutes % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
  }

  /// محاسبه و فرمت مجموع کل توقفات برنامه
  String _formatTotalPlannedStops(DateTime startDate, DateTime endDate) {
    // داده‌های واقعی برنامه سالانه 1404 (از annual_plan_screen.dart)
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
      ], // توقفات برنامه ریزی شده
      'مکانیکی': [
        1.6,
        1.6,
        1.6,
        1.6,
        1.6,
        1.6,
        1.6,
        1.6,
        1.6,
        1.6,
        1.6,
        1.5
      ], // توقفات مکانیکی
      'برقی': [
        0.4,
        0.4,
        0.4,
        0.4,
        0.4,
        0.4,
        0.4,
        0.4,
        0.4,
        0.4,
        0.4,
        0.4
      ], // توقفات برقی
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
      ], // توقفات تاسیسات
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
      ], // توقفات بهره برداری
      'معدنی': [
        0.7,
        0.7,
        0.7,
        0.7,
        0.7,
        0.7,
        0.7,
        0.7,
        0.7,
        0.7,
        0.7,
        0.7
      ], // توقفات معدنی
      'عمومی': [
        3.1,
        0.5,
        0.5,
        2.5,
        0.5,
        0.5,
        0.5,
        0.5,
        0.5,
        1.0,
        1.0,
        3.9
      ], // توقفات عمومی
      'مجاز': [
        4.8,
        4.8,
        4.8,
        4.8,
        4.8,
        4.8,
        4.6,
        4.6,
        4.6,
        4.6,
        4.6,
        4.5
      ], // توقفات مجاز
      'بارگیری': [
        0.2,
        0.2,
        0.2,
        0.2,
        0.2,
        0.2,
        0.2,
        0.2,
        0.2,
        0.2,
        0.2,
        0.2
      ], // توقفات بارگیری
    };

    final startShamsi = Jalali.fromDateTime(startDate);
    final endShamsi = Jalali.fromDateTime(endDate);
    final month = startShamsi.month;

    double totalPlannedDays = 0.0;

    // جمع تمام توقفات برنامه برای ماه مشخص
    for (List<double> monthlyValues in monthlyStopsPlan.values) {
      totalPlannedDays += monthlyValues[month - 1]; // ماه-1 برای ایندکس
    }

    // اگر بازه در یک ماه باشد
    if (startShamsi.year == endShamsi.year &&
        startShamsi.month == endShamsi.month) {
      final month = startShamsi.month;
      final daysInMonth = Jalali(startShamsi.year, month, 1).monthLength;
      final selectedDays = endShamsi.day - startShamsi.day + 1;

      // فرمول جدید: (تعداد روزهای انتخابی ÷ کل روزهای ماه) × مقدار برنامه سالانه
      final plannedDays = (selectedDays / daysInMonth) * totalPlannedDays;

      // تبدیل به فرمت ساعت:دقیقه
      final totalHours = plannedDays * 24;
      final hours = totalHours.floor();
      final minutes = ((totalHours - hours) * 60).round();

      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
    } else {
      // برای بازه چندماهه - محاسبه پیچیده‌تر
      double totalPlannedDaysForRange = 0.0;
      DateTime currentDate = startDate;

      while (currentDate.isBefore(endDate.add(const Duration(days: 1)))) {
        final currentShamsi = Jalali.fromDateTime(currentDate);
        final month = currentShamsi.month;
        final daysInMonth = Jalali(currentShamsi.year, month, 1).monthLength;

        // محاسبه روزهای این ماه در بازه
        int daysInThisMonth = 0;
        if (currentDate.year == startDate.year &&
            currentDate.month == startDate.month) {
          // ماه شروع
          daysInThisMonth = daysInMonth - startShamsi.day + 1;
        } else if (currentDate.year == endDate.year &&
            currentDate.month == endDate.month) {
          // ماه پایان
          daysInThisMonth = endShamsi.day;
        } else {
          // ماه‌های میانی
          daysInThisMonth = daysInMonth;
        }

        // محاسبه برنامه برای این ماه
        final plannedDaysForMonth =
            (daysInThisMonth / daysInMonth) * totalPlannedDays;
        totalPlannedDaysForRange += plannedDaysForMonth;

        currentDate = DateTime(currentDate.year, currentDate.month + 1, 1);
      }

      // تبدیل به فرمت ساعت:دقیقه
      final totalHours = totalPlannedDaysForRange * 24;
      final hours = totalHours.floor();
      final minutes = ((totalHours - hours) * 60).round();

      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
    }
  }

  List<Widget> _buildSortedStopRows() {
    List<Widget> rows = [];

    for (int i = 0; i < _sortedStops.length; i++) {
      final stopData = _sortedStops[i];

      Color? rowColor;
      if (stopData['duration'] > 0 && i < 8) {
        final color = _getStopRowColor(stopData['type']);
        rowColor = color.withOpacity(0.3);
      }

      // تبدیل مدت توقفات به فرمت hh:mm
      String formatDuration(int minutes) {
        int hours = minutes ~/ 60;
        int mins = minutes % 60;
        return '${hours.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')}';
      }

      // تبدیل روزهای برنامه به ساعت
      String formatPlannedDays(double days) {
        int totalMinutes = (days * 24 * 60).round();
        int hours = totalMinutes ~/ 60;
        int mins = totalMinutes % 60;
        return '${hours.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')}';
      }

      // محاسبه انحراف از برنامه برای توقفات (علامت برعکس)
      String calculateDeviation(int actualMinutes, double plannedDays) {
        if (plannedDays <= 0) return '0%';
        final plannedMinutes = plannedDays * 24 * 60;
        // برای توقفات: کمتر = بهتر، بیشتر = بدتر → علامت برعکس
        final deviation =
            -((actualMinutes - plannedMinutes) / plannedMinutes) * 100;
        return '${deviation.toStringAsFixed(1)}%';
      }

      // محاسبه مقدار برنامه برای این نوع توقف با فرمول جدید
      double plannedValue =
          _calculatePlannedStopValue(stopData['type'], _startDate!, _endDate!);

      rows.add(_buildDataRow(
        stopData['type'],
        formatDuration(stopData['duration'] ?? 0),
        formatPlannedDays(plannedValue),
        calculateDeviation(stopData['duration'] ?? 0, plannedValue),
        rowColor: rowColor,
      ));
    }

    return rows;
  }

  double _calculateDeviation(double actual, double planned) {
    if (planned == 0) return 0;
    return ((actual - planned) / planned) * 100;
  }

  /// محاسبه انحراف مجموع توقفات با علامت برعکس
  String _calculateTotalStopsDeviation(int totalActualMinutes) {
    // محاسبه کل برنامه توقفات برای بازه انتخابی
    final startShamsi = Jalali.fromDateTime(_startDate!);
    final endShamsi = Jalali.fromDateTime(_endDate!);
    final month = startShamsi.month;

    // داده‌های برنامه ماهانه
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

    double totalPlannedDays = 0.0;
    for (List<double> monthlyValues in monthlyStopsPlan.values) {
      totalPlannedDays += monthlyValues[month - 1];
    }

    // اگر بازه در یک ماه باشد
    if (startShamsi.year == endShamsi.year &&
        startShamsi.month == endShamsi.month) {
      final daysInMonth = Jalali(startShamsi.year, month, 1).monthLength;
      final selectedDays = endShamsi.day - startShamsi.day + 1;
      final plannedDaysForRange =
          (selectedDays / daysInMonth) * totalPlannedDays;
      final plannedMinutes = plannedDaysForRange * 24 * 60;

      if (plannedMinutes <= 0) return '0%';

      // برای توقفات: کمتر = بهتر → علامت برعکس
      final deviation =
          -((totalActualMinutes - plannedMinutes) / plannedMinutes) * 100;
      return '${deviation.toStringAsFixed(1)}%';
    }

    return '0%'; // برای بازه چندماهه - فعلاً ساده
  }

  /// محاسبه مقدار برنامه توقفات با فرمول جدید
  /// (تعداد روزهای انتخابی ÷ کل روزهای ماه) × مقدار برنامه ماهانه واقعی
  double _calculatePlannedStopValue(
      String stopType, DateTime startDate, DateTime endDate) {
    // داده‌های واقعی برنامه سالانه 1404 (از annual_plan_screen.dart)
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
      ], // توقفات برنامه ریزی شده
      'مکانیکی': [
        1.6,
        1.6,
        1.6,
        1.6,
        1.6,
        1.6,
        1.6,
        1.6,
        1.6,
        1.6,
        1.6,
        1.5
      ], // توقفات مکانیکی
      'برقی': [
        0.4,
        0.4,
        0.4,
        0.4,
        0.4,
        0.4,
        0.4,
        0.4,
        0.4,
        0.4,
        0.4,
        0.4
      ], // توقفات برقی
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
      ], // توقفات تاسیسات
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
      ], // توقفات بهره برداری
      'معدنی': [
        0.7,
        0.7,
        0.7,
        0.7,
        0.7,
        0.7,
        0.7,
        0.7,
        0.7,
        0.7,
        0.7,
        0.7
      ], // توقفات معدنی
      'عمومی': [
        3.1,
        0.5,
        0.5,
        2.5,
        0.5,
        0.5,
        0.5,
        0.5,
        0.5,
        1.0,
        1.0,
        3.9
      ], // توقفات عمومی
      'مجاز': [
        4.8,
        4.8,
        4.8,
        4.8,
        4.8,
        4.8,
        4.6,
        4.6,
        4.6,
        4.6,
        4.6,
        4.5
      ], // توقفات مجاز
      'بارگیری': [
        0.2,
        0.2,
        0.2,
        0.2,
        0.2,
        0.2,
        0.2,
        0.2,
        0.2,
        0.2,
        0.2,
        0.2
      ], // توقفات بارگیری
    };

    // اگر نوع توقف در برنامه وجود ندارد
    if (!monthlyStopsPlan.containsKey(stopType)) {
      return 0.0;
    }

    final startShamsi = Jalali.fromDateTime(startDate);
    final endShamsi = Jalali.fromDateTime(endDate);

    // اگر بازه در یک ماه باشد
    if (startShamsi.year == endShamsi.year &&
        startShamsi.month == endShamsi.month) {
      final month = startShamsi.month;
      final daysInMonth = Jalali(startShamsi.year, month, 1).monthLength;
      final selectedDays = endShamsi.day - startShamsi.day + 1;

      // دریافت مقدار برنامه ماهانه (ایندکس ماه - 1)
      final monthlyPlannedDays = monthlyStopsPlan[stopType]![month - 1];

      // فرمول جدید: (تعداد روزهای انتخابی ÷ کل روزهای ماه) × مقدار برنامه ماهانه
      final plannedDays = (selectedDays / daysInMonth) * monthlyPlannedDays;

      print('=== دیباگ محاسبه برنامه توقف: $stopType ===');
      print('ماه: $month');
      print('روزهای ماه: $daysInMonth');
      print('روزهای انتخابی: $selectedDays');
      print('برنامه ماهانه: $monthlyPlannedDays روز');
      print('برنامه محاسبه شده: ${plannedDays.toStringAsFixed(2)} روز');
      print('تبدیل به ساعت: ${(plannedDays * 24).toStringAsFixed(2)} ساعت');
      print('=====================================');

      return plannedDays;
    } else {
      // برای بازه چندماهه - محاسبه پیچیده‌تر
      double totalPlannedDays = 0.0;
      DateTime currentDate = startDate;

      while (currentDate.isBefore(endDate.add(const Duration(days: 1)))) {
        final currentShamsi = Jalali.fromDateTime(currentDate);
        final month = currentShamsi.month;
        final daysInMonth = Jalali(currentShamsi.year, month, 1).monthLength;

        // محاسبه روزهای این ماه در بازه
        int daysInThisMonth = 0;
        if (currentDate.year == startDate.year &&
            currentDate.month == startDate.month) {
          // ماه شروع
          daysInThisMonth = daysInMonth - startShamsi.day + 1;
        } else if (currentDate.year == endDate.year &&
            currentDate.month == endDate.month) {
          // ماه پایان
          daysInThisMonth = endShamsi.day;
        } else {
          // ماه‌های میانی
          daysInThisMonth = daysInMonth;
        }

        // دریافت مقدار برنامه ماهانه
        final monthlyPlannedDays = monthlyStopsPlan[stopType]![month - 1];

        // محاسبه برنامه برای این ماه
        final plannedDaysForMonth =
            (daysInThisMonth / daysInMonth) * monthlyPlannedDays;
        totalPlannedDays += plannedDaysForMonth;

        currentDate = DateTime(currentDate.year, currentDate.month + 1, 1);
      }

      return totalPlannedDays;
    }
  }

  /// محاسبه نرخ تناژ محقق شده بر اساس فرمول صحیح
  /// نرخ تناژ = تناژ خوراک واقعی ÷ (زمان کل در دسترس - زمان کل توقفات)
  double _calculateActualTonnageRate(
      double totalFeed, int totalDays, int totalStopMinutes) {
    if (totalDays <= 0) return 0.0;

    // محاسبه زمان کل در دسترس
    final totalWorkingHours = totalDays * 3 * 8.0; // 3 شیفت × 8 ساعت

    // محاسبه زمان کل توقفات (تبدیل دقیقه به ساعت)
    final totalStopHours = totalStopMinutes / 60.0;

    // محاسبه زمان کاری واقعی
    final actualWorkingHours = totalWorkingHours - totalStopHours;

    // محاسبه نرخ تناژ
    final tonnageRate =
        actualWorkingHours > 0 ? totalFeed / actualWorkingHours : 0.0;

    print('=== دیباگ محاسبه نرخ تناژ محقق شده ===');
    print('تناژ خوراک: $totalFeed تن');
    print('تعداد روزها: $totalDays');
    print('زمان کل در دسترس: $totalWorkingHours ساعت');
    print('زمان کل توقفات: ${totalStopHours.toStringAsFixed(2)} ساعت');
    print('زمان کاری واقعی: ${actualWorkingHours.toStringAsFixed(2)} ساعت');
    print('نرخ تناژ محقق شده: ${tonnageRate.toStringAsFixed(2)} تن/ساعت');
    print('=====================================');

    return tonnageRate;
  }

  /// محاسبه مقادیر برنامه بر اساس برنامه سالانه و بازه زمانی واقعی
  Future<Map<String, double>> _calculatePlannedValues(
      int totalDays, DateTime startDate, DateTime endDate) async {
    try {
      // برنامه سالانه 1404 (همان مقادیری که در ProductionAnalysisService استفاده می‌شود)
      const annualPlan = {
        'feed': 232248.0, // تناژ خوراک سالانه
        'product': 166754.0, // تناژ محصول سالانه
        'waste': 65494.0, // تناژ باطله سالانه
        'feedGrade': 30.00, // عیار خوراک برنامه
        'productGrade': 37.0, // عیار محصول برنامه
        'wasteGrade': 12.00, // عیار باطله برنامه
      };

      // محاسبه نسبت روزهای انتخاب شده به تعداد روزهای برنامه ماه
      final startShamsi = Jalali.fromDateTime(startDate);
      final endShamsi = Jalali.fromDateTime(endDate);

      // تعداد روزهای برنامه ماه (از شروع تا پایان ماه)
      int plannedDaysInMonth = 0;
      if (startShamsi.year == endShamsi.year &&
          startShamsi.month == endShamsi.month) {
        // اگر در یک ماه باشد
        plannedDaysInMonth =
            Jalali(startShamsi.year, startShamsi.month, 1).monthLength;
      } else {
        // اگر چندماهه باشد، میانگین روزهای ماه‌ها
        DateTime currentDate = startDate;
        int totalMonthDays = 0;
        int monthCount = 0;

        while (currentDate.isBefore(endDate.add(const Duration(days: 1)))) {
          final currentShamsi = Jalali.fromDateTime(currentDate);
          final monthLength =
              Jalali(currentShamsi.year, currentShamsi.month, 1).monthLength;
          totalMonthDays += monthLength;
          monthCount++;
          currentDate = DateTime(currentDate.year, currentDate.month + 1, 1);
        }
        plannedDaysInMonth =
            monthCount > 0 ? (totalMonthDays / monthCount).round() : 30;
      }

      final dayRatio = totalDays / plannedDaysInMonth.toDouble();

      print('=== دیباگ محاسبه نسبت برنامه ===');
      print('تعداد روزهای انتخابی: $totalDays');
      print('تعداد روزهای برنامه ماه: $plannedDaysInMonth');
      print('نسبت (dayRatio): ${dayRatio.toStringAsFixed(4)}');
      print('=====================================');

      // محاسبه دسترسی‌ها بر اساس میانگین وزنی ماهانه

      // داده‌های دسترسی ماهانه از برنامه سالانه
      final Map<int, Map<String, double>> monthlyAvailability = {
        1: {'total': 50.89, 'equipment': 75.68}, // فروردین
        2: {'total': 59.36, 'equipment': 78.40}, // اردیبهشت
        3: {'total': 59.36, 'equipment': 78.40}, // خرداد
        4: {'total': 52.91, 'equipment': 76.39}, // تیر
        5: {'total': 59.36, 'equipment': 78.40}, // مرداد
        6: {'total': 43.23, 'equipment': 57.10}, // شهریور
        7: {'total': 58.98, 'equipment': 77.96}, // مهر
        8: {'total': 58.98, 'equipment': 77.96}, // آبان
        9: {'total': 58.98, 'equipment': 77.96}, // آذر
        10: {'total': 57.18, 'equipment': 77.42}, // دی
        11: {'total': 57.18, 'equipment': 77.42}, // بهمن
        12: {'total': 29.56, 'equipment': 46.31}, // اسفند
      };

      // محاسبه میانگین وزنی دسترسی‌ها
      double weightedTotalAvailability = 0.0;
      double weightedEquipmentAvailability = 0.0;
      int totalCalculatedDays = 0;

      // اگر بازه در یک ماه باشد
      if (startShamsi.year == endShamsi.year &&
          startShamsi.month == endShamsi.month) {
        final month = startShamsi.month;
        if (monthlyAvailability.containsKey(month)) {
          weightedTotalAvailability = monthlyAvailability[month]!['total']!;
          weightedEquipmentAvailability =
              monthlyAvailability[month]!['equipment']!;
        }
      } else {
        // محاسبه برای بازه چندماهه
        DateTime currentDate = startDate;
        while (currentDate.isBefore(endDate.add(const Duration(days: 1)))) {
          final currentShamsi = Jalali.fromDateTime(currentDate);
          final month = currentShamsi.month;

          if (monthlyAvailability.containsKey(month)) {
            weightedTotalAvailability += monthlyAvailability[month]!['total']!;
            weightedEquipmentAvailability +=
                monthlyAvailability[month]!['equipment']!;
            totalCalculatedDays++;
          }
          currentDate = currentDate.add(const Duration(days: 1));
        }

        if (totalCalculatedDays > 0) {
          weightedTotalAvailability /= totalCalculatedDays;
          weightedEquipmentAvailability /= totalCalculatedDays;
        }
      }

      // برنامه ماهانه توقفات 1404 (از annual_plan_screen.dart)
      const monthlyStopsPlan = {
        'معدنی': [
          0.7,
          0.7,
          0.7,
          0.7,
          0.7,
          0.7,
          0.7,
          0.7,
          0.7,
          0.7,
          0.7,
          0.7
        ], // روز
        'مکانیکی': [
          1.6,
          1.6,
          1.6,
          1.6,
          1.6,
          1.6,
          1.6,
          1.6,
          1.6,
          1.6,
          1.6,
          1.5
        ], // روز
        'برقی': [
          0.4,
          0.4,
          0.4,
          0.4,
          0.4,
          0.4,
          0.4,
          0.4,
          0.4,
          0.4,
          0.4,
          0.4
        ], // روز
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
        ], // روز
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
        ], // روز
        'برنامه ای': [
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
        ], // روز
        'بارگیری': [
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
        ], // روز
        'عمومی': [
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
        ], // روز
        'مجاز': [
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
        ], // روز
      };

      // محاسبه توقفات برنامه (بر اساس نسبت روزهای هر ماه)
      Map<String, double> plannedStops = {};
      for (String stopType in monthlyStopsPlan.keys) {
        double totalPlannedDays = 0.0;
        int totalDaysInRange = 0;

        for (int year = startShamsi.year; year <= endShamsi.year; year++) {
          for (int month = 1; month <= 12; month++) {
            // بررسی اینکه آیا این ماه در بازه انتخابی است
            if (year == startShamsi.year && month < startShamsi.month) continue;
            if (year == endShamsi.year && month > endShamsi.month) continue;

            // محاسبه روزهای این ماه در بازه انتخابی
            int daysInThisMonth = 0;
            if (year == startShamsi.year && month == startShamsi.month) {
              // ماه شروع
              daysInThisMonth =
                  Jalali(year, month, 1).monthLength - startShamsi.day + 1;
            } else if (year == endShamsi.year && month == endShamsi.month) {
              // ماه پایان
              daysInThisMonth = endShamsi.day;
            } else {
              // ماه‌های میانی
              daysInThisMonth = Jalali(year, month, 1).monthLength;
            }

            // محاسبه توقفات برنامه برای این ماه
            final monthIndex = month - 1;
            final plannedDaysForMonth = monthlyStopsPlan[stopType]![monthIndex];
            totalPlannedDays += (plannedDaysForMonth * daysInThisMonth) /
                Jalali(year, month, 1).monthLength;
            totalDaysInRange += daysInThisMonth;
          }
        }

        plannedStops[stopType] = totalPlannedDays;

        // لاگ برای دیباگ محاسبات توقفات برنامه
        print('=== دیباگ توقفات برنامه: $stopType ===');
        print(
            'تعداد روزهای برنامه: ${totalPlannedDays.toStringAsFixed(3)} روز');
        print(
            'تبدیل به ساعت: ${(totalPlannedDays * 24).toStringAsFixed(2)} ساعت');
        print(
            'تبدیل به دقیقه: ${(totalPlannedDays * 24 * 60).toStringAsFixed(0)} دقیقه');
        print('=====================================');
      }

      // محاسبه مقادیر برنامه متناسب با تعداد روزهای واقعی
      return {
        'feed': annualPlan['feed']! * dayRatio,
        'product': annualPlan['product']! * dayRatio,
        'waste': annualPlan['waste']! * dayRatio,
        'feedGrade': annualPlan['feedGrade']!, // عیارها ثابت هستند
        'productGrade': annualPlan['productGrade']!,
        'wasteGrade': annualPlan['wasteGrade']!,
        'totalAvailability': weightedTotalAvailability,
        'equipmentAvailability': weightedEquipmentAvailability,
        'tonnageRate': 590.0, // تن بر ساعت (ثابت)
        ...plannedStops,
      };
    } catch (e) {
      print('خطا در محاسبه مقادیر برنامه: $e');
      // مقادیر پیش‌فرض در صورت خطا
      return {
        'feed': totalDays * 150.0,
        'product': totalDays * 120.0,
        'waste': totalDays * 30.0,
        'feedGrade': 30.00,
        'productGrade': 37.0,
        'wasteGrade': 12.00,
        'totalAvailability': 52.91,
        'equipmentAvailability': 58.47,
        'tonnageRate': 590.0,
        'معدنی': 0.0,
        'مکانیکی': 0.0,
        'برقی': 0.0,
        'تاسیساتی': 0.0,
        'بهره برداری': 0.0,
        'برنامه ای': 0.0,
        'بارگیری': 0.0,
        'عمومی': 0.0,
        'مجاز': 0.0,
      };
    }
  }

  String _formatPersianDate(DateTime date) {
    final j = Jalali.fromDateTime(date);
    return '${j.year}/${j.month.toString().padLeft(2, '0')}/${j.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.stopsAppBar,
        body: SafeArea(
          child: Column(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Center(
                        child: Text(
                          'گزارش کلی',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Vazirmatn',
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        // باکس انتخاب تاریخ
                        _buildDateSelectionBox(),

                        // نمایش نتایج
                        if (_isLoading)
                          Container(
                            padding: const EdgeInsets.all(40),
                            child: Column(
                              children: [
                                SizedBox(
                                  width: 60,
                                  height: 60,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 4,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.blue[600] ??
                                            Colors.blue.shade600),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'در حال تولید گزارش، لطفاً صبر کنید...',
                                  style: TextStyle(
                                    fontFamily: 'Vazirmatn',
                                    fontSize: 16,
                                    color: Colors.grey[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else if (_hasGeneratedReport &&
                            _reportData.isNotEmpty) ...[
                          _buildReportTable(),
                          const SizedBox(height: 24),
                          _buildDownloadButton(),
                        ] else if (_hasGeneratedReport && _reportData.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(40),
                            decoration: BoxDecoration(
                              color: Colors.orange[50],
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                  color: Colors.orange[200] ??
                                      Colors.orange.shade200),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.search_off_rounded,
                                  size: 60,
                                  color: Colors.orange[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'داده‌ای برای نمایش در این بازه زمانی موجود نیست',
                                  style: TextStyle(
                                    fontFamily: 'Vazirmatn',
                                    fontSize: 16,
                                    color: Colors.orange[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateSelectionBox() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // انتخاب بازه زمانی
        Text(
          _hasGeneratedReport && _reportData.isNotEmpty
              ? 'برای تغییر بازه زمانی گزارش کلیک کنید:'
              : 'لطفاً بازه زمانی گزارش را انتخاب کنید:',
          style: const TextStyle(
            fontFamily: 'Vazirmatn',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),

        Container(
          width: double.infinity,
          height: 56,
          margin: const EdgeInsets.only(bottom: 24),
          child: ElevatedButton.icon(
            onPressed: () => _selectDateRange(context),
            icon: const Icon(Icons.calendar_today_rounded, size: 18),
            label: Flexible(
              child: Text(
                _startDate != null && _endDate != null
                    ? 'از ${_formatPersianDate(_startDate!)} تا ${_formatPersianDate(_endDate!)}'
                    : 'انتخاب بازه زمانی',
                style: TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: (_startDate != null && _endDate != null)
                      ? Colors.white
                      : Colors.black87,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: (_startDate != null && _endDate != null)
                  ? Colors.blue[600]
                  : Colors.grey[400],
              foregroundColor: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
          ),
        ),

        // باکس تولید گزارش
        if (_startDate != null && _endDate != null)
          Container(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _generateReport,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.assessment_rounded, size: 20),
              label: Flexible(
                child: Text(
                  _isLoading ? 'در حال تولید...' : 'تولید گزارش',
                  style: const TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[600],
                foregroundColor: Colors.white,
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                disabledBackgroundColor: Colors.grey[400],
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),
      ],
    );
  }

  void _resetDates() {
    setState(() {
      _startDate = null;
      _endDate = null;
      _hasGeneratedReport = false;
      _reportData = {};
    });
  }

  Widget _buildReportTable() {
    return TableBox(
      child: Column(
        children: [
          // جدول اصلی - بدون باکس‌های بالای جدول
          _buildMainTable(),
        ],
      ),
    );
  }

  Widget _buildInfoRow() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: Color(0xFFE8F5E8),
        border: Border(
          bottom: BorderSide(color: Colors.grey, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildInfoCell('تاریخ شروع', _reportData['startDate'] ?? ''),
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: _buildInfoCell('تاریخ پایان', _reportData['endDate'] ?? ''),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCell(String title, String value) {
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Vazirmatn',
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Vazirmatn',
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildMainTable() {
    return Column(
      children: [
        // هدر جدول
        Container(
          decoration: const BoxDecoration(
            color: Color(0xFFE3F2FD),
            border: Border(
              bottom: BorderSide(color: Colors.grey, width: 0.5),
            ),
          ),
          child: IntrinsicHeight(
            child: Row(
              children: [
                _buildHeaderCell('عناوین', flex: 3),
                _buildHeaderCell('محقق شده', flex: 3),
                _buildHeaderCell('برنامه', flex: 2),
                _buildHeaderCell('انحراف از برنامه', flex: 2),
              ],
            ),
          ),
        ),

        // ردیف‌های داده
        _buildDataSection('شاخص ها', Color(0xFFE3F2FD), isMainCategory: true),
        _buildDataRow(
            ' دسترسی کل',
            '${_reportData['actualTotalAvailability'].toStringAsFixed(1)}%',
            '${_reportData['plannedTotalAvailability'].toStringAsFixed(1)}%',
            '${_reportData['totalAvailabilityDeviation'].toStringAsFixed(1)}%'),
        _buildDataRow(
            ' دسترسی تجهیزات',
            '${_reportData['actualEquipmentAvailability'].toStringAsFixed(1)}%',
            '${_reportData['plannedEquipmentAvailability'].toStringAsFixed(1)}%',
            '${_reportData['equipmentAvailabilityDeviation'].toStringAsFixed(1)}%',
            customFontSize: 9),
        _buildDataRow(
            'نرخ تناژ',
            '${_reportData['actualTonnageRate'].toStringAsFixed(2)}',
            '${_reportData['plannedTonnageRate'].toStringAsFixed(2)}',
            '${_reportData['tonnageRateDeviation'].toStringAsFixed(1)}%'),

        _buildDataSection('توقفات', Color(0xFFE3F2FD)),
        ..._buildSortedStopRows(),
        _buildDataRow(
            'جمع کل',
            _formatTotalStopDuration(_reportData['totalStopDuration'] ?? 0),
            _formatTotalPlannedStops(_startDate!, _endDate!),
            _calculateTotalStopsDeviation(
                _reportData['totalStopDuration'] ?? 0),
            isTotal: true),

        _buildDataSection('تولیدات', Color(0xFFE3F2FD)),
        _buildDataRow(
            'تناژ خوراک',
            NumberFormatService.formatNumber(_reportData['actualFeed']),
            NumberFormatService.formatNumber(_reportData['plannedFeed']),
            '${_reportData['feedDeviation'].toStringAsFixed(1)}%',
            rowColor: Color(0xFFB3E5FC)),
        _buildDataRow(
            'عیار خوراک',
            '${_reportData['actualFeedGrade'].toStringAsFixed(2)}%',
            '${_reportData['plannedFeedGrade'].toStringAsFixed(2)}%',
            '${_reportData['feedGradeDeviation'].toStringAsFixed(1)}%',
            rowColor: Color(0xFFB3E5FC)),
        _buildDataRow(
            'تناژ محصول',
            NumberFormatService.formatNumber(_reportData['actualProduct']),
            NumberFormatService.formatNumber(_reportData['plannedProduct']),
            '${_reportData['productDeviation'].toStringAsFixed(1)}%',
            rowColor: Color(0xFFD4EDDA)),
        _buildDataRow(
            'عیار محصول',
            '${_reportData['actualProductGrade'].toStringAsFixed(2)}%',
            '${_reportData['plannedProductGrade'].toStringAsFixed(2)}%',
            '${_reportData['productGradeDeviation'].toStringAsFixed(1)}%',
            rowColor: Color(0xFFD4EDDA)),
        _buildDataRow(
            'تناژ باطله',
            NumberFormatService.formatNumber(_reportData['actualWaste']),
            NumberFormatService.formatNumber(_reportData['plannedWaste']),
            '${_reportData['wasteDeviation'].toStringAsFixed(1)}%',
            rowColor: Color(0xFFEDE7B1)),
        _buildDataRow(
            'عیار باطله',
            '${_reportData['actualWasteGrade'].toStringAsFixed(2)}%',
            '${_reportData['plannedWasteGrade'].toStringAsFixed(2)}%',
            '${_reportData['wasteGradeDeviation'].toStringAsFixed(1)}%',
            rowColor: Color(0xFFEDE7B1)),
        _buildDataRow(
            'ریکاوری وزنی',
            '${_reportData['actualWeightRecovery'].toStringAsFixed(1)}%',
            '${_reportData['plannedWeightRecovery'].toStringAsFixed(1)}%',
            '${_reportData['weightRecoveryDeviation'].toStringAsFixed(1)}%'),
        _buildDataRow(
            'ریکاوری فلزی',
            '${_reportData['actualMetalRecovery'].toStringAsFixed(1)}%',
            '${_reportData['plannedMetalRecovery'].toStringAsFixed(1)}%',
            '${_reportData['metalRecoveryDeviation'].toStringAsFixed(1)}%'),
      ],
    );
  }

  Widget _buildDataSection(String title, Color color,
      {bool isMainCategory = false}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: color,
        border: const Border(
          bottom: BorderSide(color: Colors.grey, width: 0.5),
        ),
      ),
      child: Text(
        title,
        textAlign:
            (title == 'توقفات' || title == 'تولیدات' || title == 'شاخص ها')
                ? TextAlign.center
                : TextAlign.start,
        style: TextStyle(
          fontFamily: 'Vazirmatn',
          fontSize:
              (title == 'توقفات' || title == 'تولیدات' || title == 'شاخص ها')
                  ? 16
                  : (isMainCategory ? 14 : 12),
          fontWeight:
              (title == 'توقفات' || title == 'تولیدات' || title == 'شاخص ها')
                  ? FontWeight.bold
                  : (isMainCategory ? FontWeight.bold : FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildDataRow(
      String title, String actual, String planned, String deviation,
      {bool isTotal = false, Color? rowColor, double? customFontSize}) {
    final isPositive = !deviation.startsWith('-');
    final deviationColor = isPositive ? Colors.green : Colors.red;

    return Container(
      decoration: BoxDecoration(
        color: rowColor,
        border: const Border(
          bottom: BorderSide(color: Colors.grey, width: 0.5),
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            _buildDataCell(title,
                flex: 3, isBold: isTotal, customFontSize: customFontSize),
            _buildDataCell(actual,
                flex: 3, isBold: isTotal, customFontSize: customFontSize),
            _buildDataCell(planned,
                flex: 2, isBold: isTotal, customFontSize: customFontSize),
            _buildDataCell(deviation,
                flex: 2,
                textColor: deviationColor,
                isBold: isTotal,
                customFontSize: customFontSize),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCell(String title, {int flex = 1}) {
    return Expanded(
      flex: title == 'عناوین' ? 4 : flex,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: const BoxDecoration(
          border: Border(
            left: BorderSide(color: Colors.grey, width: 0.5),
          ),
        ),
        child: Text(
          title,
          textAlign: title == 'عناوین' ? TextAlign.right : TextAlign.center,
          style: TextStyle(
            fontFamily: 'Vazirmatn',
            fontSize: title == 'انحراف از برنامه' ? 9 : 12,
            fontWeight: FontWeight.bold,
            height: title == 'انحراف از برنامه' ? 1.2 : 1.0,
          ),
          maxLines: title == 'انحراف از برنامه' ? 2 : 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildDataCell(String content,
      {int flex = 1,
      Color? textColor,
      bool isBold = false,
      double? customFontSize}) {
    return Expanded(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: const BoxDecoration(
          border: Border(
            left: BorderSide(color: Colors.grey, width: 0.5),
          ),
        ),
        child: Text(
          content,
          textAlign: flex == 4 ? TextAlign.right : TextAlign.center,
          style: TextStyle(
            fontFamily: 'Vazirmatn',
            fontSize: customFontSize ?? 10,
            color: textColor ?? Colors.black,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildDownloadButton() {
    return GeneralBox(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      child: ElevatedButton.icon(
        onPressed: _generatePDF,
        icon: const Icon(Icons.picture_as_pdf),
        label: const Text(
          'دانلود فایل PDF',
          style: TextStyle(
            fontFamily: 'Vazirmatn',
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Future<void> _generatePDF() async {
    try {
      // تولید فایل PDF گزارش کلی
      final pdfFile = await PdfReportService.generateGeneralReportPdf(
        reportData: _reportData,
        sortedStops: _sortedStops,
        startDate: _startDate!,
        endDate: _endDate!,
      );
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PdfPreviewScreen(
            pdfFile: pdfFile,
            title: 'گزارش کلی تولید و توقفات',
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'خطا در باز کردن صفحه پیش‌نمایش: ${e.toString()}',
              style: const TextStyle(fontFamily: 'Vazirmatn'),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// محاسبه توقفات از StopData (دیتابیس جداگانه توقفات)
  Future<Map<String, dynamic>> _calculateStopsFromStopData(
      DateTime startDate, DateTime endDate) async {
    try {
      final stopBox = await Hive.openBox<StopData>('stopData');
      final allStopData = stopBox.values.toList();

      // تبدیل تاریخ‌ها به Jalali
      final startShamsi = Jalali.fromDateTime(startDate);
      final endShamsi = Jalali.fromDateTime(endDate);

      print('=== دیباگ محاسبه توقفات از StopData ===');
      print(
          'بازه زمانی: ${startShamsi.year}/${startShamsi.month}/${startShamsi.day} تا ${endShamsi.year}/${endShamsi.month}/${endShamsi.day}');
      print('تعداد کل توقفات در دیتابیس: ${allStopData.length}');

      // نمایش نمونه توقفات موجود در دیتابیس
      if (allStopData.isNotEmpty) {
        print('نمونه توقفات موجود در دیتابیس:');
        for (int i = 0;
            i < (allStopData.length > 5 ? 5 : allStopData.length);
            i++) {
          final stop = allStopData[i];
          print(
              '  ${i + 1}. ${stop.year}/${stop.month}/${stop.day} - ${stop.stopType} - ${stop.stopDuration} دقیقه');
        }
        if (allStopData.length > 5) {
          print('  ... و ${allStopData.length - 5} توقف دیگر');
        }

        // بررسی توزیع سال‌های موجود در توقفات
        Map<int, int> yearDistribution = {};
        for (var stop in allStopData) {
          yearDistribution[stop.year] = (yearDistribution[stop.year] ?? 0) + 1;
        }
        print('توزیع سال‌های توقفات موجود: $yearDistribution');

        // بررسی توقفات سال 1404
        final stops1404 =
            allStopData.where((stop) => stop.year == 1404).toList();
        print('تعداد توقفات سال 1404: ${stops1404.length}');

        if (stops1404.isNotEmpty) {
          print('نمونه توقفات سال 1404:');
          for (int i = 0;
              i < (stops1404.length > 3 ? 3 : stops1404.length);
              i++) {
            final stop = stops1404[i];
            print(
                '  ${i + 1}. ${stop.year}/${stop.month}/${stop.day} - ${stop.stopType} - ${stop.stopDuration} دقیقه');
          }
        }
      }

      // فیلتر کردن توقفات بر اساس بازه زمانی - استفاده از منطق صحیح
      final filteredStops = allStopData.where((stop) {
        // تبدیل تاریخ توقف به Jalali برای مقایسه صحیح
        final stopJalali = Jalali(stop.year, stop.month, stop.day);

        // بررسی اینکه آیا توقف در بازه انتخابی است
        final isInRange = stopJalali >= startShamsi && stopJalali <= endShamsi;

        // دیباگ برای توقفات ماه 4 سال 1404
        if (stop.year == 1404 && stop.month == 4) {
          print(
              '  -> توقف: ${stop.year}/${stop.month}/${stop.day} - ${stop.stopType}');
          print('  -> در بازه: $isInRange');
        }

        return isInRange;
      }).toList();

      print('تعداد توقفات فیلتر شده: ${filteredStops.length}');

      // محاسبه آمار توقفات
      Map<String, int> stopsByType = {};
      Map<String, int> stopsByTypeDuration = {};
      int totalStops = 0;
      int totalStopDuration = 0;

      for (var stop in filteredStops) {
        final stopType = stop.stopType;

        // تعداد توقفات
        stopsByType[stopType] = (stopsByType[stopType] ?? 0) + 1;

        // مدت توقفات
        stopsByTypeDuration[stopType] =
            (stopsByTypeDuration[stopType] ?? 0) + stop.stopDuration.toInt();

        totalStops++;
        totalStopDuration += stop.stopDuration.toInt();
      }

      print('توقفات بر اساس نوع: $stopsByType');
      print('مدت توقفات بر اساس نوع: $stopsByTypeDuration');
      print('کل توقفات: $totalStops');
      print('کل مدت توقفات: $totalStopDuration دقیقه');
      print('==========================================');

      return {
        'stopsByType': stopsByType,
        'stopsByTypeDuration': stopsByTypeDuration,
        'totalStops': totalStops,
        'totalStopDuration': totalStopDuration,
      };
    } catch (e) {
      print('خطا در محاسبه توقفات از StopData: $e');
      return {
        'stopsByType': <String, int>{},
        'stopsByTypeDuration': <String, int>{},
        'totalStops': 0,
        'totalStopDuration': 0,
      };
    }
  }
}
