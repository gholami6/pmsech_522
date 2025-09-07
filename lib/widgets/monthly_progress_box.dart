import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_colors.dart';
import '../services/production_analysis_service.dart';
import '../services/planning_calculation_service.dart';
import '../services/date_service.dart';
import '../providers/data_provider.dart';
import 'dart:async';
import 'header_box_widget.dart';

class MonthlyProgressBox extends StatefulWidget {
  final Function(int year, int month)? onMonthChanged;

  const MonthlyProgressBox({super.key, this.onMonthChanged});

  @override
  State<MonthlyProgressBox> createState() => _MonthlyProgressBoxState();
}

class _MonthlyProgressBoxState extends State<MonthlyProgressBox>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late AnimationController _animationController;
  late AnimationController _pulseController;
  late AnimationController _shimmerController;
  late Animation<double> _plannedAnimation;
  late Animation<double> _actualAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _shimmerAnimation;

  double _plannedProgress = 0.0;
  double _actualProgress = 0.0;
  double _plannedTarget = 0.0;
  double _actualCurrent = 0.0;
  bool _isLoading = true;
  DateTime? _lastLoadTime;
  static const Duration _cacheDuration = Duration(minutes: 5);

  // متغیرهای جدید برای اسکرول ماه
  int _selectedYear = 1404;
  int _selectedMonth = 4; // ماه جاری
  final List<String> _monthNames = [
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

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _plannedAnimation = Tween<double>(begin: 0.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _actualAnimation = Tween<double>(begin: 0.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _pulseAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );

    _shimmerAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeOut),
    );

    // تنظیم ماه جاری
    _initializeCurrentMonth();

    _loadMonthlyData();

    // بروزرسانی هر 10 دقیقه
    Timer.periodic(const Duration(minutes: 10), (timer) {
      _loadMonthlyData();
    });
  }

  @override
  bool get wantKeepAlive => true;

  // تنظیم ماه جاری
  void _initializeCurrentMonth() {
    print('=== دیباگ _initializeCurrentMonth ===');
    // تنظیم روی ماهی که داده دارد (تیر 1404)
    final currentYear = 1404;
    final currentMonth = 4; // تیر ماه

    print('سال تنظیم شده: $currentYear');
    print('ماه تنظیم شده: $currentMonth');

    setState(() {
      _selectedYear = currentYear;
      _selectedMonth = currentMonth;
    });

    print('ماه تنظیم شده: $_selectedYear/$_selectedMonth');
    print('==========================================');

    // اطلاع‌رسانی ماه جاری به والد - با تاخیر برای جلوگیری از setState در build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('=== دیباگ MonthlyProgressBox - ماه جاری ===');
      print('اطلاع‌رسانی ماه جاری به والد: $currentYear/$currentMonth');
      print('==========================================');
      widget.onMonthChanged?.call(currentYear, currentMonth);
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pulseController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  Future<void> _loadMonthlyData() async {
    // بررسی کش
    if (_lastLoadTime != null &&
        DateTime.now().difference(_lastLoadTime!) < _cacheDuration) {
      print('=== دیباگ MonthlyProgressBox - استفاده از کش ===');
      print('زمان آخرین بارگذاری: $_lastLoadTime');
      print('==============================================');
      return;
    }

    try {
      // استفاده از داده‌های کش شده از DataProvider
      final dataProvider = Provider.of<DataProvider>(context, listen: false);
      final allProductionData = dataProvider.getProductionData();

      // فیلتر داده‌های ماه انتخاب شده
      final selectedMonthData = allProductionData.where((data) {
        return data.year == _selectedYear && data.month == _selectedMonth;
      }).toList();

      print('=== دیباگ MonthlyProgressBox - _loadMonthlyData ===');
      print('ماه انتخاب شده: $_selectedYear/$_selectedMonth');
      print('کل داده‌های تولید: ${allProductionData.length}');
      print('داده‌های ماه انتخاب شده: ${selectedMonthData.length}');

      // محاسبه مجموع تولید
      double totalProduction = 0.0;
      final processedShifts = <String>{};

      for (var data in selectedMonthData) {
        final shiftKey = '${data.year}/${data.month}/${data.day}/${data.shift}';
        if (!processedShifts.contains(shiftKey) && data.inputTonnage > 0) {
          totalProduction += data.producedProduct;
          processedShifts.add(shiftKey);
        }
      }

      print('تولید کل ماه: $totalProduction تن');
      print('شیفت‌های پردازش شده: ${processedShifts.length}');
      print('===============================');

      // دریافت برنامه ماهانه
      final monthlyPlan =
          PlanningCalculationService.getMonthlyProductPlan(_selectedMonth);

      // محاسبه پیشرفت
      final persianDate = DateService.getCurrentShamsiDate();
      final persianParts = persianDate.split('/');
      final persianDay = int.parse(persianParts[2]);
      final daysInMonth = _getDaysInPersianMonth(_selectedYear, _selectedMonth);

      // اگر ماه انتخاب شده ماه جاری است، از روز فعلی استفاده کن
      final currentYear = int.parse(persianParts[0]);
      final currentMonth = int.parse(persianParts[1]);

      double plannedProgress;
      if (_selectedYear == currentYear && _selectedMonth == currentMonth) {
        // ماه جاری - از روز فعلی استفاده کن
        plannedProgress = (persianDay / daysInMonth).clamp(0.0, 1.0);
      } else {
        // ماه‌های گذشته - 100% پیشرفت
        plannedProgress = 1.0;
      }

      final actualProgress = monthlyPlan > 0
          ? (totalProduction / monthlyPlan).clamp(0.0, 1.0)
          : 0.0;

      setState(() {
        _plannedTarget = monthlyPlan.toDouble();
        _actualCurrent = totalProduction;
        _plannedProgress = plannedProgress;
        _actualProgress = actualProgress;
        _isLoading = false;
        _lastLoadTime = DateTime.now();
      });

      // شروع انیمیشن
      _plannedAnimation =
          Tween<double>(begin: 0.0, end: _plannedProgress).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
      );

      _actualAnimation =
          Tween<double>(begin: 0.0, end: _actualProgress).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
      );

      _animationController.reset();
      _animationController.forward();

      print('=== دیباگ MonthlyProgressBox - پایان _loadMonthlyData ===');
      print('ماه نهایی: $_selectedYear/$_selectedMonth');
      print('======================================================');
    } catch (e) {
      print('خطا در بارگذاری داده‌های ماهانه: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // تغییر ماه با اسکرول
  void _changeMonth(int direction) {
    print('=== دیباگ _changeMonth ===');
    print('جهت: $direction');
    print('ماه قبل از تغییر: $_selectedYear/$_selectedMonth');

    setState(() {
      if (direction > 0) {
        // اسکرول راست - ماه قبل
        _selectedMonth--;
        if (_selectedMonth < 1) {
          _selectedMonth = 12;
          _selectedYear--;
        }
      } else {
        // اسکرول چپ - ماه بعد
        _selectedMonth++;
        if (_selectedMonth > 12) {
          _selectedMonth = 1;
          _selectedYear++;
        }
      }
    });

    print('ماه بعد از تغییر: $_selectedYear/$_selectedMonth');
    print('==========================');

    // اطلاع‌رسانی تغییر ماه به والد - با تاخیر برای جلوگیری از setState در build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('=== دیباگ MonthlyProgressBox - تغییر ماه ===');
      print('اطلاع‌رسانی به والد: $_selectedYear/$_selectedMonth');
      print('==========================================');
      widget.onMonthChanged?.call(_selectedYear, _selectedMonth);
    });

    // پاک کردن کش و بارگذاری مجدد داده‌ها
    _lastLoadTime = null;
    _loadMonthlyData();
  }

  // محاسبه تعداد روزهای ماه شمسی
  int _getDaysInPersianMonth(int year, int month) {
    if (month <= 6) return 31;
    if (month <= 11) return 30;
    // اسفند - بررسی سال کبیسه
    return _isPersianLeapYear(year) ? 30 : 29;
  }

  // بررسی سال کبیسه شمسی
  bool _isPersianLeapYear(int year) {
    final cycle = (year - 1) % 33;
    final leapYears = [1, 5, 9, 13, 17, 22, 26, 30];
    return leapYears.contains(cycle);
  }

  // دریافت نام ماه انتخاب شده
  String _getSelectedMonthName() {
    print('=== دیباگ _getSelectedMonthName ===');
    print('_selectedMonth: $_selectedMonth');
    final monthName = _monthNames[_selectedMonth - 1];
    print('نام ماه: $monthName');
    print('===============================');
    return monthName;
  }

  // بررسی اینکه آیا ماه انتخاب شده ماه جاری است
  bool _isCurrentMonth() {
    final persianDate = DateService.getCurrentShamsiDate();
    final persianParts = persianDate.split('/');
    final currentYear = int.parse(persianParts[0]);
    final currentMonth = int.parse(persianParts[1]);
    return _selectedYear == currentYear && _selectedMonth == currentMonth;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // برای AutomaticKeepAliveClientMixin
    return Container(
      width: double.infinity,
      height: 183,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0x8000879E), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // عنوان با قابلیت اسکرول
            GestureDetector(
              onHorizontalDragEnd: (details) {
                if (details.primaryVelocity! > 0) {
                  // اسکرول راست - ماه قبل
                  _changeMonth(1);
                } else if (details.primaryVelocity! < 0) {
                  // اسکرول چپ - ماه بعد
                  _changeMonth(-1);
                }
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  children: [
                    // آیکن ماه قبل (چپ)
                    GestureDetector(
                      onTap: () => _changeMonth(1),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.chevron_left,
                          color: Colors.grey[700],
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // عنوان قابل کشیدن
                    Expanded(
                      child: GestureDetector(
                        onPanUpdate: (details) {
                          if (details.delta.dx > 10) {
                            // کشیدن به راست - ماه قبل
                            _changeMonth(1);
                          } else if (details.delta.dx < -10) {
                            // کشیدن به چپ - ماه بعد
                            _changeMonth(-1);
                          }
                        },
                        child: Text(
                          'پیشرفت تولید ماهانه - ${_getSelectedMonthName()}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // آیکن ماه بعد (راست)
                    GestureDetector(
                      onTap: () => _changeMonth(-1),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.chevron_right,
                          color: Colors.grey[700],
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2E7D32)),
                ),
              )
            else
              Expanded(
                child: Column(
                  children: [
                    // نوار برنامه‌ای
                    _buildProgressBar(
                      title: 'برنامه',
                      progress: _plannedAnimation,
                      color: const Color(0xFF2196F3),
                      value: _plannedTarget,
                      currentValue: _plannedTarget * _plannedProgress,
                    ),
                    const SizedBox(height: 6),

                    // نوار واقعی
                    _buildProgressBar(
                      title: 'واقعی',
                      progress: _actualAnimation,
                      color: const Color(0xFF4CAF50),
                      value: _plannedTarget,
                      currentValue: _actualCurrent,
                    ),

                    const SizedBox(height: 2),

                    // اطلاعات اضافی
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'هدف ماهانه: ${_plannedTarget.toStringAsFixed(0)} تن',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.black87,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          'تاریخ: ${_selectedYear}/${_selectedMonth.toString().padLeft(2, '0')}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.black87,
                            fontWeight: FontWeight.w500,
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
  }

  Widget _buildProgressBar({
    required String title,
    required Animation<double> progress,
    required Color color,
    required double value,
    required double currentValue,
  }) {
    // محاسبه درصد واقعی
    final actualPercentage = value > 0 ? (currentValue / value) : 0.0;

    // تعیین رنگ و آیکن برای نوار واقعی
    Color actualColor = color;
    IconData? statusIcon;
    Color iconColor = color;

    if (title == 'واقعی') {
      if (actualPercentage < 1.0) {
        // عقب‌ماندگی
        actualColor = Colors.red;
        statusIcon = Icons.warning;
        iconColor = Colors.red;
      } else if (actualPercentage > 1.0) {
        // پیشرفت
        actualColor = const Color(0xFF4CAF50); // سبز
        statusIcon = Icons.check_circle;
        iconColor = const Color(0xFF4CAF50);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            Row(
              children: [
                Text(
                  '${currentValue.toStringAsFixed(0)} تن',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: title == 'واقعی' ? actualColor : color,
                  ),
                ),
                const SizedBox(width: 4),
                AnimatedBuilder(
                  animation: progress,
                  builder: (context, child) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: (title == 'واقعی' ? actualColor : color)
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: (title == 'واقعی' ? actualColor : color)
                                .withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title == 'واقعی'
                                ? '${(actualPercentage * 100).toStringAsFixed(1)}%'
                                : '${(progress.value * 100).toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: title == 'واقعی' ? actualColor : color,
                            ),
                          ),
                          if (statusIcon != null) ...[
                            const SizedBox(width: 4),
                            Icon(
                              statusIcon,
                              size: 12,
                              color: iconColor,
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 4),
        AnimatedBuilder(
          animation: progress,
          builder: (context, child) {
            return Container(
              height: 8,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Stack(
                children: [
                  // نوار اصلی
                  FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: title == 'واقعی'
                        ? (actualPercentage > 1.0 ? 1.0 : actualPercentage)
                        : progress.value,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            title == 'واقعی' ? actualColor : color,
                            (title == 'واقعی' ? actualColor : color)
                                .withOpacity(0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: [
                          BoxShadow(
                            color: (title == 'واقعی' ? actualColor : color)
                                .withOpacity(0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // بخش اضافی نارنجی (فقط برای نوار واقعی با درصد > 100%)
                  if (title == 'واقعی' && actualPercentage > 1.0)
                    Positioned(
                      left: 0,
                      child: FractionallySizedBox(
                        widthFactor: actualPercentage,
                        child: Container(
                          height: 8,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFFFF9800), // نارنجی
                                const Color(0xFFFF9800).withOpacity(0.8),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(4),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFF9800).withOpacity(0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  // افکت شیمر
                  if (progress.value > 0)
                    AnimatedBuilder(
                      animation: _shimmerAnimation,
                      builder: (context, child) {
                        return FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: title == 'واقعی'
                              ? (actualPercentage > 1.0
                                  ? 1.0
                                  : actualPercentage)
                              : progress.value,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              gradient: LinearGradient(
                                begin:
                                    Alignment(_shimmerAnimation.value - 1, 0),
                                end: Alignment(_shimmerAnimation.value, 0),
                                colors: [
                                  Colors.transparent,
                                  Colors.white.withOpacity(0.3),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
