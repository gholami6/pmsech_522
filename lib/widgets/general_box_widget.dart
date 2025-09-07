import 'package:flutter/material.dart';
import '../config/general_box_styles.dart';

class GeneralBox extends StatelessWidget {
  final Widget child;
  final BoxDecoration? decoration;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final VoidCallback? onTap;
  final bool enableShadow;
  final bool enableBorder;

  const GeneralBox({
    super.key,
    required this.child,
    this.decoration,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.onTap,
    this.enableShadow = true,
    this.enableBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    BoxDecoration finalDecoration = decoration ??
        (enableBorder
            ? GeneralBoxStyles.generalBoxDecoration
            : GeneralBoxStyles.boxWithoutBorder);

    Widget boxWidget = Container(
      width: width,
      height: height,
      margin: margin ?? const EdgeInsets.all(12),
      padding: padding ?? const EdgeInsets.all(16),
      decoration: finalDecoration,
      child: child,
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: boxWidget,
      );
    }

    return boxWidget;
  }
}

// باکس‌های تخصصی
class ColoredBox extends StatelessWidget {
  final Widget child;
  final Color backgroundColor;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final VoidCallback? onTap;

  const ColoredBox({
    super.key,
    required this.child,
    required this.backgroundColor,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GeneralBox(
      decoration: GeneralBoxStyles.coloredBox(backgroundColor),
      padding: padding,
      margin: margin,
      width: width,
      height: height,
      onTap: onTap,
      child: child,
    );
  }
}

class AlertBox extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final VoidCallback? onTap;

  const AlertBox({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GeneralBox(
      decoration: GeneralBoxStyles.alertBoxDecoration,
      padding: padding,
      margin: margin,
      width: width,
      height: height,
      onTap: onTap,
      child: child,
    );
  }
}

class SuccessBox extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final VoidCallback? onTap;

  const SuccessBox({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GeneralBox(
      decoration: GeneralBoxStyles.successBoxDecoration,
      padding: padding,
      margin: margin,
      width: width,
      height: height,
      onTap: onTap,
      child: child,
    );
  }
}

class ErrorBox extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final VoidCallback? onTap;

  const ErrorBox({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GeneralBox(
      decoration: GeneralBoxStyles.errorBoxDecoration,
      padding: padding,
      margin: margin,
      width: width,
      height: height,
      onTap: onTap,
      child: child,
    );
  }
}

class InfoBox extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final VoidCallback? onTap;

  const InfoBox({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GeneralBox(
      decoration: GeneralBoxStyles.infoBoxDecoration,
      padding: padding,
      margin: margin,
      width: width,
      height: height,
      onTap: onTap,
      child: child,
    );
  }
}

class TableBox extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final VoidCallback? onTap;

  const TableBox({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GeneralBox(
      decoration: GeneralBoxStyles.tableBoxDecoration,
      padding: padding,
      margin: margin,
      width: width,
      height: height,
      onTap: onTap,
      child: child,
    );
  }
}

class FormBox extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final VoidCallback? onTap;

  const FormBox({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GeneralBox(
      decoration: GeneralBoxStyles.formBoxDecoration,
      padding: padding,
      margin: margin,
      width: width,
      height: height,
      onTap: onTap,
      child: child,
    );
  }
}
