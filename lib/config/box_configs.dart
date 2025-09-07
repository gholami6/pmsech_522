import 'package:flutter/material.dart';

// کانفیگ باکس‌های برنامه و واقعی
class SummaryCardConfig {
  final Color backgroundColor;
  final Color textColor;
  final IconData icon;
  final double iconSize;
  final double padding;
  final double borderRadius;
  final Color borderColor;
  final double borderWidth;
  final Color boxShadowColor;
  final double boxShadowBlur;
  final Offset boxShadowOffset;
  final double titleFontSize;
  final FontWeight titleFontWeight;
  final double valueFontSize;
  final FontWeight valueFontWeight;
  final Duration animationDuration;
  final Curve animationCurve;

  const SummaryCardConfig({
    required this.backgroundColor,
    required this.textColor,
    required this.icon,
    this.iconSize = 24,
    this.padding = 12,
    this.borderRadius = 24, // افزایش انحنای گوشه‌ها
    this.borderColor = const Color(0x4D9E9E9E),
    this.borderWidth = 1.2,
    this.boxShadowColor = const Color(0x1A000000),
    this.boxShadowBlur = 6,
    this.boxShadowOffset = const Offset(0, 2),
    this.titleFontSize = 12,
    this.titleFontWeight = FontWeight.bold,
    this.valueFontSize = 14,
    this.valueFontWeight = FontWeight.bold,
    this.animationDuration = const Duration(milliseconds: 1200),
    this.animationCurve = Curves.easeOutBack,
  });
}

// کانفیگ باکس انحراف از برنامه
class DeviationBoxConfig {
  final Color backgroundColorPositive;
  final Color backgroundColorNegative;
  final Color backgroundColorZero;
  final Color textColor;
  final IconData icon;
  final double iconSize;
  final double padding;
  final double borderRadius;
  final Color borderColor;
  final double borderWidth;
  final Color boxShadowColor;
  final double boxShadowBlur;
  final Offset boxShadowOffset;
  final double titleFontSize;
  final FontWeight titleFontWeight;
  final double percentFontSize;
  final FontWeight percentFontWeight;
  final double diffFontSize;
  final FontWeight diffFontWeight;
  final Duration percentAnimationDuration;
  final Curve percentAnimationCurve;
  final Duration diffAnimationDuration;
  final Curve diffAnimationCurve;

  const DeviationBoxConfig({
    required this.backgroundColorPositive,
    required this.backgroundColorNegative,
    required this.backgroundColorZero,
    required this.textColor,
    required this.icon,
    this.iconSize = 20,
    this.padding = 12,
    this.borderRadius = 24, // افزایش انحنای گوشه‌ها
    this.borderColor = const Color(0x4D9E9E9E),
    this.borderWidth = 1.2,
    this.boxShadowColor = const Color(0x1A000000),
    this.boxShadowBlur = 6,
    this.boxShadowOffset = const Offset(0, 2),
    this.titleFontSize = 14,
    this.titleFontWeight = FontWeight.bold,
    this.percentFontSize = 18,
    this.percentFontWeight = FontWeight.bold,
    this.diffFontSize = 12,
    this.diffFontWeight = FontWeight.w600,
    this.percentAnimationDuration = const Duration(milliseconds: 1000),
    this.percentAnimationCurve = Curves.easeOutBack,
    this.diffAnimationDuration = const Duration(milliseconds: 1200),
    this.diffAnimationCurve = Curves.easeOutBack,
  });
}

// کانفیگ باکس انتخاب تاریخ
class DateRangeBoxConfig {
  final Color backgroundColorCollapsed;
  final Color backgroundColorExpanded;
  final Color borderColor;
  final double borderWidth;
  final double borderRadius;
  final Color boxShadowColor;
  final double boxShadowBlur;
  final Offset boxShadowOffset;
  final double padding;
  final double margin;
  final double titleFontSize;
  final FontWeight titleFontWeight;
  final Color titleColor;
  final double valueFontSize;
  final FontWeight valueFontWeight;
  final Color valueColor;
  final double iconSize;
  final Color iconColor;
  final double editIconSize;
  final Color editIconColor;
  final double tagFontSize;
  final Color tagBackgroundColor;
  final Color tagTextColor;
  final double tagBorderRadius;
  final Duration animationDuration;
  final Curve animationCurve;
  final double collapsedHeight;
  final double expandedHeight;

  const DateRangeBoxConfig({
    required this.backgroundColorCollapsed,
    required this.backgroundColorExpanded,
    required this.borderColor,
    this.borderWidth = 1.2,
    this.borderRadius = 24, // افزایش انحنای گوشه‌ها
    required this.boxShadowColor,
    this.boxShadowBlur = 6,
    this.boxShadowOffset = const Offset(0, 2),
    this.padding = 14,
    this.margin = 12,
    this.titleFontSize = 14,
    this.titleFontWeight = FontWeight.bold,
    required this.titleColor,
    this.valueFontSize = 11,
    this.valueFontWeight = FontWeight.w500,
    required this.valueColor,
    this.iconSize = 20,
    required this.iconColor,
    this.editIconSize = 20,
    required this.editIconColor,
    this.tagFontSize = 9,
    required this.tagBackgroundColor,
    required this.tagTextColor,
    this.tagBorderRadius = 4,
    this.animationDuration = const Duration(milliseconds: 500),
    this.animationCurve = Curves.easeInOut,
    this.collapsedHeight = 64,
    this.expandedHeight = 120,
  });
}

