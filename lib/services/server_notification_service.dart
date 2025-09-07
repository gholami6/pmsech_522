import 'dart:convert';
import 'package:http/http.dart' as http;

class ServerNotificationService {
  static const String baseUrl = 'http://62.60.198.11';
  static const String apiEndpoint = '$baseUrl/notification_server.php';

  // کش اتصال برای جلوگیری از تست‌های مکرر
  static DateTime? _lastConnectionTest;
  static bool? _lastConnectionResult;
  static const Duration _connectionCacheTimeout = Duration(minutes: 2);

  static Future<bool> testConnection() async {
    // بررسی کش
    if (_lastConnectionTest != null &&
        _lastConnectionResult != null &&
        DateTime.now().difference(_lastConnectionTest!) <
            _connectionCacheTimeout) {
      print('🔄 استفاده از کش اتصال: $_lastConnectionResult');
      return _lastConnectionResult!;
    }

    try {
      print('🌐 ServerNotificationService: تست اتصال (${DateTime.now()})');

      final response = await http
          .head(Uri.parse(baseUrl)) // استفاده از HEAD برای سرعت بیشتر
          .timeout(const Duration(seconds: 3));

      final isConnected = response.statusCode < 500;

      // ذخیره در کش
      _lastConnectionTest = DateTime.now();
      _lastConnectionResult = isConnected;

      if (isConnected) {
        print('✅ اتصال موفق (cached)');
      } else {
        print('❌ خطای HTTP: ${response.statusCode}');
      }

      return isConnected;
    } catch (e) {
      print('❌ خطا در اتصال: $e');
      _lastConnectionTest = DateTime.now();
      _lastConnectionResult = false;
      return false;
    }
  }

  static Future<String> sendNotificationToAll({
    required String title,
    required String message,
    String type = 'general',
    Map<String, dynamic>? data,
    String? senderUserId,
  }) async {
    try {
      print('🌐 ServerNotificationService: ارسال نوتیفیکیشن به تمام کاربران');

      final requestBody = {
        'action': 'send_notification_to_all',
        'title': title,
        'message': message,
        'type': type,
        'data': {
          ...?data,
          if (senderUserId != null) 'user_id': senderUserId,
        },
      };

      final response = await http
          .post(
            Uri.parse(apiEndpoint),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(requestBody),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);

        if (result['success']) {
          print(
              '✅ نوتیفیکیشن با موفقیت ارسال شد. ID: ${result['notification_id']}');
          return result['notification_id'];
        } else {
          print('❌ خطا از سرور: ${result['message']}');
          throw Exception(result['message'] ?? 'خطا در ارسال نوتیفیکیشن');
        }
      } else {
        print('❌ خطای HTTP: ${response.statusCode}');
        throw Exception('خطا در ارتباط با سرور (کد: ${response.statusCode})');
      }
    } catch (e) {
      print('❌ Exception در sendNotificationToAll: $e');
      throw Exception('خطا در ارسال نوتیفیکیشن: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getNotificationsForUser({
    required String userId,
    String? lastSyncTime,
  }) async {
    try {
      final requestBody = {
        'action': 'get_notifications_for_user',
        'user_id': userId,
        'last_sync_time': lastSyncTime,
      };

      final response = await http
          .post(
            Uri.parse(apiEndpoint),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(requestBody),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);

        if (result['success']) {
          final notifications =
              List<Map<String, dynamic>>.from(result['notifications'] ?? []);
          print('✅ تعداد نوتیفیکیشن‌های دریافت شده: ${notifications.length}');
          return notifications;
        } else {
          print('❌ خطا از سرور: ${result['message']}');
          throw Exception(result['message'] ?? 'خطا در دریافت نوتیفیکیشن‌ها');
        }
      } else {
        print('❌ خطای HTTP: ${response.statusCode}');
        throw Exception('خطا در ارتباط با سرور (کد: ${response.statusCode})');
      }
    } catch (e) {
      print('❌ Exception در getNotificationsForUser: $e');
      throw Exception('خطا در دریافت نوتیفیکیشن‌ها: $e');
    }
  }

  static Future<void> markNotificationAsRead({
    required String notificationId,
    required String userId,
  }) async {
    try {
      final requestBody = {
        'action': 'mark_notification_as_read',
        'notification_id': notificationId,
        'user_id': userId,
      };

      final response = await http
          .post(
            Uri.parse(apiEndpoint),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(requestBody),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);

        if (result['success']) {
          print('✅ نوتیفیکیشن به عنوان خوانده شده علامت‌گذاری شد');
        } else {
          print('❌ خطا از سرور: ${result['message']}');
          throw Exception(result['message'] ?? 'خطا در علامت‌گذاری نوتیفیکیشن');
        }
      } else {
        print('❌ خطای HTTP: ${response.statusCode}');
        throw Exception('خطا در ارتباط با سرور (کد: ${response.statusCode})');
      }
    } catch (e) {
      print('❌ Exception در markNotificationAsRead: $e');
      throw Exception('خطا در علامت‌گذاری نوتیفیکیشن: $e');
    }
  }
}
