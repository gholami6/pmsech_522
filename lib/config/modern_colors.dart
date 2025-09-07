import 'package:flutter/material.dart';

class ModernColors {
  // رنگ‌های اصلی Material Design
  static const Color primary = Color(0xFF2196F3);
  static const Color primaryDark = Color(0xFF1976D2);
  static const Color primaryLight = Color(0xFFBBDEFB);

  static const Color secondary = Color(0xFFFF9800);
  static const Color secondaryDark = Color(0xFFE65100);
  static const Color secondaryLight = Color(0xFFFFE0B2);

  // رنگ‌های وضعیت
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFC107);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);

  // رنگ‌های پس‌زمینه
  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color cardBackground = Color(0xFFFFFFFF);

  // رنگ‌های متن
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textLight = Color(0xFFBDBDBD);

  // رنگ‌های اعلان‌ها
  static const Color alertNew = Color(0xFFE3F2FD);
  static const Color alertNewText = Color(0xFF1976D2);
  static const Color alertRead = Color(0xFFFAFAFA);
  static const Color alertReadText = Color(0xFF424242);
  static const Color alertImportant = Color(0xFFFFF3E0);
  static const Color alertImportantText = Color(0xFFE65100);

  // گرادیان‌ها
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [secondary, secondaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [success, Color(0xFF388E3C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // سایه‌های نرم
  static List<BoxShadow> softShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> mediumShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.12),
      blurRadius: 16,
      offset: const Offset(0, 6),
    ),
  ];

  static List<BoxShadow> strongShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.16),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];

  // سایه‌های رنگی
  static List<BoxShadow> primaryShadow = [
    BoxShadow(
      color: primary.withOpacity(0.2),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> secondaryShadow = [
    BoxShadow(
      color: secondary.withOpacity(0.2),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];
}
