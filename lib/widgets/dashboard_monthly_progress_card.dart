import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';
import '../config/dashboard_design_tokens.dart';
import '../providers/data_provider.dart';

/// Monthly Product Progress Card with new design specifications
class DashboardMonthlyProgressCard extends StatelessWidget {
  const DashboardMonthlyProgressCard({super.key});

  String _getCurrentJalaliMonth() {
    try {
      final now = DateTime.now();
      final jalali = Jalali.fromDateTime(now);
      final monthNames = [
        'فروردین',
        'اردیبهشت',
        'خرداد',
        'تیر',
        'مرداد',
        'شهریور',
        'مهر',
        'آبان',
        'آذر',
        'دی',
        'بهمن',
        'اسفند'
      ];
      return monthNames[jalali.month - 1];
    } catch (e) {
      return 'نامشخص';
    }
  }

  String _getCurrentJalaliDate() {
    try {
      final now = DateTime.now();
      final jalali = Jalali.fromDateTime(now);
      return '${jalali.year}/${jalali.month.toString().padLeft(2, '0')}/${jalali.day.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'نامشخص';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DataProvider>(
      builder: (context, dataProvider, child) {
        // Calculate progress data (placeholder for now)
        final programPercent = 83; // Replace with actual calculation
        final actualPercent = 0; // Replace with actual calculation
        final targetDate = _getCurrentJalaliDate();
        final monthName = _getCurrentJalaliMonth();

        return Container(
          decoration: BoxDecoration(
            color: DashboardDesignTokens.colorSurface,
            borderRadius:
                BorderRadius.circular(DashboardDesignTokens.cardRadius),
            boxShadow: DashboardDesignTokens.cardShadow,
          ),
          child: Padding(
            padding:
                const EdgeInsets.all(DashboardDesignTokens.cardPaddingLarge),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  'پیشرفت ماهانه محصول – $monthName',
                  style: DashboardDesignTokens.titleStyle,
                ),
                const SizedBox(height: DashboardDesignTokens.gapMedium),

                // Progress Bar
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Progress track
                    Container(
                      height: DashboardDesignTokens.progressBarHeight,
                      decoration: BoxDecoration(
                        color: DashboardDesignTokens.colorTrack,
                        borderRadius: BorderRadius.circular(
                            DashboardDesignTokens.progressBarHeight / 2),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerRight, // RTL alignment
                        widthFactor: programPercent / 100.0,
                        child: Container(
                          decoration: BoxDecoration(
                            color: DashboardDesignTokens.colorAccentGreen,
                            borderRadius: BorderRadius.circular(
                                DashboardDesignTokens.progressBarHeight / 2),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: DashboardDesignTokens.gapMedium),
                  ],
                ),

                // Data rows (RTL, right-aligned numbers)
                _buildDataRow('برنامه:', '$programPercent%', true),
                const SizedBox(height: DashboardDesignTokens.gapSmall),
                _buildDataRow('واقعی:', '$actualPercent%', actualPercent == 0),

                const SizedBox(height: DashboardDesignTokens.gapMedium),

                // Divider
                Container(
                  height: 1,
                  color: DashboardDesignTokens.colorBorder,
                ),

                const SizedBox(height: DashboardDesignTokens.gapMedium),

                // Meta row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'هدف ماهانه',
                      style: DashboardDesignTokens.labelStyle.copyWith(
                        color: DashboardDesignTokens.colorTextSecondary,
                      ),
                    ),
                    Text(
                      targetDate,
                      style: DashboardDesignTokens.labelStyle.copyWith(
                        color: DashboardDesignTokens.colorTextSecondary,
                      ),
                      textDirection: TextDirection.ltr,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDataRow(String label, String value, bool isBold) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: DashboardDesignTokens.subtitleStyle.copyWith(
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
        Text(
          value,
          style: DashboardDesignTokens.subtitleStyle.copyWith(
            fontWeight: FontWeight.w700,
            color: value == '0%'
                ? DashboardDesignTokens.colorTextSecondary
                : DashboardDesignTokens.colorTextPrimary,
          ),
          textDirection: TextDirection.ltr,
        ),
      ],
    );
  }
}
