import 'dart:io';
import 'package:hive/hive.dart';
import 'lib/models/stop_data.dart';

void main() async {
  try {
    // راه‌اندازی Hive
    final appDocumentDir = Directory.current;
    Hive.init(appDocumentDir.path);
    Hive.registerAdapter(StopDataAdapter());

    // باز کردن دیتابیس
    final stopBox = await Hive.openBox<StopData>('stopData');

    print('=== بررسی 10 ردیف اول ستون equipmentName ===');
    print('کل رکوردها: ${stopBox.length}');

    if (stopBox.isEmpty) {
      print('دیتابیس خالی است!');
      return;
    }

    int count = 0;
    for (var stopData in stopBox.values) {
      if (count < 10) {
        print('ردیف ${count + 1}:');
        print('  equipmentName = "${stopData.equipmentName}"');
        print('  equipment = "${stopData.equipment}"');
        print('  stopType = "${stopData.stopType}"');
        print(
            '  year = ${stopData.year}, month = ${stopData.month}, day = ${stopData.day}');
        print('  shift = "${stopData.shift}"');
        print('  stopDuration = ${stopData.stopDuration}');
        print('  ---');
        count++;
      } else {
        break;
      }
    }

    print('==========================================');

    await stopBox.close();
  } catch (e) {
    print('خطا: $e');
  }
}
