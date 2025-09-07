import 'package:hive/hive.dart';
import '../models/stop_data.dart';
import '../models/production_data.dart';

class EquipmentMigrationService {
  // Map کد تجهیزات به نام کامل - حذف شده چون باید از دیتابیس استفاده شود
  static const Map<String, String> equipmentCodeToName = {};

  /// مهاجرت رکوردهای موجود و اضافه کردن نام تجهیزات
  static Future<void> migrateEquipmentNames() async {
    try {
      print('=== شروع مهاجرت نام تجهیزات ===');

      final stopBox = await Hive.openBox<StopData>('stopData');
      final productionBox =
          await Hive.openBox<ProductionData>('productionData');

      int updatedCount = 0;
      int totalCount = stopBox.length;

      print('تعداد کل رکوردهای توقف: $totalCount');

      // دریافت نام‌های تجهیزات از دیتابیس
      final equipmentNames = await getAllEquipmentNames();
      print('تعداد نام‌های تجهیزات یافت شده: ${equipmentNames.length}');

      // مهاجرت رکوردهای توقف
      for (int i = 0; i < stopBox.length; i++) {
        final stopData = stopBox.getAt(i);
        if (stopData != null && stopData.equipmentName == null) {
          // استفاده از نام تجهیز از دیتابیس
          String? equipmentName = equipmentNames[stopData.equipment];

          // اگر در map نبود، خود کد را استفاده کن
          if (equipmentName == null) {
            equipmentName = stopData.equipment;
          }

          if (equipmentName != null && equipmentName.isNotEmpty) {
            // ایجاد رکورد جدید با نام تجهیز
            final updatedStopData = StopData(
              year: stopData.year,
              month: stopData.month,
              day: stopData.day,
              shift: stopData.shift,
              equipment: stopData.equipment,
              stopType: stopData.stopType,
              stopDuration: stopData.stopDuration,
              equipmentName: equipmentName,
            );

            // جایگزینی رکورد
            await stopBox.putAt(i, updatedStopData);
            updatedCount++;

            if (updatedCount % 10 == 0) {
              print('پیشرفت: $updatedCount/$totalCount');
            }
          }
        }
      }

      print('=== مهاجرت تکمیل شد ===');
      print('تعداد رکوردهای به‌روزرسانی شده: $updatedCount');
      print('تعداد کل رکوردها: $totalCount');

      // نمایش نمونه‌ای از رکوردهای به‌روزرسانی شده
      final sampleRecords = stopBox.values.take(5).toList();
      for (var record in sampleRecords) {
        print(
            'نمونه: ${record.equipment} -> ${record.equipmentName ?? "نام موجود نیست"}');
      }
    } catch (e) {
      print('خطا در مهاجرت: $e');
    }
  }

  /// دریافت نام تجهیز از ProductionData
  static Future<String?> _getEquipmentNameFromProduction(
      String equipmentCode) async {
    try {
      final productionBox =
          await Hive.openBox<ProductionData>('productionData');

      // جستجو در ProductionData برای یافتن نام تجهیز
      for (var productionData in productionBox.values) {
        if (productionData.equipmentName == equipmentCode &&
            productionData.equipmentName.isNotEmpty) {
          return productionData.equipmentName;
        }
      }

      // اگر در ProductionData پیدا نشد، خود کد را برگردان
      return equipmentCode.isNotEmpty ? equipmentCode : null;
    } catch (e) {
      print('خطا در دریافت نام تجهیز: $e');
      return equipmentCode.isNotEmpty ? equipmentCode : null;
    }
  }

  /// دریافت تمام نام‌های تجهیزات از دیتابیس
  static Future<Map<String, String>> getAllEquipmentNames() async {
    try {
      final productionBox =
          await Hive.openBox<ProductionData>('productionData');
      final stopBox = await Hive.openBox<StopData>('stopData');

      Map<String, String> equipmentNames = {};

      // از ProductionData
      for (var productionData in productionBox.values) {
        if (productionData.equipmentName.isNotEmpty) {
          equipmentNames[productionData.equipmentName] =
              productionData.equipmentName;
        }
      }

      // از StopData (اگر equipmentName موجود باشد)
      for (var stopData in stopBox.values) {
        if (stopData.equipmentName != null &&
            stopData.equipmentName!.isNotEmpty) {
          equipmentNames[stopData.equipment] = stopData.equipmentName!;
        }
      }

      print('نام‌های تجهیزات یافت شده: $equipmentNames');
      return equipmentNames;
    } catch (e) {
      print('خطا در دریافت نام‌های تجهیزات: $e');
      return {};
    }
  }

