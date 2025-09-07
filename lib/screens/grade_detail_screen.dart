import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_colors.dart';
import '../providers/data_provider.dart';
import '../services/grade_service.dart';
import '../models/production_data.dart';
import '../widgets/page_header.dart';
import '../config/box_configs.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';

class GradeDetailScreen extends StatefulWidget {
  final String gradeType;

  const GradeDetailScreen({
    super.key,
    required this.gradeType,
  });

  @override
  State<GradeDetailScreen> createState() => _GradeDetailScreenState();
}

class _GradeDetailScreenState extends State<GradeDetailScreen> {
  Jalali? _startDate;
  Jalali? _endDate;
  String _selectedRange = 'روزانه';
  bool _isReportGenerated = false;
  List<Map<String, dynamic>> _reportData = [];
  double _averageGrade = 0.0;
  double _plannedGrade = 0.0;

  final List<String> _rangeTypes = ['روزانه', 'هفتگی', 'ماهیانه', 'شیفتی'];

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.stopsAppBar,
        body: SafeArea(
          child: Column(
            children: [
              PageHeader(
                title: 'جزئیات عیار ${widget.gradeType}',
                backRoute: '/dashboard',
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
                        // عنوان
                        Text(
                          'گزارش تفصیلی عیار ${widget.gradeType}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: _getGradeColor(),
                          ),
                        ),
                        const SizedBox(height: 24),
                        // انتخاب بازه زمانی
                        _buildDateRangeSelector(),
                        const SizedBox(height: 16),
                        // انتخاب نوع بازه
                        _buildRangeSelector(),
                        const SizedBox(height: 24),
                        // دکمه تولید گزارش
                        if (_startDate != null && _endDate != null)
                          ElevatedButton.icon(
                            onPressed: _generateReport,
                            icon: const Icon(Icons.analytics),
                            label: const Text('تولید گزارش'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _getGradeColor(),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              textStyle: const TextStyle(fontSize: 16),
                            ),
                          ),
                        // نمایش گزارش
                        if (_isReportGenerated) ...[
                          const SizedBox(height: 32),
                          _buildReportSection(),
                        ],
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

  /// انتخاب بازه زمانی
  Widget _buildDateRangeSelector() {
    final dateRangeConfig = BoxConfigs.dateRange;
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: 6),
      padding: EdgeInsets.all(dateRangeConfig.padding),
      decoration: BoxDecoration(
        color: dateRangeConfig.backgroundColorExpanded,
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
          Text(
            'بازه زمانی گزارش',
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
            onTap: () => _selectDateRange(context),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.arrow_drop_down, color: dateRangeConfig.iconColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _startDate != null && _endDate != null
                          ? 'از ${_startDate!.year}/${_startDate!.month}/${_startDate!.day} تا ${_endDate!.year}/${_endDate!.month}/${_endDate!.day}'
                          : 'انتخاب بازه زمانی',
                      style: TextStyle(color: dateRangeConfig.valueColor),
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                    ),
                  ),
                  Icon(Icons.calendar_today, color: dateRangeConfig.iconColor),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// انتخاب بازه زمانی با تقویم
  Future<void> _selectDateRange(BuildContext context) async {
    final now = Jalali.now();
    final firstDate = Jalali(1400, 1, 1);
    final lastDate = Jalali(now.year + 1, 12, 29);
    JalaliRange? initialRange;

    if (_startDate != null && _endDate != null) {
      final startJalali = Jalali.fromDateTime(_startDate!.toDateTime());
      final endJalali = Jalali.fromDateTime(_endDate!.toDateTime());
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
        _startDate = picked.start;
        _endDate = picked.end;
        _isReportGenerated = false;
      });
    }
  }

  /// انتخاب نوع بازه
  Widget _buildRangeSelector() {
    final dateRangeConfig = BoxConfigs.dateRange;
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: 6),
      padding: EdgeInsets.all(dateRangeConfig.padding),
      decoration: BoxDecoration(
        color: dateRangeConfig.backgroundColorExpanded,
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
          Text(
            'نوع بازه گزارش',
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
          DropdownButtonFormField<String>(
            value: _selectedRange,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: dateRangeConfig.editIconColor),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: _rangeTypes.map((range) {
              return DropdownMenuItem(
                value: range,
                child: Text(range),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedRange = value!;
                _isReportGenerated = false;
              });
            },
          ),
        ],
      ),
    );
  }

  /// تولید گزارش
  Future<void> _generateReport() async {
    if (_startDate == null || _endDate == null) return;

    setState(() {
      _isReportGenerated = false;
    });

    try {
      // دانلود داده‌های عیار از هاست
      print('=== دانلود داده‌های عیار برای گزارش ===');
      await GradeService.downloadGradesFromServer();

      // دیباگ داده‌های موجود در دیتابیس
      print('=== بررسی داده‌های موجود در دیتابیس ===');
      await GradeService.debugGradeData();

      // دریافت داده‌های تولید
      final productionData = Provider.of<DataProvider>(context, listen: false)
          .getProductionDataByDateRange(
              _startDate!.toDateTime(), _endDate!.toDateTime());

      // محاسبه میانگین عیار
      final averages = await GradeService.getAverageGradeForDateRange(
        _startDate!.toDateTime(),
        _endDate!.toDateTime(),
      );
      final averageGrade = averages[widget.gradeType] ?? 0.0;

      // محاسبه مقدار برنامه‌ای
      final plannedGrade = _getPlannedGrade(widget.gradeType);

      // تولید داده‌های گزارش بر اساس نوع بازه
      final reportData = await _generateReportData();

      setState(() {
        _averageGrade = averageGrade;
        _plannedGrade = plannedGrade;
        _reportData = reportData;
        _isReportGenerated = true;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطا در تولید گزارش: $e')),
      );
    }
  }

  /// تولید داده‌های گزارش بر اساس نوع بازه
  Future<List<Map<String, dynamic>>> _generateReportData() async {
    final List<Map<String, dynamic>> data = [];

    print('=== دیباگ _generateReportData ===');
    print('نوع بازه: $_selectedRange');
    print('نوع عیار: ${widget.gradeType}');
    print(
        'تاریخ شروع: ${_startDate?.year}/${_startDate?.month}/${_startDate?.day}');
    print('تاریخ پایان: ${_endDate?.year}/${_endDate?.month}/${_endDate?.day}');

    double plannedValue = _plannedGrade;
    // اگر خوراک است، همیشه ۳۰
    if (widget.gradeType == 'خوراک') plannedValue = 30.0;

    switch (_selectedRange) {
      case 'روزانه':
        DateTime current = _startDate!.toDateTime();
        while (!current.isAfter(_endDate!.toDateTime())) {
          final jalali = Jalali.fromDateTime(current);
          final averages =
              await GradeService.getAverageGradeForDateRange(current, current);
          final grade = averages[widget.gradeType] ?? 0.0;
          data.add({
            'period': '${jalali.year}/${jalali.month}/${jalali.day}',
            'value': grade,
            'planned': plannedValue,
          });
          current = current.add(const Duration(days: 1));
        }
        break;
      case 'ماهیانه':
        int currentYear = _startDate!.year;
        int currentMonth = _startDate!.month;
        final endYear = _endDate!.year;
        final endMonth = _endDate!.month;
        while (currentYear < endYear ||
            (currentYear == endYear && currentMonth <= endMonth)) {
          final monthStart = Jalali(currentYear, currentMonth, 1).toDateTime();
          final monthEnd = Jalali(currentYear, currentMonth,
                  Jalali(currentYear, currentMonth).monthLength)
              .toDateTime();
          final averages = await GradeService.getAverageGradeForDateRange(
              monthStart, monthEnd);
          final grade = averages[widget.gradeType] ?? 0.0;
          data.add({
            'period': '$currentYear/$currentMonth',
            'value': grade,
            'planned': plannedValue,
          });
          currentMonth++;
          if (currentMonth > 12) {
            currentMonth = 1;
            currentYear++;
          }
        }
        break;
      case 'هفتگی':
        DateTime current = _startDate!.toDateTime();
        int weekNumber = 1;
        while (!current.isAfter(_endDate!.toDateTime())) {
          final weekEnd = current.add(const Duration(days: 6));
          final actualWeekEnd = weekEnd.isAfter(_endDate!.toDateTime())
              ? _endDate!.toDateTime()
              : weekEnd;
          final averages = await GradeService.getAverageGradeForDateRange(
              current, actualWeekEnd);
          final grade = averages[widget.gradeType] ?? 0.0;
          data.add({
            'period': 'هفته $weekNumber',
            'value': grade,
            'planned': plannedValue,
          });
          current = actualWeekEnd.add(const Duration(days: 1));
          weekNumber++;
        }
        break;
      case 'شیفتی':
        DateTime current = _startDate!.toDateTime();
        while (!current.isAfter(_endDate!.toDateTime())) {
          final jalali = Jalali.fromDateTime(current);

          for (int shift = 1; shift <= 3; shift++) {
            final shiftGrades = await GradeService.getGradeDataByShift(
                jalali.year, jalali.month, jalali.day, shift);

            // فقط داده‌های مربوط به نوع عیار مورد نظر
            final relevantGrades = shiftGrades
                .where((g) => g.gradeType == widget.gradeType)
                .map((g) => g.gradeValue)
                .toList();

            // دیباگ برای شیفت
            print(
                '  ${jalali.year}/${jalali.month}/${jalali.day} - شیفت $shift:');
            print('    کل داده‌های شیفت: ${shiftGrades.length}');
            print('    داده‌های ${widget.gradeType}: ${relevantGrades.length}');
            if (relevantGrades.isNotEmpty) {
              print(
                  '    مقادیر: ${relevantGrades.map((v) => v.toStringAsFixed(2)).join(', ')}');
            }

            // اگر داده‌ای برای این نوع عیار در این شیفت وجود ندارد، مقدار 0 برگردان
            final gradeForShift = relevantGrades.isNotEmpty
                ? relevantGrades.reduce((a, b) => a + b) / relevantGrades.length
                : 0.0;

            data.add({
              'period':
                  '${jalali.year}/${jalali.month}/${jalali.day} - شیفت $shift',
              'value': gradeForShift,
              'planned': plannedValue,
            });
          }

          current = current.add(const Duration(days: 1));
        }
        break;
    }

    print('=== پایان دیباگ _generateReportData ===');
    print('تعداد داده‌های تولید شده: ${data.length}');
    return data;
  }

  /// نمایش بخش گزارش
  Widget _buildReportSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // خلاصه گزارش
        Card(
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  'خلاصه گزارش عیار ${widget.gradeType}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _getGradeColor(),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildSummaryItem('میانگین محقق شده',
                        '${_averageGrade.toStringAsFixed(2)}%'),
                    _buildSummaryItem(
                        'مقدار برنامه', '${_plannedGrade.toStringAsFixed(1)}%'),
                    _buildSummaryItem('انحراف',
                        '${(_averageGrade - _plannedGrade).toStringAsFixed(2)}%'),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // نمودار
        if (_reportData.isNotEmpty) ...[
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'نمودار عیار ${widget.gradeType} (${_selectedRange})',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 300,
                    child: LineChart(
                      LineChartData(
                        gridData: FlGridData(show: true),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  '${value.toStringAsFixed(1)}%',
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
                                final idx = value.toInt();
                                if (idx < 0 || idx >= _reportData.length) {
                                  return const SizedBox();
                                }
                                return Text(
                                  _reportData[idx]['period'].toString(),
                                  style: const TextStyle(fontSize: 8),
                                  textAlign: TextAlign.center,
                                );
                              },
                              interval: 1,
                            ),
                          ),
                        ),
                        borderData: FlBorderData(show: true),
                        minX: 0,
                        maxX: (_reportData.length - 1).toDouble(),
                        minY: _calculateMinY(),
                        maxY: _calculateMaxY(),
                        lineBarsData: [
                          // خط واقعی
                          LineChartBarData(
                            spots: [
                              for (int i = 0; i < _reportData.length; i++)
                                FlSpot(i.toDouble(),
                                    _reportData[i]['value'] ?? 0.0),
                            ],
                            isCurved: true,
                            color: _getGradeColor(),
                            barWidth: 3,
                            dotData: FlDotData(show: true),
                          ),
                          // خط برنامه
                          LineChartBarData(
                            spots: [
                              for (int i = 0; i < _reportData.length; i++)
                                FlSpot(i.toDouble(), _plannedGrade),
                            ],
                            isCurved: false,
                            color: Colors.grey,
                            barWidth: 2,
                            dotData: FlDotData(show: false),
                            dashArray: [8, 4],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],

        // جدول جزئیات
        if (_reportData.isNotEmpty) ...[
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'جدول جزئیات (${_selectedRange})',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('دوره')),
                        DataColumn(label: Text('عیار محقق شده')),
                        DataColumn(label: Text('عیار برنامه')),
                        DataColumn(label: Text('انحراف')),
                      ],
                      rows: _reportData.map((data) {
                        final achieved = data['value'] as double;
                        final planned = data['planned'] as double;
                        final deviation = achieved - planned;

                        return DataRow(cells: [
                          DataCell(Text(data['period'].toString())),
                          DataCell(Text('${achieved.toStringAsFixed(2)}%')),
                          DataCell(Text('${planned.toStringAsFixed(1)}%')),
                          DataCell(
                            Text(
                              '${deviation.toStringAsFixed(2)}%',
                              style: TextStyle(
                                color:
                                    deviation >= 0 ? Colors.green : Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ]);
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  /// آیتم خلاصه
  Widget _buildSummaryItem(String title, String value) {
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: _getGradeColor(),
          ),
        ),
      ],
    );
  }

  /// رنگ عیار
  Color _getGradeColor() {
    switch (widget.gradeType) {
      case 'خوراک':
        return AppColors.feedColor;
      case 'محصول':
        return AppColors.productColor;
      case 'باطله':
        return AppColors.tailingColor;
      default:
        return Colors.blue;
    }
  }

  /// مقدار برنامه‌ای عیار
  double _getPlannedGrade(String gradeType) {
    switch (gradeType) {
      case 'خوراک':
        return 30.0;
      case 'محصول':
        return 37.0;
      case 'باطله':
        return 12.0;
      default:
        return 0.0;
    }
  }

  /// محاسبه حداقل محور Y
  double _calculateMinY() {
    if (_reportData.isEmpty) return 0.0;
    // هم مقدار واقعی و هم برنامه‌ای را در نظر بگیر
    final values = _reportData
        .expand((d) =>
            [d['value'] as double? ?? 0.0, d['planned'] as double? ?? 0.0])
        .where((v) => v > 0)
        .toList();
    if (values.isEmpty) return 0.0;
    final minValue = values.reduce((a, b) => a < b ? a : b);
    return (minValue * 0.9).clamp(0.0, double.infinity);
  }

  /// محاسبه حداکثر محور Y
  double _calculateMaxY() {
    if (_reportData.isEmpty) return 100.0;
    // هم مقدار واقعی و هم برنامه‌ای را در نظر بگیر
    final values = _reportData
        .expand((d) =>
            [d['value'] as double? ?? 0.0, d['planned'] as double? ?? 0.0])
        .toList();
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    return (maxValue * 1.1).clamp(0.0, double.infinity);
  }
}
