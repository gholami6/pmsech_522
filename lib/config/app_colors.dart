import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';

class AppColors {
  // Primary Colors - Professional Blue Theme
  static const Color primaryBlue = Color(0xFF1E3A8A); // Dark Blue
  static const Color secondaryBlue = Color(0xFF3B82F6); // Medium Blue
  static const Color lightBlue = Color(0xFF60A5FA); // Light Blue
  static const Color accentBlue = Color(0xFFDBEAFE); // Very Light Blue

  // Background Colors
  static const Color mainBackground =
      Color(0xFFF1EFEC); // Light Beige Background
  static const Color cardBackground = Color(0xFFFFFFFF); // White Cards
  static const Color surfaceBackground =
      Color(0xFFF1F5F9); // Surface Background

  // Text Colors
  static const Color primaryText = Color(0xFF1E293B); // Dark Text
  static const Color secondaryText = Color(0xFF64748B); // Medium Gray Text
  static const Color lightText = Color(0xFF94A3B8); // Light Gray Text
  static const Color whiteText = Color(0xFFFFFFFF); // White Text

  // Status Colors
  static const Color success = Color(0xFF10B981); // Green
  static const Color warning = Color(0xFFF59E0B); // Orange
  static const Color error = Color(0xFFEF4444); // Red
  static const Color info = Color(0xFF3B82F6); // Blue

  // Border and Divider Colors
  static const Color borderLight = Color(0xFFE2E8F0); // Light Border
  static const Color borderMedium = Color(0xFFCBD5E1); // Medium Border
  static const Color borderDark = Color(0xFF94A3B8); // Dark Border

  // Shadow Colors
  static const Color shadowLight = Color(0x1A000000); // Light Shadow
  static const Color shadowMedium = Color(0x33000000); // Medium Shadow
  static const Color shadowDark = Color(0x4D000000); // Dark Shadow

  // Gradient Colors
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF1E3A8A),
      Color(0xFF3B82F6),
    ],
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF3B82F6),
      Color(0xFF60A5FA),
    ],
  );

  static const LinearGradient lightGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFF8FAFC),
      Color(0xFFF1F5F9),
    ],
  );

  // Legacy Colors (for backward compatibility)
  static const Color stopsAppBar = Color(0xFF1E3A8A);
  static const Color mainContainer = Color(0xFFF1EFEC);
  static const Color boxBackground = Color(0xFFFFFFFF);

  // Legacy colors for backward compatibility
  static const Color mainContainerBackground = Color(0xFFF1EFEC);
  static const Color feedColor = Color(0xFF3B82F6); // Blue
  static const Color productColor = Color(0xFF10B981); // Green
  static const Color tailingColor = Color(0xFFEF4444); // Red
  static const Color planColor = Color(0xFF8B5CF6); // Purple
  static const Color neutralColor = Color(0xFF6B7280); // Gray

  // Stops screen specific colors
  static const Color stopsBackground = Color(0xFFF1EFEC);
  static const Color stopsMainContainerBackground = Color(0xFFF1EFEC);
  static const Color stopsCardBackground = Color(0xFFFFFFFF);
  static const Color stopsTextPrimary = Color(0xFF1E293B);
  static const Color stopsAccentOrange = Color(0xFFF59E0B);
  static const Color stopsAccentGreen = Color(0xFF10B981);
  static const Color stopsAccentBlue = Color(0xFF3B82F6);
  static const Color stopsShadow = Color(0xFFE2E8F0);
  static const Color boxOutlineColor = Color(0x4D757575);

  static const BoxShadow boxShadow = BoxShadow(
    color: Color(0x29000000),
    blurRadius: 10,
    offset: Offset(0, 4),
  );
}

// PDF Colors for backward compatibility
class AppPdfColors {
  static const PdfColor feedColor = PdfColors.blue400;
  static const PdfColor productColor = PdfColors.green400;
  static const PdfColor tailingColor = PdfColors.red400;
  static const PdfColor planColor = PdfColors.purple400;
  static const PdfColor neutralColor = PdfColors.grey;

  static const PdfColor feedColorLight = PdfColors.blue100;
  static const PdfColor productColorLight = PdfColors.green100;
  static const PdfColor tailingColorLight = PdfColors.red100;
}
