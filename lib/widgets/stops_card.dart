import 'package:flutter/material.dart';
import '../config/stops_screen_styles.dart';

class StopsCard extends StatelessWidget {
  final String title;
  final Widget child;
  final VoidCallback? onTap;
  final bool isExpanded;
  final Color? backgroundColor;
  final EdgeInsets? padding;

  const StopsCard({
    Key? key,
    required this.title,
    required this.child,
    this.onTap,
    this.isExpanded = false,
    this.backgroundColor,
    this.padding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: StopsScreenStyles.cardMargin,
      decoration: BoxDecoration(
        color: backgroundColor ?? StopsScreenStyles.cardBackgroundColor,
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: StopsScreenStyles.cardBorderRadius,
          child: Padding(
            padding: padding ?? StopsScreenStyles.cardPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: StopsScreenStyles.titleStyle,
                ),
                const SizedBox(height: 8.0),
                if (isExpanded) Expanded(child: child) else child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
