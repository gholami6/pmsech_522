import 'package:flutter/material.dart';

class AlertCardConfig {
  // رنگ‌های وضعیت خوانده شدن
  static const Color unreadColor = Color(0xFFF39C12); // نارنجی
  static const Color readColor = Color(0xFF34495E); // خاکستری تیره

  // اندازه‌های استاندارد
  static const double cardHeight = 130.0;
  static const double accentWidth = 100.0;
  static const double iconSize = 28.0;
  static const double indicatorSize = 12.0;

  // فاصله‌ها
  static const EdgeInsets cardMargin =
      EdgeInsets.symmetric(horizontal: 16, vertical: 8);
  static const EdgeInsets contentPadding = EdgeInsets.all(16);

  // انحنای گوشه‌ها
  static const double borderRadius = 16.0;

  // سایه‌ها
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withOpacity(0.12),
          blurRadius: 20,
          offset: const Offset(0, 8),
          spreadRadius: 2,
        ),
      ];

  // گرادیان‌های پس‌زمینه
  static LinearGradient get backgroundGradient => const LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [
          Colors.white,
          Color(0xFFF8F9FA),
        ],
      );

  // استایل‌های متن
  static const TextStyle titleStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: Color(0xFF2C3E50),
    fontFamily: 'Vazirmatn',
    height: 1.2,
  );

  static const TextStyle categoryStyle = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    fontFamily: 'Vazirmatn',
  );

  static const TextStyle timeStyle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    fontFamily: 'Vazirmatn',
  );

  // آیکن‌های مختلف بر اساس نوع اعلان
  static IconData getAlertIcon(String category) {
    switch (category.toLowerCase()) {
      case 'مکانیک':
        return Icons.build_rounded;
      case 'برق':
        return Icons.electric_bolt_rounded;
      case 'پروسس':
        return Icons.science_rounded;
      case 'عمومی':
        return Icons.info_rounded;
      case 'ایمنی':
        return Icons.security_rounded;
      case 'مدیریت':
        return Icons.business_center_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  // فرمت زمان
  static String formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}د';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}س';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}روز';
    } else {
      return '${dateTime.month}/${dateTime.day}';
    }
  }

  // کوتاه کردن متن
  static String truncateText(String text, int maxLength) {
    if (text.length <= maxLength) {
      return text;
    }
    return '${text.substring(0, maxLength)}...';
  }
}

// کانفیگ جدید برای کارت اعلان مدرن
class ModernAlertCardConfig {
  // اندازه‌های کارت
  static const double cardBorderRadius = 20.0;
  static const double accentBarWidth = 6.0;
  static const double iconSize = 24.0;
  static const double progressBarHeight = 4.0;

  // فاصله‌ها
  static const EdgeInsets cardMargin =
      EdgeInsets.symmetric(horizontal: 16, vertical: 8);
  static const EdgeInsets contentPadding = EdgeInsets.all(20);
  static const double iconSpacing = 16.0;
  static const double titleTimeSpacing = 8.0;
  static const double messageSpacing = 12.0;

  // سایه‌های کارت
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 15,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 5,
          offset: const Offset(0, 2),
        ),
      ];

  // سایه نوار رنگی کناری
  static List<BoxShadow> getAccentBarShadow(Color color) => [
        BoxShadow(
          color: color.withOpacity(0.3),
          blurRadius: 8,
          offset: const Offset(0, 0),
        ),
      ];

  // گرادیان‌های پس‌زمینه
  static LinearGradient getNewCardGradient() => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFFFFFFF),
          Color(0xFFF8F9FF),
        ],
      );

  static LinearGradient getReadCardGradient() => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFFFFFFF),
          Color(0xFFF5F5F5),
        ],
      );

  // گرادیان دایره پس‌زمینه
  static LinearGradient getBackgroundCircleGradient(Color accentColor) =>
      LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          accentColor.withOpacity(0.1),
          accentColor.withOpacity(0.05),
        ],
      );

  // استایل‌های متن
  static TextStyle getTitleStyle(bool isNew) => TextStyle(
        fontSize: 16,
        fontWeight: isNew ? FontWeight.bold : FontWeight.w600,
        color: const Color(0xFF2E3A59),
        fontFamily: 'Vazirmatn',
      );

  static const TextStyle messageStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: Color(0xFF5A6C7D),
    fontFamily: 'Vazirmatn',
    height: 1.3,
  );

  // رنگ‌های آکسان بر اساس نوع پیام
  static Color getAccentColor(String message) {
    if (message.contains('خطا') || message.contains('مشکل')) {
      return const Color(0xFFE74C3C); // قرمز
    } else if (message.contains('هشدار') || message.contains('توجه')) {
      return const Color(0xFFF39C12); // نارنجی
    } else if (message.contains('اطلاع') || message.contains('آگاه')) {
      return const Color(0xFF3498DB); // آبی
    } else {
      return const Color(0xFF2ECC71); // سبز
    }
  }

  // آیکن‌های بر اساس نوع پیام
  static IconData getAlertIcon(String message) {
    if (message.contains('خطا') || message.contains('مشکل')) {
      return Icons.error_outline;
    } else if (message.contains('هشدار') || message.contains('توجه')) {
      return Icons.warning_amber_rounded;
    } else if (message.contains('اطلاع') || message.contains('آگاه')) {
      return Icons.info_outline;
    } else {
      return Icons.notifications_active;
    }
  }

  // اندازه دایره پس‌زمینه
  static const double backgroundCircleSize = 80.0;
  static const double backgroundCircleOffset = 20.0;
}
