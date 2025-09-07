import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import '../config/app_colors.dart';
import '../config/standard_page_config.dart';
import '../providers/data_provider.dart';
import '../services/data_sync_service.dart';
import '../services/number_format_service.dart';
import '../services/production_analysis_service.dart';
import '../services/navigation_service.dart';
import '../models/production_data.dart';
import '../widgets/page_header.dart';
import 'quality_performance_screen.dart';
import 'general_report_screen.dart';
import 'feed_input_screen.dart';
import 'product_screen.dart';
import 'tailing_screen.dart';

class ProductionScreen extends StatefulWidget {
  const ProductionScreen({super.key});

  @override
  State<ProductionScreen> createState() => _ProductionScreenState();
}

class _ProductionScreenState extends State<ProductionScreen> {
  // محاسبه داده‌های ماه جاری
  Map<String, dynamic> _getCurrentMonthData(List<ProductionData> allData) {
    if (allData.isEmpty) {
      print('=== خطا: هیچ داده‌ای موجود نیست ===');
      return {
        'totalInputTonnage': 0.0,
        'totalProducedProduct': 0.0,
        'totalWaste': 0.0,
        'startDate': '',
        'endDate': '',
        'hasData': false,
        'daysInRange': 0,
      };
    }

    // استفاده از تاریخ واقعی ماه جاری (1404/4)
    final currentYear = 1404;
    final currentMonth = 4;

    // حذف دیباگ‌های اضافی برای بهبود عملکرد

    // فیلتر کردن داده‌های ماه جاری - تمام رکوردهای ماه جاری
    final currentMonthData = allData.where((data) {
      return data.year == currentYear && data.month == currentMonth;
    }).toList();

    // برای دیباگ
    print('جستجو برای سال: $currentYear، ماه: $currentMonth');
    print('تعداد کل داده‌ها: ${allData.length}');
    print(
        'تعداد داده‌های ماه جاری با inputTonnage > 0: ${currentMonthData.length}');

    // دیباگ: بررسی تمام ماه‌های موجود
    Map<String, int> monthDistribution = {};
    for (var data in allData) {
      String monthKey = '${data.year}/${data.month}';
      monthDistribution[monthKey] = (monthDistribution[monthKey] ?? 0) + 1;
    }
    print('توزیع ماه‌های موجود: $monthDistribution');

    // دیباگ: بررسی دقیق ماه جاری
    final currentMonthAllData = allData
        .where((data) => data.year == currentYear && data.month == currentMonth)
        .toList();

    print('=== دیباگ دقیق ماه جاری ===');
    print('سال جاری: $currentYear، ماه جاری: $currentMonth');
    print(
        'تعداد رکوردهای ماه جاری (قبل از فیلتر): ${currentMonthAllData.length}');

    // بررسی توزیع شیفت‌ها در ماه جاری
    Map<String, int> shiftDistribution = {};
    for (var data in currentMonthAllData) {
      shiftDistribution[data.shift] = (shiftDistribution[data.shift] ?? 0) + 1;
    }
    print('توزیع شیفت‌ها در ماه جاری: $shiftDistribution');

    // بررسی رکوردهای با inputTonnage > 0
    final productionRecords =
        currentMonthAllData.where((data) => data.inputTonnage > 0).toList();
    print('رکوردهای با inputTonnage > 0: ${productionRecords.length}');

    // بررسی توزیع شیفت‌ها در رکوردهای تولید
    Map<String, int> productionShiftDistribution = {};
    for (var data in productionRecords) {
      productionShiftDistribution[data.shift] =
          (productionShiftDistribution[data.shift] ?? 0) + 1;
    }
    print('توزیع شیفت‌ها در رکوردهای تولید: $productionShiftDistribution');
    print('=====================================');

    print('تعداد داده‌های ماه جاری: ${currentMonthData.length}');
    if (allData.isNotEmpty) {
      print(
          'نمونه داده: سال=${allData.first.year}, ماه=${allData.first.month}');
    }

    if (currentMonthData.isEmpty) {
      print('=== خطا: هیچ داده‌ای برای ماه جاری یافت نشد ===');
      return {
        'totalInputTonnage': 0.0,
        'totalProducedProduct': 0.0,
        'totalWaste': 0.0,
        'startDate': '',
        'endDate': '',
        'hasData': false,
        'daysInRange': 0,
      };
    }

    // یافتن آخرین تاریخ - از تمام رکوردهای ماه جاری
    currentMonthData.sort((a, b) => DateTime(a.year, a.month, a.day)
        .compareTo(DateTime(b.year, b.month, b.day)));
    final lastDate = currentMonthData.last;

    // تاریخ شروع: یکم همان ماه و سال آخرین تاریخ
    final firstDate = ProductionData(
      year: lastDate.year,
      month: lastDate.month,
      day: 1,
      shift: '1',
      shamsiDate:
          '${lastDate.year}/${lastDate.month.toString().padLeft(2, '0')}/01',
      stopDescription: '',
      equipmentName: '',
      subEquipment: '',
      stopReason: '',
      stopType: '',
      stopStartTime: '',
      stopEndTime: '',
      stopDuration: '0:00',
      serviceCount: 0,
      inputTonnage: 0,
      scale3: 0,
      scale4: 0,
      scale5: 0,
      group: 1,
      directFeed: 0,
    );

    // محاسبه تعداد روزهای موجود در بازه
    final firstDateTime =
        DateTime(firstDate.year, firstDate.month, firstDate.day);
    final lastDateTime = DateTime(lastDate.year, lastDate.month, lastDate.day);
    final daysInRange = lastDateTime.difference(firstDateTime).inDays + 1;

    // اصلاح شده: استفاده از تمام رکوردهای ماه جاری برای محاسبه آمار
    final productionData = currentMonthData;

    // استفاده از ProductionAnalysisService برای محاسبه صحیح
    final stats =
        ProductionAnalysisService.calculateProductionStatistics(productionData);

    // بررسی اینکه آیا shamsiDate خالی نیست
    final startDate = firstDate.shamsiDate.isNotEmpty
        ? firstDate.shamsiDate
        : '${firstDate.year}/${firstDate.month.toString().padLeft(2, '0')}/${firstDate.day.toString().padLeft(2, '0')}';

    final endDate = lastDate.shamsiDate.isNotEmpty
        ? lastDate.shamsiDate
        : '${lastDate.year}/${lastDate.month.toString().padLeft(2, '0')}/${lastDate.day.toString().padLeft(2, '0')}';

    return {
      'totalInputTonnage': stats['totalInputTonnage'],
      'totalProducedProduct': stats['totalProducedProduct'],
      'totalWaste': stats['totalWaste'],
      'startDate': startDate,
      'endDate': endDate,
      'hasData': true,
      'daysInRange': daysInRange,
      'year': currentYear,
      'month': currentMonth,
    };
  }

