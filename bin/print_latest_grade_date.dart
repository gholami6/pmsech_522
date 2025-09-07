import 'package:hive/hive.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';
import '../lib/models/grade_data.dart';
import 'dart:io';

Future<void> main() async {
  Hive.init(Directory.current.path);
  Hive.registerAdapter(GradeDataAdapter());
  final box = await Hive.openBox<GradeData>('gradeData');
  final allData = box.values.toList();

  if (allData.isEmpty) {
    print('هیچ داده عیاری در دیتابیس وجود ندارد!');
    return;
  }

  // مرتب‌سازی بر اساس تاریخ شمسی
  allData.sort((a, b) {
    final dateA = Jalali(a.year, a.month, a.day);
    final dateB = Jalali(b.year, b.month, b.day);
    return dateB.compareTo(dateA); // نزولی
  });

  final latest = allData.first;
  print(
      'آخرین تاریخ ثبت شده عیار: ${latest.year}/${latest.month}/${latest.day} (نوع: ${latest.gradeType})');
}
