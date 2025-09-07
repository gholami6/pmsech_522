import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';
import '../config/app_colors.dart';
import '../models/production_data.dart';
import '../models/stop_data.dart';
import 'planning_calculation_service.dart';
import 'package:flutter/services.dart';

/// کلاس نقطه نمودار برای PDF
class ChartPoint {
  final double x;
  final double y;
  ChartPoint(this.x, this.y);
}

/// کلاس داده خوراک برای PDF
class PdfFeedData {
  final String label;
  final double actualFeed;
  final double plannedFeed;
  final String shift;

  PdfFeedData({
    required this.label,
    required this.actualFeed,
    required this.plannedFeed,
    required this.shift,
  });
}

/// کلاس داده محصول برای PDF
class PdfProductData {
  final String label;
  final double actualProduct;
  final double plannedProduct;
  final String shift;

  PdfProductData({
    required this.label,
    required this.actualProduct,
    required this.plannedProduct,
    required this.shift,
  });
}

/// کلاس داده باطله برای PDF
class PdfTailingData {
  final String label;
  final double actualTailing;
  final double plannedTailing;
  final String shift;

  PdfTailingData({
    required this.label,
    required this.actualTailing,
    required this.plannedTailing,
    required this.shift,
  });
}

/// کلاس داده محصول برای PDF
class ProductData {
  final String label;
  final double actualProduct;
  final double plannedProduct;
  final String shift;

  ProductData({
    required this.label,
    required this.actualProduct,
    required this.plannedProduct,
    required this.shift,
  });
}

/// سرویس تولید گزارش PDF
class PdfReportService {
  static pw.Font? _persianFont;
  static pw.Font? _persianBoldFont;

  /// تبدیل دقیقه به فرمت ساعت:دقیقه
  static String _formatMinutesToTime(int minutes) {
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    return '${hours.toString().padLeft(2, '0')}:${remainingMinutes.toString().padLeft(2, '0')}';
  }

  /// تبدیل عدد به فرمت فارسی با جداکننده هزارگان
  static String _formatNumber(double number) {
    final formatter = NumberFormat('#,##0.0', 'fa_IR');
    return formatter.format(number);
  }

  /// بررسی وجود عیار
  static bool _hasGradeData(Map<String, dynamic> reportData) {
    return reportData.containsKey('actualFeedGrade') &&
        reportData.containsKey('plannedFeedGrade') &&
        reportData['actualFeedGrade'] != null &&
        reportData['plannedFeedGrade'] != null;
  }

  /// بارگذاری فونت فارسی
  static Future<pw.Font> _getPersianFont() async {
    if (_persianFont != null) return _persianFont!;
    final fontData =
        await rootBundle.load('assets/fonts/Vazirmatn-Regular.ttf');
    _persianFont = pw.Font.ttf(fontData);
    return _persianFont!;
  }

  /// بارگذاری فونت فارسی Bold
  static Future<pw.Font> _getPersianBoldFont() async {
    if (_persianBoldFont != null) return _persianBoldFont!;
    final fontData = await rootBundle.load('assets/fonts/Vazirmatn-Bold.ttf');
    _persianBoldFont = pw.Font.ttf(fontData);
    return _persianBoldFont!;
  }

  /// تولید گزارش کلی
  static Future<File> generateGeneralReportPdf({
    required Map<String, dynamic> reportData,
    required List<Map<String, dynamic>> sortedStops,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final pdf = pw.Document();
      final persianFont = await _getPersianFont();
      final persianBoldFont = await _getPersianBoldFont();
      final startShamsi = Jalali.fromDateTime(startDate);
      final endShamsi = Jalali.fromDateTime(endDate);
      final now = Jalali.now();

      // محدود کردن تعداد توقفات برای جلوگیری از تولید بیش از حد صفحات
      final limitedStops = sortedStops.take(50).toList();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          theme: pw.ThemeData.withFont(base: persianFont),
          build: (context) => _buildGeneralReportPage(
            reportData: reportData,
            sortedStops: limitedStops,
            startShamsi: startShamsi,
            endShamsi: endShamsi,
            now: now,
            persianFont: persianFont,
            persianBoldFont: persianBoldFont,
          ),
        ),
      );