// تنظیمات عمومی باکس‌های برنامه
class GeneralBoxConfig {
  static const double padding = 16.0; // فاصله داخلی
  static const double margin = 12.0; // فاصله خارجی
  static const Color boxShadowColor = Color(0x1A000000); // رنگ سایه
  static const double boxShadowBlur = 8.0; // تیرگی سایه
  static const Offset boxShadowOffset = Offset(0, 2); // موقعیت سایه
  static const Color borderColor = Color(0x4D9E9E9E); // رنگ حاشیه
  static const double borderWidth = 0.0; // حذف حاشیه برای یکسان‌سازی
}

// استانداردهای انحنای گوشه‌ها
class BorderRadiusStandards {
  static const double mainBox = 24.0; // باکس‌های اصلی برنامه
  static const double contentCard = 16.0; // کارت‌های محتوا
  static const double table = 8.0; // جدول‌ها و لیست‌ها
  static const double button = 12.0; // دکمه‌ها
  static const double input = 8.0; // فیلدهای ورودی
  static const double modal = 16.0; // مودال‌ها
}

// کانفیگ باکس‌های عناوین کوچک (Header Boxes)
class HeaderBoxConfig {
  final Color backgroundColor;
  final Color textColor;
  final double padding;
  final double borderRadius;
  final Color borderColor;
  final double borderWidth;
  final Color boxShadowColor;
  final double boxShadowBlur;
  final Offset boxShadowOffset;
  final double fontSize;
  final FontWeight fontWeight;
  final String fontFamily;
  final TextAlign textAlign;

  const HeaderBoxConfig({
    required this.backgroundColor,
    required this.textColor,
    this.padding = 12.0,
    this.borderRadius = 24.0, // مشابه باکس‌های دیگر
    this.borderColor = const Color(0x4D9E9E9E),
    this.borderWidth = 1.2,
    this.boxShadowColor = const Color(0x1A000000),
    this.boxShadowBlur = 6.0,
    this.boxShadowOffset = const Offset(0, 2),
    this.fontSize = 14.0,
    this.fontWeight = FontWeight.bold,
    this.fontFamily = 'Vazirmatn',
    this.textAlign = TextAlign.center,
  });
}

// نمونه کانفیگ‌های آماده
class BoxConfigs {
  static const planned = SummaryCardConfig(
    backgroundColor: Color(0xFF2196F3), // آبی روشن
    textColor: Colors.white,
    icon: Icons.assignment,
  );
  static const actual = SummaryCardConfig(
    backgroundColor: Color(0xFFFF9800), // نارنجی روشن
    textColor: Colors.white,
    icon: Icons.trending_up,
  );
  static const deviation = DeviationBoxConfig(
    backgroundColorPositive: Color(0x1A4CAF50), // سبز ملایم
    backgroundColorNegative: Color(0x1AF44336), // قرمز ملایم
    backgroundColorZero: Colors.white,
    textColor: Color(0xFF424242),
    icon: Icons.compare_arrows,
  );
  static const deviationStandard = deviation;
  static const dateRange = DateRangeBoxConfig(
    backgroundColorCollapsed: Color(0xFFF5F7FA),
    backgroundColorExpanded: Colors.white,
    borderColor: Color(0x4D9E9E9E),
    boxShadowColor: Color(0x1A000000),
    titleColor: Color(0xFF424242),
    valueColor: Color(0xFF616161),
    iconColor: Color(0xFF616161),
    editIconColor: Color(0xFF1976D2),
    tagBackgroundColor: Color(0xFFD1E9FC),
    tagTextColor: Color(0xFF1976D2),
    // افزایش ۲۰٪
    titleFontSize: 16.8,
    valueFontSize: 13.2,
    tagFontSize: 10.8,
    padding: 16.8,
    collapsedHeight: 76.8,
    expandedHeight: 144,
  );

  // کانفیگ باکس‌های عناوین با پس‌زمینه خاکستری ملایم
  static const headerBox = HeaderBoxConfig(
    backgroundColor: Color(0xFFE8E8E8), // خاکستری کمی تیره‌تر برای خوانایی بهتر
    textColor: Color(0xFF2C2C2C), // متن تیره‌تر برای کنتراست بهتر
    padding: 16.0, // افزایش padding برای فضای بیشتر
    fontSize: 15.0, // افزایش اندازه فونت
    fontWeight: FontWeight.w600, // وزن فونت متوسط
  );

  // کانفیگ مخصوص عناوین اصلی باکس‌ها (داشبورد)
  static const mainBoxTitle = HeaderBoxConfig(
    backgroundColor: Color(0xFFF5F5F5), // خاکستری ملایم
    textColor: Color(0xFF000000), // مشابه کلمات خوراک، محصول، باطله
    padding: 12.0, // padding کمتر
    fontSize: 13.0, // مشابه کلمات خوراک، محصول، باطله
    fontWeight: FontWeight.bold, // مشابه کلمات خوراک، محصول، باطله
    borderRadius: 12.0, // انحنای مناسب
    borderColor: Color(0x4D9E9E9E), // حاشیه خاکستری ملایم
    borderWidth: 1.0, // حاشیه نازک
    boxShadowColor: Color(0x1A000000), // سایه سیاه ملایم
    boxShadowBlur: 4.0, // سایه ملایم
  );
}
