import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shamsi_date/shamsi_date.dart';
import '../models/production_data.dart';
import '../models/stop_data.dart';
import '../models/shift_info.dart';
import '../models/grade_data.dart';
import 'grade_service.dart';
import 'connection_manager.dart';
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;

class SimpleDataSyncService extends ChangeNotifier {
  // آدرس API جدید (ساده)
  static const String _baseUrl = 'http://62.60.198.11';
  static const String _apiEndpoint = '/simple_xlsx_to_json.php';
  static const List<String> _fallbackBaseUrls = <String>[
    'http://62.60.198.11',
    // حذف آدرس‌های localhost که در موبایل کار نمی‌کنند
  ];

  // نام‌های Box برای Hive
  static const String _syncMetaBoxName = 'syncMeta';
  static const String _productionBoxName = 'productionData';
  static const String _stopBoxName = 'stopData';
  static const String _shiftInfoBoxName = 'shiftInfo';
  static const String _gradeBoxName = 'gradeData';
  static const String _lastSyncKey = 'last_updated';
  static const String _lastSyncErrorKey = 'last_sync_error';

  // Box‌های Hive
  late Box<ProductionData> _productionBox;
  late Box<StopData> _stopBox;
  late Box<ShiftInfo> _shiftInfoBox;
  late Box<GradeData> _gradeBox;
  late Box<String> _syncMetaBox;

  bool _isSyncing = false;
  final ConnectionManager _connectionManager = ConnectionManager();

  bool get isSyncing => _isSyncing;

  /// راه‌اندازی اولیه سرویس
  Future<void> init() async {
    try {
      // بررسی اینکه آیا box‌ها قبلاً باز شده‌اند یا نه
      if (!Hive.isBoxOpen(_productionBoxName)) {
        _productionBox = await Hive.openBox<ProductionData>(_productionBoxName);
      } else {
        _productionBox = Hive.box<ProductionData>(_productionBoxName);
      }

      if (!Hive.isBoxOpen(_stopBoxName)) {
        _stopBox = await Hive.openBox<StopData>(_stopBoxName);
      } else {
        _stopBox = Hive.box<StopData>(_stopBoxName);
      }

      if (!Hive.isBoxOpen(_shiftInfoBoxName)) {
        _shiftInfoBox = await Hive.openBox<ShiftInfo>(_shiftInfoBoxName);
      } else {
        _shiftInfoBox = Hive.box<ShiftInfo>(_shiftInfoBoxName);
      }

      if (!Hive.isBoxOpen(_gradeBoxName)) {
        _gradeBox = await Hive.openBox<GradeData>(_gradeBoxName);
      } else {
        _gradeBox = Hive.box<GradeData>(_gradeBoxName);
      }

      if (!Hive.isBoxOpen(_syncMetaBoxName)) {
        _syncMetaBox = await Hive.openBox<String>(_syncMetaBoxName);
      } else {
        _syncMetaBox = Hive.box<String>(_syncMetaBoxName);
      }

      _connectionManager.init();
      notifyListeners();
    } catch (e) {
      print('خطا در راه‌اندازی SimpleDataSyncService: $e');
      rethrow;
    }
  }

  /// بررسی اتصال اینترنت با بهینه‌سازی
  Future<bool> _checkInternetConnection() async {
    try {
      print('🔍 بررسی اتصال شبکه...');
      final hasConnection = await _connectionManager.hasInternetConnection();

      if (!hasConnection) {
        print('❌ عدم دسترسی به شبکه');
        return false;
      }

      // تست سریع سرور
      final serverOk = await _connectionManager.testServerConnection(_baseUrl);
      print(serverOk ? '✅ سرور در دسترس' : '⚠️ سرور در دسترس نیست');

      return hasConnection; // حتی اگر سرور در دسترس نباشد، اتصال شبکه را برگردان
    } catch (e) {
      print('❌ خطا در بررسی اتصال: $e');
      return false;
    }
  }

  /// بروزرسانی زمان آخرین همگام‌سازی
  Future<void> _updateLastSyncTime() async {
    await _syncMetaBox.put(_lastSyncKey, DateTime.now().toIso8601String());
  }

  /// بروزرسانی آخرین خطای همگام‌سازی
  Future<void> _updateLastSyncError(String? error) async {
    if (error != null) {
      await _syncMetaBox.put(_lastSyncErrorKey, error);
    } else {
      await _syncMetaBox.delete(_lastSyncErrorKey);
    }
  }

  /// دریافت آخرین خطای همگام‌سازی
  String? getLastSyncError() {
    try {
      return _syncMetaBox.get(_lastSyncErrorKey);
    } catch (e) {
      print('خطا در دریافت آخرین خطای همگام‌سازی: $e');
      return null;
    }
  }

  /// بررسی وضعیت box‌های Hive
  bool _checkBoxesStatus() {
    try {
      final productionBoxOk = Hive.isBoxOpen(_productionBoxName);
      final stopBoxOk = Hive.isBoxOpen(_stopBoxName);
      final shiftInfoBoxOk = Hive.isBoxOpen(_shiftInfoBoxName);
      final gradeBoxOk = Hive.isBoxOpen(_gradeBoxName);
      final syncMetaBoxOk = Hive.isBoxOpen(_syncMetaBoxName);

      print('وضعیت box‌های Hive:');
      print('  Production: $productionBoxOk');
      print('  Stop: $stopBoxOk');
      print('  ShiftInfo: $shiftInfoBoxOk');
      print('  Grade: $gradeBoxOk');
      print('  SyncMeta: $syncMetaBoxOk');

      return productionBoxOk &&
          stopBoxOk &&
          shiftInfoBoxOk &&
          gradeBoxOk &&
          syncMetaBoxOk;
    } catch (e) {
      print('خطا در بررسی وضعیت box‌ها: $e');
      return false;
    }
  }

