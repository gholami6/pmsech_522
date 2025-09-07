import 'package:flutter/material.dart';
import 'box_configs.dart';

class GeneralBoxStyles {
  // استایل عمومی برای همه باکس‌ها
  static BoxDecoration get generalBoxDecoration => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(BorderRadiusStandards.mainBox),
        boxShadow: [
          BoxShadow(
            color: GeneralBoxConfig.boxShadowColor,
            blurRadius: GeneralBoxConfig.boxShadowBlur,
            offset: GeneralBoxConfig.boxShadowOffset,
          ),
        ],
        // حذف حاشیه برای یکسان‌سازی
      );

  // استایل برای باکس‌های بدون حاشیه
  static BoxDecoration get boxWithoutBorder => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(BorderRadiusStandards.mainBox),
        boxShadow: [
          BoxShadow(
            color: GeneralBoxConfig.boxShadowColor,
            blurRadius: GeneralBoxConfig.boxShadowBlur,
            offset: GeneralBoxConfig.boxShadowOffset,
          ),
        ],
      );

  // استایل برای باکس‌های رنگی
  static BoxDecoration coloredBox(Color backgroundColor) => BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(BorderRadiusStandards.mainBox),
        boxShadow: [
          BoxShadow(
            color: GeneralBoxConfig.boxShadowColor,
            blurRadius: GeneralBoxConfig.boxShadowBlur,
            offset: GeneralBoxConfig.boxShadowOffset,
          ),
        ],
      );

  // استایل برای باکس‌های دکمه‌ای
  static BoxDecoration get buttonBoxDecoration => BoxDecoration(
        color: Colors.blue[600],
        borderRadius: BorderRadius.circular(BorderRadiusStandards.button),
        boxShadow: [
          BoxShadow(
            color: GeneralBoxConfig.boxShadowColor,
            blurRadius: GeneralBoxConfig.boxShadowBlur,
            offset: GeneralBoxConfig.boxShadowOffset,
          ),
        ],
      );

  // استایل برای باکس‌های جدول
  static BoxDecoration get tableBoxDecoration => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(BorderRadiusStandards.table),
        boxShadow: [
          BoxShadow(
            color: GeneralBoxConfig.boxShadowColor,
            blurRadius: GeneralBoxConfig.boxShadowBlur,
            offset: GeneralBoxConfig.boxShadowOffset,
          ),
        ],
      );

  // استایل برای باکس‌های فرم
  static BoxDecoration get formBoxDecoration => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(BorderRadiusStandards.contentCard),
        boxShadow: [
          BoxShadow(
            color: GeneralBoxConfig.boxShadowColor,
            blurRadius: GeneralBoxConfig.boxShadowBlur,
            offset: GeneralBoxConfig.boxShadowOffset,
          ),
        ],
        border: Border.all(
          color: Colors.grey[300]!,
          width: 1.0,
        ),
      );

  // استایل برای باکس‌های هشدار
  static BoxDecoration get alertBoxDecoration => BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(BorderRadiusStandards.contentCard),
        boxShadow: [
          BoxShadow(
            color: GeneralBoxConfig.boxShadowColor,
            blurRadius: GeneralBoxConfig.boxShadowBlur,
            offset: GeneralBoxConfig.boxShadowOffset,
          ),
        ],
        border: Border.all(
          color: Colors.orange[200]!,
          width: 1.0,
        ),
      );

  // استایل برای باکس‌های موفقیت
  static BoxDecoration get successBoxDecoration => BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(BorderRadiusStandards.contentCard),
        boxShadow: [
          BoxShadow(
            color: GeneralBoxConfig.boxShadowColor,
            blurRadius: GeneralBoxConfig.boxShadowBlur,
            offset: GeneralBoxConfig.boxShadowOffset,
          ),
        ],
        border: Border.all(
          color: Colors.green[200]!,
          width: 1.0,
        ),
      );

  // استایل برای باکس‌های خطا
  static BoxDecoration get errorBoxDecoration => BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(BorderRadiusStandards.contentCard),
        boxShadow: [
          BoxShadow(
            color: GeneralBoxConfig.boxShadowColor,
            blurRadius: GeneralBoxConfig.boxShadowBlur,
            offset: GeneralBoxConfig.boxShadowOffset,
          ),
        ],
        border: Border.all(
          color: Colors.red[200]!,
          width: 1.0,
        ),
      );

  // استایل برای باکس‌های اطلاعات
  static BoxDecoration get infoBoxDecoration => BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(BorderRadiusStandards.contentCard),
        boxShadow: [
          BoxShadow(
            color: GeneralBoxConfig.boxShadowColor,
            blurRadius: GeneralBoxConfig.boxShadowBlur,
            offset: GeneralBoxConfig.boxShadowOffset,
          ),
        ],
        border: Border.all(
          color: Colors.blue[200]!,
          width: 1.0,
        ),
      );
}
