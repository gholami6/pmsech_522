import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';

/// مدیریت مرکزی اتصالات شبکه با بهینه‌سازی و کش
class ConnectionManager {
  static final ConnectionManager _instance = ConnectionManager._internal();
  factory ConnectionManager() => _instance;
  ConnectionManager._internal();

  // تنظیمات کش
  static const Duration _cacheTimeout = Duration(minutes: 1);
  static const Duration _fastTimeout = Duration(seconds: 2);
  static const Duration _normalTimeout = Duration(seconds: 5);

  // کش اتصالات
  final Map<String, _ConnectionCache> _connectionCache = {};

  // HTTP Client مشترک
  http.Client? _httpClient;

  void init() {
    _httpClient ??= http.Client();
  }

  void dispose() {
    _httpClient?.close();
    _connectionCache.clear();
  }

  /// تست سریع اتصال اینترنت
  Future<bool> hasInternetConnection() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      return connectivityResult != ConnectivityResult.none;
    } catch (e) {
      return false;
    }
  }

  /// تست اتصال به سرور با کش
  Future<bool> testServerConnection(String baseUrl,
      {bool useCache = true}) async {
    final cacheKey = 'server_$baseUrl';

    // بررسی کش
    if (useCache && _connectionCache.containsKey(cacheKey)) {
      final cache = _connectionCache[cacheKey]!;
      if (DateTime.now().difference(cache.timestamp) < _cacheTimeout) {
        return cache.isConnected;
      }
    }

    bool isConnected = false;
    try {
      final response =
          await _httpClient!.head(Uri.parse(baseUrl)).timeout(_fastTimeout);

      isConnected = response.statusCode < 500;
    } catch (e) {
      isConnected = false;
    }

    // ذخیره در کش
    _connectionCache[cacheKey] = _ConnectionCache(
      isConnected: isConnected,
      timestamp: DateTime.now(),
    );

    return isConnected;
  }

  /// درخواست HTTP بهینه‌سازی شده
  Future<http.Response> optimizedRequest({
    required String url,
    required String method,
    Map<String, String>? headers,
    String? body,
    Duration? timeout,
    int maxRetries = 2,
  }) async {
    final effectiveTimeout = timeout ?? _normalTimeout;
    Exception? lastError;

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        final uri = Uri.parse(url);
        final request = http.Request(method.toUpperCase(), uri);

        // تنظیم headers بهینه
        request.headers.addAll({
          'User-Agent': 'PMSechApp/3.0',
          'Accept': 'application/json',
          'Connection': 'keep-alive',
          'Cache-Control': 'no-cache',
          ...?headers,
        });

        if (body != null) {
          request.body = body;
        }

        final streamedResponse =
            await _httpClient!.send(request).timeout(effectiveTimeout);

        final response = await http.Response.fromStream(streamedResponse);

        if (response.statusCode < 500) {
          return response;
        } else {
          throw http.ClientException('Server error: ${response.statusCode}');
        }
      } catch (e) {
        lastError = e is Exception ? e : Exception(e.toString());

        if (attempt < maxRetries) {
          // انتظار کوتاه بین تلاش‌ها
          await Future.delayed(Duration(milliseconds: 200 * attempt));
        }
      }
    }

    throw lastError ?? Exception('تمام تلاش‌ها ناموفق بود');
  }

  /// GET request بهینه‌سازی شده
  Future<http.Response> get(
    String url, {
    Map<String, String>? headers,
    Duration? timeout,
    int maxRetries = 2,
  }) async {
    return optimizedRequest(
      url: url,
      method: 'GET',
      headers: headers,
      timeout: timeout,
      maxRetries: maxRetries,
    );
  }

  /// POST request بهینه‌سازی شده
  Future<http.Response> post(
    String url, {
    Map<String, String>? headers,
    String? body,
    Duration? timeout,
    int maxRetries = 2,
  }) async {
    return optimizedRequest(
      url: url,
      method: 'POST',
      headers: headers,
      body: body,
      timeout: timeout,
      maxRetries: maxRetries,
    );
  }

  /// HEAD request بهینه‌سازی شده
  Future<http.Response> head(
    String url, {
    Map<String, String>? headers,
    Duration? timeout,
  }) async {
    return optimizedRequest(
      url: url,
      method: 'HEAD',
      headers: headers,
      timeout: timeout ?? _fastTimeout,
      maxRetries: 1,
    );
  }

  /// پاک کردن کش اتصالات
  void clearCache() {
    _connectionCache.clear();
  }

  /// نمایش وضعیت کش
  Map<String, dynamic> getCacheStatus() {
    return {
      'total_entries': _connectionCache.length,
      'cache_timeout_minutes': _cacheTimeout.inMinutes,
      'entries': _connectionCache.map((key, value) => MapEntry(
            key,
            {
              'is_connected': value.isConnected,
              'age_seconds':
                  DateTime.now().difference(value.timestamp).inSeconds,
            },
          )),
    };
  }
}

/// کلاس کش اتصال
class _ConnectionCache {
  final bool isConnected;
  final DateTime timestamp;

  _ConnectionCache({
    required this.isConnected,
    required this.timestamp,
  });
}
