import 'package:flutter/material.dart';
import 'app_colors.dart';

class StandardPageConfig {
  // ===== مشخصات صفحه اصلی =====
  static const Color mainPageBackground = AppColors.stopsAppBar; // آبی تیره
  
  // ===== مشخصات کانتینر اصلی =====
  static const Color mainContainerBackground = AppColors.mainContainerBackground; // کرم روشن
  static const double mainContainerTopRadius = 24.0;
  static const double mainContainerBottomRadius = 0.0;
  
  // ===== مشخصات عنوان صفحه =====
  static const double titleFontSize = 22.0;
  static const FontWeight titleFontWeight = FontWeight.w700;
  static const String titleFontFamily = 'Vazirmatn';
  static const Color titleColor = Colors.white;
  static const TextAlign titleTextAlign = TextAlign.center;
  static const EdgeInsets titlePadding = EdgeInsets.symmetric(horizontal: 16, vertical: 12);
  
  // ===== مشخصات کانتینر عنوان =====
  static const EdgeInsets titleContainerPadding = EdgeInsets.symmetric(horizontal: 16, vertical: 12);
  
  // ===== مشخصات کانتینر اصلی =====
  static const EdgeInsets mainContainerPadding = EdgeInsets.all(12);
  
  // ===== متدهای کمکی =====
  static BoxDecoration getMainContainerDecoration() {
    return const BoxDecoration(
      color: mainContainerBackground,
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(mainContainerTopRadius),
        topRight: Radius.circular(mainContainerTopRadius),
      ),
    );
  }
  
  static TextStyle getTitleTextStyle() {
    return const TextStyle(
      color: titleColor,
      fontSize: titleFontSize,
      fontWeight: titleFontWeight,
      fontFamily: titleFontFamily,
    );
  }
  
  static Widget buildStandardPage({
    required String title,
    required Widget content,
    Widget? filterSection,
    bool isFilterCollapsed = false,
    VoidCallback? onFilterToggle,
    bool showFilterToggle = false,
  }) {
    return Scaffold(
      backgroundColor: mainPageBackground,
      body: SafeArea(
        child: Column(
          children: [
            // عنوان صفحه
            Container(
              padding: titleContainerPadding,
              child: Center(
                child: Text(
                  title,
                  style: getTitleTextStyle(),
                  textAlign: titleTextAlign,
                ),
              ),
            ),
            
            // کانتینر اصلی
            Expanded(
              child: Container(
                decoration: getMainContainerDecoration(),
                child: isFilterCollapsed
                    ? Column(
                        children: [
                          if (filterSection != null) filterSection,
                          Expanded(child: content),
                        ],
                      )
                    : filterSection ?? content,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