  /// باز کردن مجدد box‌های بسته شده
  Future<void> _reopenClosedBoxes() async {
    try {
      print('🔄 تلاش برای باز کردن مجدد box‌های بسته شده...');

      if (!Hive.isBoxOpen(_productionBoxName)) {
        _productionBox = await Hive.openBox<ProductionData>(_productionBoxName);
        print('✅ Production box باز شد');
      }

      if (!Hive.isBoxOpen(_stopBoxName)) {
        _stopBox = await Hive.openBox<StopData>(_stopBoxName);
        print('✅ Stop box باز شد');
      }

      if (!Hive.isBoxOpen(_shiftInfoBoxName)) {
        _shiftInfoBox = await Hive.openBox<ShiftInfo>(_shiftInfoBoxName);
        print('✅ ShiftInfo box باز شد');
      }

      if (!Hive.isBoxOpen(_gradeBoxName)) {
        _gradeBox = await Hive.openBox<GradeData>(_gradeBoxName);
        print('✅ Grade box باز شد');
      }

      if (!Hive.isBoxOpen(_syncMetaBoxName)) {
        _syncMetaBox = await Hive.openBox<String>(_syncMetaBoxName);
        print('✅ SyncMeta box باز شد');
      }

      print('✅ تمام box‌ها باز شدند');
    } catch (e) {
      print('❌ خطا در باز کردن مجدد box‌ها: $e');
    }
  }

  /// دریافت زمان آخرین همگام‌سازی
  DateTime? getLastSyncTime() {
    final timeStr = _syncMetaBox.get(_lastSyncKey);
    if (timeStr != null) {
      return DateTime.tryParse(timeStr);
    }
    return null;
  }

  /// دریافت داده‌ها از API با retry logic
  Future<Map<String, dynamic>> _fetchDataFromAPI({String? dataType}) async {
    final List<String> bases = _fallbackBaseUrls;
    Exception? lastError;

    // اگر هیچ آدرس fallback وجود ندارد، فقط از آدرس اصلی استفاده کن
    if (bases.isEmpty) {
      bases.add(_baseUrl);
    }

    for (final base in bases) {
      String url = '$base$_apiEndpoint';
      final cacheBuster = DateTime.now().millisecondsSinceEpoch;
      if (dataType != null) {
        url += '?type=$dataType&ts=$cacheBuster';
      } else {
        url += '?ts=$cacheBuster';
      }

      print('درخواست به: $url');

      // Retry logic بهینه‌سازی شده: 3 تلاش با timeout کوتاه‌تر
      for (int attempt = 1; attempt <= 3; attempt++) {
        final int timeoutSeconds = 5 + attempt * 2; // 7/9/11 ثانیه
        try {
          print(
              '🔄 تلاش $attempt از 3 برای $base (timeout: ${timeoutSeconds}s)');
          final response = await _connectionManager.get(
            url,
            timeout: Duration(seconds: timeoutSeconds),
            maxRetries: 1, // تک تلاش در این سطح
          );

          print('کد پاسخ: ${response.statusCode}');
          print('اندازه پاسخ: ${response.body.length} کاراکتر');

          if (response.statusCode == 200) {
            String responseBody = response.body;
            if (responseBody.contains('<br />') ||
                responseBody.contains('<b>')) {
              int jsonStart = responseBody.indexOf('{');
              if (jsonStart != -1) {
                responseBody = responseBody.substring(jsonStart);
              } else {
                throw Exception('پاسخ سرور شامل JSON معتبر نیست');
              }
            }

            final data = json.decode(responseBody);

            print('=== دیباگ پاسخ API ===');
            print('نوع داده: ${data.runtimeType}');
            if (data is Map<String, dynamic>) {
              print('کلیدهای موجود: ${data.keys.toList()}');
              if (data.containsKey('data') &&
                  data['data'] is List &&
                  data['data'].isNotEmpty) {
                print('نمونه رکورد اول: ${data['data'][0]}');
              }
              if (data.containsKey('data') && data['data'] is Map) {
                final dataMap = data['data'] as Map<String, dynamic>;
                if (dataMap.containsKey('stops')) {
                  final stops = dataMap['stops'] as List;
                  print('تعداد توقفات از API: ${stops.length}');
                  if (stops.isNotEmpty) print('نمونه توقف اول: ${stops[0]}');
                }
              }

              if (data['success'] == true) {
                return data;
              } else {
                throw Exception(data['error'] ?? 'خطای ناشناخته از سرور');
              }
            } else if (data is List) {
              print('داده به صورت آرایه دریافت شد، تبدیل به Map...');
              return {
                'success': true,
                'data': data,
                'timestamp': DateTime.now().toIso8601String(),
                'count': data.length
              };
            } else {
              print('نوع داده غیرمنتظره: ${data.runtimeType}');
              // اگر داده Map نیست، آن را به عنوان خطا در نظر بگیر
              throw Exception('فرمت داده نامعتبر: ${data.runtimeType}');
            }
            // پایان پردازش پاسخ معتبر
          } else {
            throw Exception('خطای سرور: ${response.statusCode}');
          }
        } on TimeoutException catch (e) {
          lastError = Exception('base=$base attempt=$attempt timeout=$e');
          print(
              '⏳ Timeout برای $base در تلاش $attempt پس از $timeoutSeconds ثانیه');
        } catch (e) {
          lastError = Exception('base=$base attempt=$attempt error=$e');
          print('خطا برای $base تلاش $attempt: $e');
        }

        // backoff کوتاه‌تر بین تلاش‌ها
        if (attempt < 3) {
          final backoff = Duration(milliseconds: 300 + attempt * 200);
          print('⏳ انتظار ${backoff.inMilliseconds}ms قبل از تلاش بعدی...');
          await Future.delayed(backoff);
        }
      }
      print('تعویض به آدرس بعدی...');
    }

    throw lastError ?? Exception('تمام تلاش‌ها ناموفق بود');
  }

