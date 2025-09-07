import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../models/manager_alert.dart';
import '../models/alert_reply.dart';
import '../models/user_seen_status.dart';

class ServerManagerAlertService {
  static const String baseUrl = 'http://62.60.198.11';
  static const String apiEndpoint = '$baseUrl/manager_alert_api.php';

  static Future<bool> testConnection() async {
    try {
      print('🌐 ServerManagerAlertService: تست اتصال سرور');

      // تست اولیه اتصال
      final testResponse = await http
          .get(Uri.parse('http://62.60.198.11'))
          .timeout(const Duration(seconds: 2));

      if (testResponse.statusCode != 200) {
        print('❌ سرور اصلی در دسترس نیست: ${testResponse.statusCode}');
        return false;
      }

      final response = await http
          .post(
            Uri.parse(apiEndpoint),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'action': 'test_connection'}),
          )
          .timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        print('✅ اتصال سرور اعلان‌های مدیریت موفق');
        return true;
      } else {
        print('❌ خطا در اتصال سرور: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ خطا در تست اتصال سرور اعلان‌های مدیریت: $e');

      if (e is SocketException) {
        print('🔧 مشکل شبکه: ${e.message}');
      } else if (e is TimeoutException) {
        print('⏰ مشکل تایم‌اوت: سرور پاسخ نمی‌دهد');
      }

      return false;
    }
  }

  static Future<String> createManagerAlert({
    required String userId,
    required String title,
    required String message,
    required String category,
    required List<String> targetStakeholderTypes,
    required List<String> targetRoleTypes,
    String? attachmentPath,
  }) async {
    try {
      print('🌐 ServerManagerAlertService: شروع ایجاد اعلان مدیریت');

      final requestBody = {
        'action': 'create_manager_alert',
        'user_id': userId,
        'title': title,
        'message': message,
        'category': category,
        'target_stakeholder_types': targetStakeholderTypes,
        'target_role_types': targetRoleTypes,
        'attachment_path': attachmentPath,
      };

      final response = await http
          .post(
            Uri.parse(apiEndpoint),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(requestBody),
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);

        if (result['success']) {
          print('✅ اعلان مدیریت با موفقیت ایجاد شد. ID: ${result['alert_id']}');
          return result['alert_id'];
        } else {
          print('❌ خطا از سرور: ${result['message']}');
          throw Exception(result['message'] ?? 'خطا در ایجاد اعلان مدیریت');
        }
      } else {
        print('❌ خطای HTTP: ${response.statusCode}');
        throw Exception('خطا در ارتباط با سرور (کد: ${response.statusCode})');
      }
    } catch (e) {
      print('❌ Exception در createManagerAlert: $e');
      throw Exception('خطا در ایجاد اعلان مدیریت: $e');
    }
  }

  static Future<List<ManagerAlert>> getAllManagerAlerts() async {
    int retryCount = 0;
    const maxRetries = 2;

    while (retryCount <= maxRetries) {
      try {
        print(
            '🌐 ServerManagerAlertService: شروع دریافت اعلان‌های مدیریت (تلاش ${retryCount + 1})');

        final requestBody = {'action': 'get_manager_alerts'};

        final response = await http
            .post(
              Uri.parse(apiEndpoint),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(requestBody),
            )
            .timeout(const Duration(seconds: 5));

        if (response.statusCode == 200) {
          final result = jsonDecode(response.body);

          if (result['success']) {
            final alertsData = result['alerts'] as List;
            final alerts = alertsData.map((data) {
              return ManagerAlert(
                id: data['id'],
                userId: data['user_id'],
                title: data['title'],
                message: data['message'],
                category: data['category'],
                attachmentPath: data['attachment_path'],
                createdAt: DateTime.parse(data['created_at']),
                targetStakeholderTypes:
                    List<String>.from(data['target_stakeholder_types'] ?? []),
                targetRoleTypes:
                    List<String>.from(data['target_role_types'] ?? []),
                allowReplies: data['allow_replies'] ?? true,
                seenBy: ManagerAlert.parseSeenBy(data['seen_by'] ?? {}),
                replies: _parseReplies(data['replies'] ?? []),
              );
            }).toList();

            print('✅ تعداد اعلان‌های مدیریت دریافت شده: ${alerts.length}');
            return alerts;
          } else {
            print('❌ خطا از سرور: ${result['message']}');
            throw Exception(
                result['message'] ?? 'خطا در دریافت اعلان‌های مدیریت');
          }
        } else {
          print('❌ خطای HTTP: ${response.statusCode}');
          throw Exception('خطا در ارتباط با سرور (کد: ${response.statusCode})');
        }
      } catch (e) {
        retryCount++;
        if (retryCount > maxRetries) {
          print('❌ Exception در getAllManagerAlerts (تلاش ${retryCount}): $e');
          throw Exception('خطا در دریافت اعلان‌های مدیریت: $e');
        }
        print('⚠️ تلاش ${retryCount} ناموفق بود، تلاش مجدد...');
        await Future.delayed(Duration(seconds: retryCount)); // تاخیر افزایشی
      }
    }

    throw Exception('خطا در دریافت اعلان‌های مدیریت: تعداد تلاش‌ها تمام شد');
  }

  static Future<void> addReplyToManagerAlert({
    required String alertId,
    required String userId,
    required String message,
  }) async {
    try {
      final requestBody = {
        'action': 'add_manager_reply',
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
          .timeout(const Duration(seconds: 8));

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
      print('❌ Exception در addReplyToManagerAlert: $e');
      throw Exception('خطا در ارسال پاسخ: $e');
    }
  }

  static Future<void> markManagerAlertAsSeen({
    required String alertId,
    required String userId,
  }) async {
    try {
      final requestBody = {
        'action': 'mark_manager_alert_as_seen',
        'alert_id': alertId,
        'user_id': userId,
      };

      final response = await http
          .post(
            Uri.parse(apiEndpoint),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(requestBody),
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);

        if (result['success']) {
          print('✅ وضعیت مشاهده با موفقیت به سرور ارسال شد');
        } else {
          print('❌ خطا از سرور: ${result['message']}');
          throw Exception(result['message'] ?? 'خطا در ارسال وضعیت مشاهده');
        }
      } else {
        print('❌ خطای HTTP: ${response.statusCode}');
        throw Exception('خطا در ارتباط با سرور (کد: ${response.statusCode})');
      }
    } catch (e) {
      print('❌ Exception در markManagerAlertAsSeen: $e');
      throw Exception('خطا در ارسال وضعیت مشاهده: $e');
    }
  }

  static Future<void> deleteManagerAlert({
    required String alertId,
    required String userId,
  }) async {
    try {
      final requestBody = {
        'action': 'delete_manager_alert',
        'alert_id': alertId,
      };

      final response = await http
          .post(
            Uri.parse(apiEndpoint),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(requestBody),
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);

        if (result['success']) {
          print('✅ اعلان مدیریت با موفقیت از سرور حذف شد');
        } else {
          print('❌ خطا از سرور: ${result['message']}');
          throw Exception(result['message'] ?? 'خطا در حذف اعلان مدیریت');
        }
      } else {
        print('❌ خطای HTTP: ${response.statusCode}');
        throw Exception('خطا در ارتباط با سرور (کد: ${response.statusCode})');
      }
    } catch (e) {
      print('❌ Exception در deleteManagerAlert: $e');
      throw Exception('خطا در حذف اعلان مدیریت: $e');
    }
  }

  static Future<void> updateManagerAlert({
    required String alertId,
    required String userId,
    required String title,
    required String message,
    required String category,
    required List<String> targetStakeholderTypes,
    required List<String> targetRoleTypes,
    bool? allowReplies,
  }) async {
    try {
      final requestBody = {
        'action': 'update_manager_alert',
        'alert_id': alertId,
        'title': title,
        'message': message,
        'category': category,
        'target_stakeholder_types': targetStakeholderTypes,
        'target_role_types': targetRoleTypes,
        'allow_replies': allowReplies,
      };

      final response = await http
          .post(
            Uri.parse(apiEndpoint),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(requestBody),
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);

        if (result['success']) {
          print('✅ اعلان مدیریت با موفقیت در سرور به‌روزرسانی شد');
        } else {
          print('❌ خطا از سرور: ${result['message']}');
          throw Exception(
              result['message'] ?? 'خطا در به‌روزرسانی اعلان مدیریت');
        }
      } else {
        print('❌ خطای HTTP: ${response.statusCode}');
        throw Exception('خطا در ارتباط با سرور (کد: ${response.statusCode})');
      }
    } catch (e) {
      print('❌ Exception در updateManagerAlert: $e');
      throw Exception('خطا در به‌روزرسانی اعلان مدیریت: $e');
    }
  }

  static Map<String, UserSeenStatus> _parseSeenBy(dynamic seenByData) {
    try {
      final seenBy = <String, UserSeenStatus>{};

      if (seenByData == null) {
        return seenBy;
      }

      if (seenByData is Map<String, dynamic>) {
        // فرمت: { userId: { seen: bool, seen_at: string } }
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
        // دو حالت رایج:
        // 1) ["user_1", "user_2", ...]
        // 2) [{ user_id: "user_1", seen: true, seen_at: "..." }, ...]
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

      // فرمت ناشناخته → خالی
      return <String, UserSeenStatus>{};
    } catch (e) {
      print('⚠️ ServerManagerAlertService._parseSeenBy: $e');
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

  static Future<ManagerAlert?> getManagerAlertById(String alertId) async {
    try {
      final allAlerts = await getAllManagerAlerts();
      return allAlerts.firstWhere(
        (alert) => alert.id == alertId,
        orElse: () => throw Exception('اعلان یافت نشد'),
      );
    } catch (e) {
      print('❌ خطا در دریافت اعلان: $e');
      return null;
    }
  }
}
