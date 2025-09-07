import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/production_data.dart';
import '../models/stop_data.dart';
import '../models/shift_info.dart';
import '../services/production_analysis_service.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class DataSyncService extends ChangeNotifier {
  // آدرس API جدید
  static const String _baseUrl = 'http://62.60.198.11/simple_xlsx_to_json.php';

  // نام‌های Box برای Hive
  static const String _syncMetaBoxName = 'syncMeta';
  static const String _productionBoxName = 'productionData';
  static const String _stopBoxName = 'stopData';
  static const String _shiftInfoBoxName = 'shiftInfo';
  static const String _lastSyncKey = 'last_updated';
  static const String _lastSyncErrorKey = 'last_sync_error';
  static const String _lastDataHashKey = 'last_data_hash';
  static const String _lastSyncStatsKey = 'last_sync_stats';

  // Box‌های Hive
  late Box<ProductionData> _productionBox;
  late Box<StopData> _stopBox;
  late Box<ShiftInfo> _shiftInfoBox;
  late Box<String> _syncMetaBox;

  bool _isSyncing = false;
  int _retryCount = 0;
  static const int _maxRetries = 3;

  bool get isSyncing => _isSyncing;

  Future<void> init() async {
    try {
      _productionBox = await Hive.openBox<ProductionData>(_productionBoxName);
      _stopBox = await Hive.openBox<StopData>(_stopBoxName);
      _shiftInfoBox = await Hive.openBox<ShiftInfo>(_shiftInfoBoxName);
      _syncMetaBox = await Hive.openBox<String>(_syncMetaBoxName);
      notifyListeners();
    } catch (e) {
      print('خطا در راه‌اندازی DataSyncService: $e');
      rethrow;
    }
  }

  Future<bool> _checkInternetConnection() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      return connectivityResult != ConnectivityResult.none;
    } catch (e) {
      print('خطا در بررسی اتصال اینترنت: $e');
      return false;
    }
  }

  Future<void> _updateLastSyncTime() async {
    try {
      await _syncMetaBox.put(_lastSyncKey, DateTime.now().toIso8601String());
    } catch (e) {
      print('خطا در ذخیره زمان همگام‌سازی: $e');
    }
  }

  Future<void> _updateLastSyncError(String? error) async {
    try {
      if (error != null) {
        await _syncMetaBox.put(_lastSyncErrorKey, error);
      } else {
        await _syncMetaBox.delete(_lastSyncErrorKey);
      }
    } catch (e) {
      print('خطا در ذخیره خطای همگام‌سازی: $e');
    }
  }

  String? getLastSyncError() {
    try {
      return _syncMetaBox.get(_lastSyncErrorKey);
    } catch (e) {
      print('خطا در دریافت خطای همگام‌سازی: $e');
      return null;
    }
  }

  DateTime? getLastSyncTime() {
    try {
      final timeStr = _syncMetaBox.get(_lastSyncKey);
      if (timeStr != null) {
        return DateTime.tryParse(timeStr);
      }
    } catch (e) {
      print('خطا در دریافت زمان همگام‌سازی: $e');
    }
    return null;
  }

  /// تجزیه تاریخ شمسی
  Map<String, int> _parseDate(String dateStr) {
    dateStr = dateStr.trim();
    try {
      final parts = dateStr.split('/');
      if (parts.length >= 3) {
        return {
          'year': int.parse(parts[0]),
          'month': int.parse(parts[1]),
          'day': int.parse(parts[2]),
        };
      }
    } catch (e) {
      print('خطا در تجزیه تاریخ: $dateStr - $e');
    }

    // مقدار پیش‌فرض
    final now = DateTime.now();
    return {
      'year': now.year,
      'month': now.month,
      'day': now.day,
    };
  }

  /// دریافت داده‌ها از API با retry logic
  Future<Map<String, dynamic>> _fetchDataFromAPI() async {
    for (int attempt = 1; attempt <= _maxRetries; attempt++) {
      try {
        print('تلاش $attempt از $_maxRetries برای دریافت داده‌ها...');

        // تنظیم timeout پویا بر اساس تلاش
        final timeoutSeconds = 30 + (attempt * 5);

        final response = await http.get(
          Uri.parse(_baseUrl),
          headers: {
            'Content-Type': 'application/json; charset=utf-8',
            'Accept': 'application/json',
            'Connection': 'keep-alive',
            'User-Agent': 'PMSech-App/1.0',
          },
        ).timeout(Duration(seconds: timeoutSeconds));

        if (response.statusCode == 200) {
          // فیلتر کردن خطاهای PHP و استخراج JSON
          String responseBody = response.body;

          // حذف خطاهای PHP Warning و HTML tags
          if (responseBody.contains('<br />') || responseBody.contains('<b>')) {
            // پیدا کردن شروع JSON (اولین { )
            int jsonStart = responseBody.indexOf('{');
            if (jsonStart != -1) {
              responseBody = responseBody.substring(jsonStart);
            }
          }

          final data = json.decode(responseBody);
          if (data['success'] == true) {
            print('داده‌ها با موفقیت دریافت شدند');
            return data;
          } else {
            throw Exception(data['error'] ?? 'خطای ناشناخته از سرور');
          }
        } else {
          throw Exception('خطای سرور: ${response.statusCode}');
        }
      } catch (e) {
        print('خطا در تلاش $attempt: $e');

        if (attempt == _maxRetries) {
          print('تمام تلاش‌ها ناموفق بود');
          rethrow;
        }

        // انتظار پیشرونده قبل از تلاش بعدی
        final delaySeconds = attempt * 3;
        print('انتظار $delaySeconds ثانیه قبل از تلاش بعدی...');
        await Future.delayed(Duration(seconds: delaySeconds));
      }
    }

    throw Exception('خطا در دریافت داده‌ها پس از $_maxRetries تلاش');
  }

  /// تبدیل داده‌های API به مدل ProductionData
  ProductionData _convertToProductionData(Map<String, dynamic> apiData) {
    // استفاده از فیلدهای جداگانه سال/ماه/روز در صورت وجود
    int year, month, day;

    if (apiData['year'] != null &&
        apiData['month'] != null &&
        apiData['day'] != null) {
      // استفاده از فیلدهای جداگانه (روش بهتر)
      year = apiData['year'];
      month = apiData['month'];
      day = apiData['day'];
    } else {
      // fallback به parsing تاریخ string
      final dateInfo = _parseDate(apiData['date']?.toString() ?? '');
      year = dateInfo['year']!;
      month = dateInfo['month']!;
      day = dateInfo['day']!;
    }

    return ProductionData(
      shamsiDate: apiData['date']?.toString() ?? '',
      year: year,
      month: month,
      day: day,
      shift: apiData['shift']?.toString() ?? '',
      stopDescription: '',
      equipmentName: apiData['equipment']?.toString() ?? '',
      equipmentCode1: apiData['equipment_code']?.toString(),
      equipmentCode2: null,
      subEquipment: apiData['sub_equipment']?.toString() ?? '',
      subEquipmentCode: apiData['sub_equipment_code']?.toString(),
      stopReason: '',
      stopType: '',
      stopStartTime: '',
      stopEndTime: '',
      stopDuration: '00:00',
      serviceCount: (apiData['service_count'] ?? 0).toInt(),
      inputTonnage: (apiData['input_tonnage'] ?? 0).toDouble(),
      scale3: (apiData['scale3'] ?? 0).toDouble(),
      scale4: (apiData['scale4'] ?? 0).toDouble(),
      scale5: (apiData['scale5'] ?? 0).toDouble(),
      group: (apiData['group'] ?? 1).toInt(),
      directFeed: (apiData['direct_feed'] ?? 1).toInt(),
    );
  }

  /// تبدیل داده‌های API به مدل StopData
  StopData _convertToStopData(Map<String, dynamic> apiData) {
    // استفاده از فیلدهای جداگانه سال/ماه/روز در صورت وجود
    int year, month, day;

    if (apiData['year'] != null &&
        apiData['month'] != null &&
        apiData['day'] != null) {
      // استفاده از فیلدهای جداگانه (روش بهتر)
      year = apiData['year'] as int;
      month = apiData['month'] as int;
      day = apiData['day'] as int;
    } else {
      // fallback به parsing تاریخ string
      final dateInfo = _parseDate(apiData['date']?.toString() ?? '');
      year = dateInfo['year']!;
      month = dateInfo['month']!;
      day = dateInfo['day']!;
    }

    return StopData(
      year: year,
      month: month,
      day: day,
      shift: apiData['shift']?.toString() ?? '',
      equipment: apiData['equipment'] as String,
      stopType: apiData['stop_type'] as String,
      stopDuration: (apiData['stop_duration'] as num).toDouble(),
    );
  }

  /// تبدیل داده‌های API به مدل ShiftInfo
  ShiftInfo _convertToShiftInfo(
      Map<String, dynamic> apiData, double production) {
    // استفاده از فیلدهای جداگانه سال/ماه/روز در صورت وجود
    int year, month;

    if (apiData['year'] != null && apiData['month'] != null) {
      // استفاده از فیلدهای جداگانه (روش بهتر)
      year = apiData['year'];
      month = apiData['month'];
    } else {
      // fallback به parsing تاریخ string
      final dateInfo = _parseDate(apiData['date']?.toString() ?? '');
      year = dateInfo['year']!;
      month = dateInfo['month']!;
    }

    return ShiftInfo(
      year: year,
      month: month,
      shift: apiData['shift']?.toString() ?? '',
      equipment: apiData['equipment']?.toString() ?? '',
      totalStopDuration: 0.0,
      totalProduction: production,
    );
  }

  /// تبدیل داده‌های تجهیزات API به ProductionData برای نمایش در لیست
  ProductionData _convertEquipmentToProductionData(
      Map<String, dynamic> equipData) {
    return ProductionData(
      shamsiDate: '1403/01/01',
      year: 1403,
      month: 1,
      day: 1,
      shift: '1',
      stopDescription: '',
      equipmentName: equipData['name']?.toString() ?? '',
      equipmentCode1: null,
      equipmentCode2: null,
      subEquipment: equipData['equipment']?.toString() ?? '',
      subEquipmentCode: null,
      stopReason: '',
      stopType: '',
      stopStartTime: '',
      stopEndTime: '',
      stopDuration: '00:00',
      serviceCount: 0,
      inputTonnage: 0,
      scale3: (equipData['total_downtime'] ?? 0).toDouble(),
      scale4: (equipData['efficiency'] ?? 0).toDouble(),
      scale5: (equipData['total_stops'] ?? 0).toDouble(),
      group: 1,
      directFeed: 1,
    );
  }

  /// محاسبه هش داده‌ها برای تشخیص تغییرات
  String _calculateDataHash(Map<String, dynamic> data) {
    final buffer = StringBuffer();

    // هش برای داده‌های تولید - بهبود شده
    if (data['production'] != null) {
      final productionList =
          List<Map<String, dynamic>>.from(data['production']);
      buffer.write('production:${productionList.length}');

      // اضافه کردن هش از چند رکورد اول و آخر برای تشخیص بهتر تغییرات
      if (productionList.isNotEmpty) {
        final firstItem = productionList.first;
        final lastItem = productionList.last;
        buffer
            .write(':first:${firstItem['date']}:${firstItem['input_tonnage']}');
        buffer.write(':last:${lastItem['date']}:${lastItem['input_tonnage']}');

        // اضافه کردن هش از رکورد میانی برای تشخیص بهتر
        if (productionList.length > 2) {
          final middleIndex = productionList.length ~/ 2;
          final middleItem = productionList[middleIndex];
          buffer.write(
              ':middle:${middleItem['date']}:${middleItem['input_tonnage']}');
        }
      }
    }

    // هش برای داده‌های توقف - بهبود شده
    if (data['stops'] != null) {
      final stopsList = List<Map<String, dynamic>>.from(data['stops']);
      buffer.write(':stops:${stopsList.length}');
      if (stopsList.isNotEmpty) {
        final firstItem = stopsList.first;
        final lastItem = stopsList.last;
        buffer.write(':first:${firstItem['date']}:${firstItem['duration']}');
        buffer.write(':last:${lastItem['date']}:${lastItem['duration']}');
      }
    }

    // هش برای داده‌های تجهیزات - بهبود شده
    if (data['equipment'] != null) {
      final equipmentList = List<Map<String, dynamic>>.from(data['equipment']);
      buffer.write(':equipment:${equipmentList.length}');
      if (equipmentList.isNotEmpty) {
        final firstItem = equipmentList.first;
        final lastItem = equipmentList.last;
        buffer.write(
            ':first:${firstItem['name']}:${firstItem['total_downtime']}');
        buffer.write(':last:${lastItem['name']}:${lastItem['total_downtime']}');
      }
    }

    return buffer.toString();
  }

  /// بررسی نیاز به دانلود داده‌های جدید - بهبود شده
  Future<Map<String, dynamic>> _checkForNewData(
      Map<String, dynamic> apiData) async {
    final currentHash = _calculateDataHash(apiData);
    final lastHash = _syncMetaBox.get(_lastDataHashKey);

    print('هش فعلی: $currentHash');
    print('هش قبلی: $lastHash');

    if (lastHash == null) {
      // اولین بار دانلود
      print('اولین بار دانلود - دانلود کامل');
      return {
        'needsFullSync': true,
        'newProductionCount': 0,
        'newStopsCount': 0,
        'newEquipmentCount': 0,
      };
    }

    if (currentHash == lastHash) {
      // هیچ تغییری وجود ندارد
      print('هیچ تغییری در داده‌ها وجود ندارد');
      return {
        'needsFullSync': false,
        'newProductionCount': 0,
        'newStopsCount': 0,
        'newEquipmentCount': 0,
      };
    }

    // تغییرات وجود دارد - بررسی نوع تغییر
    final currentProductionCount = apiData['production']?.length ?? 0;
    final currentStopsCount = apiData['stops']?.length ?? 0;
    final currentEquipmentCount = apiData['equipment']?.length ?? 0;

    final existingProductionCount =
        _productionBox.values.where((item) => item.inputTonnage > 0).length;
    final existingStopsCount = _stopBox.length;
    final existingEquipmentCount =
        _productionBox.values.where((item) => item.inputTonnage == 0).length;

    final newProductionCount = currentProductionCount - existingProductionCount;
    final newStopsCount = currentStopsCount - existingStopsCount;
    final newEquipmentCount = currentEquipmentCount - existingEquipmentCount;

    print('تغییرات شناسایی شد:');
    print(
        '- تولید موجود: $existingProductionCount، جدید: $currentProductionCount');
    print('- توقفات موجود: $existingStopsCount، جدید: $currentStopsCount');
    print(
        '- تجهیزات موجود: $existingEquipmentCount، جدید: $currentEquipmentCount');

    // اگر تغییرات زیاد باشد، دانلود کامل انجام دهیم
    final totalChanges = newProductionCount + newStopsCount + newEquipmentCount;
    final totalExisting =
        existingProductionCount + existingStopsCount + existingEquipmentCount;

    if (totalChanges > totalExisting * 0.3) {
      // اگر بیش از 30% تغییر داشته باشد
      print('تغییرات زیاد - دانلود کامل انجام می‌شود');
      return {
        'needsFullSync': true,
        'newProductionCount': 0,
        'newStopsCount': 0,
        'newEquipmentCount': 0,
      };
    }

    return {
      'needsFullSync': false,
      'newProductionCount': newProductionCount > 0 ? newProductionCount : 0,
      'newStopsCount': newStopsCount > 0 ? newStopsCount : 0,
      'newEquipmentCount': newEquipmentCount > 0 ? newEquipmentCount : 0,
      'currentHash': currentHash,
    };
  }

  /// دانلود تدریجی داده‌های جدید - بهینه‌سازی شده
  Future<void> _syncIncrementalData(
    Map<String, dynamic> apiData,
    Map<String, dynamic> syncInfo,
    void Function(double)? onProgress,
  ) async {
    final newProductionCount = syncInfo['newProductionCount'] as int;
    final newStopsCount = syncInfo['newStopsCount'] as int;
    final newEquipmentCount = syncInfo['newEquipmentCount'] as int;

    int processedItems = 0;
    final totalNewItems =
        newProductionCount + newStopsCount + newEquipmentCount;

    if (totalNewItems == 0) {
      print('هیچ داده جدیدی برای دانلود وجود ندارد');
      return;
    }

    print('شروع دانلود تدریجی $totalNewItems رکورد جدید...');

    // دانلود داده‌های تولید جدید - بهینه‌سازی شده
    if (newProductionCount > 0 && apiData['production'] != null) {
      final productionList =
          List<Map<String, dynamic>>.from(apiData['production']);
      final existingCount =
          _productionBox.values.where((item) => item.inputTonnage > 0).length;
      final newItems =
          productionList.skip(existingCount).take(newProductionCount);

      // پردازش دسته‌ای برای سرعت بیشتر
      final batchSize = 10;
      final batches = <List<Map<String, dynamic>>>[];

      for (int i = 0; i < newItems.length; i += batchSize) {
        final end =
            (i + batchSize < newItems.length) ? i + batchSize : newItems.length;
        batches.add(newItems.skip(i).take(end - i).toList());
      }

      for (int batchIndex = 0; batchIndex < batches.length; batchIndex++) {
        final batch = batches[batchIndex];

        // پردازش همزمان رکوردهای هر دسته
        await Future.wait(batch.map((item) async {
          try {
            final productionData = _convertToProductionData(item);
            await _productionBox.add(productionData);

            final shiftInfo = _convertToShiftInfo(
                item, item['input_tonnage']?.toDouble() ?? 0.0);
            await _shiftInfoBox.add(shiftInfo);

            processedItems++;
          } catch (e) {
            print('خطا در پردازش رکورد تولید جدید: $e');
          }
        }));

        if (onProgress != null) {
          onProgress(0.5 + (processedItems / totalNewItems) * 0.4);
        }
      }
    }

    // دانلود داده‌های توقف جدید - بهینه‌سازی شده
    if (newStopsCount > 0 && apiData['stops'] != null) {
      final stopsList = List<Map<String, dynamic>>.from(apiData['stops']);
      final existingCount = _stopBox.length;
      final newItems = stopsList.skip(existingCount).take(newStopsCount);

      // پردازش دسته‌ای
      final batchSize = 10;
      final batches = <List<Map<String, dynamic>>>[];

      for (int i = 0; i < newItems.length; i += batchSize) {
        final end =
            (i + batchSize < newItems.length) ? i + batchSize : newItems.length;
        batches.add(newItems.skip(i).take(end - i).toList());
      }

      for (int batchIndex = 0; batchIndex < batches.length; batchIndex++) {
        final batch = batches[batchIndex];

        await Future.wait(batch.map((item) async {
          try {
            final stopData = _convertToStopData(item);
            await _stopBox.add(stopData);
            processedItems++;
          } catch (e) {
            print('خطا در پردازش رکورد توقف جدید: $e');
          }
        }));

        if (onProgress != null) {
          onProgress(0.5 + (processedItems / totalNewItems) * 0.4);
        }
      }
    }

    // دانلود داده‌های تجهیزات جدید - بهینه‌سازی شده
    if (newEquipmentCount > 0 && apiData['equipment'] != null) {
      final equipmentList =
          List<Map<String, dynamic>>.from(apiData['equipment']);
      final existingCount =
          _productionBox.values.where((item) => item.inputTonnage == 0).length;
      final newItems =
          equipmentList.skip(existingCount).take(newEquipmentCount);

      // پردازش دسته‌ای
      final batchSize = 10;
      final batches = <List<Map<String, dynamic>>>[];

      for (int i = 0; i < newItems.length; i += batchSize) {
        final end =
            (i + batchSize < newItems.length) ? i + batchSize : newItems.length;
        batches.add(newItems.skip(i).take(end - i).toList());
      }

      for (int batchIndex = 0; batchIndex < batches.length; batchIndex++) {
        final batch = batches[batchIndex];

        await Future.wait(batch.map((item) async {
          try {
            final equipmentData = _convertEquipmentToProductionData(item);
            await _productionBox.add(equipmentData);

            final shiftInfo = ShiftInfo(
              year: 1403,
              month: 1,
              shift: '1',
              equipment: item['name']?.toString() ?? '',
              totalStopDuration: (item['total_downtime'] ?? 0).toDouble(),
              totalProduction: 0.0,
            );
            await _shiftInfoBox.add(shiftInfo);

            processedItems++;
          } catch (e) {
            print('خطا در پردازش تجهیز جدید: $e');
          }
        }));

        if (onProgress != null) {
          onProgress(0.5 + (processedItems / totalNewItems) * 0.4);
        }
      }
    }

    print('دانلود تدریجی تکمیل شد: $processedItems رکورد جدید اضافه شد');
  }

  /// همگام‌سازی هوشمند داده‌ها
  Future<void> syncData({void Function(double)? onProgress}) async {
    if (_isSyncing) {
      print('همگام‌سازی در حال انجام است...');
      return;
    }

    try {
      _isSyncing = true;
      _retryCount = 0;
      notifyListeners();

      print('شروع فرآیند همگام‌سازی...');

      // بررسی اتصال اینترنت
      final hasInternet = await _checkInternetConnection();
      if (!hasInternet) {
        throw Exception('اتصال به اینترنت برقرار نیست');
      }

      if (onProgress != null) onProgress(0.05);

      // دریافت داده‌ها از API
      print('دریافت داده‌ها از سرور...');
      final apiResponse = await _fetchDataFromAPI();
      final data = apiResponse['data'];

      if (onProgress != null) onProgress(0.15);

      // بررسی نیاز به دانلود
      print('بررسی تغییرات داده‌ها...');
      final syncInfo = await _checkForNewData(data);

      if (onProgress != null) onProgress(0.25);

      if (syncInfo['needsFullSync'] == true) {
        // دانلود کامل
        print('شروع دانلود کامل...');

        // پاک کردن داده‌های قدیمی
        print('پاک کردن داده‌های قدیمی...');
        await _clearOldData();

        if (onProgress != null) onProgress(0.35);

        // پردازش داده‌های تولید - بهینه‌سازی شده
        if (data['production'] != null) {
          final productionList =
              List<Map<String, dynamic>>.from(data['production']);
          print('پردازش ${productionList.length} رکورد تولید...');

          await _processProductionData(productionList, onProgress, 0.35, 0.25);
        }

        // پردازش داده‌های تجهیزات - بهینه‌سازی شده
        if (data['equipment'] != null) {
          final equipmentList =
              List<Map<String, dynamic>>.from(data['equipment']);
          print('پردازش ${equipmentList.length} تجهیز...');

          await _processEquipmentData(equipmentList, onProgress, 0.6, 0.1);
        }

        // پردازش داده‌های توقف - بهینه‌سازی شده
        if (data['stops'] != null) {
          final stopsList = List<Map<String, dynamic>>.from(data['stops']);
          print('پردازش ${stopsList.length} رکورد توقف...');

          await _processStopData(stopsList, onProgress, 0.7, 0.25);
        }
      } else {
        // دانلود تدریجی
        print('شروع دانلود تدریجی...');
        await _syncIncrementalData(data, syncInfo, onProgress);
      }

      // ذخیره آمار و هش جدید
      print('ذخیره آمار همگام‌سازی...');
      await _saveSyncStats(data, syncInfo);

      // آپدیت زمان همگام‌سازی
      await _updateLastSyncTime();
      await _updateLastSyncError(null);

      if (onProgress != null) onProgress(1.0);

      print('همگام‌سازی موفقیت‌آمیز:');
      print('- تولید: ${_productionBox.length} رکورد');
      print('- توقفات: ${_stopBox.length} رکورد');
      print('- شیفت‌ها: ${_shiftInfoBox.length} رکورد');
    } catch (e) {
      print('خطا در همگام‌سازی: $e');
      await _updateLastSyncError(e.toString());
      rethrow;
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  /// پاک کردن داده‌های قدیمی
  Future<void> _clearOldData() async {
    try {
      await _productionBox.clear();
      await _stopBox.clear();
      await _shiftInfoBox.clear();
      print('داده‌های قدیمی پاک شدند');
    } catch (e) {
      print('خطا در پاک کردن داده‌های قدیمی: $e');
      rethrow;
    }
  }

  /// پردازش داده‌های تولید
  Future<void> _processProductionData(
    List<Map<String, dynamic>> productionList,
    void Function(double)? onProgress,
    double startProgress,
    double progressRange,
  ) async {
    final batchSize = 20;
    final batches = <List<Map<String, dynamic>>>[];

    for (int i = 0; i < productionList.length; i += batchSize) {
      final end = (i + batchSize < productionList.length)
          ? i + batchSize
          : productionList.length;
      batches.add(productionList.skip(i).take(end - i).toList());
    }

    for (int batchIndex = 0; batchIndex < batches.length; batchIndex++) {
      final batch = batches[batchIndex];

      try {
        // پردازش همزمان رکوردهای هر دسته
        await Future.wait(batch.map((item) async {
          try {
            final productionData = _convertToProductionData(item);
            await _productionBox.add(productionData);

            final shiftInfo = _convertToShiftInfo(
                item, item['input_tonnage']?.toDouble() ?? 0.0);
            await _shiftInfoBox.add(shiftInfo);
          } catch (e) {
            print('خطا در پردازش رکورد تولید: $e');
          }
        }));

        if (onProgress != null) {
          onProgress(
              startProgress + (batchIndex / batches.length) * progressRange);
        }
      } catch (e) {
        print('خطا در پردازش دسته تولید: $e');
      }
    }
  }

  /// پردازش داده‌های تجهیزات
  Future<void> _processEquipmentData(
    List<Map<String, dynamic>> equipmentList,
    void Function(double)? onProgress,
    double startProgress,
    double progressRange,
  ) async {
    final batchSize = 20;
    final batches = <List<Map<String, dynamic>>>[];

    for (int i = 0; i < equipmentList.length; i += batchSize) {
      final end = (i + batchSize < equipmentList.length)
          ? i + batchSize
          : equipmentList.length;
      batches.add(equipmentList.skip(i).take(end - i).toList());
    }

    for (int batchIndex = 0; batchIndex < batches.length; batchIndex++) {
      final batch = batches[batchIndex];

      try {
        await Future.wait(batch.map((item) async {
          try {
            final equipmentData = _convertEquipmentToProductionData(item);
            await _productionBox.add(equipmentData);

            final shiftInfo = ShiftInfo(
              year: 1403,
              month: 1,
              shift: '1',
              equipment: item['name']?.toString() ?? '',
              totalStopDuration: (item['total_downtime'] ?? 0).toDouble(),
              totalProduction: 0.0,
            );
            await _shiftInfoBox.add(shiftInfo);
          } catch (e) {
            print('خطا در پردازش تجهیز: $e');
          }
        }));

        if (onProgress != null) {
          onProgress(
              startProgress + (batchIndex / batches.length) * progressRange);
        }
      } catch (e) {
        print('خطا در پردازش دسته تجهیزات: $e');
      }
    }
  }

  /// پردازش داده‌های توقف
  Future<void> _processStopData(
    List<Map<String, dynamic>> stopsList,
    void Function(double)? onProgress,
    double startProgress,
    double progressRange,
  ) async {
    final batchSize = 20;
    final batches = <List<Map<String, dynamic>>>[];

    for (int i = 0; i < stopsList.length; i += batchSize) {
      final end =
          (i + batchSize < stopsList.length) ? i + batchSize : stopsList.length;
      batches.add(stopsList.skip(i).take(end - i).toList());
    }

    for (int batchIndex = 0; batchIndex < batches.length; batchIndex++) {
      final batch = batches[batchIndex];

      try {
        await Future.wait(batch.map((item) async {
          try {
            final stopData = _convertToStopData(item);
            await _stopBox.add(stopData);
          } catch (e) {
            print('خطا در پردازش رکورد توقف: $e');
          }
        }));

        if (onProgress != null) {
          onProgress(
              startProgress + (batchIndex / batches.length) * progressRange);
        }
      } catch (e) {
        print('خطا در پردازش دسته توقفات: $e');
      }
    }
  }

  /// ذخیره آمار همگام‌سازی
  Future<void> _saveSyncStats(
      Map<String, dynamic> data, Map<String, dynamic> syncInfo) async {
    try {
      final currentStats = {
        'production': data['production']?.length ?? 0,
        'stops': data['stops']?.length ?? 0,
        'equipment': data['equipment']?.length ?? 0,
      };

      await _syncMetaBox.put(_lastSyncStatsKey, json.encode(currentStats));
      if (syncInfo['currentHash'] != null) {
        await _syncMetaBox.put(_lastDataHashKey, syncInfo['currentHash']);
      }
    } catch (e) {
      print('خطا در ذخیره آمار همگام‌سازی: $e');
    }
  }

  /// تست اتصال به API
  Future<bool> testConnection() async {
    try {
      print('بررسی اتصال اینترنت...');
      final hasInternet = await _checkInternetConnection();
      if (!hasInternet) {
        print('اتصال اینترنت برقرار نیست');
        return false;
      }

      print('تست اتصال به سرور...');
      final response = await http.get(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Accept': 'application/json',
          'Connection': 'keep-alive',
          'User-Agent': 'PMSech-App/1.0',
        },
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        print('اتصال به سرور موفق');
        return true;
      } else {
        print('خطای سرور: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('خطا در تست اتصال: $e');
      return false;
    }
  }

  /// دریافت داده‌های تولید (فقط داده‌های واقعی، نه تجهیزات)
  List<ProductionData> getProductionData() {
    // فقط داده‌هایی که inputTonnage > 0 دارند (یعنی رکورد تولید واقعی هستند)
    return _productionBox.values
        .where((item) => item.inputTonnage > 0)
        .toList();
  }

  /// دریافت داده‌های توقف
  List<StopData> getStopData() {
    return _stopBox.values.toList();
  }

  /// دریافت داده‌های شیفت
  List<ShiftInfo> getShiftInfo() {
    return _shiftInfoBox.values.toList();
  }

  /// دریافت وضعیت همگام‌سازی
  Map<String, dynamic> getSyncStatus() {
    try {
      final lastSync = getLastSyncTime();
      final lastError = getLastSyncError();

      return {
        'lastSyncTime': lastSync?.toIso8601String(),
        'lastError': lastError,
        'productionCount': _productionBox.length,
        'stopCount': _stopBox.length,
        'shiftCount': _shiftInfoBox.length,
        'hasData': _productionBox.isNotEmpty ||
            _stopBox.isNotEmpty ||
            _shiftInfoBox.isNotEmpty,
        'isSyncing': _isSyncing,
        'apiUrl': _baseUrl,
        'retryCount': _retryCount,
        'maxRetries': _maxRetries,
      };
    } catch (e) {
      print('خطا در دریافت وضعیت همگام‌سازی: $e');
      return {
        'lastSyncTime': null,
        'lastError': e.toString(),
        'productionCount': 0,
        'stopCount': 0,
        'shiftCount': 0,
        'hasData': false,
        'isSyncing': false,
        'apiUrl': _baseUrl,
        'retryCount': 0,
        'maxRetries': _maxRetries,
      };
    }
  }

  // فیلتر کردن داده‌ها بر اساس تاریخ
  static List<ProductionData> filterByDateRange(
    List<ProductionData> data,
    DateTime startDate,
    DateTime endDate,
  ) {
    return data.where((item) {
      final itemDate = DateTime(item.year, item.month, item.day);
      return itemDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
          itemDate.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();
  }

  // فیلتر کردن داده‌ها بر اساس تجهیز
  static List<ProductionData> filterByEquipment(
    List<ProductionData> data,
    String equipmentName,
  ) {
    return data.where((item) => item.equipmentName == equipmentName).toList();
  }

  // فیلتر کردن داده‌ها بر اساس شیفت
  static List<ProductionData> filterByShift(
    List<ProductionData> data,
    int shift,
  ) {
    return data.where((item) => item.shift == shift).toList();
  }

  // محاسبه آمار کلی - استفاده از ProductionAnalysisService برای محاسبه صحیح
  static Map<String, dynamic> calculateStatistics(List<ProductionData> data) {
    // استفاده از سرویس تحلیل تولید برای محاسبه صحیح تولید
    final productionStats =
        ProductionAnalysisService.calculateProductionStatistics(data);
    final stopStats = ProductionAnalysisService.calculateStopStatistics(data);

    return {
      'totalInputTonnage': productionStats['totalInputTonnage'],
      'totalProducedProduct': productionStats['totalProducedProduct'],
      'totalWaste': productionStats['totalWaste'],
      'totalServiceCount': productionStats['totalServiceCount'],
      'totalStopDuration': stopStats['totalStopDuration'],
      'emergencyStops': stopStats['emergencyStops'],
      'technicalStops': stopStats['technicalStops'],
      'directFeedCount': productionStats['directFeedCount'],
      'enrichmentCount': productionStats['enrichmentCount'],
      'averageStopDuration': stopStats['averageStopDuration'],
    };
  }

  // دریافت لیست تجهیزات منحصر به فرد
  static List<String> getUniqueEquipment(List<ProductionData> data) {
    // فقط تجهیزاتی که inputTonnage صفر است (یعنی از equipment API آمده‌اند)
    final equipmentItems = data
        .where((item) =>
            item.inputTonnage == 0 &&
            item.equipmentName.isNotEmpty &&
            item.equipmentName != 'خط 1' &&
            item.equipmentName != 'خط 2')
        .toList();

    if (equipmentItems.isNotEmpty) {
      return equipmentItems.map((item) => item.equipmentName).toSet().toList()
        ..sort();
    }

    // اگر داده تجهیزات نباشد، از line های تولید استفاده کن
    return data
        .where((item) => item.inputTonnage > 0)
        .map((item) => item.equipmentName)
        .toSet()
        .toList()
      ..sort();
  }

  // گروه‌بندی داده‌ها بر اساس تاریخ
  static Map<String, List<ProductionData>> groupByDate(
      List<ProductionData> data) {
    Map<String, List<ProductionData>> grouped = {};

    for (var item in data) {
      String dateKey = item.fullShamsiDate;
      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = [];
      }
      grouped[dateKey]!.add(item);
    }

    return grouped;
  }

  // گروه‌بندی داده‌ها بر اساس تجهیز
  static Map<String, List<ProductionData>> groupByEquipment(
      List<ProductionData> data) {
    Map<String, List<ProductionData>> grouped = {};

    for (var item in data) {
      if (!grouped.containsKey(item.equipmentName)) {
        grouped[item.equipmentName] = [];
      }
      grouped[item.equipmentName]!.add(item);
    }

    return grouped;
  }

  // فیلتر کردن داده‌ها بر اساس نوع توقف
  static List<ProductionData> filterByStopType(
    List<ProductionData> data,
    String stopType,
  ) {
    return data.where((item) => item.stopType == stopType).toList();
  }

  // فیلتر کردن داده‌ها بر اساس گروه
  static List<ProductionData> filterByGroup(
    List<ProductionData> data,
    int group,
  ) {
    return data.where((item) => item.group == group).toList();
  }

  // دریافت ریز تجهیزات برای یک تجهیز
  static List<String> getSubEquipmentForEquipment(
    List<ProductionData> data,
    String equipmentName,
  ) {
    return data
        .where((item) => item.equipmentName == equipmentName)
        .map((item) => item.subEquipment)
        .toSet()
        .toList()
      ..sort();
  }

  // دریافت انواع توقف منحصر به فرد
  static List<String> getUniqueStopTypes(List<ProductionData> data) {
    return data
        .map((item) => item.stopType)
        .where((type) => type.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
  }

  // گروه‌بندی داده‌ها بر اساس نوع توقف
  static Map<String, List<ProductionData>> groupByStopType(
      List<ProductionData> data) {
    Map<String, List<ProductionData>> grouped = {};

    for (var item in data) {
      if (item.stopType.isNotEmpty) {
        if (!grouped.containsKey(item.stopType)) {
          grouped[item.stopType] = [];
        }
        grouped[item.stopType]!.add(item);
      }
    }

    return grouped;
  }

  // گروه‌بندی داده‌ها بر اساس گروه
  static Map<int, List<ProductionData>> groupByGroup(
      List<ProductionData> data) {
    Map<int, List<ProductionData>> grouped = {};

    for (var item in data) {
      if (!grouped.containsKey(item.group)) {
        grouped[item.group] = [];
      }
      grouped[item.group]!.add(item);
    }

    return grouped;
  }

  // محاسبه آمار تجهیزات
  static Map<String, dynamic> calculateEquipmentStatistics(
      List<ProductionData> data) {
    if (data.isEmpty) {
      return {
        'totalInputTonnage': 0.0,
        'totalProducedProduct': 0.0,
        'totalWaste': 0.0,
        'equipmentCount': 0,
        'topEquipments': <String>[],
      };
    }

    final equipmentGroups = groupByEquipment(data);
    Map<String, Map<String, dynamic>> equipmentStats = {};

    for (var entry in equipmentGroups.entries) {
      final stats = calculateStatistics(entry.value);
      equipmentStats[entry.key] = {
        'totalProducedProduct': stats['totalProducedProduct'] ?? 0.0,
        'totalStopDuration': stats['totalStopDuration'] ?? 0.0,
        'emergencyStops': stats['emergencyStops'] ?? 0,
        'technicalStops': stats['technicalStops'] ?? 0,
        'totalStops':
            stats['emergencyStops'] ?? 0 + (stats['technicalStops'] ?? 0),
      };
    }

    final sortedEquipments = equipmentStats.entries.toList()
      ..sort((a, b) => (b.value['totalProducedProduct'] ?? 0.0)
          .compareTo(a.value['totalProducedProduct'] ?? 0.0));

    final totalStats = calculateStatistics(data);

    return {
      'totalInputTonnage': totalStats['totalInputTonnage'],
      'totalProducedProduct': totalStats['totalProducedProduct'],
      'totalWaste': totalStats['totalWaste'],
      'equipmentCount': equipmentGroups.length,
      'topEquipments': sortedEquipments.take(5).map((e) => e.key).toList(),
      'equipmentStats': equipmentStats,
    };
  }

  /// پاک‌سازی کامل همه داده‌های محلی (Hive)
  Future<void> clearAllData() async {
    try {
      print('شروع پاک‌سازی کامل داده‌ها...');
      await _productionBox.clear();
      await _stopBox.clear();
      await _shiftInfoBox.clear();
      await _syncMetaBox.clear();
      print('پاک‌سازی کامل داده‌ها موفقیت‌آمیز');
      notifyListeners();
    } catch (e) {
      print('خطا در پاک‌سازی کامل داده‌ها: $e');
      rethrow;
    }
  }

  /// بررسی سلامت داده‌ها
  Map<String, dynamic> checkDataHealth() {
    try {
      final productionData = _productionBox.values.toList();
      final stopData = _stopBox.values.toList();
      final shiftData = _shiftInfoBox.values.toList();

      final productionErrors = <String>[];
      final stopErrors = <String>[];
      final shiftErrors = <String>[];

      // بررسی داده‌های تولید
      for (int i = 0; i < productionData.length; i++) {
        final item = productionData[i];
        if (item.year <= 0 || item.month <= 0 || item.day <= 0) {
          productionErrors.add('رکورد $i: تاریخ نامعتبر');
        }
        if (item.inputTonnage < 0) {
          productionErrors.add('رکورد $i: تناژ ورودی منفی');
        }
      }

      // بررسی داده‌های توقف
      for (int i = 0; i < stopData.length; i++) {
        final item = stopData[i];
        if (item.year <= 0 || item.month <= 0 || item.day <= 0) {
          stopErrors.add('رکورد $i: تاریخ نامعتبر');
        }
        if (item.stopDuration < 0) {
          stopErrors.add('رکورد $i: مدت توقف منفی');
        }
      }

      // بررسی داده‌های شیفت
      for (int i = 0; i < shiftData.length; i++) {
        final item = shiftData[i];
        if (item.year <= 0 || item.month <= 0) {
          shiftErrors.add('رکورد $i: تاریخ نامعتبر');
        }
        if (item.totalStopDuration < 0) {
          shiftErrors.add('رکورد $i: مدت توقف منفی');
        }
      }

      return {
        'isHealthy': productionErrors.isEmpty &&
            stopErrors.isEmpty &&
            shiftErrors.isEmpty,
        'productionErrors': productionErrors,
        'stopErrors': stopErrors,
        'shiftErrors': shiftErrors,
        'totalErrors':
            productionErrors.length + stopErrors.length + shiftErrors.length,
        'productionCount': productionData.length,
        'stopCount': stopData.length,
        'shiftCount': shiftData.length,
      };
    } catch (e) {
      print('خطا در بررسی سلامت داده‌ها: $e');
      return {
        'isHealthy': false,
        'productionErrors': ['خطا در بررسی: $e'],
        'stopErrors': [],
        'shiftErrors': [],
        'totalErrors': 1,
        'productionCount': 0,
        'stopCount': 0,
        'shiftCount': 0,
      };
    }
  }

  /// پاک کردن هش‌های قدیمی برای مجبور کردن دانلود کامل
  Future<void> forceFullSync() async {
    await _syncMetaBox.delete(_lastDataHashKey);
    await _syncMetaBox.delete(_lastSyncStatsKey);
    print(
        'هش‌های قدیمی پاک شدند - دانلود کامل در همگام‌سازی بعدی انجام خواهد شد');
  }

  /// دریافت وضعیت همگام‌سازی با جزئیات بیشتر
  Map<String, dynamic> getDetailedSyncStatus() {
    final lastSync = getLastSyncTime();
    final lastError = getLastSyncError();
    final lastHash = _syncMetaBox.get(_lastDataHashKey);
    final lastStats = _syncMetaBox.get(_lastSyncStatsKey);

    return {
      'lastSyncTime': lastSync?.toIso8601String(),
      'lastError': lastError,
      'lastHash': lastHash,
      'lastStats': lastStats,
      'productionCount': _productionBox.length,
      'stopCount': _stopBox.length,
      'shiftCount': _shiftInfoBox.length,
      'hasData': _productionBox.isNotEmpty ||
          _stopBox.isNotEmpty ||
          _shiftInfoBox.isNotEmpty,
      'isSyncing': _isSyncing,
      'apiUrl': _baseUrl,
      'canForceFullSync': lastHash != null,
    };
  }
}