      final output = await getTemporaryDirectory();
      final file = File(
          '${output.path}/general_report_${DateTime.now().millisecondsSinceEpoch}.pdf');
      await file.writeAsBytes(await pdf.save());
      return file;
    } catch (e) {
      print('خطا در تولید PDF گزارش کلی: $e');
      rethrow;
    }
  }

  /// ساخت صفحه گزارش کلی
  static pw.Widget _buildGeneralReportPage({
    required Map<String, dynamic> reportData,
    required List<Map<String, dynamic>> sortedStops,
    required Jalali startShamsi,
    required Jalali endShamsi,
    required Jalali now,
    required pw.Font persianFont,
    required pw.Font persianBoldFont,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // متن بالای جدول در سه ردیف
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.only(right: 0, top: 0, bottom: 12),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  'گزارش کلی تولید و توقفات',
                  style: pw.TextStyle(
                    fontSize: 16,
                    font: persianBoldFont,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  textDirection: pw.TextDirection.rtl,
                  textAlign: pw.TextAlign.right,
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'بازه ${startShamsi.formatCompactDate()} الی ${endShamsi.formatCompactDate()}',
                  style: pw.TextStyle(
                    fontSize: 12,
                    font: persianFont,
                  ),
                  textDirection: pw.TextDirection.rtl,
                  textAlign: pw.TextAlign.right,
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'تاریخ تولید گزارش: ${now.formatCompactDate()}',
                  style: pw.TextStyle(
                    fontSize: 12,
                    font: persianFont,
                  ),
                  textDirection: pw.TextDirection.rtl,
                  textAlign: pw.TextAlign.right,
                ),
              ],
            ),
          ),

          // جدول اصلی
          _buildMainReportTable(
            reportData: reportData,
            sortedStops: sortedStops,
            persianFont: persianFont,
            persianBoldFont: persianBoldFont,
          ),
        ],
      ),
    );
  }

  /// ساخت جدول اصلی گزارش
  static pw.Widget _buildMainReportTable({
    required Map<String, dynamic> reportData,
    required List<Map<String, dynamic>> sortedStops,
    required pw.Font persianFont,
    required pw.Font persianBoldFont,
  }) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(width: 1, color: PdfColors.grey600),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Table(
        border: pw.TableBorder.all(width: 0.5, color: PdfColors.grey600),
        defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
        columnWidths: {
          0: const pw.FlexColumnWidth(1.2), // انحراف از برنامه
          1: const pw.FlexColumnWidth(1.2), // برنامه
          2: const pw.FlexColumnWidth(1.5), // محقق شده (عرض بیشتر)
          3: const pw.FlexColumnWidth(1.0), // عناوین (عرض کمتر)
        },
        children: [
          // هدر جدول
          _buildTableHeader(persianBoldFont),

          // بخش شاخص‌ها
          _buildSectionHeader('شاخص‌ها', persianBoldFont),
          ..._buildIndicatorRows(reportData, persianFont),

          // بخش توقفات (محدود شده)
          _buildSectionHeader('توقفات', persianBoldFont),
          _buildStopsHeader(persianBoldFont),
          ...sortedStops
              .map((stop) => _buildStopRow(stop, persianFont))
              .toList(),

          // بخش تولیدات
          _buildSectionHeader('تولیدات', persianBoldFont),
          ..._buildProductionRows(reportData, persianFont),
        ],
      ),
    );
  }

  /// ساخت هدر جدول
  static pw.TableRow _buildTableHeader(pw.Font persianBoldFont) {
    return pw.TableRow(
      decoration: pw.BoxDecoration(color: PdfColors.lightBlue),
      children: [
        _buildHeaderCell('انحراف از برنامه', persianBoldFont),
        _buildHeaderCell('برنامه', persianBoldFont),
        _buildHeaderCell('محقق شده', persianBoldFont),
        _buildHeaderCell('عناوین', persianBoldFont),
      ],
    );
  }

  /// ساخت سلول هدر
  static pw.Widget _buildHeaderCell(String text, pw.Font font) {
    return pw.Container(
      alignment: pw.Alignment.center,
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(text,
          style: pw.TextStyle(
              fontSize: 8, font: font, fontWeight: pw.FontWeight.bold),
          textDirection: pw.TextDirection.rtl,
          textAlign: pw.TextAlign.center,
          maxLines: 1),
    );
  }

  /// ساخت هدر بخش
  static pw.TableRow _buildSectionHeader(
      String title, pw.Font persianBoldFont) {
    return pw.TableRow(
      decoration: pw.BoxDecoration(color: PdfColors.lightBlue),
      children: [
        pw.Container(
          alignment: pw.Alignment.center,
          padding: const pw.EdgeInsets.symmetric(vertical: 4),
          child: pw.Text(title,
              style: pw.TextStyle(
                  font: persianBoldFont,
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 10),
              textDirection: pw.TextDirection.rtl,
              textAlign: pw.TextAlign.center),
        ),
        pw.Container(
          alignment: pw.Alignment.center,
          padding: const pw.EdgeInsets.symmetric(vertical: 4),
          child: pw.Text(title,
              style: pw.TextStyle(
                  font: persianBoldFont,
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 10),
              textDirection: pw.TextDirection.rtl,
              textAlign: pw.TextAlign.center),
        ),
        pw.Container(
          alignment: pw.Alignment.center,
          padding: const pw.EdgeInsets.symmetric(vertical: 4),
          child: pw.Text(title,
              style: pw.TextStyle(
                  font: persianBoldFont,
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 10),
              textDirection: pw.TextDirection.rtl,
              textAlign: pw.TextAlign.center),
        ),
        pw.Container(
          alignment: pw.Alignment.center,
          padding: const pw.EdgeInsets.symmetric(vertical: 4),
          child: pw.Text(title,
              style: pw.TextStyle(
                  font: persianBoldFont,
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 10),
              textDirection: pw.TextDirection.rtl,
              textAlign: pw.TextAlign.center),
        ),
      ],
    );
  }

  /// ساخت ردیف‌های شاخص‌ها
  static List<pw.TableRow> _buildIndicatorRows(
      Map<String, dynamic> reportData, pw.Font persianFont) {
    return [
      _buildDataRow(
        'دسترسی کل',
        '${reportData['actualTotalAvailability']?.toStringAsFixed(1) ?? '-'}%',
        '${reportData['plannedTotalAvailability']?.toStringAsFixed(1) ?? '-'}%',
        '${reportData['totalAvailabilityDeviation']?.toStringAsFixed(1) ?? '-'}%',
        persianFont,
      ),
      _buildDataRow(
        'دسترسی تجهیزات',
        '${reportData['actualEquipmentAvailability']?.toStringAsFixed(1) ?? '-'}%',
        '${reportData['plannedEquipmentAvailability']?.toStringAsFixed(1) ?? '-'}%',
        '${reportData['equipmentAvailabilityDeviation']?.toStringAsFixed(1) ?? '-'}%',
        persianFont,
      ),
      _buildDataRow(
        'نرخ تناژ',
        '${reportData['actualTonnageRate']?.toStringAsFixed(2) ?? '-'}',
        '${reportData['plannedTonnageRate']?.toStringAsFixed(2) ?? '-'}',
        '${reportData['tonnageRateDeviation']?.toStringAsFixed(1) ?? '-'}%',
        persianFont,
      ),
    ];
  }

  /// ساخت هدر توقفات
  static pw.TableRow _buildStopsHeader(pw.Font persianBoldFont) {
    return pw.TableRow(
      decoration: pw.BoxDecoration(color: PdfColors.grey300),
      children: [
        _buildHeaderCell('انحراف', persianBoldFont),
        _buildHeaderCell('تعداد', persianBoldFont),
        _buildHeaderCell('مدت', persianBoldFont),
        _buildHeaderCell('نوع توقف', persianBoldFont),
      ],
    );
  }

  /// ساخت ردیف توقف
  static pw.TableRow _buildStopRow(
      Map<String, dynamic> stop, pw.Font persianFont) {
    // محاسبه برنامه توقف برای این نوع
    final stopType = stop['type'] ?? '';
    final actualDuration = stop['duration'] ?? 0;
    final plannedDuration = _calculatePlannedStopDuration(stopType);

    // محاسبه انحراف (برای توقفات: کمتر = بهتر)
    final deviation = plannedDuration > 0
        ? -((actualDuration - plannedDuration) / plannedDuration) * 100
        : 0.0;

    return pw.TableRow(
      decoration: pw.BoxDecoration(color: PdfColors.grey200),
      children: [
        _buildCell(deviation.toStringAsFixed(1) + '%', persianFont),
        _buildCell(_formatMinutesToTime(plannedDuration.round()), persianFont),
        _buildCell(_formatMinutesToTime(actualDuration.round()), persianFont),
        _buildCell(stopType, persianFont, alignment: pw.Alignment.centerRight),
      ],
    );
  }

  /// محاسبه مدت برنامه توقف برای نوع خاص
  static double _calculatePlannedStopDuration(String stopType) {
    // داده‌های برنامه ماهانه (از annual_plan_screen.dart)
    const Map<String, List<double>> monthlyStopsPlan = {
      'برنامه ای': [3.0, 3.0, 3.0, 3.0, 3.0, 8.0, 3.0, 3.0, 3.0, 3.0, 3.0, 8.0],
      'مکانیکی': [1.6, 1.6, 1.6, 1.6, 1.6, 1.6, 1.6, 1.6, 1.6, 1.6, 1.6, 1.5],
      'برقی': [0.4, 0.4, 0.4, 0.4, 0.4, 0.4, 0.4, 0.4, 0.4, 0.4, 0.4, 0.4],
      'تاسیساتی': [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
      'بهره برداری': [
        1.3,
        1.3,
        1.3,
        1.3,
        1.3,
        1.3,
        1.3,
        1.3,
        1.3,
        1.3,
        1.3,
        1.3
      ],
      'معدنی': [0.7, 0.7, 0.7, 0.7, 0.7, 0.7, 0.7, 0.7, 0.7, 0.7, 0.7, 0.7],
      'عمومی': [3.1, 0.5, 0.5, 2.5, 0.5, 0.5, 0.5, 0.5, 0.5, 1.0, 1.0, 3.9],
      'مجاز': [4.8, 4.8, 4.8, 4.8, 4.8, 4.8, 4.6, 4.6, 4.6, 4.6, 4.6, 4.5],
      'بارگیری': [0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2],
    };

    if (!monthlyStopsPlan.containsKey(stopType)) {
      return 0.0;
    }

    // فعلاً برای ماه 4 (تیر) محاسبه می‌کنیم
    // در آینده باید بر اساس تاریخ انتخابی محاسبه شود
    final monthIndex = 3; // ماه 4 (شمارش از 0)
    final plannedDays = monthlyStopsPlan[stopType]![monthIndex];

    // تبدیل روز به دقیقه (24 ساعت × 60 دقیقه)
    return (plannedDays * 24 * 60).round().toDouble();
  }

  /// ساخت ردیف‌های تولیدات
  static List<pw.TableRow> _buildProductionRows(
      Map<String, dynamic> reportData, pw.Font persianFont) {
    final rows = <pw.TableRow>[];

    // خوراک
    rows.addAll([
      _buildDataRow(
        'تناژ خوراک',
        _formatNumber(reportData['actualFeed'] ?? 0),
        _formatNumber(reportData['plannedFeed'] ?? 0),
        '${reportData['feedDeviation']?.toStringAsFixed(1) ?? '-'}%',
        persianFont,
        color: AppPdfColors.feedColorLight,
      ),
    ]);

    // اگر عیار موجود است
    if (_hasGradeData(reportData)) {
      rows.add(_buildDataRow(
        'عیار خوراک',
        '${reportData['actualFeedGrade']?.toStringAsFixed(2) ?? '-'}%',
        '${reportData['plannedFeedGrade']?.toStringAsFixed(2) ?? '-'}%',
        '${reportData['feedGradeDeviation']?.toStringAsFixed(1) ?? '-'}%',
        persianFont,
        color: AppPdfColors.feedColorLight,
      ));
    }

    // محصول
    rows.addAll([
      _buildDataRow(
        'تناژ محصول',
        _formatNumber(reportData['actualProduct'] ?? 0),
        _formatNumber(reportData['plannedProduct'] ?? 0),
        '${reportData['productDeviation']?.toStringAsFixed(1) ?? '-'}%',
        persianFont,
        color: AppPdfColors.productColorLight,
      ),
    ]);

    // اگر عیار موجود است
    if (_hasGradeData(reportData)) {
      rows.add(_buildDataRow(
        'عیار محصول',
        '${reportData['actualProductGrade']?.toStringAsFixed(2) ?? '-'}%',
        '${reportData['plannedProductGrade']?.toStringAsFixed(2) ?? '-'}%',
        '${reportData['productGradeDeviation']?.toStringAsFixed(1) ?? '-'}%',
        persianFont,
        color: AppPdfColors.productColorLight,
      ));
    }

    // باطله
    rows.addAll([
      _buildDataRow(
        'تناژ باطله',
        _formatNumber(reportData['actualWaste'] ?? 0),
        _formatNumber(reportData['plannedWaste'] ?? 0),
        '${reportData['wasteDeviation']?.toStringAsFixed(1) ?? '-'}%',
        persianFont,
        color: AppPdfColors.tailingColorLight,
      ),
    ]);

    // اگر عیار موجود است
    if (_hasGradeData(reportData)) {
      rows.add(_buildDataRow(
        'عیار باطله',
        '${reportData['actualWasteGrade']?.toStringAsFixed(2) ?? '-'}%',
        '${reportData['plannedWasteGrade']?.toStringAsFixed(2) ?? '-'}%',
        '${reportData['wasteGradeDeviation']?.toStringAsFixed(1) ?? '-'}%',
        persianFont,
        color: AppPdfColors.tailingColorLight,
      ));
    }

    // ریکاوری
    rows.addAll([
      _buildDataRow(
        'ریکاوری وزنی',
        '${reportData['actualWeightRecovery']?.toStringAsFixed(1) ?? '-'}%',
        '${reportData['plannedWeightRecovery']?.toStringAsFixed(1) ?? '-'}%',
        '${reportData['weightRecoveryDeviation']?.toStringAsFixed(1) ?? '-'}%',
        persianFont,
      ),
      _buildDataRow(
        'ریکاوری فلزی',
        '${reportData['actualMetalRecovery']?.toStringAsFixed(1) ?? '-'}%',
        '${reportData['plannedMetalRecovery']?.toStringAsFixed(1) ?? '-'}%',
        '${reportData['metalRecoveryDeviation']?.toStringAsFixed(1) ?? '-'}%',
        persianFont,
      ),
    ]);

    return rows;
  }

  /// ساخت ردیف داده
  static pw.TableRow _buildDataRow(
    String title,
    String actual,
    String planned,
    String deviation,
    pw.Font font, {
    PdfColor? color,
  }) {
    return pw.TableRow(
      decoration: color != null ? pw.BoxDecoration(color: color) : null,
      children: [
        _buildCell(deviation, font),
        _buildCell(planned, font),
        _buildCell(actual, font),
        _buildCell(title, font, alignment: pw.Alignment.centerRight),
      ],
    );
  }

  /// ساخت سلول داده
  static pw.Widget _buildCell(
    String text,
    pw.Font font, {
    pw.Alignment alignment = pw.Alignment.center,
  }) {
    return pw.Container(
      alignment: alignment,
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(text,
          style: pw.TextStyle(fontSize: 7, font: font),
          textDirection: pw.TextDirection.rtl,
          textAlign: pw.TextAlign.center,
          maxLines: 1),
    );
  }

  /// تولید گزارش خوراک ورودی
  static Future<File> generateFeedReport({
    required List<PdfFeedData> feedData,
    required DateTime startDate,
    required DateTime endDate,
    required String timeRange,
    required String selectedShift,
    required Map<String, double> summaryStats,
    required List<ChartPoint> actualData,
    required List<ChartPoint> plannedData,
  }) async {
    try {
      final pdf = pw.Document();
      final persianFont = await _getPersianFont();
      final persianBoldFont = await _getPersianBoldFont();

      // تبدیل تاریخ‌ها به شمسی
      final startShamsi = Jalali.fromDateTime(startDate);
      final endShamsi = Jalali.fromDateTime(endDate);
      final now = Jalali.now();

      // محدود کردن داده‌ها برای جلوگیری از تولید بیش از حد صفحات
      final limitedFeedData = feedData.take(30).toList();
      final limitedActualData = actualData.take(30).toList();
      final limitedPlannedData = plannedData.take(30).toList();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          theme: pw.ThemeData.withFont(base: persianFont),
          build: (context) => _buildFeedReportPage(
            feedData: limitedFeedData,
            startShamsi: startShamsi,
            endShamsi: endShamsi,
            now: now,
            timeRange: timeRange,
            selectedShift: selectedShift,
            summaryStats: summaryStats,
            actualData: limitedActualData,
            plannedData: limitedPlannedData,
            persianFont: persianFont,
            persianBoldFont: persianBoldFont,
          ),
        ),
      );

      final output = await getTemporaryDirectory();
      final file = File(
          '${output.path}/feed_report_${DateTime.now().millisecondsSinceEpoch}.pdf');
      await file.writeAsBytes(await pdf.save());
      return file;
    } catch (e) {
      print('خطا در تولید PDF گزارش خوراک: $e');
      rethrow;
    }
  }

  /// تولید گزارش محصول تولیدی
  static Future<File> generateProductReport({
    required List<PdfProductData> productData,
    required DateTime startDate,
    required DateTime endDate,
    required String timeRange,
    required String selectedShift,
    required Map<String, double> summaryStats,
    required List<ChartPoint> actualData,
    required List<ChartPoint> plannedData,
  }) async {
    try {
      final pdf = pw.Document();
      final persianFont = await _getPersianFont();
      final persianBoldFont = await _getPersianBoldFont();

      // تبدیل تاریخ‌ها به شمسی
      final startShamsi = Jalali.fromDateTime(startDate);
      final endShamsi = Jalali.fromDateTime(endDate);
      final now = Jalali.now();

      // محدود کردن داده‌ها برای جلوگیری از تولید بیش از حد صفحات
      final limitedProductData = productData.take(30).toList();
      final limitedActualData = actualData.take(30).toList();
      final limitedPlannedData = plannedData.take(30).toList();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          theme: pw.ThemeData.withFont(base: persianFont),
          build: (context) => _buildProductReportPage(
            productData: limitedProductData,
            startShamsi: startShamsi,
            endShamsi: endShamsi,
            now: now,
            timeRange: timeRange,
            selectedShift: selectedShift,
            summaryStats: summaryStats,
            actualData: limitedActualData,
            plannedData: limitedPlannedData,
            persianFont: persianFont,
            persianBoldFont: persianBoldFont,
          ),
        ),
      );

      final output = await getTemporaryDirectory();
      final file = File(
          '${output.path}/product_report_${DateTime.now().millisecondsSinceEpoch}.pdf');
      await file.writeAsBytes(await pdf.save());
      return file;
    } catch (e) {
      print('خطا در تولید PDF گزارش محصول: $e');
      rethrow;
    }
  }

  /// تولید گزارش باطله تولیدی
  static Future<File> generateTailingReport({
    required List<PdfTailingData> tailingData,
    required DateTime startDate,
    required DateTime endDate,
    required String timeRange,
    required String selectedShift,
    required Map<String, double> summaryStats,
    required List<ChartPoint> actualData,
    required List<ChartPoint> plannedData,
  }) async {
    try {
      final pdf = pw.Document();
      final persianFont = await _getPersianFont();
      final persianBoldFont = await _getPersianBoldFont();

      // تبدیل تاریخ‌ها به شمسی
      final startShamsi = Jalali.fromDateTime(startDate);
      final endShamsi = Jalali.fromDateTime(endDate);
      final now = Jalali.now();

      // محدود کردن داده‌ها برای جلوگیری از تولید بیش از حد صفحات
      final limitedTailingData = tailingData.take(30).toList();
      final limitedActualData = actualData.take(30).toList();
      final limitedPlannedData = plannedData.take(30).toList();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          theme: pw.ThemeData.withFont(base: persianFont),
          build: (context) => _buildTailingReportPage(
            tailingData: limitedTailingData,
            startShamsi: startShamsi,
            endShamsi: endShamsi,
            now: now,
            timeRange: timeRange,
            selectedShift: selectedShift,
            summaryStats: summaryStats,
            actualData: limitedActualData,
            plannedData: limitedPlannedData,
            persianFont: persianFont,
            persianBoldFont: persianBoldFont,
          ),
        ),
      );

      final output = await getTemporaryDirectory();
      final file = File(
          '${output.path}/tailing_report_${DateTime.now().millisecondsSinceEpoch}.pdf');
      await file.writeAsBytes(await pdf.save());
      return file;
    } catch (e) {
      print('خطا در تولید PDF گزارش باطله: $e');
      rethrow;
    }
  }

  /// تولید گزارش توقفات
  static Future<File> generateStopsReport({
    required List<ProductionData> stopData,
    required DateTime startDate,
    required DateTime endDate,
    required Map<String, int> stopsByType,
    required Map<String, int> stopsByTypeDuration,
    required int totalActualStops,
    required int totalPlannedStops,
    required double deviationPercentage,
    required List<ChartPoint> chartData,
  }) async {
    try {
      final pdf = pw.Document();
      final persianFont = await _getPersianFont();
      final persianBoldFont = await _getPersianBoldFont();

      // تبدیل تاریخ‌ها به شمسی
      final startShamsi = Jalali.fromDateTime(startDate);
      final endShamsi = Jalali.fromDateTime(endDate);
      final now = Jalali.now();

      // محدود کردن داده‌ها برای جلوگیری از تولید بیش از حد صفحات
      final limitedStopData = stopData.take(50).toList();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          theme: pw.ThemeData.withFont(base: persianFont),
          build: (context) => _buildStopsReportPage(
            stopData: limitedStopData,
            startShamsi: startShamsi,
            endShamsi: endShamsi,
            now: now,
            stopsByType: stopsByType,
            stopsByTypeDuration: stopsByTypeDuration,
            totalActualStops: totalActualStops,
            totalPlannedStops: totalPlannedStops,
            deviationPercentage: deviationPercentage,
            chartData: chartData,
            persianFont: persianFont,
            persianBoldFont: persianBoldFont,
          ),
        ),
      );

      final output = await getTemporaryDirectory();
      final file = File(
          '${output.path}/stops_report_${DateTime.now().millisecondsSinceEpoch}.pdf');
      await file.writeAsBytes(await pdf.save());
      return file;
    } catch (e) {
      print('خطا در تولید PDF گزارش توقفات: $e');
      rethrow;
    }
  }

  /// تولید گزارش توقفات (نسخه جدید با StopData)
  static Future<File> generateStopsReportFromStopData({
    required List<StopData> stopData,
    required DateTime startDate,
    required DateTime endDate,
    required Map<String, int> stopsByType,
    required Map<String, int> stopsByTypeDuration,
    required int totalActualStops,
    required int totalPlannedStops,
    required double deviationPercentage,
    required List<ChartPoint> chartData,
  }) async {
    try {
      final pdf = pw.Document();
      final persianFont = await _getPersianFont();
      final persianBoldFont = await _getPersianBoldFont();

      // تبدیل تاریخ‌ها به شمسی
      final startShamsi = Jalali.fromDateTime(startDate);
      final endShamsi = Jalali.fromDateTime(endDate);
      final now = Jalali.now();

      // محدود کردن داده‌ها برای جلوگیری از تولید بیش از حد صفحات
      final limitedStopData = stopData.take(50).toList();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          theme: pw.ThemeData.withFont(base: persianFont),
          build: (context) => _buildStopsReportPageFromStopData(
            stopData: limitedStopData,
            startShamsi: startShamsi,
            endShamsi: endShamsi,
            now: now,
            stopsByType: stopsByType,
            stopsByTypeDuration: stopsByTypeDuration,
            totalActualStops: totalActualStops,
            totalPlannedStops: totalPlannedStops,
            deviationPercentage: deviationPercentage,
            chartData: chartData,
            persianFont: persianFont,
            persianBoldFont: persianBoldFont,
          ),
        ),
      );

      final output = await getTemporaryDirectory();
      final file = File(
          '${output.path}/stops_report_${DateTime.now().millisecondsSinceEpoch}.pdf');
      await file.writeAsBytes(await pdf.save());
      return file;
    } catch (e) {
      print('خطا در تولید PDF گزارش توقفات: $e');
      rethrow;
    }
  }

  /// ساخت صفحه گزارش خوراک
  static pw.Widget _buildFeedReportPage({
    required List<PdfFeedData> feedData,
    required Jalali startShamsi,
    required Jalali endShamsi,
    required Jalali now,
    required String timeRange,
    required String selectedShift,
    required Map<String, double> summaryStats,
    required List<ChartPoint> actualData,
    required List<ChartPoint> plannedData,
    required pw.Font persianFont,
    required pw.Font persianBoldFont,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // هدر گزارش
          pw.Text('گزارش خوراک ورودی',
              style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  font: persianBoldFont),
              textDirection: pw.TextDirection.rtl),
          pw.SizedBox(height: 8),
          pw.Text(
              'بازه: ${startShamsi.formatCompactDate()} تا ${endShamsi.formatCompactDate()}',
              style: pw.TextStyle(fontSize: 10, font: persianFont),
              textDirection: pw.TextDirection.rtl),
          pw.Text('نوع بازه: $timeRange',
              style: pw.TextStyle(fontSize: 10, font: persianFont),
              textDirection: pw.TextDirection.rtl),
          pw.Text('شیفت: $selectedShift',
              style: pw.TextStyle(fontSize: 10, font: persianFont),
              textDirection: pw.TextDirection.rtl),
          pw.Text('تاریخ تولید گزارش: ${now.formatCompactDate()}',
              style: pw.TextStyle(fontSize: 10, font: persianFont),
              textDirection: pw.TextDirection.rtl),
          pw.SizedBox(height: 12),

          // نمودار
          _buildFeedChart(
              actualData, plannedData, persianFont, persianBoldFont),
          pw.SizedBox(height: 12),

          // جدول خلاصه
          _buildFeedSummaryTable(summaryStats, persianFont, persianBoldFont),
          pw.SizedBox(height: 12),

          // جدول جزئیات
          _buildFeedDetailsTable(feedData, persianFont, persianBoldFont),
        ],
      ),
    );
  }

  /// ساخت صفحه گزارش محصول
  static pw.Widget _buildProductReportPage({
    required List<PdfProductData> productData,
    required Jalali startShamsi,
    required Jalali endShamsi,
    required Jalali now,
    required String timeRange,
    required String selectedShift,
    required Map<String, double> summaryStats,
    required List<ChartPoint> actualData,
    required List<ChartPoint> plannedData,
    required pw.Font persianFont,
    required pw.Font persianBoldFont,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // هدر گزارش
          pw.Text('گزارش محصول تولیدی',
              style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  font: persianBoldFont),
              textDirection: pw.TextDirection.rtl),
          pw.SizedBox(height: 8),
          pw.Text(
              'بازه: ${startShamsi.formatCompactDate()} تا ${endShamsi.formatCompactDate()}',
              style: pw.TextStyle(fontSize: 10, font: persianFont),
              textDirection: pw.TextDirection.rtl),
          pw.Text('نوع بازه: $timeRange',
              style: pw.TextStyle(fontSize: 10, font: persianFont),
              textDirection: pw.TextDirection.rtl),
          pw.Text('شیفت: $selectedShift',
              style: pw.TextStyle(fontSize: 10, font: persianFont),
              textDirection: pw.TextDirection.rtl),
          pw.Text('تاریخ تولید گزارش: ${now.formatCompactDate()}',
              style: pw.TextStyle(fontSize: 10, font: persianFont),
              textDirection: pw.TextDirection.rtl),
          pw.SizedBox(height: 12),

          // نمودار
          _buildProductChart(
              actualData, plannedData, persianFont, persianBoldFont),
          pw.SizedBox(height: 12),

          // جدول خلاصه
          _buildProductSummaryTable(summaryStats, persianFont, persianBoldFont),
          pw.SizedBox(height: 12),

          // جدول جزئیات
          _buildProductDetailsTable(productData, persianFont, persianBoldFont),
        ],
      ),
    );
  }

  /// ساخت صفحه گزارش باطله
  static pw.Widget _buildTailingReportPage({
    required List<PdfTailingData> tailingData,
    required Jalali startShamsi,
    required Jalali endShamsi,
    required Jalali now,
    required String timeRange,
    required String selectedShift,
    required Map<String, double> summaryStats,
    required List<ChartPoint> actualData,
    required List<ChartPoint> plannedData,
    required pw.Font persianFont,
    required pw.Font persianBoldFont,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // هدر گزارش
          pw.Text('گزارش باطله تولیدی',
              style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  font: persianBoldFont),
              textDirection: pw.TextDirection.rtl),
          pw.SizedBox(height: 8),
          pw.Text(
              'بازه: ${startShamsi.formatCompactDate()} تا ${endShamsi.formatCompactDate()}',
              style: pw.TextStyle(fontSize: 10, font: persianFont),
              textDirection: pw.TextDirection.rtl),
          pw.Text('نوع بازه: $timeRange',
              style: pw.TextStyle(fontSize: 10, font: persianFont),
              textDirection: pw.TextDirection.rtl),
          pw.Text('شیفت: $selectedShift',
              style: pw.TextStyle(fontSize: 10, font: persianFont),
              textDirection: pw.TextDirection.rtl),
          pw.Text('تاریخ تولید گزارش: ${now.formatCompactDate()}',
              style: pw.TextStyle(fontSize: 10, font: persianFont),
              textDirection: pw.TextDirection.rtl),
          pw.SizedBox(height: 12),

          // نمودار
          _buildTailingChart(
              actualData, plannedData, persianFont, persianBoldFont),
          pw.SizedBox(height: 12),

          // جدول خلاصه
          _buildTailingSummaryTable(summaryStats, persianFont, persianBoldFont),
          pw.SizedBox(height: 12),

          // جدول جزئیات
          _buildTailingDetailsTable(tailingData, persianFont, persianBoldFont),
        ],
      ),
    );
  }

  /// ساخت صفحه گزارش توقفات
  static pw.Widget _buildStopsReportPage({
    required List<ProductionData> stopData,
    required Jalali startShamsi,
    required Jalali endShamsi,
    required Jalali now,
    required Map<String, int> stopsByType,
    required Map<String, int> stopsByTypeDuration,
    required int totalActualStops,
    required int totalPlannedStops,
    required double deviationPercentage,
    required List<ChartPoint> chartData,
    required pw.Font persianFont,
    required pw.Font persianBoldFont,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // هدر گزارش
          pw.Text('گزارش توقفات',
              style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  font: persianBoldFont),
              textDirection: pw.TextDirection.rtl),
          pw.SizedBox(height: 8),
          pw.Text(
              'بازه: ${startShamsi.formatCompactDate()} تا ${endShamsi.formatCompactDate()}',
              style: pw.TextStyle(fontSize: 10, font: persianFont),
              textDirection: pw.TextDirection.rtl),
          pw.Text('تاریخ تولید گزارش: ${now.formatCompactDate()}',
              style: pw.TextStyle(fontSize: 10, font: persianFont),
              textDirection: pw.TextDirection.rtl),
          pw.SizedBox(height: 12),

          // جدول خلاصه
          _buildStopsSummaryTable(
            totalActualStops,
            totalPlannedStops,
            deviationPercentage,
            persianFont,
            persianBoldFont,
          ),
          pw.SizedBox(height: 12),

          // نمودار دایره‌ای
          _buildStopsPieChart(stopsByTypeDuration, totalActualStops,
              persianFont, persianBoldFont),
          pw.SizedBox(height: 12),

          // جدول جزئیات
          _buildStopsDetailsTable(stopData, persianFont, persianBoldFont),
        ],
      ),
    );
  }

  /// ساخت صفحه گزارش توقفات (نسخه جدید با StopData)
  static pw.Widget _buildStopsReportPageFromStopData({
    required List<StopData> stopData,
    required Jalali startShamsi,
    required Jalali endShamsi,
    required Jalali now,
    required Map<String, int> stopsByType,
    required Map<String, int> stopsByTypeDuration,
    required int totalActualStops,
    required int totalPlannedStops,
    required double deviationPercentage,
    required List<ChartPoint> chartData,
    required pw.Font persianFont,
    required pw.Font persianBoldFont,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // هدر گزارش
          pw.Text('گزارش توقفات',
              style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  font: persianBoldFont),
              textDirection: pw.TextDirection.rtl),
          pw.SizedBox(height: 8),
          pw.Text(
              'بازه: ${startShamsi.formatCompactDate()} تا ${endShamsi.formatCompactDate()}',
              style: pw.TextStyle(fontSize: 10, font: persianFont),
              textDirection: pw.TextDirection.rtl),
          pw.Text('تاریخ تولید گزارش: ${now.formatCompactDate()}',
              style: pw.TextStyle(fontSize: 10, font: persianFont),
              textDirection: pw.TextDirection.rtl),
          pw.SizedBox(height: 12),

          // جدول خلاصه
          _buildStopsSummaryTable(
            totalActualStops,
            totalPlannedStops,
            deviationPercentage,
            persianFont,
            persianBoldFont,
          ),
          pw.SizedBox(height: 12),

          // نمودار دایره‌ای
          _buildStopsPieChart(stopsByTypeDuration, totalActualStops,
              persianFont, persianBoldFont),
          pw.SizedBox(height: 12),

          // جدول جزئیات
          _buildStopsDetailsTableFromStopData(
              stopData, persianFont, persianBoldFont),
        ],
      ),
    );
  }

  /// ساخت نمودار خوراک
  static pw.Widget _buildFeedChart(
    List<ChartPoint> actualData,
    List<ChartPoint> plannedData,
    pw.Font persianFont,
    pw.Font persianBoldFont,
  ) {
    // محاسبه محدوده Y برای نمودار
    final allValues = [
      ...actualData.map((p) => p.y),
      ...plannedData.map((p) => p.y)
    ];
    final maxY =
        allValues.isNotEmpty ? allValues.reduce((a, b) => a > b ? a : b) : 10;
    final minY = 0;

    // ایجاد نقاط Y برای gridlines
    final yStep = maxY > 0 ? (maxY / 5).ceil() : 2;
    final yAxis = <double>[];
    for (int i = 0; i <= (maxY / yStep).ceil(); i++) {
      yAxis.add((i * yStep).toDouble());
    }

    // ایجاد نقاط X برای gridlines
    final maxX = actualData.isNotEmpty ? actualData.length - 1 : 7;
    final xAxis = <double>[];
    for (int i = 0; i <= maxX; i++) {
      xAxis.add(i.toDouble());
    }

    return pw.Container(
      height: 200,
      margin: const pw.EdgeInsets.all(10),
      child: pw.Column(
        children: [
          // عنوان نمودار
          pw.Text(
            'نمودار خوراک ورودی',
            style: pw.TextStyle(
              fontSize: 12,
              font: persianBoldFont,
              fontWeight: pw.FontWeight.bold,
            ),
            textAlign: pw.TextAlign.center,
            textDirection: pw.TextDirection.rtl,
          ),
          pw.SizedBox(height: 8),
          // نمودار
          pw.Expanded(
            child: pw.Chart(
              grid: pw.CartesianGrid(
                xAxis: pw.FixedAxis(xAxis),
                yAxis: pw.FixedAxis(yAxis),
              ),
              datasets: [
                pw.PointDataSet(
                  legend: 'خوراک محقق شده',
                  data: actualData
                      .map((point) => pw.PointChartValue(point.x, point.y))
                      .toList(),
                  color: AppPdfColors.feedColor,
                  pointSize: 4,
                ),
                pw.LineDataSet(
                  legend: 'خوراک برنامه‌ریزی شده',
                  data: plannedData
                      .map((point) => pw.LineChartValue(point.x, point.y))
                      .toList(),
                  color: PdfColors.red,
                ),
              ],
            ),
          ),
          // لجند
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              _buildLegendItem(
                  'خوراک محقق شده', AppPdfColors.feedColor, persianFont),
              pw.SizedBox(width: 20),
              _buildLegendItem(
                  'خوراک برنامه‌ریزی شده', PdfColors.red, persianFont),
            ],
          ),
        ],
      ),
    );
  }

  /// ساخت آیتم لجند
  static pw.Widget _buildLegendItem(String text, PdfColor color, pw.Font font) {
    return pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Container(
          width: 12,
          height: 2,
          color: color,
        ),
        pw.SizedBox(width: 6),
        pw.Text(
          text,
          style: pw.TextStyle(fontSize: 8, font: font),
          textDirection: pw.TextDirection.rtl,
        ),
      ],
    );
  }

  /// ساخت نمودار محصول
  static pw.Widget _buildProductChart(
    List<ChartPoint> actualData,
    List<ChartPoint> plannedData,
    pw.Font persianFont,
    pw.Font persianBoldFont,
  ) {
    // محاسبه محدوده Y برای نمودار
    final allValues = [
      ...actualData.map((p) => p.y),
      ...plannedData.map((p) => p.y)
    ];
    final maxY =
        allValues.isNotEmpty ? allValues.reduce((a, b) => a > b ? a : b) : 10;
    final minY = 0;

    // ایجاد نقاط Y برای gridlines
    final yStep = maxY > 0 ? (maxY / 5).ceil() : 2;
    final yAxis = <double>[];
    for (int i = 0; i <= (maxY / yStep).ceil(); i++) {
      yAxis.add((i * yStep).toDouble());
    }

    // ایجاد نقاط X برای gridlines
    final maxX = actualData.isNotEmpty ? actualData.length - 1 : 7;
    final xAxis = <double>[];
    for (int i = 0; i <= maxX; i++) {
      xAxis.add(i.toDouble());
    }

    return pw.Container(
      height: 200,
      margin: const pw.EdgeInsets.all(10),
      child: pw.Column(
        children: [
          // عنوان نمودار
          pw.Text(
            'نمودار محصول تولیدی',
            style: pw.TextStyle(
              fontSize: 12,
              font: persianBoldFont,
              fontWeight: pw.FontWeight.bold,
            ),
            textAlign: pw.TextAlign.center,
            textDirection: pw.TextDirection.rtl,
          ),
          pw.SizedBox(height: 8),
          // نمودار
          pw.Expanded(
            child: pw.Chart(
              grid: pw.CartesianGrid(
                xAxis: pw.FixedAxis(xAxis),
                yAxis: pw.FixedAxis(yAxis),
              ),
              datasets: [
                pw.PointDataSet(
                  legend: 'محصول محقق شده',
                  data: actualData
                      .map((point) => pw.PointChartValue(point.x, point.y))
                      .toList(),
                  color: PdfColors.green,
                  pointSize: 4,
                ),
                pw.LineDataSet(
                  legend: 'محصول برنامه‌ریزی شده',
                  data: plannedData
                      .map((point) => pw.LineChartValue(point.x, point.y))
                      .toList(),
                  color: PdfColors.red,
                ),
              ],
            ),
          ),
          // لجند
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              _buildLegendItem('محصول محقق شده', PdfColors.green, persianFont),
              pw.SizedBox(width: 20),
              _buildLegendItem(
                  'محصول برنامه‌ریزی شده', PdfColors.red, persianFont),
            ],
          ),
        ],
      ),
    );
  }

  /// ساخت نمودار باطله
  static pw.Widget _buildTailingChart(
    List<ChartPoint> actualData,
    List<ChartPoint> plannedData,
    pw.Font persianFont,
    pw.Font persianBoldFont,
  ) {
    // محاسبه محدوده Y برای نمودار
    final allValues = [
      ...actualData.map((p) => p.y),
      ...plannedData.map((p) => p.y)
    ];
    final maxY =
        allValues.isNotEmpty ? allValues.reduce((a, b) => a > b ? a : b) : 10;
    final minY = 0;

    // ایجاد نقاط Y برای gridlines
    final yStep = maxY > 0 ? (maxY / 5).ceil() : 2;
    final yAxis = <double>[];
    for (int i = 0; i <= (maxY / yStep).ceil(); i++) {
      yAxis.add((i * yStep).toDouble());
    }

    // ایجاد نقاط X برای gridlines
    final maxX = actualData.isNotEmpty ? actualData.length - 1 : 7;
    final xAxis = <double>[];
    for (int i = 0; i <= maxX; i++) {
      xAxis.add(i.toDouble());
    }

    return pw.Container(
      height: 200,
      margin: const pw.EdgeInsets.all(10),
      child: pw.Column(
        children: [
          // عنوان نمودار
          pw.Text(
            'نمودار باطله تولیدی',
            style: pw.TextStyle(
              fontSize: 12,
              font: persianBoldFont,
              fontWeight: pw.FontWeight.bold,
            ),
            textAlign: pw.TextAlign.center,
            textDirection: pw.TextDirection.rtl,
          ),
          pw.SizedBox(height: 8),
          // نمودار
          pw.Expanded(
            child: pw.Chart(
              grid: pw.CartesianGrid(
                xAxis: pw.FixedAxis(xAxis),
                yAxis: pw.FixedAxis(yAxis),
              ),
              datasets: [
                pw.PointDataSet(
                  legend: 'باطله محقق شده',
                  data: actualData
                      .map((point) => pw.PointChartValue(point.x, point.y))
                      .toList(),
                  color: PdfColors.red,
                  pointSize: 4,
                ),
                pw.LineDataSet(
                  legend: 'باطله برنامه‌ریزی شده',
                  data: plannedData
                      .map((point) => pw.LineChartValue(point.x, point.y))
                      .toList(),
                  color: PdfColors.blue,
                ),
              ],
            ),
          ),
          // لجند
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              _buildLegendItem('باطله محقق شده', PdfColors.red, persianFont),
              pw.SizedBox(width: 20),
              _buildLegendItem(
                  'باطله برنامه‌ریزی شده', PdfColors.blue, persianFont),
            ],
          ),
        ],
      ),
    );
  }

  /// ساخت جدول خلاصه محصول
  static pw.Widget _buildProductSummaryTable(
    Map<String, double> summaryStats,
    pw.Font persianFont,
    pw.Font persianBoldFont,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'خلاصه آمار محصول',
            style: pw.TextStyle(
              fontSize: 12,
              font: persianBoldFont,
              fontWeight: pw.FontWeight.bold,
            ),
            textDirection: pw.TextDirection.rtl,
          ),
          pw.SizedBox(height: 8),
          pw.Table(
            columnWidths: {
              0: const pw.FlexColumnWidth(1.5), // عنوان
              1: const pw.FlexColumnWidth(1.0), // مقدار
            },
            children: [
              _buildSummaryRow(
                  'کل محصول محقق شده',
                  '${_formatNumber(summaryStats['totalActual'] ?? 0)} تن',
                  persianFont,
                  persianBoldFont),
              _buildSummaryRow(
                  'کل محصول برنامه',
                  '${_formatNumber(summaryStats['totalPlanned'] ?? 0)} تن',
                  persianFont,
                  persianBoldFont),
              _buildSummaryRow(
                  'انحراف کل',
                  '${summaryStats['deviationPercentage']?.toStringAsFixed(1) ?? '0'}%',
                  persianFont,
                  persianBoldFont),
              _buildSummaryRow(
                  'حداکثر روزانه',
                  '${_formatNumber(summaryStats['maxDaily'] ?? 0)} تن',
                  persianFont,
                  persianBoldFont),
            ],
          ),
        ],
      ),
    );
  }

  /// ساخت جدول خلاصه باطله
  static pw.Widget _buildTailingSummaryTable(
    Map<String, double> summaryStats,
    pw.Font persianFont,
    pw.Font persianBoldFont,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'خلاصه آمار باطله',
            style: pw.TextStyle(
              fontSize: 12,
              font: persianBoldFont,
              fontWeight: pw.FontWeight.bold,
            ),
            textDirection: pw.TextDirection.rtl,
          ),
          pw.SizedBox(height: 8),
          pw.Table(
            columnWidths: {
              0: const pw.FlexColumnWidth(1.5), // عنوان
              1: const pw.FlexColumnWidth(1.0), // مقدار
            },
            children: [
              _buildSummaryRow(
                  'کل باطله محقق شده',
                  '${_formatNumber(summaryStats['totalActual'] ?? 0)} تن',
                  persianFont,
                  persianBoldFont),
              _buildSummaryRow(
                  'کل باطله برنامه',
                  '${_formatNumber(summaryStats['totalPlanned'] ?? 0)} تن',
                  persianFont,
                  persianBoldFont),
              _buildSummaryRow(
                  'انحراف کل',
                  '${summaryStats['deviationPercentage']?.toStringAsFixed(1) ?? '0'}%',
                  persianFont,
                  persianBoldFont),
              _buildSummaryRow(
                  'حداکثر روزانه',
                  '${_formatNumber(summaryStats['maxDaily'] ?? 0)} تن',
                  persianFont,
                  persianBoldFont),
            ],
          ),
        ],
      ),
    );
  }

  /// ساخت جدول جزئیات محصول
  static pw.Widget _buildProductDetailsTable(
    List<PdfProductData> productData,
    pw.Font persianFont,
    pw.Font persianBoldFont,
  ) {
    return pw.Container(
      margin: const pw.EdgeInsets.all(10),
      child: pw.Column(
        children: [
          pw.Text(
            'جدول جزئیات محصول تولیدی',
            style: pw.TextStyle(
              fontSize: 14,
              font: persianBoldFont,
              fontWeight: pw.FontWeight.bold,
            ),
            textAlign: pw.TextAlign.center,
            textDirection: pw.TextDirection.rtl,
          ),
          pw.SizedBox(height: 12),
          pw.Table(
            border: pw.TableBorder.all(),
            columnWidths: {
              0: const pw.FlexColumnWidth(1.2), // تاریخ/بازه
              1: const pw.FlexColumnWidth(0.8), // شیفت
              2: const pw.FlexColumnWidth(1.3), // محصول محقق شده
              3: const pw.FlexColumnWidth(1.3), // محصول برنامه‌ریزی شده
              4: const pw.FlexColumnWidth(1.0), // انحراف از برنامه
            },
            children: [
              // هدر جدول
              pw.TableRow(
                decoration: pw.BoxDecoration(color: PdfColors.grey300),
                children: [
                  _buildHeaderCell('تاریخ/بازه', persianBoldFont),
                  _buildHeaderCell('شیفت', persianBoldFont),
                  _buildHeaderCell('محصول محقق شده (تن)', persianBoldFont),
                  _buildHeaderCell(
                      'محصول برنامه‌ریزی شده (تن)', persianBoldFont),
                  _buildHeaderCell('انحراف از برنامه', persianBoldFont),
                ],
              ),
              // ردیف‌های داده
              ...productData.map((data) {
                final deviation = data.plannedProduct > 0
                    ? ((data.actualProduct - data.plannedProduct) /
                            data.plannedProduct) *
                        100
                    : 0.0;
                final deviationText =
                    '${deviation >= 0 ? '+' : ''}${deviation.toStringAsFixed(1)}%';
                final deviationColor =
                    deviation >= 0 ? PdfColors.green : PdfColors.red;

                return pw.TableRow(
                  children: [
                    _buildCell(data.label, persianFont),
                    _buildCell(data.shift, persianFont),
                    _buildCell(_formatNumber(data.actualProduct), persianFont),
                    _buildCell(_formatNumber(data.plannedProduct), persianFont),
                    pw.Container(
                      alignment: pw.Alignment.center,
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text(
                        deviationText,
                        style: pw.TextStyle(
                          fontSize: 8,
                          font: persianFont,
                          color: deviationColor,
                          fontWeight: pw.FontWeight.bold,
                        ),
                        textDirection: pw.TextDirection.rtl,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ],
          ),
        ],
      ),
    );
  }

  /// ساخت جدول خلاصه خوراک
  static pw.Widget _buildFeedSummaryTable(
    Map<String, double> summaryStats,
    pw.Font persianFont,
    pw.Font persianBoldFont,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'خلاصه آمار',
            style: pw.TextStyle(
              fontSize: 12,
              font: persianBoldFont,
              fontWeight: pw.FontWeight.bold,
            ),
            textDirection: pw.TextDirection.rtl,
          ),
          pw.SizedBox(height: 8),
          pw.Table(
            columnWidths: {
              0: const pw.FlexColumnWidth(1.5), // عنوان
              1: const pw.FlexColumnWidth(1.0), // مقدار
            },
            children: [
              _buildSummaryRow(
                  'کل خوراک محقق شده',
                  '${_formatNumber(summaryStats['totalActualFeed'] ?? 0)} تن',
                  persianFont,
                  persianBoldFont),
              _buildSummaryRow(
                  'کل خوراک برنامه',
                  '${_formatNumber(summaryStats['totalPlannedFeed'] ?? 0)} تن',
                  persianFont,
                  persianBoldFont),
              _buildSummaryRow(
                  'انحراف کل',
                  '${summaryStats['feedDeviation']?.toStringAsFixed(1) ?? '0'}%',
                  persianFont,
                  persianBoldFont),
              _buildSummaryRow(
                  'حداکثر روزانه',
                  '${_formatNumber(summaryStats['maxDailyFeed'] ?? 0)} تن',
                  persianFont,
                  persianBoldFont),
            ],
          ),
        ],
      ),
    );
  }

  /// ساخت ردیف جدول خلاصه
  static pw.TableRow _buildSummaryRow(String title, String value,
      pw.Font persianFont, pw.Font persianBoldFont) {
    return pw.TableRow(
      children: [
        pw.Text(title,
            style: pw.TextStyle(fontSize: 8, font: persianBoldFont),
            textDirection: pw.TextDirection.rtl),
        pw.Text(value,
            style: pw.TextStyle(fontSize: 8, font: persianFont),
            textDirection: pw.TextDirection.rtl),
      ],
    );
  }

  /// ساخت جدول جزئیات خوراک
  static pw.Widget _buildFeedDetailsTable(
    List<PdfFeedData> feedData,
    pw.Font persianFont,
    pw.Font persianBoldFont,
  ) {
    return pw.Container(
      margin: const pw.EdgeInsets.all(10),
      child: pw.Column(
        children: [
          pw.Text(
            'جدول جزئیات خوراک ورودی',
            style: pw.TextStyle(
              fontSize: 14,
              font: persianBoldFont,
              fontWeight: pw.FontWeight.bold,
            ),
            textAlign: pw.TextAlign.center,
            textDirection: pw.TextDirection.rtl,
          ),
          pw.SizedBox(height: 12),
          pw.Table(
            border: pw.TableBorder.all(),
            columnWidths: {
              0: const pw.FlexColumnWidth(1.2), // تاریخ/بازه
              1: const pw.FlexColumnWidth(0.8), // شیفت
              2: const pw.FlexColumnWidth(1.3), // خوراک محقق شده
              3: const pw.FlexColumnWidth(1.3), // خوراک برنامه‌ریزی شده
              4: const pw.FlexColumnWidth(1.0), // انحراف از برنامه
            },
            children: [
              // هدر جدول
              pw.TableRow(
                decoration: pw.BoxDecoration(color: PdfColors.grey300),
                children: [
                  _buildHeaderCell('تاریخ/بازه', persianBoldFont),
                  _buildHeaderCell('شیفت', persianBoldFont),
                  _buildHeaderCell('خوراک محقق شده (تن)', persianBoldFont),
                  _buildHeaderCell(
                      'خوراک برنامه‌ریزی شده (تن)', persianBoldFont),
                  _buildHeaderCell('انحراف از برنامه', persianBoldFont),
                ],
              ),
              // ردیف‌های داده
              ...feedData.map((data) {
                final deviation = data.plannedFeed > 0
                    ? ((data.actualFeed - data.plannedFeed) /
                            data.plannedFeed) *
                        100
                    : 0.0;
                final deviationText =
                    '${deviation >= 0 ? '+' : ''}${deviation.toStringAsFixed(1)}%';
                final deviationColor =
                    deviation >= 0 ? PdfColors.green : PdfColors.red;

                return pw.TableRow(
                  children: [
                    _buildCell(data.label, persianFont),
                    _buildCell(data.shift, persianFont),
                    _buildCell(_formatNumber(data.actualFeed), persianFont),
                    _buildCell(_formatNumber(data.plannedFeed), persianFont),
                    pw.Container(
                      alignment: pw.Alignment.center,
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text(
                        deviationText,
                        style: pw.TextStyle(
                          fontSize: 8,
                          font: persianFont,
                          color: deviationColor,
                          fontWeight: pw.FontWeight.bold,
                        ),
                        textDirection: pw.TextDirection.rtl,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ],
          ),
        ],
      ),
    );
  }

  /// ساخت جدول جزئیات باطله
  static pw.Widget _buildTailingDetailsTable(
    List<PdfTailingData> tailingData,
    pw.Font persianFont,
    pw.Font persianBoldFont,
  ) {
    return pw.Container(
      margin: const pw.EdgeInsets.all(10),
      child: pw.Column(
        children: [
          pw.Text(
            'جدول جزئیات باطله تولیدی',
            style: pw.TextStyle(
              fontSize: 14,
              font: persianBoldFont,
              fontWeight: pw.FontWeight.bold,
            ),
            textAlign: pw.TextAlign.center,
            textDirection: pw.TextDirection.rtl,
          ),
          pw.SizedBox(height: 12),
          pw.Table(
            border: pw.TableBorder.all(),
            columnWidths: {
              0: const pw.FlexColumnWidth(1.2), // تاریخ/بازه
              1: const pw.FlexColumnWidth(0.8), // شیفت
              2: const pw.FlexColumnWidth(1.3), // باطله محقق شده
              3: const pw.FlexColumnWidth(1.3), // باطله برنامه‌ریزی شده
              4: const pw.FlexColumnWidth(1.0), // انحراف از برنامه
            },
            children: [
              // هدر جدول
              pw.TableRow(
                decoration: pw.BoxDecoration(color: PdfColors.grey300),
                children: [
                  _buildHeaderCell('تاریخ/بازه', persianBoldFont),
                  _buildHeaderCell('شیفت', persianBoldFont),
                  _buildHeaderCell('باطله محقق شده (تن)', persianBoldFont),
                  _buildHeaderCell(
                      'باطله برنامه‌ریزی شده (تن)', persianBoldFont),
                  _buildHeaderCell('انحراف از برنامه', persianBoldFont),
                ],
              ),
              // ردیف‌های داده
              ...tailingData.map((data) {
                final deviation = data.plannedTailing > 0
                    ? ((data.actualTailing - data.plannedTailing) /
                            data.plannedTailing) *
                        100
                    : 0.0;
                final deviationText =
                    '${deviation >= 0 ? '+' : ''}${deviation.toStringAsFixed(1)}%';
                final deviationColor =
                    deviation >= 0 ? PdfColors.green : PdfColors.red;

                return pw.TableRow(
                  children: [
                    _buildCell(data.label, persianFont),
                    _buildCell(data.shift, persianFont),
                    _buildCell(_formatNumber(data.actualTailing), persianFont),
                    _buildCell(_formatNumber(data.plannedTailing), persianFont),
                    pw.Container(
                      alignment: pw.Alignment.center,
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text(
                        deviationText,
                        style: pw.TextStyle(
                          fontSize: 8,
                          font: persianFont,
                          color: deviationColor,
                          fontWeight: pw.FontWeight.bold,
                        ),
                        textDirection: pw.TextDirection.rtl,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ],
          ),
        ],
      ),
    );
  }

  /// ساخت جدول خلاصه توقفات
  static pw.Widget _buildStopsSummaryTable(
    int totalActualStops,
    int totalPlannedStops,
    double deviationPercentage,
    pw.Font persianFont,
    pw.Font persianBoldFont,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'خلاصه آمار توقفات',
            style: pw.TextStyle(
              fontSize: 12,
              font: persianBoldFont,
              fontWeight: pw.FontWeight.bold,
            ),
            textDirection: pw.TextDirection.rtl,
          ),
          pw.SizedBox(height: 8),
          pw.Table(
            columnWidths: {
              0: const pw.FlexColumnWidth(1.5), // عنوان
              1: const pw.FlexColumnWidth(1.0), // مقدار
            },
            children: [
              _buildSummaryRow(
                  'کل توقفات واقعی',
                  _formatDuration(totalActualStops),
                  persianFont,
                  persianBoldFont),
              _buildSummaryRow(
                  'کل توقفات برنامه',
                  _formatDuration(totalPlannedStops),
                  persianFont,
                  persianBoldFont),
              _buildSummaryRow(
                  'انحراف کل',
                  '${deviationPercentage.toStringAsFixed(1)}%',
                  persianFont,
                  persianBoldFont),
            ],
          ),
        ],
      ),
    );
  }

  /// ساخت جدول توزیع توقفات
  static pw.Widget _buildStopsPieChart(
    Map<String, int> stopsByTypeDuration,
    int totalActualStops,
    pw.Font persianFont,
    pw.Font persianBoldFont,
  ) {
    if (stopsByTypeDuration.isEmpty) {
      return pw.Container(
        padding: const pw.EdgeInsets.all(20),
        child: pw.Text(
          'داده‌ای برای نمایش وجود ندارد',
          style: pw.TextStyle(fontSize: 12, font: persianFont),
          textDirection: pw.TextDirection.rtl,
        ),
      );
    }

    final chartData = stopsByTypeDuration.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return pw.Container(
      margin: const pw.EdgeInsets.all(10),
      child: pw.Column(
        children: [
          pw.Text(
            'توزیع انواع توقف',
            style: pw.TextStyle(
              fontSize: 14,
              font: persianBoldFont,
              fontWeight: pw.FontWeight.bold,
            ),
            textAlign: pw.TextAlign.center,
            textDirection: pw.TextDirection.rtl,
          ),
          pw.SizedBox(height: 12),
          pw.Table(
            border: pw.TableBorder.all(),
            columnWidths: {
              0: const pw.FlexColumnWidth(1.5), // نوع توقف
              1: const pw.FlexColumnWidth(1.0), // مدت
              2: const pw.FlexColumnWidth(1.0), // درصد
            },
            children: [
              // هدر جدول
              pw.TableRow(
                decoration: pw.BoxDecoration(color: PdfColors.grey300),
                children: [
                  _buildHeaderCell('نوع توقف', persianBoldFont),
                  _buildHeaderCell('مدت (ساعت)', persianBoldFont),
                  _buildHeaderCell('درصد', persianBoldFont),
                ],
              ),
              // ردیف‌های داده
              ...chartData.map((entry) {
                final percentage = (entry.value / totalActualStops * 100);
                final hours = entry.value / 60.0;
                return pw.TableRow(
                  children: [
                    _buildCell(entry.key, persianFont),
                    _buildCell(hours.toStringAsFixed(1), persianFont),
                    _buildCell(
                        '${percentage.toStringAsFixed(1)}%', persianFont),
                  ],
                );
              }).toList(),
            ],
          ),
        ],
      ),
    );
  }

  /// ساخت جدول جزئیات توقفات
  static pw.Widget _buildStopsDetailsTable(
    List<ProductionData> stopData,
    pw.Font persianFont,
    pw.Font persianBoldFont,
  ) {
    return pw.Container(
      margin: const pw.EdgeInsets.all(10),
      child: pw.Column(
        children: [
          pw.Text(
            'جدول جزئیات توقفات',
            style: pw.TextStyle(
              fontSize: 14,
              font: persianBoldFont,
              fontWeight: pw.FontWeight.bold,
            ),
            textAlign: pw.TextAlign.center,
            textDirection: pw.TextDirection.rtl,
          ),
          pw.SizedBox(height: 12),
          pw.Table(
            border: pw.TableBorder.all(),
            columnWidths: {
              0: const pw.FlexColumnWidth(1.0), // تاریخ
              1: const pw.FlexColumnWidth(0.6), // شیفت
              2: const pw.FlexColumnWidth(1.2), // تجهیز
              3: const pw.FlexColumnWidth(1.0), // نوع توقف
              4: const pw.FlexColumnWidth(0.8), // مدت توقف
            },
            children: [
              // هدر جدول
              pw.TableRow(
                decoration: pw.BoxDecoration(color: PdfColors.grey300),
                children: [
                  _buildHeaderCell('تاریخ', persianBoldFont),
                  _buildHeaderCell('شیفت', persianBoldFont),
                  _buildHeaderCell('تجهیز', persianBoldFont),
                  _buildHeaderCell('نوع توقف', persianBoldFont),
                  _buildHeaderCell('مدت توقف', persianBoldFont),
                ],
              ),
              // ردیف‌های داده
              ...stopData.map((data) {
                return pw.TableRow(
                  children: [
                    _buildCell(data.fullShamsiDate, persianFont),
                    _buildCell('شیفت ${data.shift}', persianFont),
                    _buildCell(data.equipmentName, persianFont),
                    _buildCell(data.stopType, persianFont),
                    _buildCell(
                        _formatDuration(data.stopDurationMinutes), persianFont),
                  ],
                );
              }).toList(),
            ],
          ),
        ],
      ),
    );
  }

  /// ساخت جدول جزئیات توقفات (نسخه جدید با StopData)
  static pw.Widget _buildStopsDetailsTableFromStopData(
    List<StopData> stopData,
    pw.Font persianFont,
    pw.Font persianBoldFont,
  ) {
    return pw.Container(
      margin: const pw.EdgeInsets.all(10),
      child: pw.Column(
        children: [
          pw.Text(
            'جدول جزئیات توقفات',
            style: pw.TextStyle(
              fontSize: 14,
              font: persianBoldFont,
              fontWeight: pw.FontWeight.bold,
            ),
            textAlign: pw.TextAlign.center,
            textDirection: pw.TextDirection.rtl,
          ),
          pw.SizedBox(height: 12),
          pw.Table(
            border: pw.TableBorder.all(),
            columnWidths: {
              0: const pw.FlexColumnWidth(1.0), // تاریخ
              1: const pw.FlexColumnWidth(0.6), // شیفت
              2: const pw.FlexColumnWidth(1.2), // تجهیز
              3: const pw.FlexColumnWidth(1.0), // نوع توقف
              4: const pw.FlexColumnWidth(0.8), // مدت توقف
            },
            children: [
              // هدر جدول
              pw.TableRow(
                decoration: pw.BoxDecoration(color: PdfColors.grey300),
                children: [
                  _buildHeaderCell('تاریخ', persianBoldFont),
                  _buildHeaderCell('شیفت', persianBoldFont),
                  _buildHeaderCell('تجهیز', persianBoldFont),
                  _buildHeaderCell('نوع توقف', persianBoldFont),
                  _buildHeaderCell('مدت توقف', persianBoldFont),
                ],
              ),
              // ردیف‌های داده
              ...stopData.map((data) {
                return pw.TableRow(
                  children: [
                    _buildCell(
                        '${data.year}/${data.month.toString().padLeft(2, '0')}/${data.day.toString().padLeft(2, '0')}',
                        persianFont),
                    _buildCell('شیفت ${data.shift}', persianFont),
                    _buildCell(data.equipment, persianFont),
                    _buildCell(data.stopType, persianFont),
                    _buildCell(_formatDuration(data.stopDuration.toInt()),
                        persianFont),
                  ],
                );
              }).toList(),
            ],
          ),
        ],
      ),
    );
  }

  /// تبدیل دقیقه به فرمت ساعت:دقیقه
  static String _formatDuration(int minutes) {
    if (minutes == 0) return '00:00';

    int hours = minutes ~/ 60;
    int mins = minutes % 60;

    return '${hours.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')}';
  }

  /// دریافت رنگ برای نوع توقف
  static PdfColor _getStopTypeColor(String stopType) {
    // تبدیل رنگ‌های Flutter به PDF
    switch (stopType) {
      case 'برنامه ای':
        return PdfColors.blue;
      case 'مکانیکی':
        return PdfColors.red;
      case 'برقی':
        return PdfColors.orange;
      case 'تاسیساتی':
        return PdfColors.purple;
      case 'بهره برداری':
        return PdfColors.green;
      case 'معدنی':
        return PdfColors.brown;
      case 'عمومی':
        return PdfColors.grey;
      case 'مجاز':
        return PdfColors.cyan;
      case 'بارگیری':
        return PdfColors.pink;
      default:
        return PdfColors.black;
    }
  }
}
