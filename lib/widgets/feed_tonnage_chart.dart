import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../providers/data_provider.dart';
import '../models/production_data.dart';
import '../models/stop_data.dart';
import '../config/app_colors.dart';
import 'package:shamsi_date/shamsi_date.dart';

class FeedTonnageChart extends StatefulWidget {
  const FeedTonnageChart({Key? key}) : super(key: key);

  @override
  State<FeedTonnageChart> createState() => _FeedTonnageChartState();
}

class _FeedTonnageChartState extends State<FeedTonnageChart>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  bool _isLoading = false;
  List<ProductionData> _currentMonthProduction = [];
  List<StopData> _allStopData = []; // کش توقفات

  int _selectedYear = 1404;
  int _selectedMonth = 4;

  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _initializeCurrentMonth();
    _loadData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _initializeCurrentMonth() {
    setState(() {
      _selectedYear = 1404;
      _selectedMonth = 4;
    });
    print('=== دیباگ FeedTonnageChart - _initializeCurrentMonth ===');
    print('ماه تنظیم شده: $_selectedYear/$_selectedMonth');
    print('====================================================');
  }

  void _changeMonth(int direction) {
    int newYear = _selectedYear;
    int newMonth = _selectedMonth;

    if (direction > 0) {
      if (_selectedMonth == 12) {
        newMonth = 1;
        newYear++;
      } else {
        newMonth++;
      }
    } else {
      if (_selectedMonth == 1) {
        newMonth = 12;
        newYear--;
      } else {
        newMonth--;
      }
    }

    if (newYear == _selectedYear && newMonth == _selectedMonth) return;

    setState(() {
      _selectedYear = newYear;
      _selectedMonth = newMonth;
    });

    print('=== دیباگ FeedTonnageChart - _changeMonth ===');
    print('ماه جدید: $_selectedYear/$_selectedMonth');
    print('============================================');

    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final dataProvider = Provider.of<DataProvider>(context, listen: false);

      final allProductionData = dataProvider.getProductionData();
      _currentMonthProduction = allProductionData.where((data) {
        return data.year == _selectedYear && data.month == _selectedMonth;
      }).toList();

      // دریافت توقفات یک بار
      _allStopData = dataProvider.getStopData();

      print('=== دیباگ FeedTonnageChart - _loadData ===');
      print('ماه انتخاب شده: $_selectedYear/$_selectedMonth');
      print('تعداد داده‌های تولید: ${_currentMonthProduction.length}');
      print('تعداد توقفات: ${_allStopData.length}');
      print('==========================================');

      _animationController.reset();
      _animationController.forward();
    } catch (e) {
      print('خطا در بارگذاری داده‌ها: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  List<FlSpot> _calculateChartData() {
    print('=== دیباگ _calculateChartData ===');
    print('تعداد داده‌های تولید: ${_currentMonthProduction.length}');

    if (_currentMonthProduction.isEmpty) {
      print('داده‌های تولید خالی است!');
      return [];
    }

    final spots = <FlSpot>[];
    int shiftIndex = 0;

    // گروه‌بندی داده‌ها بر اساس شیفت
    final Map<String, List<ProductionData>> shiftGroups = {};

    for (final production in _currentMonthProduction) {
      final key =
          '${production.year}-${production.month}-${production.day}-${production.shift}';
      if (!shiftGroups.containsKey(key)) {
        shiftGroups[key] = [];
      }
      shiftGroups[key]!.add(production);
    }

    print('تعداد گروه‌های شیفت: ${shiftGroups.length}');

    // مرتب‌سازی کلیدها
    final sortedKeys = shiftGroups.keys.toList()..sort();

    for (final key in sortedKeys) {
      final shiftData = shiftGroups[key]!;
      final firstProduction = shiftData.first;

      print(
          'محاسبه برای شیفت ${firstProduction.shift} روز ${firstProduction.day}');

      // محاسبه تناژ خوراک - فقط یک ردیف (منطق محاسبات تولید)
      final feedTonnage = shiftData.first.inputTonnage;

      // محاسبه کل توقفات این شیفت
      final shiftStops = _allStopData
          .where((stop) =>
              stop.year == firstProduction.year &&
              stop.month == firstProduction.month &&
              stop.day == firstProduction.day &&
              stop.shift == firstProduction.shift)
          .toList();

      double totalStopHours = 0.0;
      for (final stop in shiftStops) {
        try {
          final stopDurationStr = stop.stopDuration.toString();
          final parts = stopDurationStr.split(':');
          if (parts.length == 2) {
            final hours = double.tryParse(parts[0]) ?? 0.0;
            final minutes = double.tryParse(parts[1]) ?? 0.0;
            totalStopHours += hours + (minutes / 60.0);
          } else {
            final stopMinutes = double.tryParse(stopDurationStr) ?? 0.0;
            totalStopHours += stopMinutes / 60.0;
          }
        } catch (e) {
          print('خطا در تبدیل مدت توقف: ${stop.stopDuration}');
          continue;
        }
      }

      final workingHours = 8.0 - totalStopHours;
      double tonnageRate = 0.0;

      if (workingHours > 0) {
        tonnageRate = feedTonnage / workingHours;
      }

      print('تناژ خوراک شیفت: $feedTonnage تن');
      print('کل ساعات توقف: $totalStopHours ساعت');
      print('ساعات کاری: $workingHours ساعت');
      print('نرخ تناژ نهایی: $tonnageRate تن/ساعت');

      spots.add(FlSpot(shiftIndex.toDouble(), tonnageRate));
      shiftIndex++;
    }

    print('تعداد نقاط نمودار: ${spots.length}');
    print('================================');
    return spots;
  }

  List<FlSpot> _calculatePlannedData() {
    final actualSpots = _calculateChartData();
    if (actualSpots.isEmpty) return [];

    // عدد برنامه ثابت: 590 تن/ساعت
    const plannedRate = 590.0;

    return actualSpots.map((spot) => FlSpot(spot.x, plannedRate)).toList();
  }

  String _getMonthName(int month) {
    const monthNames = [
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
    return monthNames[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final actualSpots = _calculateChartData();
    final plannedSpots = _calculatePlannedData();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.grey[50]!,
                        Colors.grey[100]!,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
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
                            Icons.chevron_left,
                            color: Colors.grey[700],
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onPanUpdate: (details) {
                            if (details.delta.dx > 10) {
                              _changeMonth(-1);
                            } else if (details.delta.dx < -10) {
                              _changeMonth(1);
                            }
                          },
                          child: Text(
                            'نمودار پیوسته نرخ تناژ خوراک ورودی - ${_getMonthName(_selectedMonth)}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                              fontFamily: 'Vazirmatn',
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
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
                            Icons.chevron_right,
                            color: Colors.grey[700],
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : actualSpots.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.bar_chart, size: 48, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'داده‌ای برای نمایش وجود ندارد',
                              style:
                                  TextStyle(color: Colors.grey, fontSize: 16),
                            ),
                          ],
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          children: [
                            Expanded(
                              child: AnimatedBuilder(
                                animation: _animation,
                                builder: (context, child) {
                                  return SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    physics: const BouncingScrollPhysics(),
                                    child: SizedBox(
                                      width:
                                          (actualSpots.length * 30).toDouble(),
                                      child: LineChart(
                                        LineChartData(
                                          gridData: FlGridData(
                                            show: true,
                                            drawVerticalLine: true,
                                            horizontalInterval: 1,
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
                                            bottomTitles: AxisTitles(
                                              sideTitles: SideTitles(
                                                showTitles: true,
                                                reservedSize: 35,
                                                interval: 1,
                                                getTitlesWidget: (value, meta) {
                                                  if (value.toInt() >=
                                                      actualSpots.length) {
                                                    return const Text('');
                                                  }

                                                  // استفاده از همان منطق گروه‌بندی که برای محاسبه نقاط استفاده شد
                                                  final Map<String,
                                                          List<ProductionData>>
                                                      shiftGroups = {};
                                                  for (final production
                                                      in _currentMonthProduction) {
                                                    final key =
                                                        '${production.year}-${production.month}-${production.day}-${production.shift}';
                                                    if (!shiftGroups
                                                        .containsKey(key)) {
                                                      shiftGroups[key] = [];
                                                    }
                                                    shiftGroups[key]!
                                                        .add(production);
                                                  }

                                                  final sortedKeys =
                                                      shiftGroups.keys.toList()
                                                        ..sort();

                                                  if (value.toInt() <
                                                      sortedKeys.length) {
                                                    final key = sortedKeys[
                                                        value.toInt()];
                                                    final shiftData =
                                                        shiftGroups[key]!;
                                                    final firstProduction =
                                                        shiftData.first;
                                                    final day =
                                                        firstProduction.day;
                                                    final shift =
                                                        firstProduction.shift;

                                                    return Container(
                                                      padding:
                                                          const EdgeInsets.only(
                                                              top: 8),
                                                      child: Column(
                                                        children: [
                                                          Container(
                                                            padding:
                                                                const EdgeInsets
                                                                    .symmetric(
                                                              horizontal: 6,
                                                              vertical: 2,
                                                            ),
                                                            decoration:
                                                                BoxDecoration(
                                                              color: Colors
                                                                  .grey[200],
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          8),
                                                            ),
                                                            child: Text(
                                                              '$shift/$day',
                                                              style:
                                                                  const TextStyle(
                                                                fontSize: 10,
                                                                color: Colors
                                                                    .black54,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
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
                                                interval: 100,
                                                reservedSize: 60,
                                                getTitlesWidget: (value, meta) {
                                                  return Text(
                                                    '${value.toInt()}',
                                                    style: const TextStyle(
                                                      color: Colors.black54,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 10,
                                                    ),
                                                  );
                                                },
                                              ),
                                            ),
                                            rightTitles: AxisTitles(
                                              sideTitles:
                                                  SideTitles(showTitles: false),
                                            ),
                                            topTitles: AxisTitles(
                                              sideTitles:
                                                  SideTitles(showTitles: false),
                                            ),
                                          ),
                                          borderData: FlBorderData(
                                            show: true,
                                            border: Border.all(
                                                color: Colors.grey[400]!),
                                          ),
                                          minX: 0,
                                          maxX: (actualSpots.length - 1)
                                              .toDouble(),
                                          minY: 300, // ثابت
                                          maxY: 900, // ثابت
                                          lineBarsData: [
                                            LineChartBarData(
                                              spots: actualSpots
                                                  .map((spot) => FlSpot(
                                                      spot.x,
                                                      spot.y *
                                                          _animation.value))
                                                  .toList(),
                                              isCurved: true,
                                              color: Colors.blue,
                                              barWidth: 3,
                                              isStrokeCapRound: true,
                                              dotData: FlDotData(
                                                show: true,
                                                getDotPainter: (spot, percent,
                                                    barData, index) {
                                                  return FlDotCirclePainter(
                                                    radius: 4,
                                                    color: Colors.blue,
                                                    strokeWidth: 2,
                                                    strokeColor: Colors.white,
                                                  );
                                                },
                                              ),
                                              belowBarData: BarAreaData(
                                                show: true,
                                                color: Colors.blue
                                                    .withOpacity(0.1),
                                              ),
                                            ),
                                            LineChartBarData(
                                              spots: plannedSpots
                                                  .map((spot) => FlSpot(
                                                      spot.x,
                                                      spot.y *
                                                          _animation.value))
                                                  .toList(),
                                              isCurved: false,
                                              color: Colors.red,
                                              barWidth: 2,
                                              isStrokeCapRound: true,
                                              dotData: FlDotData(show: false),
                                              dashArray: [5, 5],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 16,
                                      height: 3,
                                      color: Colors.blue,
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'نرخ واقعی',
                                      style: TextStyle(
                                          fontSize: 12, color: Colors.black87),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 24),
                                Row(
                                  children: [
                                    Container(
                                      width: 16,
                                      height: 3,
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        borderRadius: BorderRadius.circular(1),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'نرخ برنامه',
                                      style: TextStyle(
                                          fontSize: 12, color: Colors.black87),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
