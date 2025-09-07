import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/data_provider.dart';
import '../services/number_format_service.dart';
import '../services/production_analysis_service.dart';
import '../services/navigation_service.dart';
import '../models/production_data.dart';
import '../models/stop_data.dart';
import '../config/stops_screen_styles.dart';
import '../config/app_colors.dart';
import '../config/standard_page_config.dart';
import '../widgets/stops_widgets.dart';
import 'package:hive/hive.dart';

class IndicatorsScreen extends StatefulWidget {
  const IndicatorsScreen({super.key});

  @override
  State<IndicatorsScreen> createState() => _IndicatorsScreenState();
}

class _IndicatorsScreenState extends State<IndicatorsScreen> {
  bool _isWeightRecoveryExpanded = false;
  bool _isTotalAvailabilityExpanded = false;
  bool _isEquipmentAvailabilityExpanded = false;
  bool _isMaintenanceExpanded = false;
  bool _areIconsEnabled = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      setState(() {
        _areIconsEnabled = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: StandardPageConfig.buildStandardPage(
        title: 'مدیریت شاخص‌های عملکرد',
        content: Consumer<DataProvider>(
          builder: (context, dataProvider, child) {
            final allProductionData = dataProvider.getProductionData();

            return FutureBuilder<Map<String, dynamic>>(
              future: _getCurrentMonthData(allProductionData),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final currentMonthData = snapshot.data ?? {
                  'totalInputTonnage': 0.0,
                  'totalProducedProduct': 0.0,
                  'weightRecovery': 0.0,
                  'totalAvailability': 0.0,
                  'equipmentAvailability': 0.0,
                  'maintenanceIndicators': {},
                  'hasData': false,
                };

                // بررسی وجود داده
                if (!currentMonthData['hasData']) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.data_usage,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'داده‌ای برای نمایش موجود نیست',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'لطفاً ابتدا داده‌ها را به‌روزرسانی کنید',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () async {
                            try {
                              final dataProvider = Provider.of<DataProvider>(
                                  context, listen: false);
                              await dataProvider.refreshData();
                              if (mounted) {
                                // بررسی اینکه آیا خطایی وجود دارد یا نه
                                final error = dataProvider.error;
                                if (error == null || error.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'داده‌ها با موفقیت به‌روزرسانی شدند'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          'خطا در به‌روزرسانی: $error'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('خطا در به‌روزرسانی: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                          icon: const Icon(Icons.sync),
                          label: const Text('به‌روزرسانی داده‌ها'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // کارت قابلیت دسترسی کل
                      _buildTotalAvailabilityCard(currentMonthData),
                      const SizedBox(height: 16),

                      // کارت قابلیت دسترسی تجهیزات
                      _buildEquipmentAvailabilityCard(currentMonthData),
                      const SizedBox(height: 16),

                      // کارت ریکاوری وزنی
                      _buildWeightRecoveryCard(currentMonthData),
                      const SizedBox(height: 16),

                      // کارت شاخص‌های نت
                      _buildMaintenanceIndicatorsCard(currentMonthData),
                      const SizedBox(height: 16),

                      // کامپوننت تست آمار کلی
                      _buildTestSummaryGrid(currentMonthData),
                      const SizedBox(height: 24),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  // محاسبه داده‌های ماه جاری
  Future<Map<String, dynamic>> _getCurrentMonthData(
      List<dynamic> allData) async {
    if (allData.isEmpty) {
      return {
        'totalInputTonnage': 0.0,
        'totalProducedProduct': 0.0,
        'weightRecovery': 0.0,
        'totalAvailability': 0.0,
        'equipmentAvailability': 0.0,
        'maintenanceIndicators': {},
        'hasData': false,
      };
    }

    // یافتن آخرین تاریخ موجود در داده‌ها
    allData.sort((a, b) => DateTime(a.year, a.month, a.day)
        .compareTo(DateTime(b.year, b.month, b.day)));

    final latestData = allData.last;
    final currentYear = latestData.year;
    final currentMonth = latestData.month;

    // فیلتر کردن داده‌های ماه جاری
    final currentMonthData = allData.where((data) {
      return data.year == currentYear && data.month == currentMonth;
    }).toList();

    if (currentMonthData.isEmpty) {
      return {
        'totalInputTonnage': 0.0,
        'totalProducedProduct': 0.0,
        'weightRecovery': 0.0,
        'totalAvailability': 0.0,
        'equipmentAvailability': 0.0,
        'maintenanceIndicators': {},
        'hasData': false,
      };
    }

    // محاسبه تعداد روزهای ماه
    final daysInMonth = DateTime(currentYear, currentMonth + 1, 0).day;
    final totalDays = currentMonthData.map((data) => data.day).toSet().length;

    // استفاده از ProductionAnalysisService برای محاسبه صحیح
    final productionStats =
        ProductionAnalysisService.calculateProductionStatistics(
            currentMonthData.cast<ProductionData>());
    double totalInputTonnage = productionStats['totalInputTonnage'];
    double totalProducedProduct = productionStats['totalProducedProduct'];

    // محاسبه ریکاوری وزنی
    double weightRecovery = 0.0;
    if (totalInputTonnage > 0) {
      weightRecovery = (totalProducedProduct / totalInputTonnage) * 100;
    }

    // محاسبه قابلیت دسترسی کل - استفاده از StopData
    double totalAvailability = await _calculateTotalAvailabilityFromStopData(
        currentYear, currentMonth, totalDays);

    // محاسبه قابلیت دسترسی تجهیزات - استفاده از StopData
    double equipmentAvailability =
        await _calculateEquipmentAvailabilityFromStopData(
            currentYear, currentMonth, totalDays);

    // محاسبه شاخص‌های نت - استفاده از StopData
    Map<String, dynamic> maintenanceIndicators =
        await _calculateMaintenanceIndicatorsFromStopData(
            currentYear, currentMonth, totalDays);

    return {
      'totalInputTonnage': totalInputTonnage,
      'totalProducedProduct': totalProducedProduct,
      'weightRecovery': weightRecovery,
      'totalAvailability': totalAvailability,
      'equipmentAvailability': equipmentAvailability,
      'maintenanceIndicators': maintenanceIndicators,
      'hasData': true,
      'year': currentYear,
      'month': currentMonth,
      'totalDays': totalDays,
    };
  }

  // محاسبه شاخص‌های نت از StopData
  Future<Map<String, dynamic>> _calculateMaintenanceIndicatorsFromStopData(
      int year, int month, int totalDays) async {
    try {
      final stopBox = await Hive.openBox<StopData>('stopData');
      final allStopData = stopBox.values.toList();

      // فیلتر کردن توقفات ماه جاری
      final monthStopData = allStopData.where((stop) {
        return stop.year == year && stop.month == month;
      }).toList();

      print('=== دیباگ محاسبه شاخص‌های نت از StopData ===');
      print('سال: $year, ماه: $month, روزها: $totalDays');
      print('تعداد توقفات ماه جاری: ${monthStopData.length}');

      if (totalDays <= 0) {
        return {
          'mttr': 0.0, // Mean Time To Repair
          'mtbf': 0.0, // Mean Time Between Failures
          'maintenanceEfficiency': 0.0,
          'emergencyStops': 0,
          'plannedStops': 0,
          'totalStops': 0,
          'totalEmergencyHours': 0.0,
          'totalPlannedHours': 0.0,
        };
      }

      int emergencyStops = 0;
      int plannedStops = 0;
      double totalEmergencyHours = 0.0;
      double totalPlannedHours = 0.0;

      // انواع توقفات اضطراری
      final emergencyStopTypes = ['مکانیکی', 'برقی', 'تاسیساتی'];

      for (var stop in monthStopData) {
        final stopHours = stop.stopDuration / 60.0;

        if (emergencyStopTypes.contains(stop.stopType)) {
          emergencyStops++;
          totalEmergencyHours += stopHours;
        } else {
          plannedStops++;
          totalPlannedHours += stopHours;
        }
      }

      // محاسبه MTTR (Mean Time To Repair)
      double mttr =
          emergencyStops > 0 ? totalEmergencyHours / emergencyStops : 0.0;

      // محاسبه MTBF (Mean Time Between Failures)
      final totalWorkingHours = totalDays * 3 * 8.0; // 3 شیفت × 8 ساعت
      double mtbf =
          emergencyStops > 0 ? totalWorkingHours / emergencyStops : 0.0;

      // محاسبه کارایی نگهداری
      double maintenanceEfficiency = 0.0;
      if (totalEmergencyHours + totalPlannedHours > 0) {
        maintenanceEfficiency =
            (totalPlannedHours / (totalEmergencyHours + totalPlannedHours)) *
                100;
      }

      print('توقفات اضطراری: $emergencyStops');
      print('توقفات برنامه‌ای: $plannedStops');
      print('ساعات توقفات اضطراری: ${totalEmergencyHours.toStringAsFixed(2)}');
      print('ساعات توقفات برنامه‌ای: ${totalPlannedHours.toStringAsFixed(2)}');
      print('MTTR: ${mttr.toStringAsFixed(2)} ساعت');
      print('MTBF: ${mtbf.toStringAsFixed(2)} ساعت');
      print('کارایی نگهداری: ${maintenanceEfficiency.toStringAsFixed(2)}%');
      print('==========================================');

      return {
        'mttr': mttr,
        'mtbf': mtbf,
        'maintenanceEfficiency': maintenanceEfficiency,
        'emergencyStops': emergencyStops,
        'plannedStops': plannedStops,
        'totalStops': emergencyStops + plannedStops,
        'totalEmergencyHours': totalEmergencyHours,
        'totalPlannedHours': totalPlannedHours,
      };
    } catch (e) {
      print('خطا در محاسبه شاخص‌های نت: $e');
      return {
        'mttr': 0.0,
        'mtbf': 0.0,
        'maintenanceEfficiency': 0.0,
        'emergencyStops': 0,
        'plannedStops': 0,
        'totalStops': 0,
        'totalEmergencyHours': 0.0,
        'totalPlannedHours': 0.0,
      };
    }
  }

  Widget _buildTotalAvailabilityCard(Map<String, dynamic> monthData) {
    return StopsCard(
      title: 'قابلیت دسترسی کل',
      onTap: () {
        setState(() {
          _isTotalAvailabilityExpanded = !_isTotalAvailabilityExpanded;
        });
      },
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.access_time,
                  color: Colors.green[700],
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // حذف عنوان
                    Text(
                      monthData['hasData']
                          ? '${monthData['totalAvailability'].toStringAsFixed(1)}%'
                          : 'داده‌ای موجود نیست',
                      style: TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: monthData['hasData']
                            ? Colors.green[700]
                            : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ماه جاری',
                      style: TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                _isTotalAvailabilityExpanded
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down,
                color: Colors.grey[600],
                size: 24,
              ),
            ],
          ),
          if (_isTotalAvailabilityExpanded) ...[
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (monthData['hasData']) ...[
                      Row(
                        children: [
                          Expanded(
                            child: _buildDetailItem(
                              'تعداد روزها',
                              '${monthData['totalDays']} روز',
                              Colors.green,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildDetailItem(
                              'ساعات کاری کل',
                              '${(monthData['totalDays'] * 3 * 8).toStringAsFixed(0)} ساعت',
                              Colors.blue,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green[200]!),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'قابلیت دسترسی کل:',
                              style: TextStyle(
                                fontFamily: 'Vazirmatn',
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                            Text(
                              '${monthData['totalAvailability'].toStringAsFixed(1)}%',
                              style: const TextStyle(
                                fontFamily: 'Vazirmatn',
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(
                          child: Text(
                            'داده‌ای برای محاسبه موجود نیست',
                            style: TextStyle(
                              fontFamily: 'Vazirmatn',
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEquipmentAvailabilityCard(Map<String, dynamic> monthData) {
    return StopsCard(
      title: 'قابلیت دسترسی تجهیزات',
      onTap: () {
        setState(() {
          _isEquipmentAvailabilityExpanded = !_isEquipmentAvailabilityExpanded;
        });
      },
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[100],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.precision_manufacturing,
                  color: Colors.orange[700],
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // حذف عنوان
                    Text(
                      monthData['hasData']
                          ? '${monthData['equipmentAvailability'].toStringAsFixed(1)}%'
                          : 'داده‌ای موجود نیست',
                      style: TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: monthData['hasData']
                            ? Colors.orange[700]
                            : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ماه جاری',
                      style: TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontSize: 10,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                _isEquipmentAvailabilityExpanded
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down,
                color: Colors.grey[600],
                size: 24,
              ),
            ],
          ),
          if (_isEquipmentAvailabilityExpanded) ...[
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (monthData['hasData']) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange[200]!),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'قابلیت دسترسی تجهیزات:',
                              style: TextStyle(
                                fontFamily: 'Vazirmatn',
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange,
                              ),
                            ),
                            Text(
                              '${monthData['equipmentAvailability'].toStringAsFixed(1)}%',
                              style: const TextStyle(
                                fontFamily: 'Vazirmatn',
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'توضیحات:',
                        style: TextStyle(
                          fontFamily: 'Vazirmatn',
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'این شاخص نشان‌دهنده درصد زمان کارکرد تجهیزات نسبت به زمان در دسترس فنی (بدون توقفات غیرفنی) است.',
                        style: TextStyle(
                          fontFamily: 'Vazirmatn',
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                      ),
                    ] else ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(
                          child: Text(
                            'داده‌ای برای محاسبه موجود نیست',
                            style: TextStyle(
                              fontFamily: 'Vazirmatn',
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWeightRecoveryCard(Map<String, dynamic> monthData) {
    return StopsCard(
      title: 'ریکاوری وزنی',
      onTap: () {
        setState(() {
          _isWeightRecoveryExpanded = !_isWeightRecoveryExpanded;
        });
      },
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.analytics,
                  color: Colors.blue[700],
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      monthData['hasData']
                          ? '${monthData['weightRecovery'].toStringAsFixed(1)}%'
                          : 'داده‌ای موجود نیست',
                      style: TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: monthData['hasData']
                            ? Colors.blue[700]
                            : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ماه جاری',
                      style: TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontSize: 10,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                _isWeightRecoveryExpanded
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down,
                color: Colors.grey[600],
                size: 24,
              ),
            ],
          ),
          if (_isWeightRecoveryExpanded) ...[
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (monthData['hasData']) ...[
                      Row(
                        children: [
                          Expanded(
                            child: _buildDetailItem(
                              'خوراک ورودی',
                              '${NumberFormatService.formatNumber(monthData['totalInputTonnage'])} تن',
                              Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildDetailItem(
                              'محصول تولید شده',
                              '${NumberFormatService.formatNumber(monthData['totalProducedProduct'])} تن',
                              Colors.green,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue[200]!),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'ریکاوری وزنی:',
                              style: TextStyle(
                                fontFamily: 'Vazirmatn',
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                            Text(
                              '${monthData['weightRecovery'].toStringAsFixed(1)}%',
                              style: const TextStyle(
                                fontFamily: 'Vazirmatn',
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(
                          child: Text(
                            'داده‌ای برای محاسبه موجود نیست',
                            style: TextStyle(
                              fontFamily: 'Vazirmatn',
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMaintenanceIndicatorsCard(Map<String, dynamic> monthData) {
    final maintenanceData =
        monthData['maintenanceIndicators'] as Map<String, dynamic>;

    return StopsCard(
      title: 'شاخص‌های نت',
      onTap: () {
        setState(() {
          _isMaintenanceExpanded = !_isMaintenanceExpanded;
        });
      },
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.purple[100],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.build,
                  color: Colors.purple[700],
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      monthData['hasData']
                          ? '${maintenanceData['maintenanceEfficiency'].toStringAsFixed(1)}% کارایی'
                          : 'داده‌ای موجود نیست',
                      style: TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: monthData['hasData']
                            ? Colors.purple[700]
                            : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ماه جاری',
                      style: TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontSize: 10,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                _isMaintenanceExpanded
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down,
                color: Colors.grey[600],
                size: 24,
              ),
            ],
          ),
          if (_isMaintenanceExpanded) ...[
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (monthData['hasData']) ...[
                      Row(
                        children: [
                          Expanded(
                            child: _buildDetailItem(
                              'توقفات اضطراری',
                              '${maintenanceData['emergencyStops']} مورد',
                              Colors.red,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildDetailItem(
                              'توقفات برنامه‌ای',
                              '${maintenanceData['plannedStops']} مورد',
                              Colors.green,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildDetailItem(
                              'MTTR',
                              '${maintenanceData['mttr'].toStringAsFixed(1)} ساعت',
                              Colors.orange,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildDetailItem(
                              'MTBF',
                              '${maintenanceData['mtbf'].toStringAsFixed(1)} ساعت',
                              Colors.blue,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.purple[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.purple[200]!),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'کارایی نگهداری:',
                              style: TextStyle(
                                fontFamily: 'Vazirmatn',
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.purple,
                              ),
                            ),
                            Text(
                              '${maintenanceData['maintenanceEfficiency'].toStringAsFixed(1)}%',
                              style: const TextStyle(
                                fontFamily: 'Vazirmatn',
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.purple,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'توضیحات شاخص‌ها:',
                        style: TextStyle(
                          fontFamily: 'Vazirmatn',
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '• MTTR: میانگین زمان تعمیر (ساعت)\n• MTBF: میانگین زمان بین خرابی‌ها (ساعت)\n• کارایی نگهداری: نسبت توقفات برنامه‌ای به کل توقفات',
                        style: TextStyle(
                          fontFamily: 'Vazirmatn',
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ] else ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(
                          child: Text(
                            'داده‌ای برای محاسبه موجود نیست',
                            style: TextStyle(
                              fontFamily: 'Vazirmatn',
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Vazirmatn',
              fontSize: 12,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Vazirmatn',
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // محاسبه قابلیت دسترسی کل از StopData
  Future<double> _calculateTotalAvailabilityFromStopData(
      int year, int month, int totalDays) async {
    try {
      final stopBox = await Hive.openBox<StopData>('stopData');
      final allStopData = stopBox.values.toList();

      // فیلتر کردن توقفات ماه جاری
      final monthStopData = allStopData.where((stop) {
        return stop.year == year && stop.month == month;
      }).toList();

      print('=== دیباگ محاسبه دسترسی کل از StopData ===');
      print('سال: $year, ماه: $month, روزها: $totalDays');
      print('تعداد کل توقفات: ${allStopData.length}');
      print('تعداد توقفات ماه جاری: ${monthStopData.length}');

      if (totalDays <= 0) return 0.0;

      // محاسبه شیفت‌های کاری واقعی (3 شیفت در روز، 8 ساعت هر شیفت)
      final totalWorkingHours = totalDays * 3 * 8.0; // 3 شیفت × 8 ساعت

      double totalStopHours = 0.0;
      for (var stop in monthStopData) {
        final stopHours = stop.stopDuration / 60.0;
        totalStopHours += stopHours;

        if (monthStopData.length <= 10) {
          print(
              'توقف: ${stop.stopType} - ${stop.stopDuration} دقیقه (${stopHours.toStringAsFixed(2)} ساعت)');
        }
      }

      print('مجموع ساعات توقف: ${totalStopHours.toStringAsFixed(2)}');
      print('ساعات کاری کل: ${totalWorkingHours.toStringAsFixed(2)}');

      if (totalWorkingHours == 0) return 0.0;

      final availability =
          ((totalWorkingHours - totalStopHours) / totalWorkingHours) * 100;
      final result = availability.clamp(0.0, 100.0);

      print('دسترسی کل محاسبه شده: ${result.toStringAsFixed(2)}%');
      print('==========================================');

      return result;
    } catch (e) {
      print('خطا در محاسبه دسترسی کل: $e');
      return 0.0;
    }
  }

  // محاسبه قابلیت دسترسی تجهیزات از StopData
  Future<double> _calculateEquipmentAvailabilityFromStopData(
      int year, int month, int totalDays) async {
    try {
      final stopBox = await Hive.openBox<StopData>('stopData');
      final allStopData = stopBox.values.toList();

      // فیلتر کردن توقفات ماه جاری
      final monthStopData = allStopData.where((stop) {
        return stop.year == year && stop.month == month;
      }).toList();

      print('=== دیباگ محاسبه دسترسی تجهیزات از StopData ===');
      print('سال: $year, ماه: $month, روزها: $totalDays');
      print('تعداد توقفات ماه جاری: ${monthStopData.length}');

      if (totalDays <= 0) return 0.0;

      // محاسبه شیفت‌های کاری واقعی (3 شیفت در روز، 8 ساعت هر شیفت)
      final totalWorkingHours = totalDays * 3 * 8.0; // 3 شیفت × 8 ساعت

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

      for (var stop in monthStopData) {
        final stopHours = stop.stopDuration / 60.0;
        totalStopHours += stopHours;

        if (nonTechnicalStopTypes.contains(stop.stopType)) {
          nonTechnicalStopHours += stopHours;
        }
      }

      print(
          'مجموع توقفات غیرفنی: ${nonTechnicalStopHours.toStringAsFixed(2)} ساعت');
      print('مجموع کل توقفات: ${totalStopHours.toStringAsFixed(2)} ساعت');

      // محاسبه زمان در دسترس فنی
      final availableForTechnicalWork =
          totalWorkingHours - nonTechnicalStopHours;

      print(
          'زمان در دسترس فنی: ${availableForTechnicalWork.toStringAsFixed(2)} ساعت');

      if (availableForTechnicalWork <= 0) return 0.0;

      // محاسبه دسترسی تجهیزات: (زمان فنی - توقفات فنی) / زمان فنی
      final technicalStopHours = totalStopHours - nonTechnicalStopHours;
      final equipmentAvailability =
          ((availableForTechnicalWork - technicalStopHours) /
                  availableForTechnicalWork) *
              100;

      final result = equipmentAvailability.clamp(0.0, 100.0);

      print('توقفات فنی: ${technicalStopHours.toStringAsFixed(2)} ساعت');
      print('دسترسی تجهیزات محاسبه شده: ${result.toStringAsFixed(2)}%');
      print('==========================================');

      return result;
    } catch (e) {
      print('خطا در محاسبه دسترسی تجهیزات: $e');
      return 0.0;
    }
  }

  // کامپوننت تست آمار کلی
  Widget _buildTestSummaryGrid(Map<String, dynamic> monthData) {
    final stats = {
      'تناژ ورودی':
          '${NumberFormatService.formatNumber(monthData['totalInputTonnage'])} تن',
      'تناژ محصول':
          '${NumberFormatService.formatNumber(monthData['totalProducedProduct'])} تن',
      'ریکاوری وزنی': '${monthData['weightRecovery'].toStringAsFixed(1)}%',
      'دسترسی کل': '${monthData['totalAvailability'].toStringAsFixed(1)}%',
    };

    final valueColors = {
      'تناژ ورودی': Colors.blue,
      'تناژ محصول': Colors.green,
      'ریکاوری وزنی': Colors.orange,
      'دسترسی کل': Colors.purple,
    };

    final icons = {
      'تناژ ورودی': Icons.input,
      'تناژ محصول': Icons.output,
      'ریکاوری وزنی': Icons.percent,
      'دسترسی کل': Icons.access_time,
    };

    return StopsSummaryGrid(
      stats: stats,
      valueColors: valueColors,
      icons: icons,
    );
  }
}
