/// سرویس محاسبات برنامه‌ریزی مشترک
///
/// این سرویس برای محاسبه برنامه‌ریزی در تمام صفحات استفاده می‌شود
/// فرمول‌های صحیح:
/// - برنامه روزانه = برنامه ماهانه ÷ تعداد روزهای ماه
/// - برنامه هفتگی = برنامه روزانه × 7 روز
/// - برنامه ماهانه = برنامه ماهانه کامل
/// - برنامه شیفتی = برنامه روزانه ÷ 3
class PlanningCalculationService {
  /// داده‌های برنامه سالانه 1404 (خوراک - تن)
  static const List<double> annualPlanData = [
    223398, // فروردین
    260568, // اردیبهشت
    260568, // خرداد
    232248, // تیر
    260568, // مرداد
    189768, // شهریور
    250564, // مهر
    250564, // آبان
    250564, // آذر
    242894, // دی
    242894, // بهمن
    121380 // اسفند
  ];

  /// داده‌های برنامه سالانه 1404 (محصول - تن)
  static const List<double> annualProductPlanData = [
    160400, // فروردین
    187088, // اردیبهشت
    187088, // خرداد
    166754, // تیر
    187088, // مرداد
    136254, // شهریور
    179905, // مهر
    179905, // آبان
    179905, // آذر
    174398, // دی
    174398, // بهمن
    87151 // اسفند
  ];

  /// دریافت برنامه ماهانه برای تاریخ مشخص
  static double getMonthlyPlan(DateTime date) {
    // تبدیل تاریخ میلادی به شمسی
    final persianYear = date.year - 621;
    final persianMonth = date.month > 6 ? date.month - 6 : date.month + 6;

    // اگر سال 1404 باشد، از برنامه سالانه استفاده کن
    if (persianYear == 1404 && persianMonth >= 1 && persianMonth <= 12) {
      return annualPlanData[persianMonth - 1];
    }

    // برای سال‌های دیگر، از میانگین استفاده کن
    return annualPlanData.reduce((a, b) => a + b) / annualPlanData.length;
  }

  /// محاسبه برنامه روزانه
  static double getDailyPlan(DateTime date) {
    final monthlyPlan = getMonthlyPlan(date);
    final daysInMonth = DateTime(date.year, date.month + 1, 0).day;
    return monthlyPlan / daysInMonth;
  }

  /// محاسبه برنامه هفتگی
  static double getWeeklyPlan(DateTime date) {
    final dailyPlan = getDailyPlan(date);
    return dailyPlan * 7;
  }

  /// محاسبه برنامه ماهانه
  static double getMonthlyPlanForDate(DateTime date) {
    return getMonthlyPlan(date);
  }

  /// محاسبه برنامه شیفتی
  static double getShiftPlan(DateTime date) {
    final dailyPlan = getDailyPlan(date);
    return dailyPlan / 3;
  }

  /// محاسبه برنامه بر اساس نوع بازه
  static double getPlanByTimeRange(DateTime date, String timeRange) {
    switch (timeRange) {
      case 'روزانه':
        return getDailyPlan(date);
      case 'هفتگی':
        return getWeeklyPlan(date);
      case 'ماهانه':
        return getMonthlyPlanForDate(date);
      case 'شیفتی':
        return getShiftPlan(date);
      default:
        return getDailyPlan(date);
    }
  }

  /// محاسبه برنامه محصول بر اساس نوع بازه
  static double getProductPlanByTimeRange(DateTime date, String timeRange) {
    // برای محصول، از همان منطق خوراک استفاده می‌کنیم
    // چون برنامه سالانه برای کل تولید (خوراک + محصول) است
    return getPlanByTimeRange(date, timeRange);
  }

  /// محاسبه ضریب شیفت
  static double getShiftMultiplier(String shift) {
    switch (shift) {
      case 'شیفت 1':
        return 0.33;
      case 'شیفت 2':
        return 0.33;
      case 'شیفت 3':
        return 0.34;
      default:
        return 1.0;
    }
  }

  /// تبدیل نام شیفت به شماره
  static int getShiftNumber(String shiftName) {
    switch (shiftName) {
      case 'شیفت 1':
        return 1;
      case 'شیفت 2':
        return 2;
      case 'شیفت 3':
        return 3;
      default:
        return 0;
    }
  }

  /// تبدیل شماره شیفت به نام
  static String getShiftName(int shift) {
    switch (shift) {
      case 1:
        return 'شیفت 1';
      case 2:
        return 'شیفت 2';
      case 3:
        return 'شیفت 3';
      default:
        return 'نامشخص';
    }
  }

  /// دریافت برنامه ماهانه محصول برای ماه مشخص
  static double getMonthlyProductPlan(int month) {
    // تبدیل ماه میلادی به شمسی
    final persianMonth = month > 6 ? month - 6 : month + 6;

    // اگر ماه معتبر باشد، از برنامه سالانه محصول استفاده کن
    if (persianMonth >= 1 && persianMonth <= 12) {
      return annualProductPlanData[persianMonth - 1];
    }

    // برای ماه‌های نامعتبر، از میانگین استفاده کن
    return annualProductPlanData.reduce((a, b) => a + b) /
        annualProductPlanData.length;
  }
}
