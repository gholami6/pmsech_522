import 'package:flutter/material.dart';
import '../config/stops_screen_styles.dart';

class StopsStatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final IconData? icon;
  final Color? iconColor;

  const StopsStatCard({
    Key? key,
    required this.label,
    required this.value,
    this.valueColor,
    this.icon,
    this.iconColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12.0),
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
            blurRadius: 2.0,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              color: iconColor ?? StopsScreenStyles.cardBorderColor,
              size: 20.0,
            ),
            const SizedBox(height: 4.0),
          ],
          Text(
            value,
            style: StopsScreenStyles.statValueStyle.copyWith(
              color: valueColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2.0),
          Text(
            label,
            style: StopsScreenStyles.statLabelStyle,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
