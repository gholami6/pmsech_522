import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class SimpleApiService extends ChangeNotifier {
  // آدرس API جدید ساده
  static const String _baseUrl = 'https://sechah.liara.run';
  static const String _apiEndpoint = '/simple_xlsx_to_json.php';

  bool _isSyncing = false;
  String? _lastError;
  DateTime? _lastSyncTime;

  bool get isSyncing => _isSyncing;
  String? get lastError => _lastError;
  DateTime? get lastSyncTime => _lastSyncTime;

  /// بررسی اتصال اینترنت
  Future<bool> _checkInternetConnection() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      return connectivityResult != ConnectivityResult.none;
    } catch (e) {
      print('خطا در بررسی اتصال اینترنت: $e');
      return false;
    }
  }

  /// دریافت داده‌ها از API جدید
  Future<Map<String, dynamic>> fetchData({String? type}) async {
    if (_isSyncing) {
      throw Exception('همگام‌سازی در حال انجام است');
    }

    try {
      _isSyncing = true;
      _lastError = null;
      notifyListeners();

      // بررسی اتصال اینترنت
      final hasInternet = await _checkInternetConnection();
      if (!hasInternet) {
        throw Exception('اتصال به اینترنت برقرار نیست');
      }

      // ساخت URL
      String url = '$_baseUrl$_apiEndpoint';
      if (type != null) {
        url += '?type=$type';
      }

      print('درخواست به: $url');

      // ارسال درخواست
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      print('کد پاسخ: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true) {
          _lastSyncTime = DateTime.now();
          print('دریافت داده‌ها موفقیت‌آمیز بود');
          return data;
        } else {
          throw Exception(data['error'] ?? 'خطای ناشناخته از سرور');
        }
      } else {
        throw Exception('خطای سرور: ${response.statusCode}');
      }
    } catch (e) {
      _lastError = e.toString();
      print('خطا در دریافت داده‌ها: $e');
      rethrow;
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  /// دریافت فقط داده‌های تولید
  Future<List<Map<String, dynamic>>> getProductionData() async {
    try {
      final response = await fetchData(type: 'production');
      final data = response['data'];

      if (data is List) {
        return List<Map<String, dynamic>>.from(data);
      } else if (data is Map && data['production'] != null) {
        return List<Map<String, dynamic>>.from(data['production']);
      }

      return [];
    } catch (e) {
      print('خطا در دریافت داده‌های تولید: $e');
      return [];
    }
  }

  /// دریافت فقط داده‌های تجهیزات
  Future<List<Map<String, dynamic>>> getEquipmentData() async {
    try {
      final response = await fetchData(type: 'equipment');
      final data = response['data'];

      if (data is List) {
        return List<Map<String, dynamic>>.from(data);
      } else if (data is Map && data['equipment'] != null) {
        return List<Map<String, dynamic>>.from(data['equipment']);
      }

      return [];
    } catch (e) {
      print('خطا در دریافت داده‌های تجهیزات: $e');
      return [];
    }
  }

  /// دریافت همه داده‌ها
  Future<Map<String, List<Map<String, dynamic>>>> getAllData() async {
    try {
      final response = await fetchData();
      final data = response['data'];

      Map<String, List<Map<String, dynamic>>> result = {
        'production': [],
        'equipment': [],
      };

      if (data is Map) {
        if (data['production'] != null) {
          result['production'] =
              List<Map<String, dynamic>>.from(data['production']);
        }
        if (data['equipment'] != null) {
          result['equipment'] =
              List<Map<String, dynamic>>.from(data['equipment']);
        }
      }

      return result;
    } catch (e) {
      print('خطا در دریافت همه داده‌ها: $e');
      return {
        'production': [],
        'equipment': [],
      };
    }
  }

  /// تست اتصال به API
  Future<bool> testConnection() async {
    try {
      final hasInternet = await _checkInternetConnection();
      if (!hasInternet) return false;

      final response = await http.get(
        Uri.parse('$_baseUrl$_apiEndpoint'),
        headers: {'Content-Type': 'application/json; charset=utf-8'},
      ).timeout(const Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (e) {
      print('خطا در تست اتصال: $e');
      return false;
    }
  }

  /// بررسی وضعیت سرویس
  Map<String, dynamic> getStatus() {
    return {
      'isOnline': _lastError == null,
      'isSyncing': _isSyncing,
      'lastSyncTime': _lastSyncTime?.toIso8601String(),
      'lastError': _lastError,
      'apiUrl': '$_baseUrl$_apiEndpoint',
    };
  }

  /// پاک کردن خطاها
  void clearErrors() {
    _lastError = null;
    notifyListeners();
  }
}
