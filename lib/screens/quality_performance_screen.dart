import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_colors.dart';
import '../providers/data_provider.dart';
import '../services/grade_service.dart';
import '../services/auth_service.dart';
import '../models/production_data.dart';
import '../widgets/page_header.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';
import 'grade_detail_screen.dart';
import 'grade_entry_screen.dart';

class QualityPerformanceScreen extends StatefulWidget {
  const QualityPerformanceScreen({super.key});

  @override
  State<QualityPerformanceScreen> createState() =>
      _QualityPerformanceScreenState();
}

class _QualityPerformanceScreenState extends State<QualityPerformanceScreen> {
  bool _isFeedGradeExpanded = false;
  bool _isProductGradeExpanded = false;
  bool _isWasteGradeExpanded = false;
  bool _dataImported = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // همگام‌سازی خودکار حذف شد - کاربر می‌تواند دستی انجام دهد
    setState(() {
      _dataImported = true;
    });
  }

  /// همگام‌سازی دستی - قابل فراخوانی از دکمه آپدیت
  Future<void> _manualSync() async {
    try {
      print('🔄 صفحه عملکرد کیفی - شروع همگام‌سازی دستی...');
      setState(() {
        _isLoading = true;
      });

      // همگام‌سازی دستی
      final success = await GradeService.forceSync();

      if (success) {
        print('✅ همگام‌سازی دستی تکمیل شد');
        setState(() {
          _dataImported = true;
        });
      } else {
        print('⚠️ خطا در همگام‌سازی دستی');
      }
    } catch (e) {
      print('❌ خطا در همگام‌سازی دستی: $e');
      // حتی در صورت خطا، صفحه را به‌روزرسانی کن
      setState(() {
        _dataImported = true;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });

      // نمایش پیام نتیجه
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ همگام‌سازی عیارها تکمیل شد'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final isGradeEntryAllowed = true; // تمام کاربران دسترسی دارند

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.stopsAppBar,
        floatingActionButton: isGradeEntryAllowed
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // دکمه همگام‌سازی دستی
                  FloatingActionButton(
                    onPressed: _isLoading ? null : _manualSync,
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    mini: true,
                    child: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.sync, size: 20),
                    tooltip: 'همگام‌سازی دستی',
                  ),
                  const SizedBox(height: 8),
                  // دکمه ثبت عیار جدید
                  FloatingActionButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const GradeEntryScreen(),
                        ),
                      );
                    },
                    backgroundColor: AppColors.planColor,
                    foregroundColor: Colors.white,
                    child: const Icon(Icons.add),
                    tooltip: 'ثبت عیار جدید',
                  ),
                ],
              )
            : null,
        floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
        body: SafeArea(
          child: Column(
            children: [
              PageHeader(
                title: 'عملکرد کیفی تولید',
                backRoute: '/dashboard',
                actions: [],
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
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // کارت‌های عیار
                        FutureBuilder<List<double>>(
                          future: Future.wait([
                            _calculateGradeAverage('خوراک'),
                            _calculateGradeAverage('محصول'),
                            _calculateGradeAverage('باطله'),
                          ]),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                  child: CircularProgressIndicator());
                            }

                            if (snapshot.hasError) {
                              return Center(
                                child: Text('خطا: ${snapshot.error}'),
                              );
                            }

                            final feedAvg = snapshot.data?[0] ?? 0.0;
                            final productAvg = snapshot.data?[1] ?? 0.0;
                            final wasteAvg = snapshot.data?[2] ?? 0.0;

                            return Column(
                              children: [
                                // کارت عیار خوراک
                                _buildGradeCard(
                                  title: 'عیار خوراک',
                                  value: '${feedAvg.toStringAsFixed(1)}%',
                                  icon: Icons.input,
                                  color: AppColors.feedColor,
                                  isExpanded: _isFeedGradeExpanded,
                                  onToggle: () {
                                    setState(() {
                                      _isFeedGradeExpanded =
                                          !_isFeedGradeExpanded;
                                    });
                                  },
                                  gradeType: 'خوراک',
                                ),
                                const SizedBox(height: 16),

                                // کارت عیار محصول
                                _buildGradeCard(
                                  title: 'عیار محصول',
                                  value: '${productAvg.toStringAsFixed(1)}%',
                                  icon: Icons.output,
                                  color: AppColors.productColor,
                                  isExpanded: _isProductGradeExpanded,
                                  onToggle: () {
                                    setState(() {
                                      _isProductGradeExpanded =
                                          !_isProductGradeExpanded;
                                    });
                                  },
                                  gradeType: 'محصول',
                                ),
                                const SizedBox(height: 16),

                                // کارت عیار باطله
                                _buildGradeCard(
                                  title: 'عیار باطله',
                                  value: '${wasteAvg.toStringAsFixed(1)}%',
                                  icon: Icons.delete_outline,
                                  color: AppColors.tailingColor,
                                  isExpanded: _isWasteGradeExpanded,
                                  onToggle: () {
                                    setState(() {
                                      _isWasteGradeExpanded =
                                          !_isWasteGradeExpanded;
                                    });
                                  },
                                  gradeType: 'باطله',
                                ),
                              ],
                            );
                          },
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

  /// محاسبه میانگین ترکیبی عیار (از سرور + CSV تاریخی)
  Future<double> _calculateGradeAverage(String gradeType) async {
    // استفاده از منطق ترکیبی (بدون دیباگ برای سرعت بیشتر)
    return await GradeService.getCombinedMonthlyAverageForType(gradeType);
  }

  /// ساخت کارت عیار حرفه‌ای با قابلیت گسترش
  Widget _buildGradeCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required bool isExpanded,
    required VoidCallback onToggle,
    required String gradeType,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.1),
            color.withOpacity(0.05),
            Colors.white,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // هدر کارت
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Row(
              children: [
                // آیکون
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),

                // اطلاعات اصلی
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              color: Colors.black,
                              blurRadius: 0.5,
                              offset: Offset(0, 0),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            value,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              shadows: [
                                Shadow(
                                  color: Colors.black,
                                  blurRadius: 0.5,
                                  offset: Offset(0, 0),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'میانگین ماهانه',
                              style: TextStyle(
                                color: color,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // دکمه گسترش
                Container(
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: IconButton(
                    icon: Icon(
                      isExpanded ? Icons.expand_less : Icons.expand_more,
                      color: color,
                      size: 28,
                    ),
                    onPressed: onToggle,
                  ),
                ),
              ],
            ),
          ),

          // محتوای گسترش یافته
          if (isExpanded)
            Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: _buildGradeDetails(gradeType, color),
            ),
        ],
      ),
    );
  }

  /// ساخت جزئیات عیار حرفه‌ای (نمودار و جدول)
  Widget _buildGradeDetails(String gradeType, Color color) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _getDailyGradeData(gradeType),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(24),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'در حال بارگذاری داده‌ها...',
                      style: TextStyle(
                        color: color.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          if (snapshot.hasError) {
            return Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Colors.red[400],
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'خطا در بارگذاری داده‌ها',
                      style: TextStyle(
                        color: Colors.red[600],
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${snapshot.error}',
                      style: TextStyle(
                        color: Colors.red[500],
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          final dailyData = snapshot.data ?? [];

          if (dailyData.isEmpty) {
            return Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.inbox_outlined,
                      color: Colors.grey[400],
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'داده‌ای برای نمایش موجود نیست',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'لطفاً ابتدا داده‌های عیار را ثبت کنید',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // عنوان بخش
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.analytics_outlined,
                      color: color,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'تحلیل روند عیار $gradeType',
                      style: TextStyle(
                        color: color,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // نمودار خطی حرفه‌ای
              Container(
                height: 240,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.grey[200]!),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: true,
                      horizontalInterval: 5,
                      verticalInterval: 1,
                      getDrawingHorizontalLine: (value) {
                        return FlLine(
                          color: Colors.grey[300]!,
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
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 45,
                          interval: 5,
                          getTitlesWidget: (value, meta) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Text(
                                '${value.toInt()}%',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final idx = value.toInt();
                            if (idx < 0 || idx >= dailyData.length) {
                              return const SizedBox();
                            }
                            final day = dailyData[idx]['day'];
                            final gradeValue =
                                dailyData[idx]['value'] as double? ?? 0.0;

                            if (gradeValue > 0) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  '$day',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              );
                            }
                            return const SizedBox();
                          },
                          reservedSize: 30,
                          interval: 1,
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
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    minX: 0,
                    maxX: dailyData
                            .where((d) => (d['value'] as double? ?? 0.0) > 0)
                            .length
                            .toDouble() -
                        1,
                    minY: _calculateMinY(dailyData),
                    maxY: _calculateMaxY(dailyData),
                    lineBarsData: [
                      // خط واقعی
                      LineChartBarData(
                        spots: [
                          for (int i = 0; i < dailyData.length; i++)
                            if (dailyData[i]['value'] != null &&
                                dailyData[i]['value'] > 0)
                              FlSpot(
                                  i.toDouble(), dailyData[i]['value'] ?? 0.0),
                        ],
                        isCurved: true,
                        color: color,
                        barWidth: 4,
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, barData, index) {
                            return FlDotCirclePainter(
                              radius: 4,
                              color: color,
                              strokeWidth: 2,
                              strokeColor: Colors.white,
                            );
                          },
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          color: color.withOpacity(0.1),
                        ),
                      ),
                      // خط برنامه
                      LineChartBarData(
                        spots: [
                          for (int i = 0; i < dailyData.length; i++)
                            if (dailyData[i]['value'] != null &&
                                dailyData[i]['value'] > 0)
                              FlSpot(i.toDouble(), _getPlannedGrade(gradeType)),
                        ],
                        isCurved: false,
                        color: Colors.orange,
                        barWidth: 3,
                        dotData: FlDotData(show: false),
                        dashArray: [8, 4],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // راهنمای نمودار
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 16,
                      height: 4,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'مقدار واقعی',
                      style: TextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 24),
                    Container(
                      width: 16,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'مقدار برنامه‌ای',
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // جدول جزئیات حرفه‌ای
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.grey[200]!),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // هدر جدول
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(24),
                          topRight: Radius.circular(24),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.table_chart,
                            color: color,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'جزئیات روزانه',
                            style: TextStyle(
                              color: color,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // محتوای جدول
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingTextStyle: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        dataTextStyle: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                        columns: [
                          DataColumn(
                            label: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: const Text('تاریخ'),
                            ),
                          ),
                          DataColumn(
                            label: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: const Text('مقدار عیار'),
                            ),
                          ),
                          DataColumn(
                            label: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: const Text('وضعیت'),
                            ),
                          ),
                        ],
                        rows: [
                          for (final d in dailyData)
                            DataRow(
                              cells: [
                                DataCell(
                                  Text(
                                      '${d['year']}/${d['month']}/${d['day']}'),
                                ),
                                DataCell(
                                  Text(
                                    '${d['value'].toStringAsFixed(2)}%',
                                    style: TextStyle(
                                      color: color,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(
                                              d['value'] as double? ?? 0.0,
                                              gradeType)
                                          .withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      _getStatusText(
                                          d['value'] as double? ?? 0.0,
                                          gradeType),
                                      style: TextStyle(
                                        color: _getStatusColor(
                                            d['value'] as double? ?? 0.0,
                                            gradeType),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
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
              ),
              const SizedBox(height: 20),

              // دکمه اطلاعات بیشتر
              Center(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        color.withOpacity(0.1),
                        color.withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: color.withOpacity(0.3)),
                  ),
                  child: TextButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => GradeDetailScreen(
                            gradeType: gradeType,
                          ),
                        ),
                      );
                    },
                    icon: Icon(
                      Icons.analytics,
                      color: color,
                      size: 20,
                    ),
                    label: Text(
                      'تحلیل کامل عیار $gradeType',
                      style: TextStyle(
                        color: color,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// دریافت داده‌های روزانه فقط برای روزهایی که داده واقعی دارند
  Future<List<Map<String, dynamic>>> _getDailyGradeData(
      String gradeType) async {
    return await GradeService.getDailyValuesForMonth(gradeType);
  }

  /// محاسبه حداقل محور Y
  double _calculateMinY(List<Map<String, dynamic>> data) {
    if (data.isEmpty) return 0.0;

    // پیدا کردن کمترین مقدار غیر صفر
    final values = data
        .map((d) => d['value'] as double? ?? 0.0)
        .where((v) => v > 0)
        .toList();

    if (values.isEmpty) return 0.0;

    final minValue = values.reduce((a, b) => a < b ? a : b);

    // اضافه کردن حاشیه 5% به پایین
    final margin = minValue * 0.05;
    return (minValue - margin).clamp(0.0, double.infinity);
  }

  /// محاسبه حداکثر محور Y
  double _calculateMaxY(List<Map<String, dynamic>> data) {
    if (data.isEmpty) return 50.0; // مقدار پیش‌فرض منطقی

    final values = data
        .map((d) => d['value'] as double? ?? 0.0)
        .where((v) => v > 0)
        .toList();

    if (values.isEmpty) return 50.0;

    final maxValue = values.reduce((a, b) => a > b ? a : b);

    // اضافه کردن حاشیه 10% به بالا
    final margin = maxValue * 0.1;
    return (maxValue + margin)
        .clamp(0.0, 100.0); // محدود کردن به 100% به جای 50%
  }

  /// دریافت مقدار برنامه‌ای عیار از برنامه سالانه
  double _getPlannedGrade(String gradeType) {
    // مقادیر برنامه‌ای از برنامه سالانه
    switch (gradeType) {
      case 'خوراک':
        return 30.0; // درصد
      case 'محصول':
        return 37.0; // درصد
      case 'باطله':
        return 12.0; // درصد
      default:
        return 0.0;
    }
  }

  /// دریافت رنگ وضعیت بر اساس مقدار عیار
  Color _getStatusColor(double value, String gradeType) {
    final plannedValue = _getPlannedGrade(gradeType);
    final deviation = ((value - plannedValue) / plannedValue * 100).abs();

    if (deviation <= 5) {
      return Colors.green; // عالی
    } else if (deviation <= 10) {
      return Colors.orange; // قابل قبول
    } else {
      return Colors.red; // نیاز به بهبود
    }
  }

  /// دریافت متن وضعیت بر اساس مقدار عیار
  String _getStatusText(double value, String gradeType) {
    final plannedValue = _getPlannedGrade(gradeType);
    final deviation = ((value - plannedValue) / plannedValue * 100).abs();

    if (deviation <= 5) {
      return 'عالی';
    } else if (deviation <= 10) {
      return 'قابل قبول';
    } else {
      return 'نیاز به بهبود';
    }
  }

  // تابع _manualSync تکراری حذف شد - قبلاً در خط 39 تعریف شده است
}