  // نمایش داده‌های روزانه ماه جاری - اصلاح شده برای استفاده از منطق صحیح
  void _printDailyProductionData(
      List<ProductionData> productionData, int year, int month) {
    print('=== داده‌های روزانه ماه جاری (${year}/${month}) ===');

    // گروه‌بندی بر اساس روز
    Map<int, List<ProductionData>> dailyData = {};
    for (var data in productionData) {
      if (!dailyData.containsKey(data.day)) {
        dailyData[data.day] = [];
      }
      dailyData[data.day]!.add(data);
    }

    // مرتب‌سازی روزها
    final sortedDays = dailyData.keys.toList()..sort();

    // نمایش داده‌های هر روز - استفاده از منطق صحیح
    for (int day in sortedDays) {
      final dayData = dailyData[day]!;

      // استفاده از ProductionAnalysisService برای محاسبه صحیح روزانه
      final dayStats =
          ProductionAnalysisService.calculateProductionStatistics(dayData);

      print(
          'روز ${day.toString().padLeft(2, '0')}: خوراک=${dayStats['totalInputTonnage'].toStringAsFixed(1)}, محصول=${dayStats['totalProducedProduct'].toStringAsFixed(1)}, باطله=${dayStats['totalWaste'].toStringAsFixed(1)}, شیفت‌ها=${dayStats['shiftsCount']}');
    }

    print('==========================================');
  }

  // محاسبه درصد انحراف
  double _calculateDeviationPercentage(double actual, double planned) {
    if (planned == 0) return 0;
    final deviation = ((actual - planned) / planned) * 100;

    // دیباگ محاسبه انحراف
    print('=== دیباگ محاسبه انحراف ===');
    print('واقعی: $actual');
    print('برنامه: $planned');
    print('انحراف: $deviation%');
    print('==========================');

    return deviation;
  }

