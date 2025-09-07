import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/alert_notification.dart';
import '../models/alert_reply.dart';
import '../models/user_seen_status.dart';

class ServerAlertService {
  static const String baseUrl = 'http://62.60.198.11';
  static const String apiEndpoint = '$baseUrl/alert_api.php';

  static Future<bool> testConnection() async {
    try {
      print('🌐 ServerAlertService: تست اتصال سرور اعلان‌ها');

      final response = await http
          .post(
            Uri.parse(apiEndpoint),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'action': 'get_alerts'}),
          )
          .timeout(const Duration(seconds: 5)); // کاهش timeout

      if (response.statusCode == 200) {
        print('✅ اتصال سرور اعلان‌ها موفق');
        return true;
      } else {
        print('❌ خطای HTTP: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ خطا در تست اتصال سرور اعلان‌ها: $e');
      return false;
    }
  }

  static Future<String> createAlert({
    required String userId,
    required String equipmentId,
    required String message,
    String? attachmentPath,
    String? category,
    bool? allowReplies,
  }) async {
    try {
      print('🌐 ServerAlertService: شروع ایجاد اعلان');

      final requestBody = {
        'action': 'create_alert',
        'user_id': userId,
        'equipment_id': equipmentId,
        'message': message,
        'attachment_path': attachmentPath,
        'category': category ?? 'عمومی',
        'allow_replies': allowReplies ?? true,
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
          print('✅ اعلان با موفقیت ایجاد شد. ID: ${result['alert_id']}');
          return result['alert_id'];
        } else {
          print('❌ خطا از سرور: ${result['message']}');
          throw Exception(result['message'] ?? 'خطا در ایجاد اعلان');
        }
      } else {
        print('❌ خطای HTTP: ${response.statusCode}');
        throw Exception('خطا در ارتباط با سرور (کد: ${response.statusCode})');
      }
    } catch (e) {
      print('❌ Exception در createAlert: $e');
      throw Exception('خطا در ایجاد اعلان: $e');
    }
  }

  static Future<List<AlertNotification>> getAllAlerts() async {
    try {
      print('🌐 ServerAlertService: شروع دریافت اعلان‌ها');

      final requestBody = {'action': 'get_alerts'};

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
          final alertsData = result['alerts'] as List;
          final alerts = alertsData.map((data) {
            return AlertNotification(
              id: data['id'],
              userId: data['user_id'],
              equipmentId: data['equipment_id'],
              message: data['message'],
              attachmentPath: data['attachment_path'],
              createdAt: DateTime.parse(data['created_at']),
              seenBy: _parseSeenBy(data['seen_by'] ?? {}),
              replies: _parseReplies(data['replies'] ?? []),
              category: data['category'] ?? 'عمومی',
            );
          }).toList();

          print('✅ تعداد اعلان‌های دریافت شده: ${alerts.length}');
          return alerts;
        } else {
          print('❌ خطا از سرور: ${result['message']}');
          throw Exception(result['message'] ?? 'خطا در دریافت اعلان‌ها');
        }
      } else {
        print('❌ خطای HTTP: ${response.statusCode}');
        throw Exception('خطا در ارتباط با سرور (کد: ${response.statusCode})');
      }
    } catch (e) {
      print('❌ Exception در getAllAlerts: $e');
      throw Exception('خطا در دریافت اعلان‌ها: $e');
    }
  }

  static Future<void> addReply({
    required String alertId,
    required String userId,
    required String message,
  }) async {
    try {
      final requestBody = {
        'action': 'add_reply',
        'alert_id': alertId,
        'user_id': userId,
        'message': message,
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
          print('✅ پاسخ با موفقیت به سرور ارسال شد');
        } else {
          print('❌ خطا از سرور: ${result['message']}');
          throw Exception(result['message'] ?? 'خطا در ارسال پاسخ');
        }
      } else {
        print('❌ خطای HTTP: ${response.statusCode}');
        throw Exception('خطا در ارتباط با سرور (کد: ${response.statusCode})');
      }
    } catch (e) {
      print('❌ Exception در addReply: $e');
      throw Exception('خطا در ارسال پاسخ: $e');
    }
  }

  static Future<void> markAsSeen({
    required String alertId,
    required String userId,
  }) async {
    try {
      final requestBody = {
        'action': 'mark_as_seen',
        'alert_id': alertId,
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
          print('✅ وضعیت مشاهده با موفقیت به سرور ارسال شد');
        } else {
          final errorMessage = result['message'] ?? 'خطا در ارسال وضعیت مشاهده';
          print('❌ خطا از سرور: $errorMessage');

          // اگر اعلان در سرور وجود ندارد، خطا ندهیم (احتمالاً حذف شده)
          if (errorMessage.contains('یافت نشد') ||
              errorMessage.contains('not found')) {
            print('⚠️ اعلان در سرور وجود ندارد (احتمالاً حذف شده)');
            return; // بدون خطا ادامه دهیم
          }

          throw Exception(errorMessage);
        }
      } else {
        print('❌ خطای HTTP: ${response.statusCode}');
        throw Exception('خطا در ارتباط با سرور (کد: ${response.statusCode})');
      }
    } catch (e) {
      print('❌ Exception در markAsSeen: $e');
      throw Exception('خطا در ارسال وضعیت مشاهده: $e');
    }
  }

  static Future<void> deleteAlert({
    required String alertId,
    required String userId,
  }) async {
    try {
      final requestBody = {
        'action': 'delete_alert',
        'alert_id': alertId,
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
          print('✅ اعلان با موفقیت از سرور حذف شد');
        } else {
          final errorMessage = result['message'] ?? 'خطا در حذف اعلان';
          print('❌ خطا از سرور: $errorMessage');

          // اگر اعلان در سرور وجود ندارد، خطا ندهیم (احتمالاً قبلاً حذف شده)
          if (errorMessage.contains('یافت نشد') ||
              errorMessage.contains('not found')) {
            print('⚠️ اعلان در سرور وجود ندارد (احتمالاً قبلاً حذف شده)');
            return; // بدون خطا ادامه دهیم
          }

          throw Exception(errorMessage);
        }
      } else {
        print('❌ خطای HTTP: ${response.statusCode}');
        throw Exception('خطا در ارتباط با سرور (کد: ${response.statusCode})');
      }
    } catch (e) {
      print('❌ Exception در deleteAlert: $e');
      throw Exception('خطا در حذف اعلان: $e');
    }
  }

  static Future<void> updateAlert({
    required String alertId,
    required String userId,
    required String message,
    String? equipmentId,
    String? category,
  }) async {
    try {
      final requestBody = {
        'action': 'update_alert',
        'alert_id': alertId,
        'user_id': userId,
        'message': message,
        'equipment_id': equipmentId,
        'category': category ?? 'عمومی',
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
          print('✅ اعلان با موفقیت در سرور به‌روزرسانی شد');
        } else {
          final errorMessage = result['message'] ?? 'خطا در به‌روزرسانی اعلان';
          print('❌ خطا از سرور: $errorMessage');

          // اگر اعلان در سرور وجود ندارد، خطا ندهیم (احتمالاً حذف شده)
          if (errorMessage.contains('یافت نشد') ||
              errorMessage.contains('not found')) {
            print('⚠️ اعلان در سرور وجود ندارد (احتمالاً حذف شده)');
            return; // بدون خطا ادامه دهیم
          }

          throw Exception(errorMessage);
        }
      } else {
        print('❌ خطای HTTP: ${response.statusCode}');
        throw Exception('خطا در ارتباط با سرور (کد: ${response.statusCode})');
      }
    } catch (e) {
      print('❌ Exception در updateAlert: $e');
      throw Exception('خطا در به‌روزرسانی اعلان: $e');
    }
  }

  static Map<String, UserSeenStatus> _parseSeenBy(dynamic seenByData) {
    try {
      final seenBy = <String, UserSeenStatus>{};

      if (seenByData == null) {
        return seenBy;
      }

      if (seenByData is Map<String, dynamic>) {
        seenByData.forEach((userId, data) {
          if (data is Map<String, dynamic>) {
            seenBy[userId] = UserSeenStatus(
              seen: (data['seen'] ?? false) as bool,
              seenAt: data['seen_at'] != null
                  ? DateTime.parse(data['seen_at'] as String)
                  : DateTime.now(),
            );
          }
        });
        return seenBy;
      }

      if (seenByData is List) {
        for (final item in seenByData) {
          if (item is String) {
            seenBy[item] = UserSeenStatus(seen: true, seenAt: DateTime.now());
          } else if (item is Map<String, dynamic>) {
            final String? userId = item['user_id'] as String?;
            if (userId != null && userId.isNotEmpty) {
              seenBy[userId] = UserSeenStatus(
                seen: (item['seen'] ?? true) as bool,
                seenAt: item['seen_at'] != null
                    ? DateTime.parse(item['seen_at'] as String)
                    : DateTime.now(),
              );
            }
          }
        }
        return seenBy;
      }

      return <String, UserSeenStatus>{};
    } catch (e) {
      print('⚠️ ServerAlertService._parseSeenBy: $e');
      return <String, UserSeenStatus>{};
    }
  }

  static List<AlertReply> _parseReplies(List<dynamic> repliesData) {
    return repliesData.map((data) {
      return AlertReply(
        userId: data['user_id'],
        message: data['message'],
        createdAt: data['created_at'] != null
            ? DateTime.parse(data['created_at'])
            : DateTime.now(),
      );
    }).toList();
  }

  static Future<AlertNotification?> getAlertById(String alertId) async {
    try {
      final allAlerts = await getAllAlerts();
      return allAlerts.firstWhere(
        (alert) => alert.id == alertId,
        orElse: () => throw Exception('اعلان یافت نشد'),
      );
    } catch (e) {
      print('❌ خطا در دریافت اعلان: $e');
      return null;
    }
  }

  static Future<int> getUnseenCount(String userId) async {
    try {
      final allAlerts = await getAllAlerts();
      return allAlerts
          .where((alert) =>
              !alert.seenBy.containsKey(userId) && alert.userId != userId)
          .length;
    } catch (e) {
      print('❌ خطا در دریافت تعداد اعلان‌های نخوانده: $e');
      return 0;
    }
  }
}
