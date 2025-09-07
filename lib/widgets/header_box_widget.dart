import 'package:flutter/material.dart';
import '../config/box_configs.dart';

/// ویجت باکس عناوین کوچک با استفاده از HeaderBoxConfig
/// مناسب برای نمایش عناوین مثل "نوع توقف"، "واقعی"، "برنامه"، "انحراف"
class HeaderBoxWidget extends StatelessWidget {
  final String title;
  final HeaderBoxConfig? config;
  final VoidCallback? onTap;
  final double? width;
  final double? height;

  const HeaderBoxWidget({
    super.key,
    required this.title,
    this.config,
    this.onTap,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final boxConfig = config ?? BoxConfigs.headerBox;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: boxConfig.backgroundColor,
        borderRadius: BorderRadius.circular(boxConfig.borderRadius),
        border: Border.all(
          color: boxConfig.borderColor,
          width: boxConfig.borderWidth,
        ),
        boxShadow: [
          BoxShadow(
            color: boxConfig.boxShadowColor,
            blurRadius: boxConfig.boxShadowBlur,
            offset: boxConfig.boxShadowOffset,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(boxConfig.borderRadius),
          onTap: onTap,
          child: Container(
            padding: EdgeInsets.all(boxConfig.padding),
            child: Text(
              title,
              textAlign: boxConfig.textAlign,
              style: TextStyle(
                fontFamily: boxConfig.fontFamily,
                fontSize: boxConfig.fontSize,
                fontWeight: boxConfig.fontWeight,
                color: boxConfig.textColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// ویجت ردیف عناوین (برای استفاده در جداول)
class HeaderRowWidget extends StatelessWidget {
  final List<String> headers;
  final List<int>? flexValues;
  final HeaderBoxConfig? config;
  final double spacing;

  const HeaderRowWidget({
    super.key,
    required this.headers,
    this.flexValues,
    this.config,
    this.spacing = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        children: headers.asMap().entries.map((entry) {
          final index = entry.key;
          final header = entry.value;
          final flex = flexValues != null && index < flexValues!.length
              ? flexValues![index]
              : 1;

          return Expanded(
            flex: flex,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: spacing / 2),
              child: HeaderBoxWidget(
                title: header,
                config: config,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// نمونه استفاده برای صفحه توقفات
class StopsHeaderRowWidget extends StatelessWidget {
  const StopsHeaderRowWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const HeaderRowWidget(
      headers: ['انحراف', 'برنامه', 'واقعی', 'نوع توقف'],
      flexValues: [1, 1, 1, 2], // نوع توقف عرض بیشتری دارد
      spacing: 8.0,
    );
  }
}

/// ویجت آماده برای عناوین باکس‌های اصلی
class MainBoxTitleWidget extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const MainBoxTitleWidget({
    super.key,
    required this.title,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // عنوان با کانفیگ جدید
        Expanded(
          child: HeaderBoxWidget(
            title: title,
            config:
                BoxConfigs.mainBoxTitle, // استفاده از کانفیگ مخصوص عناوین اصلی
            height: null, // ارتفاع خودکار بر اساس محتوا
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 12),
          trailing!,
        ],
      ],
    );
  }
}
