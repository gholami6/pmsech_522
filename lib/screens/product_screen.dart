import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'dart:io';
import '../services/production_analysis_service.dart';
import '../services/planning_calculation_service.dart';
import '../services/pdf_report_service.dart';
import '../models/production_data.dart';
import '../widgets/summary_card.dart';
import '../widgets/page_header.dart';
import 'pdf_preview_screen.dart';
import '../config/app_colors.dart';
import '../services/number_format_service.dart';
import '../config/box_configs.dart';

class ProductScreen extends StatefulWidget {
  const ProductScreen({Key? key}) : super(key: key);

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  DateTime? startDate;
  DateTime? endDate;
  String selectedTimeRange = 'روزانه';
  bool isLoading = false;
  List<ProductData> productData = [];
  Map<String, double> summaryStats = {};
  bool _isFilterCollapsed = true; // حالت اولیه: فیلترها باز باشند

  final List<String> timeRanges = ['روزانه', 'هفتگی', 'ماهانه', 'شیفتی'];

  @override
  void initState() {
    super.initState();
    _initializeDefaultDates();
  }

  void _initializeDefaultDates() async {
    // منطق ماه جاری: آخرین تاریخ دیتا را بگیر و از اول همان ماه تا آخرین تاریخ
    final latestData =
        await ProductionAnalysisService.getLatestProductionDate();

    if (latestData != null) {
      try {
        // تبدیل به شمسی
        final persianDate = Jalali.fromDateTime(latestData);
        // اول ماه - با بررسی محدوده معتبر
        final firstOfMonth = Jalali(persianDate.year, persianDate.month, 1);

        setState(() {
          startDate = firstOfMonth.toDateTime();
          endDate = latestData;
        });
      } catch (e) {
        // در صورت خطا، از تاریخ پیش‌فرض استفاده کن
        _setDefaultDates();
      }
    } else {
      // اگر دیتایی نباشد، از تاریخ پیش‌فرض استفاده کن
      _setDefaultDates();
    }

    // بارگذاری داده‌ها پس از تنظیم تاریخ‌ها
    await _loadProductData();
  }

