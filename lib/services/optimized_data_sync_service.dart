import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../models/production_data.dart';
import '../models/stop_data.dart';
import '../models/shift_info.dart';
import '../models/grade_data.dart';
import 'grade_service.dart';

class OptimizedDataSyncService extends ChangeNotifier {
  // تنظیمات بهینه‌سازی شده
  static const String _baseUrl = 'http://62.60.198.11';
  static const String _apiEndpoint = '/simple_xlsx_to_json.php';
  static const String _gradeApiEndpoint = '/grade_api.php';

  // Timeout های بهینه‌سازی شده
  static const Duration _connectionTimeout = Duration(seconds: 10);
  static const Duration _receiveTimeout = Duration(seconds: 15);
  static const int _maxRetries = 2;
  static const Duration _retryDelay = Duration(seconds: 3);

  // Box‌های Hive
  late Box<ProductionData> _productionBox;
  late Box<StopData> _stopBox;
  late Box<ShiftInfo> _shiftInfoBox;
  late Box<GradeData> _gradeBox;
  late Box<String> _syncMetaBox;

  bool _isSyncing = false;
  String? _lastError;
  DateTime? _lastSyncTime;

  bool get isSyncing => _isSyncing;
  String? get lastError => _lastError;
  DateTime? get lastSyncTime => _lastSyncTime;

  /// راه‌اندازی اولیه
  Future<void> init() async {
    try {
      _productionBox = await Hive.openBox<ProductionData>('productionData');
      _stopBox = await Hive.openBox<StopData>('stopData');
      _shiftInfoBox = await Hive.openBox<ShiftInfo>('shiftInfo');
      _gradeBox = await Hive.openBox<GradeData>('gradeData');
      _syncMetaBox = await Hive.openBox<String>('syncMeta');

      // بازیابی زمان آخرین همگام‌سازی
      final lastSyncStr = _syncMetaBox.get('last_sync_time');
      if (lastSyncStr != null) {
        _lastSyncTime = DateTime.tryParse(lastSyncStr);
      }

      notifyListeners();
    } catch (e) {
      print('خطا در راه‌اندازی OptimizedDataSyncService: $e');
      rethrow;
    }
  }

