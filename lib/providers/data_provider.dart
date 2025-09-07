import 'package:flutter/foundation.dart';
import '../models/production_data.dart';
import '../models/stop_data.dart';
import '../models/grade_data.dart';
import '../models/shift_info.dart';
import '../services/data_sync_service.dart';
import '../services/simple_data_sync_service.dart';

class DataProvider extends ChangeNotifier {
  final DataSyncService _dataSyncService;
  final SimpleDataSyncService _simpleDataSyncService;
  bool _isLoading = false;
  String? _error;
  double _downloadProgress = 0.0;

  DataProvider(this._dataSyncService, this._simpleDataSyncService);

  bool get isLoading => _isLoading;
  String? get error => _error;
  double get downloadProgress => _downloadProgress;
  DataSyncService get dataSyncService => _dataSyncService;
  SimpleDataSyncService get simpleDataSyncService => _simpleDataSyncService;

  set downloadProgress(double value) {
    _downloadProgress = value;
    notifyListeners();
  }

  // تابع اطلاع‌رسانی به‌روزرسانی داده‌ها
  void notifyDataUpdated() {
    notifyListeners();
  }

  Future<void> refreshData() async {
    try {
      _isLoading = true;
      _downloadProgress = 0.0;
      _error = null;
      notifyListeners();

      // ابتدا وضعیت فعلی را بررسی کنیم
      final currentStatus = _simpleDataSyncService.getSyncStatus();

      // بررسی اتصال اینترنت قبل از شروع
      final hasInternet =
          await _simpleDataSyncService.checkInternetConnection();
      if (!hasInternet) {
        // بررسی داده‌های محلی موجود
        final productionData = _simpleDataSyncService.getProductionData();
        final stopData = _simpleDataSyncService.getStopData();

        if (productionData.isNotEmpty || stopData.isNotEmpty) {
          // اگر داده محلی موجود است، فقط هشدار نمایش دهیم و ادامه دهیم
        } else {
          _error =
              '❌ اتصال به اینترنت برقرار نیست\n\nلطفاً موارد زیر را بررسی کنید:\n• اتصال WiFi یا موبایل\n• فیلترشکن (در صورت نیاز)\n• تنظیمات DNS دستگاه\n\n⚠️ هیچ داده‌ای در حافظه محلی موجود نیست';
          return;
        }
      }

      // استفاده از SimpleDataSyncService برای همگام‌سازی
      await _simpleDataSyncService.init();
      await _simpleDataSyncService.syncAllData(
        onProgress: (progress) {
          _downloadProgress = progress;
          notifyListeners();
        },
      );

      // بررسی نتیجه همگام‌سازی
      final syncStatus = _simpleDataSyncService.getSyncStatus();

      // بررسی اینکه آیا داده‌ای ذخیره شده است
      final productionData = _simpleDataSyncService.getProductionData();
      final stopData = _simpleDataSyncService.getStopData();

      if (productionData.isEmpty && stopData.isEmpty) {
        final lastError = _simpleDataSyncService.getLastSyncError();
        String errorMessage;
        if (lastError != null && lastError.contains('Failed host lookup')) {
          errorMessage =
              '❌ سرور در دسترس نیست\n\nمشکل: سرور sechahoon.liara.run قابل دسترسی نیست\n\nراه‌حل‌ها:\n• اتصال اینترنت را بررسی کنید\n• از فیلترشکن استفاده کنید\n• بعداً دوباره تلاش کنید';
        } else if (lastError != null && lastError.contains('403')) {
          errorMessage =
              '🚫 دسترسی به سرور مسدود شده\n\nمشکل: سرور دسترسی را رد کرد (خطای 403)\n\nراه‌حل‌ها:\n• از فیلترشکن استفاده کنید\n• VPN فعال کنید\n• DNS دستگاه را تغییر دهید\n• بعداً دوباره تلاش کنید';
        } else {
          errorMessage =
              '❌ هیچ داده‌ای دریافت نشد\n\nلطفاً موارد زیر را بررسی کنید:\n• اتصال اینترنت\n• وضعیت سرور\n• دوباره تلاش کنید';
        }
        _error = errorMessage;
        throw Exception(errorMessage);
      } else {
        final lastError = _simpleDataSyncService.getLastSyncError();
        if (lastError != null) {
          _error = lastError;
          throw Exception(lastError);
        } else {
          _error = null;
        }
      }
    } catch (e) {
      final errorMessage = e.toString();
      if (errorMessage.contains('Failed host lookup')) {
        _error =
            '❌ سرور در دسترس نیست\n\nمشکل: سرور sechahoon.liara.run قابل دسترسی نیست\n\nراه‌حل‌ها:\n• اتصال اینترنت را بررسی کنید\n• از فیلترشکن استفاده کنید\n• بعداً دوباره تلاش کنید';
      } else if (errorMessage.contains('timeout')) {
        _error =
            '⏰ زمان اتصال به سرور تمام شد\n\nلطفاً:\n• اتصال اینترنت را بررسی کنید\n• دوباره تلاش کنید';
      } else {
        _error = '❌ خطا در به‌روزرسانی داده‌ها\n\nخطا: $errorMessage';
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<ProductionData> getProductionData() {
    try {
      // استفاده از SimpleDataSyncService برای دریافت داده‌های تولید
      final data = _simpleDataSyncService.getProductionData();
      print('دریافت ${data.length} رکورد تولید از SimpleDataSyncService');
      return data;
    } catch (e) {
      print('❌ خطا در دریافت داده‌های تولید: $e');
      // در صورت خطای Hive، لیست خالی برگردان
      return [];
    }
  }

  List<StopData> getStopData() {
    try {
      // استفاده از SimpleDataSyncService که داده‌های توقف واقعی دارد
      final data = _simpleDataSyncService.getStopData();
      print('دریافت ${data.length} رکورد توقف از SimpleDataSyncService');
      return data;
    } catch (e) {
      print('❌ خطا در دریافت داده‌های توقف: $e');
      // در صورت خطای Hive، لیست خالی برگردان
      return [];
    }
  }

  List<StopData> getStopDataByDateRange(DateTime startDate, DateTime endDate) {
    // استفاده از SimpleDataSyncService که داده‌های توقف واقعی دارد
    final data =
        _simpleDataSyncService.getStopDataByDateRange(startDate, endDate);

    return data;
  }

  List<ShiftInfo> getShiftInfo() {
    // استفاده از SimpleDataSyncService برای سازگاری
    final data = _simpleDataSyncService.getShiftInfo();

    return data;
  }

  List<GradeData> getGradeData() {
    final data = _simpleDataSyncService.getGradeData();

    return data;
  }

  List<ProductionData> getProductionDataByDateRange(
      DateTime startDate, DateTime endDate) {
    final allData = getProductionData();
    final filteredData = allData.where((item) {
      final itemDate = DateTime(item.year, item.month, item.day);
      return itemDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
          itemDate.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();

    return filteredData;
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> clearAllData() async {
    // استفاده از SimpleDataSyncService
    await _simpleDataSyncService.clearAllData();
    notifyListeners();
  }

  // متد جدید برای بررسی وضعیت داده‌ها
  Map<String, dynamic> getDataStatus() {
    final productionData = getProductionData();
    final stopData = getStopData();
    final shiftInfo = getShiftInfo();

    return {
      'productionCount': productionData.length,
      'stopCount': stopData.length,
      'shiftCount': shiftInfo.length,
      'hasData': productionData.isNotEmpty ||
          stopData.isNotEmpty ||
          shiftInfo.isNotEmpty,
      'lastSyncError': _simpleDataSyncService.getLastSyncError(),
      'lastSyncTime':
          _simpleDataSyncService.getLastSyncTime()?.toIso8601String(),
    };
  }

  // متد جدید برای همگام‌سازی کامل داده‌ها
  Future<void> forceFullSync() async {
    try {
      _isLoading = true;
      _downloadProgress = 0.0;
      _error = null;
      notifyListeners();

      // پاک کردن تمام داده‌های موجود
      await _simpleDataSyncService.clearAllData();

      // همگام‌سازی مجدد
      await _simpleDataSyncService.init();
      await _simpleDataSyncService.syncAllData(
        onProgress: (progress) {
          _downloadProgress = progress;
          notifyListeners();
        },
      );

      // بررسی نتیجه
      final syncStatus = _simpleDataSyncService.getSyncStatus();

      final productionData = _simpleDataSyncService.getProductionData();
      final stopData = _simpleDataSyncService.getStopData();

      if (productionData.isEmpty && stopData.isEmpty) {
        _error =
            'هیچ داده‌ای در همگام‌سازی کامل دریافت نشد. لطفاً اتصال اینترنت را بررسی کنید.';
      } else {
        _error = _simpleDataSyncService.getLastSyncError();
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