  /// بررسی وضعیت مهاجرت
  static Future<void> checkMigrationStatus() async {
    try {
      final stopBox = await Hive.openBox<StopData>('stopData');

      int totalRecords = stopBox.length;
      int recordsWithName = 0;
      int recordsWithoutName = 0;

      for (var record in stopBox.values) {
        if (record.equipmentName != null && record.equipmentName!.isNotEmpty) {
          recordsWithName++;
        } else {
          recordsWithoutName++;
        }
      }

      print('=== وضعیت مهاجرت ===');
      print('کل رکوردها: $totalRecords');
      print('رکوردهای با نام: $recordsWithName');
      print('رکوردهای بدون نام: $recordsWithoutName');
      print(
          'درصد تکمیل: ${((recordsWithName / totalRecords) * 100).toStringAsFixed(1)}%');

      // نمایش نمونه‌هایی از رکوردهای با نام
      final sampleRecords = stopBox.values
          .where((r) => r.equipmentName != null && r.equipmentName!.isNotEmpty)
          .take(5)
          .toList();

      print('نمونه رکوردهای با نام:');
      for (var record in sampleRecords) {
        print('  ${record.equipment} -> ${record.equipmentName}');
      }
    } catch (e) {
      print('خطا در بررسی وضعیت: $e');
    }
  }

  /// پاک کردن نام‌های تجهیزات (برای تست)
  static Future<void> clearEquipmentNames() async {
    try {
      final stopBox = await Hive.openBox<StopData>('stopData');

      int clearedCount = 0;

      for (int i = 0; i < stopBox.length; i++) {
        final stopData = stopBox.getAt(i);
        if (stopData != null && stopData.equipmentName != null) {
          final updatedStopData = StopData(
            year: stopData.year,
            month: stopData.month,
            day: stopData.day,
            shift: stopData.shift,
            equipment: stopData.equipment,
            stopType: stopData.stopType,
            stopDuration: stopData.stopDuration,
            equipmentName: null,
          );

          await stopBox.putAt(i, updatedStopData);
          clearedCount++;
        }
      }

      print('تعداد رکوردهای پاک شده: $clearedCount');
    } catch (e) {
      print('خطا در پاک کردن: $e');
    }
  }

  /// بررسی نتیجه مهاجرت
  static Future<void> checkMigrationResult() async {
    try {
      final stopBox = await Hive.openBox<StopData>('stopData');
      final productionBox =
          await Hive.openBox<ProductionData>('productionData');

      print('=== بررسی نتیجه مهاجرت ===');

      // بررسی StopData
      int stopRecordsWithName = 0;
      int stopRecordsWithoutName = 0;
      Set<String> stopEquipmentNames = {};

      for (var record in stopBox.values) {
        if (record.equipmentName != null && record.equipmentName!.isNotEmpty) {
          stopRecordsWithName++;
          stopEquipmentNames.add(record.equipmentName!);
        } else {
          stopRecordsWithoutName++;
        }
      }

      print('StopData:');
      print('  رکوردهای با نام: $stopRecordsWithName');
      print('  رکوردهای بدون نام: $stopRecordsWithoutName');
      print('  نام‌های منحصر به فرد: ${stopEquipmentNames.length}');

      // بررسی ProductionData
      Set<String> productionEquipmentNames = {};
      for (var record in productionBox.values) {
        if (record.equipmentName.isNotEmpty) {
          productionEquipmentNames.add(record.equipmentName);
        }
      }

      print('ProductionData:');
      print('  نام‌های منحصر به فرد: ${productionEquipmentNames.length}');

      // نمایش نمونه‌هایی از نام‌های StopData
      print('نمونه نام‌های StopData:');
      final sampleStopNames = stopEquipmentNames.take(10).toList();
      for (var name in sampleStopNames) {
        print('  - $name');
      }

      // نمایش نمونه‌هایی از نام‌های ProductionData
      print('نمونه نام‌های ProductionData:');
      final sampleProductionNames = productionEquipmentNames.take(10).toList();
      for (var name in sampleProductionNames) {
        print('  - $name');
      }
    } catch (e) {
      print('خطا در بررسی نتیجه مهاجرت: $e');
    }
  }
}
