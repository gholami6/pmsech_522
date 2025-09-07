import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:ui';
import '../config/stop_colors.dart';

// کلاس برای رسم خط اتصال tooltip
class ConnectionLinePainter extends CustomPainter {
  final Color color;

  ConnectionLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // خط اتصال برای tooltip کوچک
    if (size.width < 50) {
      final path = Path()
        ..moveTo(size.width, size.height / 2)
        ..lineTo(0, size.height / 2);
      canvas.drawPath(path, paint);
    } else {
      // خط اتصال برای باکس اطلاعات بزرگ
      final path = Path()
        ..moveTo(size.width / 2, 0)
        ..lineTo(size.width / 2, size.height);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class PieChartWidget extends StatefulWidget {
  final Map<String, int> stopsByTypeDuration;
  final int totalActualStops;
  final Function(String)? onSliceTap;
  final Function(String)? onLegendTap;

  const PieChartWidget({
    Key? key,
    required this.stopsByTypeDuration,
    required this.totalActualStops,
    this.onSliceTap,
    this.onLegendTap,
  }) : super(key: key);

  @override
  State<PieChartWidget> createState() => _PieChartWidgetState();
}

class _PieChartWidgetState extends State<PieChartWidget>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  String? _selectedStopType;

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
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.stopsByTypeDuration.isEmpty) {
      return _buildEmptyChart();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: _buildPieChart(),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 1,
                child: _buildLegend(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFF1976D2).withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Icon(
            Icons.pie_chart,
            color: Color(0xFF1976D2),
            size: 16,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'نمودار توزیع توقفات',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.grey[800],
            fontFamily: 'Vazirmatn',
          ),
        ),
      ],
    );
  }

  Widget _buildPieChart() {
    final sections = <PieChartSectionData>[];
    int index = 0;

    widget.stopsByTypeDuration.forEach((stopType, duration) {
      final percentage = (duration / widget.totalActualStops) * 100;
      final color = StopColors.getColorForStopType(stopType);

      sections.add(
        PieChartSectionData(
          value: duration.toDouble(),
          title: '', // حذف درصد از روی اسلایس
          color: color,
          radius: _selectedStopType == stopType ? 60 : 55,
          titleStyle: const TextStyle(
            fontSize: 0, // مخفی کردن متن
            color: Colors.transparent,
          ),
          badgeWidget: _selectedStopType == stopType
              ? _buildSliceTooltip(stopType, duration, percentage)
              : null,
          badgePositionPercentageOffset: 1.4, // بیرون نمودار
        ),
      );
      index++;
    });

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Column(
          children: [
            SizedBox(
              height: 160,
              child: PieChart(
                PieChartData(
                  sections: sections,
                  centerSpaceRadius: 30,
                  sectionsSpace: 2,
                  startDegreeOffset: -90,
                  pieTouchData: PieTouchData(
                    touchCallback: (FlTouchEvent event, pieTouchResponse) {
                      if (event is! FlPointerHoverEvent &&
                          pieTouchResponse != null) {
                        final touchedIndex = pieTouchResponse
                            .touchedSection?.touchedSectionIndex;
                        final stopTypes =
                            widget.stopsByTypeDuration.keys.toList();
                        if (touchedIndex != null &&
                            touchedIndex >= 0 &&
                            touchedIndex < stopTypes.length) {
                          final stopType = stopTypes[touchedIndex];
                          setState(() {
                            _selectedStopType =
                                _selectedStopType == stopType ? null : stopType;
                          });

                          if (widget.onSliceTap != null) {
                            widget.onSliceTap!(stopType);
                          }
                        }
                      }
                    },
                  ),
                ),
              ),
            ),
            // باکس اطلاعات زیر نمودار
            if (_selectedStopType != null) ...[
              const SizedBox(height: 12),
              _buildInfoBox(),
            ],
          ],
        );
      },
    );
  }

  Widget _buildSliceTooltip(String stopType, int duration, double percentage) {
    return Stack(
      children: [
        // خط اتصال به اسلایس
        Positioned(
          left: -15,
          top: 15,
          child: CustomPaint(
            size: const Size(15, 15),
            painter: ConnectionLinePainter(
              color: StopColors.getColorForStopType(stopType),
            ),
          ),
        ),
        // tooltip کوچک‌تر و بیرون از نمودار
        Positioned(
          left: -120,
          top: -10,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
              border: Border.all(
                color: StopColors.getColorForStopType(stopType),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: StopColors.getColorForStopType(stopType),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      stopType,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${(duration / 60).toStringAsFixed(1)} ساعت',
                  style: const TextStyle(
                    fontSize: 9,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                Text(
                  '${percentage.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    fontSize: 9,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoBox() {
    if (_selectedStopType == null) return const SizedBox.shrink();

    final duration = widget.stopsByTypeDuration[_selectedStopType!] ?? 0;
    final percentage = (duration / widget.totalActualStops) * 100;
    final color = StopColors.getColorForStopType(_selectedStopType!);

    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ردیف اول: نام نوع توقف با آیکن رنگ
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _selectedStopType!,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Vazirmatn',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // ردیف دوم: مدت به ساعت
          Text(
            '${(duration / 60).toStringAsFixed(1)} ساعت',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: color,
              fontFamily: 'Vazirmatn',
              fontFeatures: [FontFeature.tabularFigures()],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          // ردیف سوم: درصد
          Text(
            '${percentage.toStringAsFixed(1)}%',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
              fontFamily: 'Vazirmatn',
              fontFeatures: [FontFeature.tabularFigures()],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widget.stopsByTypeDuration.entries.map((entry) {
        final stopType = entry.key;
        final duration = entry.value;
        final percentage = (duration / widget.totalActualStops) * 100;
        final color = StopColors.getColorForStopType(stopType);

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: InkWell(
            onTap: () {
              if (widget.onLegendTap != null) {
                widget.onLegendTap!(stopType);
              }
            },
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    stopType,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[700],
                      fontFamily: 'Vazirmatn',
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEmptyChart() {
    return Container(
      height: 250,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.pie_chart,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'داده‌ای برای نمایش وجود ندارد',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontFamily: 'Vazirmatn',
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
