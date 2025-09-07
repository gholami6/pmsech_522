import 'package:shamsi_date/shamsi_date.dart';

class DateService {
  static String formatDate(int year, int month) {
    try {
      final gregorian = DateTime(year, month);
      final jalali = Jalali.fromDateTime(gregorian);
      return '${jalali.year}/${jalali.month.toString().padLeft(2, '0')}';
    } catch (e) {
      return '$year/$month';
    }
  }

  static String formatFullDate(DateTime date) {
    try {
      final jalali = Jalali.fromDateTime(date);
      return '${jalali.year}/${jalali.month.toString().padLeft(2, '0')}/${jalali.day.toString().padLeft(2, '0')}';
    } catch (e) {
      return '${date.year}/${date.month}/${date.day}';
    }
  }

  static String formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  static DateTime? parseJalaliDate(String date) {
    try {
      final parts = date.split('/');
      if (parts.length != 3) return null;

      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final day = int.parse(parts[2]);

      final jalali = Jalali(year, month, day);
      return jalali.toDateTime();
    } catch (e) {
      return null;
    }
  }

  static String getCurrentShamsiDate() {
    final now = DateTime.now();
    final jalali = Jalali.fromDateTime(now);
    return '${jalali.year}/${jalali.month.toString().padLeft(2, '0')}/${jalali.day.toString().padLeft(2, '0')}';
  }

  static String getShamsiDate(DateTime date) {
    final jalali = Jalali.fromDateTime(date);
    return '${jalali.year}/${jalali.month.toString().padLeft(2, '0')}/${jalali.day.toString().padLeft(2, '0')}';
  }
}