  /// تبدیل داده‌های API به مدل‌های Flutter
  ProductionData _convertToProductionData(Map<String, dynamic> apiData) {
    final dateStr = apiData['date']?.toString() ?? '';

    // تشخیص اینکه آیا این رکورد توقف است یا تولید
    final stopDescription = apiData['stop_description']?.toString() ?? '';
    final stopDuration = apiData['stop_duration']?.toString() ?? '0';
    final stopType = apiData['stop_type']?.toString() ?? '';

    // دیباگ: نمایش stop_duration از API
    print('دیباگ API stop_duration: "${apiData['stop_duration']}"');

    // خواندن کلیدها با پشتیبانی از فارسی/انگلیسی
    String readString(List<String> keys) {
      for (final key in keys) {
        if (apiData.containsKey(key) && apiData[key] != null) {
          return apiData[key].toString();
        }
      }
      return '';
    }

    dynamic readAny(List<String> keys) {
      for (final key in keys) {
        if (apiData.containsKey(key) && apiData[key] != null) {
          return apiData[key];
        }
      }
      return null;
    }

    final int serviceCount =
        _parseInt(readAny(['service_count', 'تعداد سرویس'])) ?? 0;
    final double inputTonnage =
        _parseDouble(readAny(['input_tonnage', 'تناژ ورودی']));
    final double scale3 = _parseDouble(readAny(['scale3', 'اسکیل 3']));
    final double scale4 = _parseDouble(readAny(['scale4', 'اسکیل 4']));
    final double scale5 = _parseDouble(readAny(['scale5', 'اسکیل 5']));
    final int group = _parseInt(readAny(['group', 'گروه'])) ?? 1;
    final int directFeed =
        _parseInt(readAny(['direct_feed', 'فید مستقیم'])) ?? 1;
    final String shiftStr = readString(['shift', 'شیفت']);
    final String equipmentName =
        readString(['equipment', 'تجهیز', 'equipment_name', 'name']);
    final String subEquipment = readString(['sub_equipment', 'ریز تجهیز']);
    final String equipmentCode1 =
        readString(['equipment_code1', 'equipment_code', 'کد تجهیز']);
    final String equipmentCode2 = readString(['equipment_code2']);
    final String subEquipmentCode =
        readString(['sub_equipment_code', 'کد ریز تجهیز']);
    final String stopStart = readString(['stop_start_time', 'start_time']);
    final String stopEnd = readString(['stop_end_time', 'end_time']);
    final String stopReasonStr = readString(['stop_reason', 'علت توقف']);

    return ProductionData(
      shamsiDate: dateStr,
      year: apiData['year'] ?? _parseYear(dateStr),
      month: apiData['month'] ?? _parseMonth(dateStr),
      day: apiData['day'] ?? _parseDay(dateStr),
      shift: shiftStr,
      stopDescription: stopDescription,
      equipmentName: equipmentName,
      equipmentCode1: equipmentCode1.isEmpty ? null : equipmentCode1,
      equipmentCode2: equipmentCode2.isEmpty ? null : equipmentCode2,
      subEquipment: subEquipment,
      subEquipmentCode: subEquipmentCode.isEmpty ? null : subEquipmentCode,
      stopReason: stopReasonStr,
      stopType: stopType,
      stopStartTime: stopStart,
      stopEndTime: stopEnd,
      stopDuration: stopDuration,
      serviceCount: serviceCount,
      inputTonnage: inputTonnage,
      scale3: scale3,
      scale4: scale4,
      scale5: scale5,
      group: group,
      directFeed: directFeed,
    );
  }

  // تبدیل مقدار shift به int
  int _parseShiftForStop(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    final str = value.toString();
    if (str.contains(':')) {
      final parts = str.split(':');
      if (parts.length == 2) {
        final h = int.tryParse(parts[0]) ?? 0;
        final m = int.tryParse(parts[1]) ?? 0;
        return (h * 60 + m).toInt();
      }
    }
    return int.tryParse(str) ?? 0;
  }

  StopData _convertToStopData(Map<String, dynamic> apiData) {
    final dateStr = apiData['date']?.toString() ?? '';

    // دیباگ: بررسی فیلدهای موجود در API
    print('=== دیباگ API داده‌های توقف ===');
    print('کلیدهای موجود: ${apiData.keys.toList()}');
    print(
        'نمونه مقادیر: year=${apiData['year'] ?? apiData['سال']}, month=${apiData['month'] ?? apiData['ماه']}, day=${apiData['day'] ?? apiData['روز']}, stop_type=${apiData['stop_type'] ?? apiData['نوع توقف'] ?? apiData['نوع_توقف']}, stop_duration=${apiData['stop_duration'] ?? apiData['مدت توقف'] ?? apiData['duration'] ?? apiData['downtime']}');
    print('================================');

    // سال/ماه/روز: با درنظر گرفتن کلیدهای جایگزین و در نهایت استخراج از تاریخ
    final int year = _parseInt(apiData['year']) ??
        _parseInt(apiData['سال']) ??
        _parseYear(dateStr);
    final int month = _parseInt(apiData['month']) ??
        _parseInt(apiData['ماه']) ??
        _parseMonth(dateStr);
    final int day = _parseInt(apiData['day']) ??
        _parseInt(apiData['روز']) ??
        _parseDay(dateStr);

    // شیفت: کلیدهای جایگزین
    final String shift = (apiData['shift'] ?? apiData['شیفت'] ?? '').toString();

    // تجهیز: اولویت equipment_name → equipment → sub_equipment_code → sub_equipment → name
    String equipmentName = apiData['equipment_name'] as String? ?? '';
    if (equipmentName.isEmpty) {
      equipmentName = apiData['equipment'] as String? ?? '';
    }
    if (equipmentName.isEmpty) {
      equipmentName = apiData['sub_equipment_code'] as String? ?? '';
    }
    if (equipmentName.isEmpty) {
      equipmentName = apiData['sub_equipment'] as String? ?? '';
    }
    if (equipmentName.isEmpty) {
      equipmentName = apiData['name'] as String? ?? '';
    }

    // نوع توقف: کلیدهای جایگزین
    final String stopType = (apiData['stop_type'] ??
            apiData['نوع توقف'] ??
            apiData['نوع_توقف'] ??
            apiData['stopType'] ??
            '')
        .toString();

    // مدت توقف: از stop_duration/مدت توقف/… یا محاسبه از start/end
    double stopDurationMinutes = 0.0;
    dynamic durationValue = apiData['stop_duration'] ??
        apiData['مدت توقف'] ??
        apiData['duration'] ??
        apiData['downtime'] ??
        apiData['stop_time'] ??
        apiData['downtime_min'];

    String startTimeStr =
        (apiData['stop_start_time'] ?? apiData['start_time'] ?? '').toString();
    String endTimeStr =
        (apiData['stop_end_time'] ?? apiData['end_time'] ?? '').toString();

    // اگر مقدار مستقیم داریم، تبدیل کن
    if (durationValue != null && durationValue.toString().isNotEmpty) {
      if (durationValue is String) {
        final val = durationValue.trim();
        if (val.contains(':')) {
          final parts = val.split(':');
          if (parts.length >= 2) {
            final hours = int.tryParse(parts[0]) ?? 0;
            final minutes = int.tryParse(parts[1]) ?? 0;
            stopDurationMinutes = (hours * 60 + minutes).toDouble();
          }
        } else {
          stopDurationMinutes = double.tryParse(val) ?? 0.0;
        }
      } else if (durationValue is num) {
        stopDurationMinutes = durationValue.toDouble();
      }
    }

    // اگر هنوز صفر است و زمان شروع/پایان داریم، محاسبه کن
    if (stopDurationMinutes <= 0 &&
        startTimeStr.isNotEmpty &&
        endTimeStr.isNotEmpty) {
      double toMinutes(String t) {
        final parts = t.split(':');
        if (parts.length < 2) return 0;
        final h = int.tryParse(parts[0]) ?? 0;
        final m = int.tryParse(parts[1]) ?? 0;
        return (h * 60 + m).toDouble();
      }

      final startM = toMinutes(startTimeStr);
      final endM = toMinutes(endTimeStr);
      if (endM >= startM) {
        stopDurationMinutes = endM - startM;
      } else {
        // عبور از نیمه‌شب
        stopDurationMinutes = (24 * 60 - startM) + endM;
      }
    }

    return StopData(
      year: year,
      month: month,
      day: day,
      shift: shift,
      equipment: equipmentName,
      stopType: stopType,
      stopDuration: stopDurationMinutes,
      equipmentName: equipmentName,
    );
  }