  // دریافت برنامه سالانه برای ماه مشخص بر اساس تعداد روزهای گذشته
  Map<String, double> _getAnnualPlanForMonth(int month, int daysInRange) {
    // داده‌های برنامه سالانه - مطابق annual_plan_screen.dart
    final annualPlanData = [
      {
        'title': 'فید ورودی',
        'values': [
          223398,
          260568,
          260568,
          232248,
          260568,
          189768,
          250564,
          250564,
          250564,
          242894,
          242894,
          121380
        ]
      },
      {
        'title': 'محصول',
        'values': [
          160400,
          187088,
          187088,
          166754,
          187088,
          136254,
          179905,
          179905,
          179905,
          174398,
          174398,
          87151
        ]
      },
      {
        'title': 'باطله',
        'values': [
          62998,
          73480,
          73480,
          65494,
          73480,
          53515,
          70659,
          70659,
          70659,
          68496,
          68496,
          34229
        ]
      },
    ];

    // روزهای کاری و غیرکاری واقعی هر ماه
    final monthlyDays = [
      31.0, // فروردین
      31.0, // اردیبهشت
      31.0, // خرداد
      31.0, // تیر
      31.0, // مرداد
      31.0, // شهریور
      30.0, // مهر
      30.0, // آبان
      30.0, // آذر
      30.0, // دی
      30.0, // بهمن
      29.0 // اسفند
    ];

    if (month < 1 || month > 12 || daysInRange <= 0) {
      print('=== خطا در برنامه سالانه ===');
      print('ماه: $month (باید بین 1-12 باشد)');
      print('روزهای موجود: $daysInRange (باید > 0 باشد)');
      print('============================');
      return {
        'plannedFeed': 0.0,
        'plannedProduct': 0.0,
        'plannedWaste': 0.0,
      };
    }

    final monthIndex = month - 1; // تبدیل به index (0-11)

    // محاسبه نسبت بر اساس روزهای واقعی ماه
    final totalDaysInMonth = monthlyDays[monthIndex];
    final ratio = daysInRange / totalDaysInMonth;

    // برای دیباگ برنامه سالانه
    print('=== دیباگ برنامه سالانه ===');
    print('ماه: $month (index: $monthIndex)');
    print('روزهای موجود: $daysInRange');
    print('کل روزهای ماه: $totalDaysInMonth');
    print('نسبت: $ratio');
    print(
        'خوراک سالانه: ${(annualPlanData[0]['values'] as List<int>)[monthIndex]}');
    print(
        'محصول سالانه: ${(annualPlanData[1]['values'] as List<int>)[monthIndex]}');
    print(
        'باطله سالانه: ${(annualPlanData[2]['values'] as List<int>)[monthIndex]}');

    // محاسبه مقادیر برنامه
    final plannedFeed =
        (annualPlanData[0]['values'] as List<int>)[monthIndex].toDouble() *
            ratio;
    final plannedProduct =
        (annualPlanData[1]['values'] as List<int>)[monthIndex].toDouble() *
            ratio;
    final plannedWaste =
        (annualPlanData[2]['values'] as List<int>)[monthIndex].toDouble() *
            ratio;

    print('خوراک برنامه (محاسبه شده): $plannedFeed');
    print('محصول برنامه (محاسبه شده): $plannedProduct');
    print('باطله برنامه (محاسبه شده): $plannedWaste');
    print('==========================');

    return {
      'plannedFeed': plannedFeed,
      'plannedProduct': plannedProduct,
      'plannedWaste': plannedWaste,
    };
  }

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
        title: 'مدیریت تولید',
        content: Consumer<DataProvider>(
          builder: (context, dataProvider, child) {
            final allProductionData = dataProvider.getProductionData();

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // باکس اطلاعات کلی تولید ماه جاری
                  _buildCurrentMonthInfoBox(allProductionData),
                  const SizedBox(height: 24),

                  // باکس گزارش کلی (اندازه بزرگ)
                  _buildGeneralReportBox(),
                  const SizedBox(height: 16),

                  // چهار کارت اصلی
                  _buildMainCards(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCurrentMonthInfoBox(List<ProductionData> allProductionData) {
    final monthData = _getCurrentMonthData(allProductionData);

    if (!monthData['hasData']) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
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
        child: Column(
          children: [
            const Text(
              'داده‌ای برای ماه جاری موجود نیست',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Vazirmatn',
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'تعداد کل داده‌های تولید: ${allProductionData.length}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Vazirmatn',
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            if (allProductionData.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'نمونه داده: ${allProductionData.first.year}/${allProductionData.first.month}/${allProductionData.first.day}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ],
        ),
      );
    }

    return Stack(
      children: [
        // باکس اصلی اطلاعات کلی (بدون تغییر)
        Container(
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
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'اطلاعات کلی تولید ماه جاری',
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
                monthData['hasData'] &&
                        monthData['startDate'].isNotEmpty &&
                        monthData['endDate'].isNotEmpty
                    ? 'از تاریخ ${monthData['startDate']} الی ${monthData['endDate']}'
                    : 'ماه جاری (داده‌ای موجود نیست)',
                style: const TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 20),
              _buildProductionTable(monthData),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGeneralReportBox() {
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
      child: InkWell(
        onTap: () => _navigateToDetailPage('گزارش کلی'),
        borderRadius: BorderRadius.circular(24),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.feedColor, // رنگ کامل برای پس‌زمینه آیکن
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.feedColor.withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.analytics,
                    color: Colors.white, // آیکن سفید برای دیده شدن بهتر
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'گزارش کلی',
                  style: TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E3A59),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'مشاهده گزارش جامع تولید و توقفات',
              style: TextStyle(
                fontFamily: 'Vazirmatn',
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductionTable(Map<String, dynamic> monthData) {
    // محاسبه برنامه سالانه بر اساس ماه جاری و تعداد روزهای گذشته
    // استفاده از ماه شمسی از داده‌ها، نه ماه میلادی از سیستم
    final currentMonth = monthData['month'] ?? 4; // تیر ماه به عنوان پیش‌فرض
    final daysInRange = monthData['daysInRange'] ?? 0;

    final planData = _getAnnualPlanForMonth(currentMonth, daysInRange);
    final plannedFeed = planData['plannedFeed']!;
    final plannedProduct = planData['plannedProduct']!;
    final plannedWaste = planData['plannedWaste']!;

    // محاسبه میانگین عیار ماه جاری
    final gradeData = context.read<DataProvider>().getGradeData();
    final currentYear = 1404;
    final currentMonthGrade = currentMonth;

    // فیلتر داده‌های عیار ماه جاری
    final monthGradeData = gradeData.where((grade) {
      return grade.year == currentYear && grade.month == currentMonthGrade;
    }).toList();

    // محاسبه میانگین عیار برای هر نوع
    final feedGrades =
        monthGradeData.where((g) => g.gradeType == 'خوراک').toList();
    final productGrades =
        monthGradeData.where((g) => g.gradeType == 'محصول').toList();
    final wasteGrades =
        monthGradeData.where((g) => g.gradeType == 'باطله').toList();

    final avgFeedGrade = feedGrades.isNotEmpty
        ? feedGrades.map((g) => g.gradeValue).reduce((a, b) => a + b) /
            feedGrades.length
        : 0.0;
    final avgProductGrade = productGrades.isNotEmpty
        ? productGrades.map((g) => g.gradeValue).reduce((a, b) => a + b) /
            productGrades.length
        : 0.0;
    final avgWasteGrade = wasteGrades.isNotEmpty
        ? wasteGrades.map((g) => g.gradeValue).reduce((a, b) => a + b) /
            wasteGrades.length
        : 0.0;

    // برای دیباگ - بررسی اعداد
    print('=== دیباگ جدول تولید ===');
    print('ماه: $currentMonth');
    print('تعداد روزها: $daysInRange');
    print('خوراک واقعی: ${monthData['totalInputTonnage']}');
    print('محصول واقعی: ${monthData['totalProducedProduct']}');
    print('باطله واقعی: ${monthData['totalWaste']}');
    print('خوراک برنامه: $plannedFeed');
    print('محصول برنامه: $plannedProduct');
    print('باطله برنامه: $plannedWaste');

    // بررسی همخوانی اعداد
    print('=== بررسی همخوانی ===');
    print(
        'خوراک: واقعی=${monthData['totalInputTonnage']}, برنامه=$plannedFeed');
    print(
        'محصول: واقعی=${monthData['totalProducedProduct']}, برنامه=$plannedProduct');
    print('باطله: واقعی=${monthData['totalWaste']}, برنامه=$plannedWaste');

    // بررسی منطق محاسبات
    final actualFeed = monthData['totalInputTonnage'] as double;
    final actualProduct = monthData['totalProducedProduct'] as double;
    final actualWaste = monthData['totalWaste'] as double;

    // بررسی اینکه آیا محصول + باطله = خوراک
    final calculatedWaste = actualFeed - actualProduct;
    print(
        'محاسبه باطله: خوراک($actualFeed) - محصول($actualProduct) = $calculatedWaste');
    print('باطله واقعی: $actualWaste');
    print('تفاوت: ${actualWaste - calculatedWaste}');
    print('========================');

    // محاسبه درصد انحراف
    final feedDeviation =
        _calculateDeviationPercentage(actualFeed, plannedFeed);
    final productDeviation =
        _calculateDeviationPercentage(actualProduct, plannedProduct);
    final wasteDeviation =
        _calculateDeviationPercentage(actualWaste, plannedWaste);

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // ردیف عناوین ستون‌ها (واقعی، برنامه، انحراف)
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: Row(
              children: [
                // ستون اول برای عناوین ردیف‌ها
                Expanded(
                  flex: 3,
                  child: Container(),
                ),
                Expanded(
                  flex: 4,
                  child: const Text(
                    'واقعی',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: const Text(
                    'برنامه',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: const Text(
                    'انحراف',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ردیف خوراک
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            child: Column(
              children: [
                // ردیف اصلی خوراک
                Row(
                  children: [
                    // عنوان ردیف
                    Expanded(
                      flex: 3,
                      child: const Text(
                        'خوراک',
                        style: TextStyle(
                          fontFamily: 'Vazirmatn',
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    // مقدار واقعی
                    Expanded(
                      flex: 4,
                      child: Text(
                        NumberFormatService.formatNumber(
                            monthData['totalInputTonnage']),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Vazirmatn',
                          fontSize: 12,
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    // مقدار برنامه
                    Expanded(
                      flex: 4,
                      child: Text(
                        NumberFormatService.formatNumber(plannedFeed),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Vazirmatn',
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    // درصد انحراف
                    Expanded(
                      flex: 3,
                      child: _buildDeviationText(feedDeviation),
                    ),
                  ],
                ),
                // ردیف عیار خوراک
                const SizedBox(height: 4),
                Row(
                  children: [
                    // فضای خالی برای هم‌ترازی
                    Expanded(
                      flex: 3,
                      child: Container(),
                    ),
                    // عیار واقعی
                    Expanded(
                      flex: 4,
                      child: Text(
                        avgFeedGrade > 0
                            ? '${avgFeedGrade.toStringAsFixed(1)}%'
                            : '-',
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Vazirmatn',
                          fontSize: 11,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                    // عیار برنامه (30.0% ثابت)
                    Expanded(
                      flex: 4,
                      child: const Text(
                        '30.0%',
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Vazirmatn',
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    // انحراف عیار
                    Expanded(
                      flex: 3,
                      child: Text(
                        avgFeedGrade > 0
                            ? _calculateGradeDeviation(avgFeedGrade, 30.0)
                            : '-',
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Vazirmatn',
                          fontSize: 11,
                          color:
                              avgFeedGrade > 30.0 ? Colors.green : Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ردیف محصول
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            child: Column(
              children: [
                // ردیف اصلی محصول
                Row(
                  children: [
                    // عنوان ردیف
                    Expanded(
                      flex: 3,
                      child: const Text(
                        'محصول',
                        style: TextStyle(
                          fontFamily: 'Vazirmatn',
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    // مقدار واقعی
                    Expanded(
                      flex: 4,
                      child: Text(
                        NumberFormatService.formatNumber(
                            monthData['totalProducedProduct']),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Vazirmatn',
                          fontSize: 12,
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    // مقدار برنامه
                    Expanded(
                      flex: 4,
                      child: Text(
                        NumberFormatService.formatNumber(plannedProduct),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Vazirmatn',
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    // درصد انحراف
                    Expanded(
                      flex: 3,
                      child: _buildDeviationText(productDeviation),
                    ),
                  ],
                ),
                // ردیف عیار محصول
                const SizedBox(height: 4),
                Row(
                  children: [
                    // فضای خالی برای هم‌ترازی
                    Expanded(
                      flex: 3,
                      child: Container(),
                    ),
                    // عیار واقعی
                    Expanded(
                      flex: 4,
                      child: Text(
                        avgProductGrade > 0
                            ? '${avgProductGrade.toStringAsFixed(1)}%'
                            : '-',
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Vazirmatn',
                          fontSize: 11,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                    // عیار برنامه (37.0% ثابت)
                    Expanded(
                      flex: 4,
                      child: const Text(
                        '37.0%',
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Vazirmatn',
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    // انحراف عیار
                    Expanded(
                      flex: 3,
                      child: Text(
                        avgProductGrade > 0
                            ? _calculateGradeDeviation(avgProductGrade, 37.0)
                            : '-',
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Vazirmatn',
                          fontSize: 11,
                          color: avgProductGrade > 37.0
                              ? Colors.green
                              : Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ردیف باطله
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(8),
                bottomRight: Radius.circular(8),
              ),
            ),
            child: Column(
              children: [
                // ردیف اصلی باطله
                Row(
                  children: [
                    // عنوان ردیف
                    Expanded(
                      flex: 3,
                      child: const Text(
                        'باطله',
                        style: TextStyle(
                          fontFamily: 'Vazirmatn',
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    // مقدار واقعی
                    Expanded(
                      flex: 4,
                      child: Text(
                        NumberFormatService.formatNumber(
                            monthData['totalWaste']),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Vazirmatn',
                          fontSize: 12,
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    // مقدار برنامه
                    Expanded(
                      flex: 4,
                      child: Text(
                        NumberFormatService.formatNumber(plannedWaste),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Vazirmatn',
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    // درصد انحراف
                    Expanded(
                      flex: 3,
                      child: _buildDeviationText(wasteDeviation),
                    ),
                  ],
                ),
                // ردیف عیار باطله
                const SizedBox(height: 4),
                Row(
                  children: [
                    // فضای خالی برای هم‌ترازی
                    Expanded(
                      flex: 3,
                      child: Container(),
                    ),
                    // عیار واقعی
                    Expanded(
                      flex: 4,
                      child: Text(
                        avgWasteGrade > 0
                            ? '${avgWasteGrade.toStringAsFixed(1)}%'
                            : '-',
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Vazirmatn',
                          fontSize: 11,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                    // عیار برنامه (12.0% ثابت)
                    Expanded(
                      flex: 4,
                      child: const Text(
                        '12.0%',
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Vazirmatn',
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    // انحراف عیار
                    Expanded(
                      flex: 3,
                      child: Text(
                        avgWasteGrade > 0
                            ? _calculateGradeDeviation(avgWasteGrade, 12.0)
                            : '-',
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Vazirmatn',
                          fontSize: 11,
                          color:
                              avgWasteGrade > 12.0 ? Colors.green : Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableRow(String title, List<String> values, Color textColor) {
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
            child: Column(
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 12,
                    color: textColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  values[0],
                  style: TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 14,
                    color: textColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 12,
                    color: textColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  values[1],
                  style: TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 14,
                    color: textColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 12,
                    color: textColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  values[2],
                  style: TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 14,
                    color: textColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviationRow(
    double actualFeed,
    double plannedFeed,
    double actualProduct,
    double plannedProduct,
    double actualWaste,
    double plannedWaste,
  ) {
    final feedDeviation =
        _calculateDeviationPercentage(actualFeed, plannedFeed);
    final productDeviation =
        _calculateDeviationPercentage(actualProduct, plannedProduct);
    final wasteDeviation =
        _calculateDeviationPercentage(actualWaste, plannedWaste);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(8),
          bottomRight: Radius.circular(8),
        ),
      ),
      child: Row(
        children: [
          Expanded(child: _buildDeviationItem(feedDeviation)),
          Expanded(child: _buildDeviationItem(productDeviation)),
          Expanded(child: _buildDeviationItem(wasteDeviation)),
        ],
      ),
    );
  }

  Widget _buildDeviationText(double deviation) {
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
          size: 14,
        ),
        const SizedBox(width: 2),
        Flexible(
          child: Text(
            '${deviation.abs().toStringAsFixed(1)}%',
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Vazirmatn',
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  String _calculateGradeDeviation(double actual, double planned) {
    final deviation = actual - planned;
    final isPositive = deviation >= 0;
    final sign = isPositive ? '+' : '';
    return '$sign${deviation.toStringAsFixed(1)}%';
  }

  Widget _buildDeviationItem(double deviation) {
    final isPositive = deviation >= 0;
    final color = isPositive ? Colors.green : Colors.red;
    final icon = isPositive ? Icons.arrow_upward : Icons.arrow_downward;

    return Column(
      children: [
        const Text(
          'انحراف از برنامه',
          style: TextStyle(
            fontFamily: 'Vazirmatn',
            fontSize: 10,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: color,
              size: 18,
            ),
            const SizedBox(width: 4),
            Text(
              '${deviation.abs().toStringAsFixed(1)}%',
              style: TextStyle(
                fontFamily: 'Vazirmatn',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMainCards() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildCard(
                'محصول تولیدی',
                Icons.production_quantity_limits,
                AppColors.productColor
                    .withOpacity(0.3), // غیرفعال کردن با شفافیت
                () {
                  // غیرفعال شده - هیچ عملیاتی انجام نمی‌شود
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('این صفحه در حال توسعه است'),
                      backgroundColor: Colors.orange,
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildCard(
                'خوراک ورودی',
                Icons.input,
                AppColors.feedColor,
                () => _navigateToDetailPage('خوراک ورودی'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildCard(
                'باطله تولیدی',
                Icons.delete_outline,
                AppColors.tailingColor
                    .withOpacity(0.3), // غیرفعال کردن با شفافیت
                () {
                  // غیرفعال شده - هیچ عملیاتی انجام نمی‌شود
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('این صفحه در حال توسعه است'),
                      backgroundColor: Colors.orange,
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildCard(
                'عملکرد کیفی تولید',
                Icons.auto_awesome,
                AppColors.planColor,
                () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const QualityPerformanceScreen(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCard(
      String title, IconData icon, Color color, VoidCallback onTap) {
    // بررسی اینکه آیا آیکن غیرفعال است یا خیر
    final bool isDisabled = color.opacity < 0.5;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 90,
        decoration: BoxDecoration(
          color: isDisabled
              ? Colors.grey[100]
              : Colors.white, // پس‌زمینه خاکستری برای غیرفعال
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: isDisabled ? Colors.grey[300]! : Colors.grey[400]!,
              width: 1.5),
          boxShadow: [
            BoxShadow(
              color: isDisabled
                  ? Colors.grey.withOpacity(0.1)
                  : Colors.grey.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color, // رنگ کامل برای پس‌زمینه آیکن
                borderRadius: BorderRadius.circular(12),
                boxShadow: isDisabled
                    ? []
                    : [
                        BoxShadow(
                          color: color.withOpacity(0.4),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: Icon(
                icon,
                size: 24,
                color: isDisabled
                    ? Colors.grey[400]
                    : Colors.white, // آیکن خاکستری برای غیرفعال
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Vazirmatn',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDisabled
                    ? Colors.grey[500]
                    : const Color(0xFF2E3A59), // متن خاکستری برای غیرفعال
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToDetailPage(String pageTitle) {
    if (pageTitle == 'گزارش کلی') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const GeneralReportScreen(),
        ),
      );
    } else if (pageTitle == 'خوراک ورودی') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const FeedInputScreen(),
        ),
      );
    } else if (pageTitle == 'محصول تولیدی') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const ProductScreen(),
        ),
      );
    } else if (pageTitle == 'باطله تولیدی') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const TailingScreen(),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProductionDetailPage(title: pageTitle),
        ),
      );
    }
  }
}

class ProductionDetailPage extends StatelessWidget {
  final String title;

  const ProductionDetailPage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            title,
            style: const TextStyle(
              fontFamily: 'Vazirmatn',
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
        ),
        body: const Center(
          child: Text(
            'صفحه جزئیات در حال توسعه است',
            style: TextStyle(fontFamily: 'Vazirmatn'),
          ),
        ),
      ),
    );
  }
}
