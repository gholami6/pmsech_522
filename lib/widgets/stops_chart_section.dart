import 'package:flutter/material.dart';
import '../config/stops_screen_styles.dart';

class StopsChartSection extends StatelessWidget {
  final String title;
  final Widget chart;
  final String? subtitle;
  final VoidCallback? onTap;

  const StopsChartSection({
    Key? key,
    required this.title,
    required this.chart,
    this.subtitle,
    this.onTap,
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
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: StopsScreenStyles.chartTitleStyle,
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2.0),
                      Text(
                        subtitle!,
                        style: StopsScreenStyles.subtitleStyle,
                      ),
                    ],
                  ],
                ),
              ),
              if (onTap != null)
                IconButton(
                  onPressed: onTap,
                  icon: const Icon(Icons.fullscreen, size: 20.0),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
          const SizedBox(height: 12.0),
          SizedBox(
            height: 200.0,
            child: chart,
          ),
        ],
      ),
    );
  }
}