  ShiftInfo _convertToShiftInfo(Map<String, dynamic> apiData) {
    final dateStr = apiData['date']?.toString() ?? '';

    return ShiftInfo(
      year: apiData['year'] ?? _parseYear(dateStr),
      month: apiData['month'] ?? _parseMonth(dateStr),
      shift: apiData['shift']?.toString() ?? '',
      equipment: apiData['name']?.toString() ?? '',
      totalStopDuration: _parseDouble(apiData['total_downtime']),
      totalProduction: _parseDouble(apiData['total_production']),
    );
  }

  /// تجزیه سال از رشته تاریخ
  int _parseYear(String dateStr) {
    if (dateStr.isEmpty) return DateTime.now().year;

    try {
      final parts = dateStr.split('/');
      if (parts.length >= 3) {
        // فرمت: 1403/01/15
        return int.parse(parts[0]);
      }
    } catch (e) {
      print('خطا در تجزیه سال: $e');
    }
    return DateTime.now().year;
  }

  /// تجزیه ماه از رشته تاریخ
  int _parseMonth(String dateStr) {
    if (dateStr.isEmpty) return DateTime.now().month;

    try {
      final parts = dateStr.split('/');
      if (parts.length >= 3) {
        return int.parse(parts[1]);
      }
    } catch (e) {
      print('خطا در تجزیه ماه: $e');
    }
    return DateTime.now().month;
  }

  /// تجزیه روز از رشته تاریخ
  int _parseDay(String dateStr) {
    if (dateStr.isEmpty) return DateTime.now().day;

    try {
      final parts = dateStr.split('/');
      if (parts.length >= 3) {
        return int.parse(parts[2]);
      }
    } catch (e) {
      print('خطا در تجزیه روز: $e');
    }
    return DateTime.now().day;
  }