  void _setDefaultDates() {
    // تنظیم تاریخ پیش‌فرض: از 30 روز قبل تا امروز
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));

    setState(() {
      startDate = thirtyDaysAgo;
      endDate = now;
    });
  }

  Future<void> _loadProductData() async {
    if (startDate == null || endDate == null) return;

    setState(() {
      isLoading = true;
    });

    try {
      final productionData = await ProductionAnalysisService.getProductionData(
        startDate: startDate!,
        endDate: endDate!,
      );

      final convertedData = _convertToProductData(productionData);
      final stats = _calculateSummaryStats(convertedData);

      setState(() {
        productData = convertedData;
        summaryStats = stats;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('خطا در بارگذاری داده‌ها: $e');
    }
  }

  List<ProductData> _convertToProductData(List<ProductionData> productionData) {
    // ابتدا فقط رکورد یکتا برای هر شیفت هر روز را نگه می‌داریم
    final uniqueData =
        ProductionAnalysisService.getUniqueProductionData(productionData);

    List<ProductData> result = [];

    switch (selectedTimeRange) {
      case 'روزانه':
        // هر روز یک ردیف (جمع سه شیفت)
        final Map<int, List<ProductionData>> dayGroups = {};
        for (final d in uniqueData) {
          dayGroups.putIfAbsent(d.day, () => []).add(d);
        }
        dayGroups.forEach((day, list) {
          final total =
              list.fold<double>(0, (sum, e) => sum + e.producedProduct);
          result.add(ProductData(
            label: day.toString(),
            actualProduct: total,
            plannedProduct: PlanningCalculationService.getPlanByTimeRange(
                DateTime(list.first.year, list.first.month, list.first.day),
                'روزانه'),
            shift: '-',
          ));
        });
        break;
      case 'هفتگی':
        // هر هفته یک ردیف (جمع کل شیفت‌های هر هفته)
        final Map<String, List<ProductionData>> weekGroups = {};
        for (final d in uniqueData) {
          final date = DateTime(d.year, d.month, d.day);
          final weekStart = ((d.day - 1) ~/ 7) * 7 + 1;
          final weekEnd = weekStart + 6;
          final key = '${weekStart}-${weekEnd}';
          weekGroups.putIfAbsent(key, () => []).add(d);
        }
        weekGroups.forEach((key, list) {
          final total =
              list.fold<double>(0, (sum, e) => sum + e.producedProduct);
          result.add(ProductData(
            label: key,
            actualProduct: total,
            plannedProduct: PlanningCalculationService.getPlanByTimeRange(
                DateTime(list.first.year, list.first.month, list.first.day),
                'هفتگی'),
            shift: '-',
          ));
        });
        break;
      case 'ماهانه':
        // هر ماه یک ردیف (جمع کل شیفت‌های هر ماه)
        final Map<int, List<ProductionData>> monthGroups = {};
        for (final d in uniqueData) {
          monthGroups.putIfAbsent(d.month, () => []).add(d);
        }
        const monthNames = [
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
          'اسفند'
        ];
        monthGroups.forEach((month, list) {
          final total =
              list.fold<double>(0, (sum, e) => sum + e.producedProduct);
          result.add(ProductData(
            label: monthNames[month],
            actualProduct: total,
            plannedProduct: PlanningCalculationService.getPlanByTimeRange(
                DateTime(list.first.year, list.first.month, 1), 'ماهانه'),
            shift: '-',
          ));
        });
        break;
      case 'شیفتی':
        // هر روز سه ردیف (هر ردیف یک شیفت)
        final Map<String, ProductionData> shiftGroups = {};
        for (final d in uniqueData) {
          final key = '${d.year}/${d.month}/${d.day}-شیفت${d.shift}';
          shiftGroups[key] = d;
        }
        shiftGroups.forEach((key, d) {
          result.add(ProductData(
            label: key,
            actualProduct: d.producedProduct,
            plannedProduct: PlanningCalculationService.getPlanByTimeRange(
                DateTime(d.year, d.month, d.day), 'شیفتی'),
            shift: d.shift.toString(),
          ));
        });
        break;
      default:
        break;
    }
    return result;
  }

  Map<String, double> _calculateSummaryStats(List<ProductData> productData) {
    if (productData.isEmpty) return {};

    double totalActual = 0;
    double totalPlanned = 0;
    double maxDaily = 0;
    double minDaily = double.infinity;

    for (final data in productData) {
      totalActual += data.actualProduct;
      totalPlanned += data.plannedProduct;

      if (data.actualProduct > maxDaily) maxDaily = data.actualProduct;
      if (data.actualProduct < minDaily) minDaily = data.actualProduct;
    }

    // محاسبه درصد انحراف از برنامه
    // فرمول: ((واقعی - برنامه) / برنامه) × 100
    double deviationPercentage = 0;
    if (totalPlanned > 0) {
      deviationPercentage = ((totalActual - totalPlanned) / totalPlanned) * 100;
    }

    return {
      'totalActual': totalActual,
      'totalPlanned': totalPlanned,
      'deviationPercentage': deviationPercentage,
      'maxDaily': maxDaily,
      'minDaily': minDaily,
    };
  }

  /// پرینت گزارش
  Future<void> _printReport() async {
    if (productData.isEmpty) {
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
      // تبدیل داده‌های نمودار
      final actualData = productData.asMap().entries.map((entry) {
        return ChartPoint(
            entry.key.toDouble(), entry.value.actualProduct / 1000);
      }).toList();

      final plannedData = productData.asMap().entries.map((entry) {
        return ChartPoint(
            entry.key.toDouble(), entry.value.plannedProduct / 1000);
      }).toList();

      // تبدیل داده‌های جدول
      final pdfProductData = productData.map((data) {
        return PdfProductData(
          label: data.label,
          actualProduct: data.actualProduct,
          plannedProduct: data.plannedProduct,
          shift: data.shift,
        );
      }).toList();

      // تولید PDF
      final pdfFile = await PdfReportService.generateProductReport(
        productData: pdfProductData,
        startDate: startDate!,
        endDate: endDate!,
        timeRange: selectedTimeRange,
        selectedShift: 'همه شیفت‌ها', // پیش‌فرض برای PDF
        summaryStats: summaryStats,
        actualData: actualData,
        plannedData: plannedData,
      );

      // نمایش صفحه پیش‌نمایش PDF برای پرینت
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => PdfPreviewScreen(
              pdfFile: pdfFile,
              title: 'پرینت گزارش محصول تولیدی',
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

  /// دانلود گزارش PDF
  Future<void> _downloadPdfReport() async {
    if (productData.isEmpty) {
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
      // تبدیل داده‌های نمودار
      final actualData = productData.asMap().entries.map((entry) {
        return ChartPoint(
            entry.key.toDouble(), entry.value.actualProduct / 1000);
      }).toList();

      final plannedData = productData.asMap().entries.map((entry) {
        return ChartPoint(
            entry.key.toDouble(), entry.value.plannedProduct / 1000);
      }).toList();

      // تبدیل داده‌های جدول
      final pdfProductData = productData.map((data) {
        return PdfProductData(
          label: data.label,
          actualProduct: data.actualProduct,
          plannedProduct: data.plannedProduct,
          shift: data.shift,
        );
      }).toList();

      // تولید PDF
      final pdfFile = await PdfReportService.generateProductReport(
        productData: pdfProductData,
        startDate: startDate!,
        endDate: endDate!,
        timeRange: selectedTimeRange,
        selectedShift: 'همه شیفت‌ها', // پیش‌فرض برای PDF
        summaryStats: summaryStats,
        actualData: actualData,
        plannedData: plannedData,
      );

      // نمایش صفحه پیش‌نمایش PDF
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => PdfPreviewScreen(
              pdfFile: pdfFile,
              title: 'گزارش محصول تولیدی',
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
      final defaultStart = Jalali(currentJalali.year, currentJalali.month, 1);
      final defaultEnd = currentJalali;
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

      // فیلترها باز بمانند تا کاربر نوع بازه را انتخاب کند
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.stopsAppBar,
      body: SafeArea(
        child: Column(
          children: [
            // عنوان صفحه
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: const Center(
                child: Text(
                  'محصول تولیدی',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Vazirmatn',
                  ),
                ),
              ),
            ),
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.mainContainerBackground,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Column(
                  children: [
                    _buildFilterSection(),
                    Expanded(
                      child: isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : _buildContent(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildDownloadButton(),
    );
  }

  Widget _buildFilterSection() {
    final dateRangeConfig = BoxConfigs.dateRange;
    if (_isFilterCollapsed) {
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
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green[100],
                      borderRadius: BorderRadius.circular(
                          dateRangeConfig.tagBorderRadius),
                    ),
                    child: Text(
                      'محصول تولیدی',
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
            // باکس بازه زمانی
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
            const SizedBox(height: 12),
            // نوع بازه
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 6),
              padding: const EdgeInsets.all(12),
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
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'نوع بازه',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                      shadows: [
                        Shadow(
                          offset: const Offset(0, 1),
                          blurRadius: 3,
                          color: Colors.black.withOpacity(0.15),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: selectedTimeRange,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: timeRanges.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedTimeRange = newValue ?? 'روزانه';
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // دکمه نمایش گزارش
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _isFilterCollapsed = true;
                    });
                    _loadProductData();
                  },
                  icon: const Icon(Icons.analytics),
                  label: const Text('نمایش گزارش'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
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

  String _formatPersianDate(DateTime date) {
    try {
      // استفاده از کتابخانه persian_datetime_picker برای تبدیل صحیح
      final jalali = Jalali.fromDateTime(date);
      return '${jalali.year}/${jalali.month.toString().padLeft(2, '0')}/${jalali.day.toString().padLeft(2, '0')}';
    } catch (e) {
      // در صورت خطا، از تبدیل ساده استفاده کن
      final year = date.year;
      final month = date.month;
      final day = date.day;

      // تبدیل تقریبی میلادی به شمسی - فرمول صحیح
      final persianYear = year - 622;
      final persianMonth = month > 6 ? month - 6 : month + 6;
      final persianDay = day;

      return '${persianYear}/${persianMonth.toString().padLeft(2, '0')}/${persianDay.toString().padLeft(2, '0')}';
    }
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildSummaryCards(),
          const SizedBox(height: 12),
          _buildChart(),
          const SizedBox(height: 12),
          _buildDataTable(),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    final deviation = summaryStats['deviationPercentage'] ?? 0.0;
    final deviationConfig = BoxConfigs.deviationStandard;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: SummaryCard(
                title: 'محصول واقعی',
                value:
                    '${NumberFormatService.formatNumber(summaryStats['totalActual'] ?? 0)} تن',
                icon: BoxConfigs.actual.icon,
                backgroundColor: BoxConfigs.actual.backgroundColor,
                textColor: BoxConfigs.actual.textColor,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: SummaryCard(
                title: 'محصول برنامه‌ای',
                value:
                    '${NumberFormatService.formatNumber(summaryStats['totalPlanned'] ?? 0)} تن',
                icon: BoxConfigs.planned.icon,
                backgroundColor: BoxConfigs.planned.backgroundColor,
                textColor: BoxConfigs.planned.textColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // باکس انحراف از برنامه
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(deviationConfig.padding),
          decoration: BoxDecoration(
            color: deviation < 0
                ? deviationConfig.backgroundColorNegative
                : deviation > 0
                    ? deviationConfig.backgroundColorPositive
                    : deviationConfig.backgroundColorZero,
            borderRadius: BorderRadius.circular(deviationConfig.borderRadius),
            boxShadow: [
              BoxShadow(
                color: deviationConfig.boxShadowColor,
                spreadRadius: 1,
                blurRadius: deviationConfig.boxShadowBlur,
                offset: deviationConfig.boxShadowOffset,
              ),
            ],
            border: Border.all(
              color: deviationConfig.borderColor,
              width: deviationConfig.borderWidth,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'انحراف از برنامه',
                      style: TextStyle(
                        fontSize: deviationConfig.titleFontSize,
                        fontWeight: deviationConfig.titleFontWeight,
                        color: deviationConfig.textColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${deviation.round()}%',
                      style: TextStyle(
                        fontSize: deviationConfig.percentFontSize,
                        fontWeight: deviationConfig.percentFontWeight,
                        color: deviation < 0
                            ? Colors.red
                            : deviation > 0
                                ? Colors.green
                                : Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${((summaryStats['totalActual'] ?? 0) - (summaryStats['totalPlanned'] ?? 0)).round()} تن',
                      style: TextStyle(
                        fontSize: deviationConfig.diffFontSize,
                        fontWeight: deviationConfig.diffFontWeight,
                        color: deviationConfig.textColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              Icon(
                deviationConfig.icon,
                size: deviationConfig.iconSize,
                color: deviation < 0
                    ? Colors.red
                    : deviation > 0
                        ? Colors.green
                        : Colors.black,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChart() {
    if (productData.isEmpty) {
      return const Center(child: Text('داده‌ای برای نمایش وجود ندارد'));
    }
    double maxY = productData
        .map((d) => d.actualProduct)
        .fold<double>(0, (a, b) => a > b ? a : b);
    bool useK = maxY > 10000;
    double yDiv = useK ? 1000 : 1;
    String yUnit = useK ? 'k' : 'تن';
    return Container(
      height: 280,
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
            'مقایسه محصول محقق شده و برنامه ($yUnit)',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Stack(
              children: [
                BarChart(
                  BarChartData(
                    barGroups: [
                      for (int i = 0; i < productData.length; i++)
                        BarChartGroupData(
                          x: i,
                          barRods: [
                            BarChartRodData(
                              toY: productData[i].actualProduct / yDiv,
                              color: Colors.green,
                              width: 16,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ],
                        ),
                    ],
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              (value * yDiv).toStringAsFixed(0),
                              style: const TextStyle(fontSize: 10),
                            );
                          },
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          getTitlesWidget: (value, meta) {
                            if (value.toInt() >= 0 &&
                                value.toInt() < productData.length) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  productData[value.toInt()].label,
                                  style: const TextStyle(fontSize: 10),
                                  textAlign: TextAlign.center,
                                ),
                              );
                            }
                            return const Text('');
                          },
                        ),
                      ),
                      topTitles:
                          AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles:
                          AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: true),
                    minY: 0,
                    maxY: (maxY / yDiv) * 1.2,
                    barTouchData: BarTouchData(enabled: true),
                    gridData: FlGridData(show: true),
                  ),
                ),
                // LineChart برای برنامه سالانه
                Positioned.fill(
                  child: IgnorePointer(
                    child: LineChart(
                      LineChartData(
                        lineBarsData: [
                          LineChartBarData(
                            spots: [
                              for (int i = 0; i < productData.length; i++)
                                FlSpot(i.toDouble(),
                                    productData[i].plannedProduct / yDiv),
                            ],
                            isCurved: true,
                            color: Colors.red,
                            barWidth: 2,
                            dotData: FlDotData(show: true),
                          ),
                        ],
                        minY: 0,
                        maxY: (maxY / yDiv) * 1.2,
                        titlesData: FlTitlesData(show: false),
                        gridData: FlGridData(show: false),
                        borderData: FlBorderData(show: false),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem('محصول محقق شده', Colors.green),
              const SizedBox(width: 24),
              _buildLegendItem('برنامه سالانه', Colors.red),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 3,
          color: color,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildDataTable() {
    if (productData.isEmpty) {
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

    // تعیین عنوان جدول بر اساس نوع بازه
    String tableTitle = 'جزئیات محصول تولیدی';
    switch (selectedTimeRange) {
      case 'روزانه':
        tableTitle = 'جزئیات محصول تولیدی - روزانه';
        break;
      case 'هفتگی':
        tableTitle = 'جزئیات محصول تولیدی - هفتگی';
        break;
      case 'ماهانه':
        tableTitle = 'جزئیات محصول تولیدی - ماهانه';
        break;
      case 'شیفتی':
        tableTitle = 'جزئیات محصول تولیدی - شیفتی';
        break;
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
                const Icon(Icons.table_chart, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  tableTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('تاریخ/بازه')),
                DataColumn(label: Text('شیفت')),
                DataColumn(label: Text('محصول محقق شده (تن)')),
                DataColumn(label: Text('محصول برنامه‌ریزی شده (تن)')),
                DataColumn(label: Text('انحراف از برنامه')),
              ],
              rows: productData.map((data) {
                final deviation = data.actualProduct - data.plannedProduct;

                // تعیین نام شیفت با استفاده از سرویس مشترک
                String shiftName = data.shift;
                if (shiftName == 'نامشخص') {
                  shiftName = 'همه شیفت‌ها';
                }

                return DataRow(
                  cells: [
                    DataCell(Text(data.label)),
                    DataCell(Text(shiftName)),
                    DataCell(Text(data.actualProduct.toStringAsFixed(1))),
                    DataCell(Text(data.plannedProduct.toStringAsFixed(1))),
                    DataCell(
                      Text(
                        data.plannedProduct > 0
                            ? '${(((data.actualProduct - data.plannedProduct) / data.plannedProduct) * 100).toStringAsFixed(1)}%'
                            : '-',
                        style: TextStyle(
                          color: data.plannedProduct > 0 &&
                                  data.actualProduct - data.plannedProduct >= 0
                              ? Colors.green
                              : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  /// ساخت دکمه دانلود PDF
  Widget _buildDownloadButton() {
    return SpeedDial(
      icon: Icons.file_download,
      activeIcon: Icons.close,
      backgroundColor: Colors.red,
      foregroundColor: Colors.white,
      children: [
        SpeedDialChild(
          child: const Icon(Icons.print),
          label: 'پرینت گزارش',
          onTap: () => _printReport(),
        ),
        SpeedDialChild(
          child: const Icon(Icons.download),
          label: 'دانلود گزارش',
          onTap: () => _downloadPdfReport(),
        ),
      ],
    );
  }
}

class ProductData {
  final String label;
  double actualProduct;
  double plannedProduct;
  final String shift;

  ProductData({
    required this.label,
    required this.actualProduct,
    required this.plannedProduct,
    this.shift = 'نامشخص',
  });
}