  /// بررسی اتصال اینترنت بهینه‌سازی شده
  Future<bool> _checkConnectivity() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      return connectivityResult != ConnectivityResult.none;
    } catch (e) {
      print('خطا در بررسی اتصال: $e');
      return false;
    }
  }

  /// درخواست HTTP بهینه‌سازی شده
  Future<http.Response> _makeRequest(String url,
      {Map<String, String>? headers}) async {
    final client = http.Client();
    try {
      return await client.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Accept': 'application/json',
          'User-Agent': 'PMSechApp/2.0',
          'Connection': 'keep-alive',
          'Cache-Control': 'no-cache',
          ...?headers,
        },
      ).timeout(_connectionTimeout + _receiveTimeout);
    } finally {
      client.close();
    }
  }

  /// Retry logic بهینه‌سازی شده
  Future<T> _retryRequest<T>(Future<T> Function() request,
      {String? operation}) async {
    Exception? lastException;

    for (int attempt = 1; attempt <= _maxRetries; attempt++) {
      try {
        print('${operation ?? 'درخواست'} - تلاش $attempt از $_maxRetries');
        return await request();
      } catch (e) {
        lastException = e is Exception ? e : Exception(e.toString());
        print('خطا در تلاش $attempt: $e');

        if (attempt < _maxRetries) {
          print('انتظار ${_retryDelay.inSeconds} ثانیه قبل از تلاش بعدی...');
          await Future.delayed(_retryDelay);
        }
      }
    }

    throw lastException ?? Exception('تمام تلاش‌ها ناموفق بود');
  }

  /// همگام‌سازی سریع داده‌های تولید و توقف
  Future<bool> syncProductionAndStops() async {
    if (_isSyncing) {
      print('همگام‌سازی در حال انجام است');
      return false;
    }

    _isSyncing = true;
    _lastError = null;
    notifyListeners();

    try {
      // بررسی اتصال
      if (!await _checkConnectivity()) {
        throw Exception('اتصال اینترنت موجود نیست');
      }

      print('=== شروع همگام‌سازی سریع ===');

      // دریافت داده‌ها از سرور
      final data = await _retryRequest(
        () => _fetchProductionAndStopsData(),
        operation: 'دریافت داده‌های تولید و توقف',
      );

      if (data['success'] == true) {
        // پردازش و ذخیره داده‌ها
        await _processAndSaveData(data);

        // بروزرسانی زمان همگام‌سازی
        _lastSyncTime = DateTime.now();
        await _syncMetaBox.put(
            'last_sync_time', _lastSyncTime!.toIso8601String());

        print('✅ همگام‌سازی با موفقیت انجام شد');
        return true;
      } else {
        throw Exception(data['error'] ?? 'خطای ناشناخته از سرور');
      }
    } catch (e) {
      _lastError = e.toString();
      print('❌ خطا در همگام‌سازی: $e');
      return false;
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  /// دریافت داده‌های تولید و توقف از سرور
  Future<Map<String, dynamic>> _fetchProductionAndStopsData() async {
    final cacheBuster = DateTime.now().millisecondsSinceEpoch;
    final url = '$_baseUrl$_apiEndpoint?ts=$cacheBuster';

    print('درخواست به: $url');

    final response = await _makeRequest(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      print('داده‌های دریافتی: ${data.length} رکورد');
      return data;
    } else {
      throw Exception('خطای سرور: ${response.statusCode}');
    }
  }

  /// پردازش و ذخیره داده‌ها
  Future<void> _processAndSaveData(Map<String, dynamic> data) async {
    try {
      // پاک کردن داده‌های قدیمی
      await _productionBox.clear();
      await _stopBox.clear();
      await _shiftInfoBox.clear();

      int productionCount = 0;
      int stopCount = 0;
      int shiftCount = 0;

      if (data['data'] is List) {
        final records = data['data'] as List;

        for (final record in records) {
          if (record is Map<String, dynamic>) {
            // تشخیص نوع رکورد
            if (record.containsKey('stop_type') &&
                record['stop_type'] != null) {
              // رکورد توقف
              final stopData = _convertToStopData(record);
              await _stopBox.put(stopData.id, stopData);
              stopCount++;
            } else {
              // رکورد تولید
              final productionData = _convertToProductionData(record);
              await _productionBox.put(productionData.id, productionData);
              productionCount++;
            }

            // اطلاعات شیفت
            if (record.containsKey('shift')) {
              final shiftInfo = _convertToShiftInfo(record);
              await _shiftInfoBox.put(shiftInfo.id, shiftInfo);
              shiftCount++;
            }
          }
        }
      }

      print('✅ داده‌ها ذخیره شدند:');
      print('  - تولید: $productionCount رکورد');
      print('  - توقف: $stopCount رکورد');
      print('  - شیفت: $shiftCount رکورد');
    } catch (e) {
      print('خطا در پردازش داده‌ها: $e');
      rethrow;
    }
  }

  /// همگام‌سازی سریع عیارها
  Future<bool> syncGrades() async {
    if (_isSyncing) {
      print('همگام‌سازی در حال انجام است');
      return false;
    }

    _isSyncing = true;
    _lastError = null;
    notifyListeners();

    try {
      // بررسی اتصال
      if (!await _checkConnectivity()) {
        throw Exception('اتصال اینترنت موجود نیست');
      }

      print('=== شروع همگام‌سازی عیارها ===');

      // دانلود عیارها از سرور
      final success = await _retryRequest(
        () => _downloadGradesFromServer(),
        operation: 'دانلود عیارها',
      );

      if (success) {
        _lastSyncTime = DateTime.now();
        await _syncMetaBox.put(
            'last_sync_time', _lastSyncTime!.toIso8601String());
        print('✅ همگام‌سازی عیارها با موفقیت انجام شد');
        return true;
      } else {
        throw Exception('خطا در دانلود عیارها');
      }
    } catch (e) {
      _lastError = e.toString();
      print('❌ خطا در همگام‌سازی عیارها: $e');
      return false;
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  /// دانلود عیارها از سرور
  Future<bool> _downloadGradesFromServer() async {
    try {
      final url =
          '$_baseUrl$_gradeApiEndpoint?action=download&api_key=pmsech_grade_api_2024';

      final response = await _makeRequest(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true && data['data'] is List) {
          // پاک کردن عیارهای قدیمی
          await _gradeBox.clear();

          final grades = data['data'] as List;
          int count = 0;

          for (final grade in grades) {
            if (grade is Map<String, dynamic>) {
              final gradeData = _convertToGradeData(grade);
              await _gradeBox.put(gradeData.id, gradeData);
              count++;
            }
          }

          print('✅ $count عیار از سرور دانلود شد');
          return true;
        } else {
          print('❌ فرمت داده نامعتبر');
          return false;
        }
      } else {
        print('❌ خطای سرور: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('خطا در دانلود عیارها: $e');
      return false;
    }
  }

  /// تبدیل داده‌های API به مدل‌های Flutter
  ProductionData _convertToProductionData(Map<String, dynamic> apiData) {
    // پیاده‌سازی تبدیل داده‌های تولید
    return ProductionData(
      shamsiDate: apiData['date']?.toString() ?? '',
      year: apiData['year'] ?? 1404,
      month: apiData['month'] ?? 1,
      day: apiData['day'] ?? 1,
      shift: apiData['shift']?.toString() ?? '1',
      stopDescription: apiData['stop_description']?.toString() ?? '',
      equipmentName: apiData['equipment_name']?.toString() ?? '',
      equipmentCode1: apiData['equipment_code1']?.toString(),
      equipmentCode2: apiData['equipment_code2']?.toString(),
      subEquipment: apiData['sub_equipment']?.toString() ?? '',
      subEquipmentCode: apiData['sub_equipment_code']?.toString(),
      stopReason: apiData['stop_reason']?.toString() ?? '',
      stopType: apiData['stop_type']?.toString() ?? '',
      stopStartTime: apiData['stop_start_time']?.toString() ?? '',
      stopEndTime: apiData['stop_end_time']?.toString() ?? '',
      stopDuration: apiData['stop_duration']?.toString() ?? '0',
      serviceCount:
          int.tryParse(apiData['service_count']?.toString() ?? '0') ?? 0,
      inputTonnage:
          double.tryParse(apiData['input_tonnage']?.toString() ?? '0') ?? 0.0,
      scale3: double.tryParse(apiData['scale3']?.toString() ?? '0') ?? 0.0,
      scale4: double.tryParse(apiData['scale4']?.toString() ?? '0') ?? 0.0,
      scale5: double.tryParse(apiData['scale5']?.toString() ?? '0') ?? 0.0,
      group: int.tryParse(apiData['group']?.toString() ?? '1') ?? 1,
      directFeed: int.tryParse(apiData['direct_feed']?.toString() ?? '1') ?? 1,
    );
  }

  StopData _convertToStopData(Map<String, dynamic> apiData) {
    // پیاده‌سازی تبدیل داده‌های توقف
    return StopData(
      id: apiData['id']?.toString() ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      year: apiData['year'] ?? 1404,
      month: apiData['month'] ?? 1,
      day: apiData['day'] ?? 1,
      shift: apiData['shift']?.toString() ?? '1',
      equipmentName: apiData['equipment_name']?.toString() ?? '',
      stopType: apiData['stop_type']?.toString() ?? '',
      stopDuration: apiData['stop_duration']?.toString() ?? '0',
      stopStartTime: apiData['stop_start_time']?.toString() ?? '',
      stopEndTime: apiData['stop_end_time']?.toString() ?? '',
      stopReason: apiData['stop_reason']?.toString() ?? '',
      recordedBy: apiData['recorded_by']?.toString() ?? '',
      recordedAt: DateTime.now(),
    );
  }

  ShiftInfo _convertToShiftInfo(Map<String, dynamic> apiData) {
    // پیاده‌سازی تبدیل داده‌های شیفت
    return ShiftInfo(
      id: apiData['id']?.toString() ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      year: apiData['year'] ?? 1404,
      month: apiData['month'] ?? 1,
      day: apiData['day'] ?? 1,
      shift: apiData['shift']?.toString() ?? '1',
      startTime: apiData['start_time']?.toString() ?? '',
      endTime: apiData['end_time']?.toString() ?? '',
      recordedBy: apiData['recorded_by']?.toString() ?? '',
      recordedAt: DateTime.now(),
    );
  }

  GradeData _convertToGradeData(Map<String, dynamic> apiData) {
    // پیاده‌سازی تبدیل داده‌های عیار
    final dateStr = apiData['date']?.toString() ?? '';
    final dateParts = dateStr.split('/');

    return GradeData(
      id: apiData['id']?.toString() ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      year: dateParts.length >= 3 ? int.tryParse(dateParts[0]) ?? 1404 : 1404,
      month: dateParts.length >= 3 ? int.tryParse(dateParts[1]) ?? 1 : 1,
      day: dateParts.length >= 3 ? int.tryParse(dateParts[2]) ?? 1 : 1,
      shift: int.tryParse(apiData['shift']?.toString() ?? '1') ?? 1,
      gradeType: apiData['grade_type']?.toString() ?? '',
      gradeValue:
          double.tryParse(apiData['grade_value']?.toString() ?? '0') ?? 0.0,
      recordedBy: apiData['recorded_by']?.toString() ?? '',
      recordedAt: DateTime.now(),
      equipmentId: apiData['equipment_id']?.toString(),
      workGroup: int.tryParse(apiData['work_group']?.toString() ?? '1') ?? 1,
    );
  }

  /// همگام‌سازی کامل (تولید + توقف + عیار)
  Future<bool> syncAllData() async {
    if (_isSyncing) {
      print('همگام‌سازی در حال انجام است');
      return false;
    }

    _isSyncing = true;
    _lastError = null;
    notifyListeners();

    try {
      print('=== شروع همگام‌سازی کامل ===');

      // همگام‌سازی موازی برای سرعت بیشتر
      final results = await Future.wait([
        syncProductionAndStops(),
        syncGrades(),
      ]);

      final success = results.every((result) => result == true);

      if (success) {
        print('✅ همگام‌سازی کامل با موفقیت انجام شد');
      } else {
        print('⚠️ برخی عملیات همگام‌سازی ناموفق بودند');
      }

      return success;
    } catch (e) {
      _lastError = e.toString();
      print('❌ خطا در همگام‌سازی کامل: $e');
      return false;
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  /// تست اتصال به سرور
  Future<bool> testConnection() async {
    try {
      print('=== تست اتصال به سرور ===');

      final response = await _makeRequest('$_baseUrl$_apiEndpoint?test=1');

      final success = response.statusCode == 200;
      print(
          'نتیجه تست: ${success ? "موفق" : "ناموفق"} (${response.statusCode})');

      return success;
    } catch (e) {
      print('خطا در تست اتصال: $e');
      return false;
    }
  }

  /// دریافت وضعیت همگام‌سازی
  Map<String, dynamic> getSyncStatus() {
    return {
      'isSyncing': _isSyncing,
      'lastSyncTime': _lastSyncTime?.toIso8601String(),
      'lastError': _lastError,
      'productionCount': _productionBox.length,
      'stopCount': _stopBox.length,
      'shiftCount': _shiftInfoBox.length,
      'gradeCount': _gradeBox.length,
    };
  }
}