  /// تبدیل سریع رشته به عدد صحیح
  int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  /// تبدیل سریع رشته به عدد اعشاری
  double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }

  /// پردازش سریع همه انواع داده‌ها با حداکثر بهینه‌سازی
  Future<void> _processFastBatchData(
    Map<String, dynamic> data,
    void Function(double)? onProgress,
  ) async {
    print('شروع پردازش سریع داده‌ها...');
    print('کلیدهای موجود در data: ${data.keys.toList()}');

    // دیباگ: بررسی ساختار داده‌ها
    print('=== دیباگ ساختار داده‌ها ===');
    print('کلیدهای سطح اول: ${data.keys.toList()}');
    print('نوع data[\'data\']: ${data['data'].runtimeType}');

    if (data.containsKey('data')) {
      if (data['data'] is List) {
        print(
            'data[\'data\'] یک List است با ${(data['data'] as List).length} عنصر');
      } else if (data['data'] is Map) {
        final dataMap = data['data'] as Map<String, dynamic>;
        print('کلیدهای موجود در data.data: ${dataMap.keys.toList()}');
        if (dataMap.containsKey('stops')) {
          final stops = dataMap['stops'] as List;
          print('تعداد توقفات در data.data.stops: ${stops.length}');
        }
      }
    }

    // بررسی فرمت داده‌ها - پشتیبانی از فرمت جدید simple_xlsx_to_json.php
    List<Map<String, dynamic>> allDataList = [];

    print('=== دیباگ ساختار داده‌ها ===');
    print('کلیدهای سطح اول: ${data.keys.toList()}');
    print('نوع data[\'data\']: ${data['data'].runtimeType}');

    try {
      if (data['data'] is List) {
        // فرمت جدید: data به صورت آرایه مستقیم
        allDataList = List<Map<String, dynamic>>.from(data['data']);
        print(
            'فرمت جدید: داده‌ها به صورت آرایه مستقیم - ${allDataList.length} رکورد');
      } else if (data['data'] is Map) {
        // فرمت قدیمی: data به صورت Map با کلیدهای جداگانه
        final dataMap = data['data'] as Map<String, dynamic>;
        print('کلیدهای سطح دوم: ${dataMap.keys.toList()}');
        if (dataMap.containsKey('production')) {
          allDataList
              .addAll(List<Map<String, dynamic>>.from(dataMap['production']));
        }
        if (dataMap.containsKey('production_data')) {
          allDataList.addAll(
              List<Map<String, dynamic>>.from(dataMap['production_data']));
        }
        if (dataMap.containsKey('stops')) {
          allDataList.addAll(List<Map<String, dynamic>>.from(dataMap['stops']));
        }
        print(
            'فرمت قدیمی: داده‌ها از Map جداگانه - ${allDataList.length} رکورد');
      } else {
        print('نوع داده غیرمنتظره: ${data['data'].runtimeType}');
        throw Exception('فرمت داده نامعتبر: ${data['data'].runtimeType}');
      }
    } catch (e) {
      print('خطا در پردازش ساختار داده‌ها: $e');
      print('داده دریافتی: $data');
      rethrow;
    }

    // جداسازی تولید و توقفات با منطق پایدارتر
    final productionList = <Map<String, dynamic>>[];
    final stopsList = <Map<String, dynamic>>[];

    double minutesFrom(dynamic value) {
      if (value == null) return 0.0;
      final str = value.toString().trim();
      if (str.isEmpty) return 0.0;
      if (str.contains(':')) {
        final parts = str.split(':');
        if (parts.length >= 2) {
          final h = int.tryParse(parts[0]) ?? 0;
          final m = int.tryParse(parts[1]) ?? 0;
          return (h * 60 + m).toDouble();
        }
      }
      return double.tryParse(str) ?? 0.0;
    }

    for (final item in allDataList) {
      final String stopTypeStr = (item['stop_type'] ??
              item['نوع توقف'] ??
              item['نوع_توقف'] ??
              item['stopType'] ??
              '')
          .toString()
          .trim();
      final double stopMinutes =
          minutesFrom(item['stop_duration'] ?? item['مدت توقف']);
      final double inputTonnage =
          _parseDouble(item['input_tonnage'] ?? item['تناژ ورودی']);
      final int serviceCount =
          _parseInt(item['service_count'] ?? item['تعداد سرویس']) ?? 0;

      // اصلاح منطق تشخیص: اول بررسی کنیم آیا رکورد توقف است
      final bool isStop = stopTypeStr.isNotEmpty || (stopMinutes > 0);
      final bool isProduction =
          !isStop && ((inputTonnage > 0) || (serviceCount > 0));

      if (isProduction) {
        productionList.add(item);
      } else if (isStop) {
        stopsList.add(item);
      } else {
        // داده نامشخص: به تولید اختصاص نده، تا داده‌های توقف را اشتباه زیاد نکنیم
      }
    }

    print('تعداد تولید: ${productionList.length}');
    print('تعداد توقفات: ${stopsList.length}');
    final equipmentList = <Map<String, dynamic>>[];

    print('تعداد production: ${productionList.length}');
    print('تعداد stops: ${stopsList.length}');
    print('تعداد equipment: ${equipmentList.length}');

    if (onProgress != null) onProgress(0.3);

    // پردازش سریع production
    if (productionList.isNotEmpty) {
      final List<ProductionData> allProduction = [];
      int errorCount = 0;
      for (final item in productionList) {
        try {
          allProduction.add(_convertToProductionData(item));
        } catch (e) {
          errorCount++;
        }
      }
      await _productionBox.addAll(allProduction);

      // اگر بیش از 50% خطا داشتیم، خطا throw کنیم
      if (errorCount > productionList.length * 0.5) {
        throw Exception('خطا در پردازش بیش از 50% داده‌های تولید');
      }
    }

    if (onProgress != null) onProgress(0.6);

    // پردازش سریع stops
    if (stopsList.isNotEmpty) {
      final List<StopData> allStops = [];
      int errorCount = 0;

      for (int i = 0; i < stopsList.length; i++) {
        final item = stopsList[i];
        try {
          final stopData = _convertToStopData(item);
          allStops.add(stopData);
        } catch (e) {
          errorCount++;
        }
      }

      if (allStops.isNotEmpty) {
        await _stopBox.addAll(allStops);
      }

      // اگر بیش از 50% خطا داشتیم، خطا throw کنیم
      if (errorCount > stopsList.length * 0.5) {
        throw Exception('خطا در پردازش بیش از 50% داده‌های توقف');
      }
    } else {
      print('لیست توقفات خالی است!');
    }

    if (onProgress != null) onProgress(0.9);

    // پردازش سریع equipment
    if (equipmentList.isNotEmpty) {
      final List<ShiftInfo> allEquipment = [];
      int errorCount = 0;
      for (final item in equipmentList) {
        try {
          allEquipment.add(_convertToShiftInfo(item));
        } catch (e) {
          errorCount++;
        }
      }
      await _shiftInfoBox.addAll(allEquipment);

      // اگر بیش از 50% خطا داشتیم، خطا throw کنیم
      if (errorCount > equipmentList.length * 0.5) {
        throw Exception('خطا در پردازش بیش از 50% داده‌های تجهیزات');
      }
    }
  }

  /// پردازش دسته‌ای داده‌ها برای بهبود سرعت - بهینه‌سازی نهایی
  Future<void> _processBatchData<T>(
    List<Map<String, dynamic>> dataList,
    T Function(Map<String, dynamic>) converter,
    Box<T> box,
    String dataType,
    void Function(double)? onProgress,
    double startProgress,
    double progressRange,
  ) async {
    if (dataList.isEmpty) return;

    const int batchSize = 1000; // افزایش اندازه batch برای سرعت بیشتر
    final int totalBatches = (dataList.length / batchSize).ceil();

    print('پردازش $dataType: ${dataList.length} رکورد در $totalBatches دسته');

    for (int batchIndex = 0; batchIndex < totalBatches; batchIndex++) {
      final int startIndex = batchIndex * batchSize;
      final int endIndex = (startIndex + batchSize < dataList.length)
          ? startIndex + batchSize
          : dataList.length;

      // تبدیل سریع کل دسته
      final List<T> batchData = <T>[];
      for (int i = startIndex; i < endIndex; i++) {
        try {
          batchData.add(converter(dataList[i]));
        } catch (e) {
          print('خطا در پردازش $dataType رکورد $i: $e');
        }
      }

      // ذخیره یکجای کل دسته
      if (batchData.isNotEmpty) {
        await box.addAll(batchData);
      }

      // بروزرسانی پیشرفت فقط هر 5 دسته
      if (onProgress != null && (batchIndex + 1) % 5 == 0) {
        final batchProgress = (batchIndex + 1) / totalBatches;
        final currentProgress = startProgress + (batchProgress * progressRange);
        onProgress(currentProgress);
      }
    }

    print('پردازش $dataType تکمیل شد: ${box.length} رکورد');
  }

  /// همگام‌سازی همه داده‌ها با بهینه‌سازی سرعت
  Future<void> syncAllData({void Function(double)? onProgress}) async {
    if (_isSyncing) return;

    try {
      _isSyncing = true;
      notifyListeners();

      print('شروع همگام‌سازی داده‌ها...');

      // بررسی اتصال اینترنت
      final hasInternet = await _checkInternetConnection();
      if (!hasInternet) {
        print(
            '⚠️ اتصال اینترنت تایید نشد؛ تلاش برای همگام‌سازی ادامه می‌یابد.');
      }

      if (onProgress != null) onProgress(0.05);

      // دریافت داده‌ها از API
      print('دریافت داده‌ها از API...');
      final apiResponse = await _fetchDataFromAPI();

      if (onProgress != null) onProgress(0.15);

      // پاک کردن داده‌های قدیمی تنها پس از موفقیت دریافت داده‌های جدید
      print('پاک کردن داده‌های قدیمی...');
      await Future.wait([
        _productionBox.clear(),
        _stopBox.clear(),
        _shiftInfoBox.clear(),
      ]);

      if (onProgress != null) onProgress(0.25);

      // پردازش سریع همه انواع داده‌ها
      await _processFastBatchData(apiResponse, onProgress);

      // همگام‌سازی پایدار داده‌های عیار از سرور و آینه‌سازی در باکس داخلی
      if (onProgress != null) onProgress(0.92);
      await syncGradeData();

      await _updateLastSyncTime();
      await _updateLastSyncError(null);

      if (onProgress != null) onProgress(1.0);

      print('همگام‌سازی با موفقیت انجام شد');
      print('تعداد داده‌های تولید: ${_productionBox.length}');
      print('تعداد داده‌های توقف: ${_stopBox.length}');
      print('تعداد داده‌های شیفت: ${_shiftInfoBox.length}');
      print('تعداد داده‌های عیار: ${_gradeBox.length}');
    } catch (e) {
      print('خطا در همگام‌سازی: $e');
      await _updateLastSyncError(e.toString());
      rethrow;
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  /// همگام‌سازی داده‌های عیار از سرور و آینه‌سازی در باکس داخلی
  Future<void> syncGradeData() async {
    print('🔄 [SYNC_GRADES] شروع همگام‌سازی عیارها - SimpleDataSyncService');

    try {
      // تست اتصال
      print('🌐 [SYNC_GRADES] بررسی اتصال...');
      final hasConnection = await _checkInternetConnection();
      if (!hasConnection) {
        print('❌ [SYNC_GRADES] عدم اتصال - متوقف شدن');
        return;
      }

      // دانلود از سرور
      print('📡 [SYNC_GRADES] شروع دانلود از GradeService...');
      final ok = await GradeService.downloadGradesFromServer();
      print('📡 [SYNC_GRADES] نتیجه دانلود: ${ok ? "✅ موفق" : "❌ ناموفق"}');

      if (!ok) {
        print('❌ [SYNC_GRADES] دانلود ناموفق - خروج');
        return;
      }

      // خواندن از GradeService
      print('📥 [SYNC_GRADES] خواندن از GradeService...');
      final allGrades = await GradeService.getAllGradeData();
      print('📥 [SYNC_GRADES] دریافت ${allGrades.length} عیار');

      // آینه‌سازی در باکس داخلی
      print('🗑️ [SYNC_GRADES] پاک کردن باکس داخلی...');
      await _gradeBox.clear();

      if (allGrades.isNotEmpty) {
        final gradeMap = <String, GradeData>{};
        for (int i = 0; i < allGrades.length; i++) {
          gradeMap[allGrades[i].id] = allGrades[i];
        }
        print('💾 [SYNC_GRADES] ذخیره ${gradeMap.length} عیار...');
        await _gradeBox.putAll(gradeMap);
      }

      print(
          '✅ [SYNC_GRADES] تکمیل: ${_gradeBox.length} رکورد نهایی در باکس داخلی');
    } catch (e, stackTrace) {
      print('❌ [SYNC_GRADES] خطا: $e');
      print(
          '📍 [SYNC_GRADES] StackTrace: ${stackTrace.toString().substring(0, 200)}...');
    }
  }

  /// همگام‌سازی فقط داده‌های تولید
  Future<void> syncProductionData() async {
    try {
      final apiResponse = await _fetchDataFromAPI(dataType: 'production');
      // API ممکن است دو ساختار برگرداند: {data: [...]} یا {data: {production: [...]}}
      final dynamic dataNode = apiResponse['data'];
      final List<Map<String, dynamic>> productionList = dataNode is List
          ? List<Map<String, dynamic>>.from(dataNode)
          : List<Map<String, dynamic>>.from(
              (dataNode as Map<String, dynamic>)['production'] ?? const []);

      await _productionBox.clear();
      await _processBatchData(
        productionList,
        _convertToProductionData,
        _productionBox,
        'تولید',
        null,
        0,
        1,
      );

      await _updateLastSyncTime();
      print(
          'همگام‌سازی داده‌های تولید انجام شد: ${_productionBox.length} رکورد');
    } catch (e) {
      print('خطا در همگام‌سازی داده‌های تولید: $e');
      rethrow;
    }
  }

  /// همگام‌سازی فقط داده‌های توقف
  Future<void> syncStopData() async {
    try {
      final apiResponse = await _fetchDataFromAPI(dataType: 'stops');
      final dynamic dataNode = apiResponse['data'];
      final List<Map<String, dynamic>> stopsList = dataNode is List
          ? List<Map<String, dynamic>>.from(dataNode)
          : List<Map<String, dynamic>>.from(
              (dataNode as Map<String, dynamic>)['stops'] ?? const []);

      await _stopBox.clear();
      await _processBatchData(
        stopsList,
        _convertToStopData,
        _stopBox,
        'توقف',
        null,
        0,
        1,
      );

      await _updateLastSyncTime();
      print('همگام‌سازی داده‌های توقف انجام شد: ${_stopBox.length} رکورد');
      // دیباگ: توزیع سال/ماه بعد از همگام‌سازی
      final allStops = _stopBox.values.toList();
      final Map<int, int> yearDist = {};
      final Map<String, int> monthDist = {};
      for (final s in allStops) {
        yearDist[s.year] = (yearDist[s.year] ?? 0) + 1;
        final key = '${s.year}/${s.month}';
        monthDist[key] = (monthDist[key] ?? 0) + 1;
      }
      print('توزیع سال توقفات: $yearDist');
      print('توزیع ماه توقفات: $monthDist');
    } catch (e) {
      print('خطا در همگام‌سازی داده‌های توقف: $e');
      rethrow;
    }
  }

  /// همگام‌سازی فقط داده‌های تجهیزات
  Future<void> syncEquipmentData() async {
    try {
      // ابتدا equipment، در صورت خالی بودن fallback به shift
      var apiResponse = await _fetchDataFromAPI(dataType: 'equipment');
      dynamic dataNode = apiResponse['data'];
      List<Map<String, dynamic>> equipmentList = dataNode is List
          ? List<Map<String, dynamic>>.from(dataNode)
          : List<Map<String, dynamic>>.from(
              (dataNode as Map<String, dynamic>)['equipment'] ?? const []);

      if (equipmentList.isEmpty) {
        apiResponse = await _fetchDataFromAPI(dataType: 'shift');
        dataNode = apiResponse['data'];
        equipmentList = dataNode is List
            ? List<Map<String, dynamic>>.from(dataNode)
            : List<Map<String, dynamic>>.from(
                (dataNode as Map<String, dynamic>)['shift'] ?? const []);
      }

      await _shiftInfoBox.clear();
      await _processBatchData(
        equipmentList,
        _convertToShiftInfo,
        _shiftInfoBox,
        'تجهیزات',
        null,
        0,
        1,
      );

      await _updateLastSyncTime();
      print(
          'همگام‌سازی داده‌های تجهیزات انجام شد: ${_shiftInfoBox.length} رکورد');
    } catch (e) {
      print('خطا در همگام‌سازی داده‌های تجهیزات: $e');
      rethrow;
    }
  }

    /// دریافت داده‌های تولید
  List<ProductionData> getProductionData() {
    try {
      // بررسی وضعیت box قبل از دسترسی
      if (!_checkBoxesStatus()) {
        print('⚠️ خطا: box‌های Hive بسته شده‌اند');
        return [];
      }

      // دیباگ: بررسی تمام داده‌های موجود
      final allData = _productionBox.values.toList();
      print('=== دیباگ SimpleDataSyncService ===');
      print('کل رکوردها در دیتابیس: ${allData.length}');

      // بررسی توزیع شیفت‌ها در کل دیتابیس
      Map<String, int> shiftDistribution = {};
      for (var item in allData) {
        shiftDistribution[item.shift] =
            (shiftDistribution[item.shift] ?? 0) + 1;
      }
      print('توزیع شیفت‌ها در کل دیتابیس: $shiftDistribution');

      // بررسی توزیع ماه‌ها
      Map<String, int> monthDistribution = {};
      for (var item in allData) {
        String monthKey = '${item.year}/${item.month}';
        monthDistribution[monthKey] = (monthDistribution[monthKey] ?? 0) + 1;
      }
      print('توزیع ماه‌ها در کل دیتابیس: $monthDistribution');

      // بررسی رکوردهای ماه 4 سال 1404
      final month4Data = allData
          .where((item) => item.year == 1404 && item.month == 4)
          .toList();
      print('رکوردهای ماه 4/1404: ${month4Data.length}');

      // بررسی توزیع شیفت‌ها در ماه 4
      Map<String, int> month4ShiftDistribution = {};
      for (var item in month4Data) {
        month4ShiftDistribution[item.shift] =
            (month4ShiftDistribution[item.shift] ?? 0) + 1;
      }
      print('توزیع شیفت‌ها در ماه 4/1404: $month4ShiftDistribution');

      // بررسی داده‌های با inputTonnage > 0
      final productionData =
          allData.where((item) => item.inputTonnage > 0).toList();
      print('رکوردهای با inputTonnage > 0: ${productionData.length}');

      // بررسی توزیع شیفت‌ها در رکوردهای تولید
      Map<String, int> productionShiftDistribution = {};
      for (var item in productionData) {
        productionShiftDistribution[item.shift] =
            (productionShiftDistribution[item.shift] ?? 0) + 1;
      }
      print('توزیع شیفت‌ها در رکوردهای تولید: $productionShiftDistribution');

      // بررسی رکوردهای تولید ماه 4
      final month4ProductionData = productionData
          .where((item) => item.year == 1404 && item.month == 4)
          .toList();
      print('رکوردهای تولید ماه 4/1404: ${month4ProductionData.length}');

      // بررسی توزیع شیفت‌ها در رکوردهای تولید ماه 4
      Map<String, int> month4ProductionShiftDistribution = {};
      for (var item in month4ProductionData) {
        month4ProductionShiftDistribution[item.shift] =
            (month4ProductionShiftDistribution[item.shift] ?? 0) + 1;
      }
      print(
          'توزیع شیفت‌ها در رکوردهای تولید ماه 4/1404: $month4ProductionShiftDistribution');

      print('=====================================');

      // اصلاح: تمام رکوردها را برمی‌گردانیم (فیلتر در production_screen.dart انجام می‌شود)
      return allData;
    } catch (e) {
      print('❌ خطا در دریافت داده‌های تولید: $e');
      return [];
    }
  }

  /// دریافت داده‌های توقف
  List<StopData> getStopData() {
    try {
      // بررسی وضعیت box قبل از دسترسی
      if (!_checkBoxesStatus()) {
        print('⚠️ خطا: box‌های Hive بسته شده‌اند');
        return [];
      }

      return _stopBox.values.toList();
    } catch (e) {
      print('❌ خطا در دریافت داده‌های توقف: $e');
      return [];
    }
  }

  /// دریافت داده‌های توقف با فیلتر تاریخ
  List<StopData> getStopDataByDateRange(DateTime startDate, DateTime endDate) {
    final allStopData = _stopBox.values.toList();

    // تبدیل تاریخ‌های میلادی به شمسی
    final startShamsi = Jalali.fromDateTime(startDate);
    final endShamsi = Jalali.fromDateTime(endDate);

    // فیلتر بر اساس بازه تاریخ
    final filteredStopData = allStopData.where((stop) {
      // تبدیل تاریخ توقف به شمسی
      final stopDate = Jalali(stop.year, stop.month, stop.day);

      // بررسی اینکه آیا در بازه انتخاب شده است
      return stopDate >= startShamsi && stopDate <= endShamsi;
    }).toList();

    print('=== دیباگ فیلتر توقفات ===');
    print('کل توقفات در دیتابیس: ${allStopData.length}');
    print('توقفات فیلتر شده: ${filteredStopData.length}');
    print(
        'بازه تاریخ: ${startShamsi.year}/${startShamsi.month}/${startShamsi.day} تا ${endShamsi.year}/${endShamsi.month}/${endShamsi.day}');
    print('============================');

    return filteredStopData;
  }

  /// دریافت داده‌های شیفت
  List<ShiftInfo> getShiftInfo() {
    return _shiftInfoBox.values.toList();
  }

  /// دریافت داده‌های عیار
  List<GradeData> getGradeData() {
    return _gradeBox.values.toList();
  }

  /// بررسی وضعیت آخرین همگام‌سازی
  Map<String, dynamic> getSyncStatus() {
    final lastSync = getLastSyncTime();
    final lastError = getLastSyncError();

    return {
      'lastSyncTime': lastSync?.toIso8601String(),
      'lastError': lastError,
      'productionCount': _productionBox.length,
      'stopCount': _stopBox.length,
      'shiftCount': _shiftInfoBox.length,
      'gradeCount': _gradeBox.length,
      'hasData': _productionBox.isNotEmpty ||
          _stopBox.isNotEmpty ||
          _shiftInfoBox.isNotEmpty ||
          _gradeBox.isNotEmpty,
      'isSyncing': _isSyncing,
    };
  }

  /// تست اتصال به API
  Future<bool> testConnection() async {
    try {
      final hasInternet = await _checkInternetConnection();
      if (!hasInternet) return false;

      final response = await http.get(
        Uri.parse('$_baseUrl$_apiEndpoint'),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Accept': 'application/json, text/plain, */*',
          'User-Agent': 'PMSechApp/1.0 (Flutter)',
          'Accept-Language': 'fa-IR,fa;q=0.9,en;q=0.8',
          'Accept-Encoding': 'gzip, deflate, br',
          'Connection': 'keep-alive',
          'Cache-Control': 'no-cache',
        },
      ).timeout(const Duration(seconds: 15));

      print('تست اتصال API - کد پاسخ: ${response.statusCode}');

      if (response.statusCode == 200) {
        return true;
      } else if (response.statusCode == 403) {
        print('⚠️ خطای 403 در تست اتصال - احتمالاً مشکل فیلترینگ');
        return false;
      } else {
        print('❌ خطای ${response.statusCode} در تست اتصال');
        return false;
      }
    } catch (e) {
      print('خطا در تست اتصال: $e');
      return false;
    }
  }

  /// تست مستقیم سرور برای تشخیص مشکل
  Future<Map<String, dynamic>> testServerDirectly() async {
    try {
      print('=== تست مستقیم سرور ===');

      // تست 1: اتصال به سرور اصلی
      print('تست 1: اتصال به سرور اصلی');
      final response1 = await http.get(
        Uri.parse('$_baseUrl'),
        headers: {
          'User-Agent': 'PMSechApp/1.0 (Flutter)',
          'Accept':
              'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
        },
      ).timeout(const Duration(seconds: 10));

      print('کد پاسخ سرور اصلی: ${response1.statusCode}');
      print('Headers سرور اصلی: ${response1.headers}');

      // تست 2: اتصال به API
      print('تست 2: اتصال به API');
      final response2 = await http.get(
        Uri.parse('$_baseUrl$_apiEndpoint'),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Accept': 'application/json, text/plain, */*',
          'User-Agent': 'PMSechApp/1.0 (Flutter)',
          'Accept-Language': 'fa-IR,fa;q=0.9,en;q=0.8',
          'Accept-Encoding': 'gzip, deflate, br',
          'Connection': 'keep-alive',
          'Cache-Control': 'no-cache',
        },
      ).timeout(const Duration(seconds: 15));

      print('کد پاسخ API: ${response2.statusCode}');
      print('Headers API: ${response2.headers}');
      print('بدنه پاسخ API: ${response2.body.substring(0, 200)}...');

      return {
        'server_status': response1.statusCode,
        'api_status': response2.statusCode,
        'server_headers': response1.headers.toString(),
        'api_headers': response2.headers.toString(),
        'api_body_preview': response2.body.substring(0, 200),
        'success': response1.statusCode == 200 && response2.statusCode == 200,
      };
    } catch (e) {
      print('❌ خطا در تست مستقیم سرور: $e');
      return {
        'error': e.toString(),
        'success': false,
      };
    }
  }

  /// بررسی اتصال اینترنت (متد عمومی)
  Future<bool> checkInternetConnection() async {
    return await _checkInternetConnection();
  }

  /// پاک کردن همه داده‌های محلی
  Future<void> clearAllData() async {
    try {
      await _productionBox.clear();
      await _stopBox.clear();
      await _shiftInfoBox.clear();
      await _gradeBox.clear();
      await _syncMetaBox.clear();
      print('همه داده‌های محلی پاک شدند');
    } catch (e) {
      print('خطا در پاک کردن داده‌ها: $e');
      rethrow;
    }
  }
}
