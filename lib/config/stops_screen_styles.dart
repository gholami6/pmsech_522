import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'stop_colors.dart';

class StopsScreenStyles {
  // استایل‌های کارت‌ها
  static const cardPadding = EdgeInsets.all(12.0);
  static const cardMargin =
      EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0);
  static const cardBorderRadius = BorderRadius.all(Radius.circular(8.0));
  static const cardElevation = 2.0;

  // استایل‌های عنوان
  static const titleStyle = TextStyle(
    fontSize: 16.0,
    fontWeight: FontWeight.bold,
    fontFamily: 'Vazirmatn',
    color: AppColors.stopsTextPrimary,
  );

  static const subtitleStyle = TextStyle(
    fontSize: 14.0,
    fontWeight: FontWeight.w600,
    fontFamily: 'Vazirmatn',
    color: AppColors.neutralColor,
  );

  // استایل‌های متن
  static const bodyTextStyle = TextStyle(
    fontSize: 12.0,
    fontFamily: 'Vazirmatn',
    color: AppColors.stopsTextPrimary,
  );

  // استایل‌های دکمه‌ها
  static const buttonStyle = TextStyle(
    fontSize: 12.0,
    fontFamily: 'Vazirmatn',
    fontWeight: FontWeight.w500,
  );

  // استایل‌های فیلتر
  static const filterChipStyle = TextStyle(
    fontSize: 11.0,
    fontFamily: 'Vazirmatn',
  );

  // رنگ‌های کارت‌ها
  static const cardBackgroundColor = Colors.white;
  static const cardBorderColor = AppColors.stopsShadow;

  // استایل‌های نمودار
  static const chartTitleStyle = TextStyle(
    fontSize: 14.0,
    fontWeight: FontWeight.bold,
    fontFamily: 'Vazirmatn',
    color: AppColors.stopsTextPrimary,
  );

  // استایل‌های آمار
  static const statValueStyle = TextStyle(
    fontSize: 18.0,
    fontWeight: FontWeight.bold,
    fontFamily: 'Vazirmatn',
    color: AppColors.stopsTextPrimary,
  );

  static const statLabelStyle = TextStyle(
    fontSize: 11.0,
    fontFamily: 'Vazirmatn',
    color: AppColors.neutralColor,
  );
}
