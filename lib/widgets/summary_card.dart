import 'package:flutter/material.dart';
import 'general_box_widget.dart';

class SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color backgroundColor;
  final Color textColor;

  const SummaryCard({
    Key? key,
    required this.title,
    required this.value,
    required this.icon,
    required this.backgroundColor,
    this.textColor = Colors.white,
  }) : super(key: key);

  // استخراج عدد از مقدار (مثل "10.9 ساعت" -> 10.9)
  double _extractNumber(String value) {
    try {
      // حذف واحدها و استخراج عدد
      final numberMatch = RegExp(r'([\d.]+)').firstMatch(value);
      if (numberMatch != null) {
        return double.parse(numberMatch.group(1)!);
      }
      return 0.0;
    } catch (e) {
      return 0.0;
    }
  }

  // استخراج واحد از مقدار (مثل "10.9 ساعت" -> " ساعت")
  String _extractUnit(String value) {
    try {
      final numberMatch = RegExp(r'([\d.]+)').firstMatch(value);
      if (numberMatch != null) {
        return value.substring(numberMatch.end);
      }
      return '';
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final number = _extractNumber(value);
    final unit = _extractUnit(value);

    return GeneralBox(
      width: double.infinity,
      padding: const EdgeInsets.all(12), // کاهش از 16 به 12
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(24),
        // حذف حاشیه برای یکسان‌سازی
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: textColor,
            size: 24, // کاهش از 32 به 24
          ),
          const SizedBox(height: 6), // کاهش از 8 به 6
          Text(
            title,
            style: TextStyle(
              color: textColor,
              fontSize: 12, // کاهش از 14 به 12
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 3), // کاهش از 4 به 3
          // انیمیشن برای عدد
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 1200),
            curve: Curves.easeOutBack,
            tween: Tween(begin: 0.0, end: number),
            builder: (context, animatedValue, child) {
              return Text(
                '${animatedValue.toStringAsFixed(1)}$unit',
                style: TextStyle(
                  color: textColor,
                  fontSize: 14, // کاهش از 18 به 14
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              );
            },
          ),
        ],
      ),
    );
  }
}

// کانفیگ‌های استاندارد برای باکس‌های برنامه و واقعی
class SummaryCardConfigs {
  // کانفیگ باکس برنامه
  static const plannedCardConfig = SummaryCardConfig(
    backgroundColor: Color(0xFF2196F3), // آبی روشن
    textColor: Colors.white,
    icon: Icons.assignment,
  );

  // کانفیگ باکس واقعی
  static const actualCardConfig = SummaryCardConfig(
    backgroundColor: Color(0xFFFF9800), // نارنجی روشن
    textColor: Colors.white,
    icon: Icons.trending_up,
  );
}

class SummaryCardConfig {
  final Color backgroundColor;
  final Color textColor;
  final IconData icon;

  const SummaryCardConfig({
    required this.backgroundColor,
    required this.textColor,
    required this.icon,
  });
}
