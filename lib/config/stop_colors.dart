import 'package:flutter/material.dart';

class StopColors {
  // رنگ‌های ثابت برای انواع توقف
  static const Map<String, Color> stopTypeColors = {
    'برنامه ای': Color(0xFF2196F3), // آبی
    'مکانیکی': Color(0xFFF44336), // قرمز
    'برقی': Color(0xFFFF9800), // نارنجی
    'تاسیساتی': Color(0xFF9C27B0), // بنفش
    'بهره برداری': Color(0xFF4CAF50), // سبز
    'معدنی': Color(0xFF795548), // قهوه‌ای
    'عمومی': Color(0xFF9E9E9E), // خاکستری
    'مجاز': Color(0xFF00BCD4), // فیروزه‌ای
    'بارگیری': Color(0xFFE91E63), // صورتی
  };

  // دریافت رنگ برای نوع توقف
  static Color getColorForStopType(String stopType) {
    return stopTypeColors[stopType] ?? Colors.grey;
  }

  // دریافت لیست رنگ‌ها برای نمودار
  static List<Color> getColorsList() {
    return stopTypeColors.values.toList();
  }

  // دریافت نام‌های انواع توقف
  static List<String> getStopTypeNames() {
    return stopTypeColors.keys.toList();
  }
}
