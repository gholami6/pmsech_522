import 'package:flutter/material.dart';

/// Design tokens for the new dashboard according to UI Redesign Spec
class DashboardDesignTokens {
  // Color Palette
  static const Color colorPrimary600 = Color(0xFF2563EB);
  static const Color colorPrimary700 =
      Color(0xFF1D4ED8); // Brand blue for announcement cards
  static const Color colorPrimary800 = Color(0xFF1E40AF);
  static const Color colorAccentGreen = Color(0xFF22C55E); // Progress fill
  static const Color colorSurface = Color(0xFFFFFFFF);
  static const Color colorSurface2 = Color(0xFFF8FAFC);
  static const Color colorTextPrimary = Color(0xFF0F172A);
  static const Color colorTextSecondary = Color(0xFF334155);
  static const Color colorBorder = Color(0xFFE2E8F0);
  static const Color colorTrack = Color(0xFFE5E7EB);
  static const Color shadowColor = Color.fromRGBO(2, 6, 23, 0.12);

  // Dark Mode Colors (for future use)
  static const Color dmSurface = Color(0xFF0B1220);
  static const Color dmSurface2 = Color(0xFF0F172A);
  static const Color dmTextPrimary = Color(0xFFE2E8F0);
  static const Color dmTextSecondary = Color(0xFF94A3B8);
  static const Color dmBorder = Color(0xFF1F2937);
  static const Color dmTrack = Color(0xFF1F2937);

  // Spacing & Sizing (base grid: 8dp)
  static const double baseGrid = 8.0;
  static const double screenPadding = 16.0;
  static const double cardPadding = 16.0;
  static const double cardPaddingLarge = 20.0;
  static const double gapSmall = 12.0;
  static const double gapMedium = 16.0;
  static const double touchTargetMin = 48.0;

  // Radii & Elevation
  static const double cardRadius = 16.0;
  static const double buttonRadius = 12.0;
  static const double fabRadius = 28.0;
  static const double headerBottomRadius = 24.0;
  static const double headerBottomRadiusLarge = 32.0;

  // Elevations
  static const double cardElevation = 4.0;
  static const double fabElevation = 6.0;
  static const double bottomNavElevation = 8.0;

  // Typography (RTL-friendly)
  static const String primaryFont = 'Vazirmatn';

  // Text Styles
  static const TextStyle titleStyle = TextStyle(
    fontFamily: primaryFont,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: colorTextPrimary,
    height: 1.3,
  );

  static const TextStyle subtitleStyle = TextStyle(
    fontFamily: primaryFont,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: colorTextPrimary,
    height: 1.3,
  );

  static const TextStyle labelStyle = TextStyle(
    fontFamily: primaryFont,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: colorTextPrimary,
    height: 1.4,
  );

  static const TextStyle bodyStyle = TextStyle(
    fontFamily: primaryFont,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: colorTextPrimary,
    height: 1.4,
  );

  static const TextStyle captionStyle = TextStyle(
    fontFamily: primaryFont,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: colorTextSecondary,
    height: 1.4,
  );

  // Card Styles
  static const TextStyle cardTitleWhite = TextStyle(
    fontFamily: primaryFont,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: Colors.white,
    height: 1.3,
  );

  // Gradients
  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF1E40AF),
      Color(0xFF3B82F6),
    ],
    stops: [0.0, 0.85],
  );

  // Shadows
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: shadowColor,
          blurRadius: 10,
          offset: const Offset(0, 4),
          spreadRadius: 0,
        ),
      ];

  static List<BoxShadow> get fabShadow => [
        BoxShadow(
          color: shadowColor,
          blurRadius: 12,
          offset: const Offset(0, 6),
          spreadRadius: 0,
        ),
      ];

  // Component Dimensions
  static const double headerHeight = 220.0;
  static const double announcementCardHeight = 112.0;
  static const double progressBarHeight = 14.0;
  static const double iconSize = 24.0;
  static const double iconSizeLarge = 28.0;
  static const double fabSize = 56.0;

  // Animation Durations
  static const Duration animationFast = Duration(milliseconds: 200);
  static const Duration animationMedium = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);
}
