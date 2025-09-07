import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../providers/data_provider.dart';
import '../models/grade_data.dart';
import '../config/app_colors.dart';
import 'package:shamsi_date/shamsi_date.dart';

class GradeContinuousChart extends StatefulWidget {
  const GradeContinuousChart({
    Key? key,
  }) : super(key: key);

  @override
  State<GradeContinuousChart> createState() => _GradeContinuousChartState();
}

class _GradeContinuousChartState extends State<GradeContinuousChart>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  bool _isLoading = false;
  List<GradeData> _currentMonthGrades = [];
  int _currentYear = 0;
  int _currentMonth = 0;

  // متغیرهای ماه انتخاب شده برای نمودار عیار
  int _selectedYear = 1404;
  int _selectedMonth = 4; // ماه جاری

  // انیمیشن برای نمودار
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    print('=== دیباگ GradeContinuousChart - initState ===');
    print('==========================================');

    // راه‌اندازی انیمیشن
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _initializeCurrentMonth();
    _loadGradeData();
  }

  // تنظیم ماه جاری
  void _initializeCurrentMonth() {
    // تنظیم روی ماهی که داده دارد (تیر 1404)
    setState(() {
      _selectedYear = 1404;
      _selectedMonth = 4; // تیر ماه
    });
    print('=== دیباگ GradeContinuousChart - _initializeCurrentMonth ===');
    print('ماه جاری تنظیم شد: $_selectedYear/$_selectedMonth');
    print('====================================================');
  }

  // تابع تغییر ماه
  void _changeMonth(int direction) {
    print('=== دیباگ GradeContinuousChart - _changeMonth ===');
    print('تغییر ماه از: $_selectedYear/$_selectedMonth');
    print('جهت: $direction');

    int newYear = _selectedYear;
    int newMonth = _selectedMonth;

    if (direction > 0) {
      // ماه بعد
      if (_selectedMonth == 12) {
        newMonth = 1;
        newYear++;
      } else {
        newMonth++;
      }
    } else {
      // ماه قبل
      if (_selectedMonth == 1) {
        newMonth = 12;
        newYear--;
      } else {
        newMonth--;
      }
    }

    // بررسی اینکه آیا ماه واقعاً تغییر کرده است
    if (newYear == _selectedYear && newMonth == _selectedMonth) {
      print('ماه تغییر نکرده است، عملیات لغو شد');
      print('==============================================');
      return;
    }

    setState(() {
      _selectedYear = newYear;
      _selectedMonth = newMonth;
    });

    print('تغییر ماه به: $_selectedYear/$_selectedMonth');
    print('==============================================');
    _loadGradeData();
  }

  // تابع تغییر ماه با تاخیر برای بهبود تجربه کاربری
  void _changeMonthWithDelay(int direction) {
    print('=== دیباگ GradeContinuousChart - _changeMonthWithDelay ===');
    print('تغییر ماه با تاخیر از: $_selectedYear/$_selectedMonth');
    print('جهت: $direction');

    // تاخیر 300 میلی‌ثانیه برای بهبود تجربه کاربری
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _changeMonth(direction);
      }
    });
  }

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadGradeData() async {
    try {
      // بررسی اینکه آیا داده‌های ماه فعلی قبلاً بارگذاری شده‌اند
      if (_currentYear == _selectedYear &&
          _currentMonth == _selectedMonth &&
          _currentMonthGrades.isNotEmpty) {
        print(
            '=== دیباگ GradeContinuousChart - داده‌ها قبلاً بارگذاری شده‌اند ===');
        print('ماه: $_selectedYear/$_selectedMonth');
        print('تعداد داده‌ها: ${_currentMonthGrades.length}');
        print('==========================================================');
        return;
      }

      setState(() {
        _isLoading = true;
      });

      final dataProvider = Provider.of<DataProvider>(context, listen: false);
      final allGradeData = dataProvider.getGradeData();

      if (allGradeData.isEmpty) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // استفاده از ماه انتخاب شده
      print('=== دیباگ GradeContinuousChart - _loadGradeData ===');
      print('استفاده از ماه انتخاب شده: $_selectedYear/$_selectedMonth');

      int targetYear = _selectedYear;
      int targetMonth = _selectedMonth;

      // فیلتر کردن داده‌های ماه انتخاب شده
      final selectedMonthGrades = allGradeData
          .where((g) => g.year == targetYear && g.month == targetMonth)
          .toList();

      print('=== دیباگ GradeContinuousChart ===');
      print('ماه هدف: $targetYear/$targetMonth');
      print('داده‌های عیار ماه انتخاب شده: ${selectedMonthGrades.length}');
      print('===============================');

      // به‌روزرسانی مستقیم UI
      if (mounted) {
        print('=== دیباگ GradeContinuousChart - setState فراخوانی شد ===');
        print('قبل از setState:');
        print('_currentYear: $_currentYear');
        print('_currentMonth: $_currentMonth');
        print('تعداد داده‌ها: ${_currentMonthGrades.length}');

        setState(() {
          _currentMonthGrades = selectedMonthGrades;
          _currentYear = targetYear;
          _currentMonth = targetMonth;
          _isLoading = false;
        });

        print('بعد از setState:');
        print('_currentYear: $_currentYear');
        print('_currentMonth: $_currentMonth');
        print('تعداد داده‌ها: ${_currentMonthGrades.length}');
        print('==================================================');
      }

      print('=== دیباگ GradeContinuousChart - پایان ===');
      print('_currentYear: $_currentYear');
      print('_currentMonth: $_currentMonth');
      print('تعداد داده‌های بارگذاری شده: ${_currentMonthGrades.length}');
      print('==========================================');
    } catch (e) {
      print('خطا در بارگذاری داده‌های عیار: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // برای AutomaticKeepAliveClientMixin

    print('=== دیباگ GradeContinuousChart - build فراخوانی شد ===');
    print('_currentYear: $_currentYear');
    print('_currentMonth: $_currentMonth');
    print('Key: ${widget.key}');
    print('====================================================');

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          height: 450,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[300]!),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // هدر نمودار
              Container(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // عنوان با استایل یکسان با باکس پیشرفت تولید ماهانه
                    Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 16),
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
                          // آیکن ماه قبل (چپ)
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
                          // عنوان قابل کشیدن
                          Expanded(
                            child: GestureDetector(
                              onPanUpdate: (details) {
                                if (details.delta.dx > 10) {
                                  // کشیدن به راست - ماه قبل
                                  _changeMonthWithDelay(-1);
                                } else if (details.delta.dx < -10) {
                                  // کشیدن به چپ - ماه بعد
                                  _changeMonthWithDelay(1);
                                }
                              },
                              child: Text(
                                'نمودار پیوسته عیار خوراک و محصول - ${_getMonthName(_selectedMonth)}',
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
                          // آیکن ماه بعد (راست)
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

              // محتوای نمودار
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(),
                      )
                    : _currentMonthGrades.isEmpty
                        ? const Center(
                            child: Text(
                              'هیچ داده‌ای برای ماه جاری موجود نیست',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          )
                        : _buildChart(),
              ),

              // میانگین‌های ماهانه - مستقیماً در باکس نمودار
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  children: [
                    // میانگین‌های ماهانه - زیر یکدیگر و وسط چین
                    _buildAverageItem('میانگین عیار خوراک ماه:',
                        _calculateAverageFeedGrade(), AppColors.feedColor),
                    const SizedBox(height: 8),
                    _buildAverageItem(
                        'میانگین عیار محصول ماه:',
                        _calculateAverageProductGrade(),
                        AppColors.productColor),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChart() {
    final chartData = _prepareChartData();
    final yAxisLimits = _calculateYAxisLimits();

    if (chartData.isEmpty) {
      return Container(
        height: 280,
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
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.show_chart_outlined,
                size: 48,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'هیچ داده‌ای برای نمایش موجود نیست',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      height: 330,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Colors.grey[50]!,
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          // محور Y ثابت با طراحی مدرن
          Container(
            width: 60,
            height: 280,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.grey[100]!,
                  Colors.grey[50]!,
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
            ),
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 60,
                      interval: _calculateYInterval(yAxisLimits['max']!),
                      getTitlesWidget: (value, meta) {
                        return Container(
                          width: 50,
                          alignment: Alignment.centerRight,
                          child: Text(
                            '${value.toInt()}%',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Vazirmatn',
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: 0,
                minY: yAxisLimits['min']!,
                maxY: yAxisLimits['max']!,
                lineBarsData: [],
              ),
            ),
          ),
          // نمودار اصلی با اسکرول و طراحی مدرن
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withOpacity(0.95),
                    Colors.grey[50]!.withOpacity(0.8),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: SizedBox(
                  width:
                      (chartData.length * 30).toDouble(), // افزایش عرض هر نقطه
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: true,
                        horizontalInterval:
                            _calculateYInterval(yAxisLimits['max']!),
                        verticalInterval: 1,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: Colors.grey[300]!,
                            strokeWidth: 1,
                            dashArray: [5, 5], // خطوط نقطه‌چین
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
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 35,
                            interval: 1,
                            getTitlesWidget: (value, meta) {
                              final idx = value.toInt();
                              if (idx < 0 || idx >= chartData.length) {
                                return const SizedBox();
                              }

                              final data = chartData[idx];
                              final day = data['day'].toInt();
                              final shift = data['shift'].toInt();

                              return Container(
                                padding: const EdgeInsets.only(top: 8),
                                child: Column(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[200],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '$shift/$day',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey[700],
                                          fontWeight: FontWeight.w600,
                                          fontFamily: 'Vazirmatn',
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      borderData: FlBorderData(
                        show: true,
                        border: Border(
                          bottom:
                              BorderSide(color: Colors.grey[300]!, width: 1),
                          right: BorderSide(color: Colors.grey[300]!, width: 1),
                        ),
                      ),
                      minX: 0,
                      maxX: (chartData.length - 1).toDouble(),
                      minY: yAxisLimits['min']!,
                      maxY: yAxisLimits['max']!,
                      lineBarsData: [
                        // خط عیار خوراک - طراحی مدرن با گرادینت
                        LineChartBarData(
                          spots: List.generate(
                            chartData.length,
                            (i) => FlSpot(
                              i.toDouble(),
                              chartData[i]['feedGrade'] ?? 0.0,
                            ),
                          ).where((spot) => spot.y > 0).toList(),
                          isCurved: true, // خط منحنی
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF3B82F6), // آبی
                              Color(0xFF8B5CF6), // بنفش
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          barWidth: 2.5, // 50% کاهش ضخامت
                          isStrokeCapRound: true,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, barData, index) {
                              return FlDotCirclePainter(
                                radius: 3,
                                color: const Color(0xFF3B82F6),
                                strokeWidth: 1.5,
                                strokeColor: Colors.white,
                              );
                            },
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                const Color(0xFF3B82F6).withOpacity(0.3),
                                const Color(0xFF3B82F6).withOpacity(0.05),
                              ],
                            ),
                          ),
                          shadow: const Shadow(
                            blurRadius: 15,
                            color: Color(0x40000000),
                            offset: Offset(0, 4),
                          ),
                        ),
                        // خط عیار محصول - طراحی مدرن با گرادینت
                        LineChartBarData(
                          spots: List.generate(
                            chartData.length,
                            (i) => FlSpot(
                              i.toDouble(),
                              chartData[i]['productGrade'] ?? 0.0,
                            ),
                          ).where((spot) => spot.y > 0).toList(),
                          isCurved: true, // خط منحنی
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF10B981), // سبز
                              Color(0xFF06B6D4), // فیروزه‌ای
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          barWidth: 2.5, // 50% کاهش ضخامت
                          isStrokeCapRound: true,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, barData, index) {
                              return FlDotCirclePainter(
                                radius: 3,
                                color: const Color(0xFF10B981),
                                strokeWidth: 1.5,
                                strokeColor: Colors.white,
                              );
                            },
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                const Color(0xFF10B981).withOpacity(0.3),
                                const Color(0xFF10B981).withOpacity(0.05),
                              ],
                            ),
                          ),
                          shadow: const Shadow(
                            blurRadius: 15,
                            color: Color(0x40000000),
                            offset: Offset(0, 4),
                          ),
                        ),
                        // خط عیار برنامه‌ای خوراک - خط مستقیم
                        LineChartBarData(
                          spots: List.generate(
                            chartData.length,
                            (i) => FlSpot(i.toDouble(), 30.0),
                          ),
                          isCurved: false, // خط مستقیم
                          color: const Color(0xFFEF4444)
                              .withOpacity(0.5), // قرمز با 50% شفافیت
                          barWidth: 2.0,
                          isStrokeCapRound: false,
                          dotData: FlDotData(show: false), // بدون نقطه
                          belowBarData: BarAreaData(show: false),
                        ),
                        // خط عیار برنامه‌ای محصول - خط مستقیم
                        LineChartBarData(
                          spots: List.generate(
                            chartData.length,
                            (i) => FlSpot(i.toDouble(), 37.0),
                          ),
                          isCurved: false, // خط مستقیم
                          color: const Color(0xFFF59E0B)
                              .withOpacity(0.5), // نارنجی با 50% شفافیت
                          barWidth: 2.0,
                          isStrokeCapRound: false,
                          dotData: FlDotData(show: false), // بدون نقطه
                          belowBarData: BarAreaData(show: false),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _prepareChartData() {
    if (_currentMonthGrades.isEmpty) return [];

    // گروه‌بندی داده‌ها بر اساس روز و شیفت
    final Map<String, Map<String, double>> shiftData = {};

    for (final grade in _currentMonthGrades) {
      final key = '${grade.day}_${grade.shift}';
      shiftData.putIfAbsent(
          key,
          () => {
                'day': grade.day.toDouble(),
                'shift': grade.shift.toDouble(),
                'feedGrade': 0.0,
                'productGrade': 0.0,
              });

      if (grade.gradeType == 'خوراک') {
        shiftData[key]!['feedGrade'] = grade.gradeValue;
      } else if (grade.gradeType == 'محصول') {
        shiftData[key]!['productGrade'] = grade.gradeValue;
      }
    }

    // تبدیل به لیست و مرتب‌سازی
    final List<Map<String, dynamic>> result = shiftData.values.toList();
    result.sort((a, b) {
      if (a['day'] != b['day']) {
        return a['day'].compareTo(b['day']);
      }
      return a['shift'].compareTo(b['shift']);
    });

    return result;
  }

  /// ساخت آیتم میانگین با طراحی مدرن
  Widget _buildAverageItem(String label, double average, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(5),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$label ',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[800],
              fontWeight: FontWeight.w600,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '${average.toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// محاسبه میانگین عیار خوراک ماهانه
  double _calculateAverageFeedGrade() {
    if (_currentMonthGrades.isEmpty) return 0.0;

    final feedGrades = _currentMonthGrades
        .where((grade) => grade.gradeType == 'خوراک' && grade.gradeValue > 0)
        .map((grade) => grade.gradeValue)
        .toList();

    if (feedGrades.isEmpty) return 0.0;

    final sum = feedGrades.reduce((a, b) => a + b);
    return sum / feedGrades.length;
  }

  /// محاسبه میانگین عیار محصول ماهانه
  double _calculateAverageProductGrade() {
    if (_currentMonthGrades.isEmpty) return 0.0;

    final productGrades = _currentMonthGrades
        .where((grade) => grade.gradeType == 'محصول' && grade.gradeValue > 0)
        .map((grade) => grade.gradeValue)
        .toList();

    if (productGrades.isEmpty) return 0.0;

    final sum = productGrades.reduce((a, b) => a + b);
    return sum / productGrades.length;
  }

  /// محاسبه فاصله محور Y بر اساس حداکثر مقدار
  double _calculateYInterval(double maxValue) {
    if (maxValue <= 10) return 2.0;
    if (maxValue <= 20) return 5.0;
    if (maxValue <= 50) return 10.0;
    if (maxValue <= 100) return 20.0;
    return 25.0;
  }

  /// محاسبه محدودیت‌های محور Y بر اساس داده‌ها
  Map<String, double> _calculateYAxisLimits() {
    if (_currentMonthGrades.isEmpty) {
      return {'min': 20.0, 'max': 50.0}; // مقادیر پیش‌فرض با min = 20%
    }

    // یافتن حداقل و حداکثر مقادیر عیار
    double minGrade = double.infinity;
    double maxGrade = 0.0;

    for (final grade in _currentMonthGrades) {
      if (grade.gradeValue > 0) {
        if (grade.gradeValue < minGrade) {
          minGrade = grade.gradeValue;
        }
        if (grade.gradeValue > maxGrade) {
          maxGrade = grade.gradeValue;
        }
      }
    }

    // اگر هیچ داده‌ای نداریم، از مقادیر پیش‌فرض استفاده کنیم
    if (minGrade == double.infinity) {
      return {'min': 20.0, 'max': 50.0};
    }

    // اضافه کردن حاشیه برای نمایش بهتر
    final margin = (maxGrade - minGrade) * 0.1; // 10% حاشیه
    final calculatedMin =
        (minGrade - margin).clamp(20.0, double.infinity); // حداقل 20%
    final calculatedMax = (maxGrade + margin).clamp(0.0, 100.0);

    // اگر محدوده خیلی کوچک است، از مقادیر پیش‌فرض استفاده کنیم
    if (calculatedMax - calculatedMin < 5.0) {
      return {'min': 20.0, 'max': 50.0};
    }

    return {
      'min': calculatedMin,
      'max': calculatedMax,
    };
  }

  String _getMonthName(int month) {
    print('=== دیباگ _getMonthName ===');
    print('ماه ورودی: $month');

    String monthName;
    switch (month) {
      case 1:
        monthName = 'فروردین';
        break;
      case 2:
        monthName = 'اردیبهشت';
        break;
      case 3:
        monthName = 'خرداد';
        break;
      case 4:
        monthName = 'تیر';
        break;
      case 5:
        monthName = 'مرداد';
        break;
      case 6:
        monthName = 'شهریور';
        break;
      case 7:
        monthName = 'مهر';
        break;
      case 8:
        monthName = 'آبان';
        break;
      case 9:
        monthName = 'آذر';
        break;
      case 10:
        monthName = 'دی';
        break;
      case 11:
        monthName = 'بهمن';
        break;
      case 12:
        monthName = 'اسفند';
        break;
      default:
        monthName = 'نامشخص';
    }

    print('نام ماه: $monthName');
    print('==========================');
    return monthName;
  }
}
