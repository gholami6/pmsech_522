import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/production_data.dart';
import '../config/app_colors.dart';

class MonthlyProductionLineChart extends StatelessWidget {
  final List<double> feedActual;
  final List<double> productActual;
  final List<double> tailingActual;
  final List<double> feedPlan;
  final List<double> productPlan;
  final List<double> tailingPlan;
  final int daysInMonth;

  const MonthlyProductionLineChart({
    Key? key,
    required this.feedActual,
    required this.productActual,
    required this.tailingActual,
    required this.feedPlan,
    required this.productPlan,
    required this.tailingPlan,
    required this.daysInMonth,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // محور x: فقط هر ۵ روز یک برچسب
    List<int> xLabels = [];
    for (int i = 1; i <= daysInMonth; i++) {
      if (i == 1 || i % 5 == 0 || i == daysInMonth) xLabels.add(i);
    }

    double maxY = [
      ...feedActual,
      ...productActual,
      ...tailingActual,
      ...feedPlan,
      ...productPlan,
      ...tailingPlan
    ].fold<double>(0, (prev, e) => e > prev ? e : prev);
    maxY = ((maxY / 1000).ceil() * 1000).toDouble();

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: maxY,
        gridData: FlGridData(show: true, horizontalInterval: 1000),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 48,
              getTitlesWidget: (value, meta) {
                // رنگ‌بندی محور y بر اساس بازه
                Color color = AppColors.feedColor;
                if (value <= (maxY * 0.33)) {
                  color = AppColors.tailingColor;
                } else if (value <= (maxY * 0.66)) {
                  color = AppColors.productColor;
                }
                return Text(
                  (value ~/ 1000).toString(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                );
              },
              interval: 1000,
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                int day = value.toInt() + 1;
                if (xLabels.contains(day)) {
                  return Text(
                    day.toString(),
                    style: const TextStyle(fontSize: 12),
                  );
                }
                return const SizedBox.shrink();
              },
              reservedSize: 28,
              interval: 1,
            ),
          ),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: true),
        lineBarsData: [
          // Actual Feed
          LineChartBarData(
            spots: List.generate(
                feedActual.length, (i) => FlSpot(i.toDouble(), feedActual[i])),
            isCurved: true,
            color: AppColors.feedColor,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(show: false),
            curveSmoothness: 0.25,
            preventCurveOverShooting: true,
            dashArray: null,
          ),
          // Actual Product
          LineChartBarData(
            spots: List.generate(productActual.length,
                (i) => FlSpot(i.toDouble(), productActual[i])),
            isCurved: true,
            color: AppColors.productColor,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(show: false),
            curveSmoothness: 0.25,
            preventCurveOverShooting: true,
            dashArray: null,
          ),
          // Actual Tailing
          LineChartBarData(
            spots: List.generate(tailingActual.length,
                (i) => FlSpot(i.toDouble(), tailingActual[i])),
            isCurved: true,
            color: AppColors.tailingColor,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(show: false),
            curveSmoothness: 0.25,
            preventCurveOverShooting: true,
            dashArray: null,
          ),
          // Plan Feed
          LineChartBarData(
            spots: List.generate(
                feedPlan.length, (i) => FlSpot(i.toDouble(), feedPlan[i])),
            isCurved: true,
            color: AppColors.feedColor.withOpacity(0.5),
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(show: false),
            curveSmoothness: 0.25,
            preventCurveOverShooting: true,
            dashArray: [8, 4],
          ),
          // Plan Product
          LineChartBarData(
            spots: List.generate(productPlan.length,
                (i) => FlSpot(i.toDouble(), productPlan[i])),
            isCurved: true,
            color: AppColors.productColor.withOpacity(0.5),
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(show: false),
            curveSmoothness: 0.25,
            preventCurveOverShooting: true,
            dashArray: [8, 4],
          ),
          // Plan Tailing
          LineChartBarData(
            spots: List.generate(tailingPlan.length,
                (i) => FlSpot(i.toDouble(), tailingPlan[i])),
            isCurved: true,
            color: AppColors.tailingColor.withOpacity(0.5),
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(show: false),
            curveSmoothness: 0.25,
            preventCurveOverShooting: true,
            dashArray: [8, 4],
          ),
        ],
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            tooltipBgColor: Colors.white.withOpacity(0.9),
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final day = spot.x.toInt() + 1;
                final value = spot.y;
                return LineTooltipItem(
                  'روز $day\n${(value / 1000).toStringAsFixed(2)} هزار تن',
                  TextStyle(
                    color: spot.bar.color ?? Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }).toList();
            },
          ),
        ),
        showingTooltipIndicators: [],
        clipData: FlClipData.all(),
        backgroundColor: Colors.transparent,
        // افکت زنده: انیمیشن اولیه
        // (در صفحه والد باید AnimatedSwitcher یا AnimatedContainer استفاده شود)
      ),
      // پارامترهای swapAnimationDuration و swapAnimationCurve حذف شدند
    );
  }
}
