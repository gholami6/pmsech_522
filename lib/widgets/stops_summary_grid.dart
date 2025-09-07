import 'package:flutter/material.dart';
import '../config/stops_screen_styles.dart';
import 'stops_stat_card.dart';

class StopsSummaryGrid extends StatelessWidget {
  final Map<String, String> stats;
  final Map<String, Color>? valueColors;
  final Map<String, IconData>? icons;

  const StopsSummaryGrid({
    Key? key,
    required this.stats,
    this.valueColors,
    this.icons,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: StopsScreenStyles.cardMargin,
      padding: StopsScreenStyles.cardPadding,
      decoration: BoxDecoration(
        color: StopsScreenStyles.cardBackgroundColor,
        borderRadius: StopsScreenStyles.cardBorderRadius,
        border: Border.all(
          color: StopsScreenStyles.cardBorderColor,
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: StopsScreenStyles.cardBorderColor.withOpacity(0.1),
            blurRadius: 4.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'آمار کلی',
            style: StopsScreenStyles.titleStyle,
          ),
          const SizedBox(height: 12.0),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12.0,
              mainAxisSpacing: 12.0,
              childAspectRatio: 1.5,
            ),
            itemCount: stats.length,
            itemBuilder: (context, index) {
              final label = stats.keys.elementAt(index);
              final value = stats.values.elementAt(index);
              final color = valueColors?[label];
              final icon = icons?[label];

              return StopsStatCard(
                label: label,
                value: value,
                valueColor: color,
                icon: icon,
              );
            },
          ),
        ],
      ),
    );
  }
}
