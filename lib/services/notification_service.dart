import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive/hive.dart';
import '../models/alert_notification.dart';
import '../models/alert_reply.dart';
import '../models/user_seen_status.dart';
import '../models/user_model.dart';
import '../models/position_model.dart';
import 'server_notification_service.dart';
import 'server_alert_service.dart';
import 'navigation_service.dart';
import 'dart:convert';
import '../screens/equipment_alerts_screen.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';

class NotificationService extends ChangeNotifier {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  Timer? _logTimer;
  int _logCount = 0;
  static const int _maxLogsPerMinute = 10;

  /// مدیریت لاگ‌های تکراری
  void logWithRateLimit(String message, {String? tag}) {
    _logCount++;
    
    if (_logCount <= _maxLogsPerMinute) {
      print('${tag != null ? '[$tag] ' : ''}$message');
    } else if (_logCount == _maxLogsPerMinute + 1) {
      print('${tag != null ? '[$tag] ' : ''}تعداد لاگ‌ها محدود شد - کاهش نمایش');
    }
    
    // ریست کردن شمارنده هر دقیقه
    _logTimer?.cancel();
    _logTimer = Timer(const Duration(minutes: 1), () {
      _logCount = 0;
    });
  }

  /// لاگ با محدودیت نرخ برای اعلان‌ها
  void logNotification(String message) {
    logWithRateLimit(message, tag: 'Notification');
  }

  /// لاگ با محدودیت نرخ برای اتصال
  void logConnection(String message) {
    logWithRateLimit(message, tag: 'Connection');
  }

  /// لاگ با محدودیت نرخ برای همگام‌سازی
  void logSync(String message) {
    logWithRateLimit(message, tag: 'Sync');
  }

  @override
  void dispose() {
    _logTimer?.cancel();
    super.dispose();
  }

  static const String _alertBoxName = 'alert_notifications';
  static Box<AlertNotification>? _alertBox;

  static final FlutterLocalNotificationsPlugin
      _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    if (_alertBox == null || !_alertBox!.isOpen) {
      _alertBox = await Hive.openBox<AlertNotification>(_alertBoxName);
    }

    const initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettingsIOS = DarwinInitializationSettings();
    const initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        final payload = response.payload;
        if (payload != null && payload.trim().startsWith('{')) {
          try {
            final Map<String, dynamic> data = jsonDecode(payload);
            final String? type = data['type'];
            if (type == 'alert' || type == 'alert_reply') {
              final equipmentId = data['equipment_id'] as String?;
              if (equipmentId != null && equipmentId.isNotEmpty) {
                NavigationService.pushGlobalPage(
                  EquipmentAlertsScreen(equipmentName: equipmentId),
                );
                return;
              }
            } else if (type == 'manager_alert' ||
                type == 'manager_alert_reply') {
              final managerAlertId = data['alert_id'] as String?;
              if (managerAlertId != null && managerAlertId.isNotEmpty) {
                NavigationService.navigateToGlobal('/manager-alerts');
                return;
              }
            }
          } catch (_) {}
        }
        NavigationService.navigateToGlobal('/alerts-management');
      },
    );
  }

  static Future<Box<AlertNotification>> get _alertNotificationBox async {
    await initialize();
    return _alertBox!;
  }

  static bool canDeleteAlert(UserModel user, AlertNotification alert) {
    // فقط صادرکننده اعلان می‌تواند آن را حذف کند
    return alert.userId == user.id;
  }

  static bool canEditAlert(UserModel user, AlertNotification alert) {
    // فقط صادرکننده اعلان می‌تواند آن را ویرایش کند
    return alert.userId == user.id;
  }

  static Future<String> createAlert({
    required String userId,
    required String equipmentId,
    required String message,
    String? attachmentPath,
    bool? allowReplies,
  }) async {
    final box = await _alertNotificationBox;

    final alert = AlertNotification(
      userId: userId,
      equipmentId: equipmentId,
      message: message,
      attachmentPath: attachmentPath,
      allowReplies: allowReplies ?? true,
    );

    await box.put(alert.id, alert);

    await _sendLocalNotification(
      id: alert.id.hashCode,
      title: 'اعلان جدید',
      body: message.length > 50 ? '${message.substring(0, 50)}...' : message,
    );

    return alert.id;
  }

  static Future<void> replyToAlert({
    required String alertId,
    required String userId,
    required String message,
  }) async {
    final box = await _alertNotificationBox;
    final alert = box.get(alertId);

    if (alert != null) {
      final reply = AlertReply(
        userId: userId,
        message: message,
      );

      alert.replies.add(reply);
      await box.put(alertId, alert);
    }
  }

  static Future<void> markAsSeen(String alertId, String userId) async {
    final box = await _alertNotificationBox;
    final alert = box.get(alertId);

    if (alert != null) {
      alert.seenBy[userId] = UserSeenStatus(
        seen: true,
        seenAt: DateTime.now(),
      );
      await box.put(alertId, alert);
    }
  }

  static Future<void> syncServerAlertsToLocal(
      List<AlertNotification> serverAlerts) async {
    try {
      print(
          '🔄 NotificationService: شروع همگام‌سازی ${serverAlerts.length} اعلان از سرور');
      final box = await _alertNotificationBox;

      for (final serverAlert in serverAlerts) {
        final localAlert = box.get(serverAlert.id);

        if (localAlert == null) {
          await box.put(serverAlert.id, serverAlert);
          continue;
        }

        final mergedSeenBy =
            Map<String, UserSeenStatus>.from(serverAlert.seenBy);
        localAlert.seenBy.forEach((userId, status) {
          final existing = mergedSeenBy[userId];
          if (existing == null || existing.seen == false) {
            if (status.seen) {
              mergedSeenBy[userId] = status;
            }
          }
        });

        final updated = serverAlert.copyWith(seenBy: mergedSeenBy);
        await box.put(serverAlert.id, updated);
      }

      print('✅ NotificationService: همگام‌سازی اعلان‌ها تکمیل شد');
    } catch (e) {
      print('❌ NotificationService: خطا در همگام‌سازی اعلان‌ها: $e');
      throw Exception('خطا در همگام‌سازی اعلان‌ها: $e');
    }
  }

  static Future<List<AlertNotification>> getAllAlerts() async {
    final box = await _alertNotificationBox;
    return box.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  static Future<List<AlertNotification>> getAlertsByEquipment(
      String equipmentId) async {
    final allAlerts = await getAllAlerts();
    return allAlerts
        .where((alert) => alert.equipmentId == equipmentId)
        .toList();
  }

  static Future<List<AlertNotification>> getNewAlertsForUser(
      String userId) async {
    final allAlerts = await getAllAlerts();
    return allAlerts
        .where((alert) =>
            !alert.seenBy.containsKey(userId) && alert.userId != userId)
        .toList();
  }

  static Future<List<AlertNotification>> getSeenAlertsForUser(
      String userId) async {
    final allAlerts = await getAllAlerts();
    return allAlerts
        .where((alert) =>
            alert.seenBy.containsKey(userId) || alert.userId == userId)
        .toList();
  }

  static Future<bool> deleteAlert(String alertId, String currentUserId) async {
    final box = await _alertNotificationBox;
    final alert = box.get(alertId);

    if (alert != null) {
      // ابتدا از سرور حذف کن
      try {
        await ServerAlertService.deleteAlert(
          alertId: alertId,
          userId: currentUserId,
        );
      } catch (e) {
        print('⚠️ NotificationService: خطا در حذف از سرور: $e');
        // حتی اگر از سرور حذف نشد، از محلی حذف کن
      }

      // از دیتابیس محلی حذف کن
      await box.delete(alertId);
      print('🗑️ NotificationService: اعلان $alertId از دیتابیس محلی حذف شد');
      return true;
    }
    return false;
  }

  static Future<bool> updateAlert({
    required String alertId,
    required String currentUserId,
    required String message,
    String? equipmentId,
  }) async {
    final box = await _alertNotificationBox;
    final alert = box.get(alertId);

    if (alert != null) {
      if (alert.userId == currentUserId) {
        // ابتدا در سرور به‌روزرسانی کن
        try {
          await ServerAlertService.updateAlert(
            alertId: alertId,
            userId: currentUserId,
            message: message,
            equipmentId: equipmentId,
          );
        } catch (e) {
          print('⚠️ NotificationService: خطا در به‌روزرسانی سرور: $e');
          // حتی اگر در سرور به‌روزرسانی نشد، در محلی به‌روزرسانی کن
        }

        // در دیتابیس محلی به‌روزرسانی کن
        final updatedAlert = alert.copyWith(
          message: message,
          equipmentId: equipmentId ?? alert.equipmentId,
        );
        await box.put(alertId, updatedAlert);
        print(
            '✅ NotificationService: اعلان $alertId در دیتابیس محلی به‌روزرسانی شد');
        return true;
      }
    }
    return false;
  }

  static Future<void> archiveAlert(String alertId, String userId) async {
    await markAsSeen(alertId, userId);
  }

  static Future<int> getNewAlertsCount(String userId) async {
    final newAlerts = await getNewAlertsForUser(userId);
    return newAlerts.length;
  }

  static Future<void> clearAllAlerts() async {
    final box = await _alertNotificationBox;
    await box.clear();
  }

  // متد همگام‌سازی با سرور و حذف اعلان‌های قدیمی
  static Future<void> syncWithServer() async {
    try {
      print('🔄 NotificationService: شروع همگام‌سازی با سرور');

      // دریافت اعلان‌های سرور
      final serverAlerts = await ServerAlertService.getAllAlerts();
      final serverAlertIds = serverAlerts.map((alert) => alert.id).toSet();

      // دریافت اعلان‌های محلی
      final localAlerts = await getAllAlerts();
      final localAlertIds = localAlerts.map((alert) => alert.id).toSet();

      // پیدا کردن اعلان‌های حذف شده از سرور
      final deletedAlertIds = localAlertIds.difference(serverAlertIds);

      if (deletedAlertIds.isNotEmpty) {
        print(
            '🗑️ NotificationService: حذف ${deletedAlertIds.length} اعلان قدیمی از دیتابیس محلی');

        final box = await _alertNotificationBox;
        for (final alertId in deletedAlertIds) {
          await box.delete(alertId);
          print('🗑️ NotificationService: اعلان $alertId حذف شد');
        }
      }

      // به‌روزرسانی اعلان‌های موجود
      for (final serverAlert in serverAlerts) {
        final localAlert = localAlerts.firstWhere(
          (alert) => alert.id == serverAlert.id,
          orElse: () => serverAlert,
        );

        // اگر اعلان در محلی وجود دارد، وضعیت seenBy را ادغام کن
        if (localAlertIds.contains(serverAlert.id)) {
          final mergedSeenBy =
              Map<String, UserSeenStatus>.from(localAlert.seenBy);
          mergedSeenBy.addAll(serverAlert.seenBy);

          final updatedAlert = serverAlert.copyWith(seenBy: mergedSeenBy);
          final box = await _alertNotificationBox;
          await box.put(serverAlert.id, updatedAlert);
        } else {
          // اعلان جدید از سرور
          final box = await _alertNotificationBox;
          await box.put(serverAlert.id, serverAlert);
        }
      }

      print('✅ NotificationService: همگام‌سازی با سرور تکمیل شد');
    } catch (e) {
      print('❌ NotificationService: خطا در همگام‌سازی با سرور: $e');
      // در صورت خطا، ادامه کار بدون همگام‌سازی
    }
  }

  static Future<void> _sendLocalNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'alerts_channel',
      'اعلان‌های کارشناسان',
      channelDescription: 'اعلان‌های مربوط به تجهیزات و مسائل فنی',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const iOSPlatformChannelSpecifics = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      platformChannelSpecifics,
      payload: payload,
    );
  }

  static Future<bool> requestNotificationPermission() async {
    final result = await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    return result ?? false;
  }

  static Future<void> checkAndShowServerNotifications(String userId) async {
    try {
      final metaBox = await Hive.openBox<String>('syncMeta');

      final lastSyncKey = 'last_notifications_sync_' + userId;
      final shownIdsKey = 'shown_notification_ids_' + userId;
      final lastSyncTime = metaBox.get(lastSyncKey);

      if (lastSyncTime == null) {
        await metaBox.put(lastSyncKey, DateTime.now().toIso8601String());
        return;
      }

      final shownIdsCsv = metaBox.get(shownIdsKey) ?? '';
      final Set<String> shownIds = shownIdsCsv.isEmpty
          ? <String>{}
          : shownIdsCsv.split(',').where((e) => e.isNotEmpty).toSet();

      final notifications =
          await ServerNotificationService.getNotificationsForUser(
        userId: userId,
        lastSyncTime: lastSyncTime,
      );

      int shownCount = 0;
      for (final notification in notifications) {
        final idStr = (notification['id'] ?? '').toString();
        if (idStr.isEmpty || shownIds.contains(idStr)) {
          continue;
        }

        final title = notification['title'] ?? 'اعلان جدید';

        final Map<String, dynamic> payload = {
          'type': notification['type'] ?? '',
          'data': notification['data'] ?? {},
          'alert_id': (notification['data'] ?? {})['alert_id'] ?? '',
          'equipment_id': (notification['data'] ?? {})['equipment_id'] ?? '',
          'sender_user_id': (notification['data'] ?? {})['user_id'] ?? '',
        };

        final senderId = payload['sender_user_id'] as String?;
        if (senderId != null && senderId == userId) {
          continue;
        }

        await _sendLocalNotification(
          id: notification.hashCode,
          title: title,
          body: notification['message'] ?? '',
          payload: jsonEncode(payload),
        );

        shownIds.add(idStr);
        shownCount++;
      }

      if (shownCount > 0) {
        await metaBox.put(shownIdsKey, shownIds.join(','));
        await metaBox.put(lastSyncKey, DateTime.now().toIso8601String());
        print('✅ تعداد نوتیفیکیشن‌های نمایش داده شده: $shownCount');
      }
    } catch (e) {
      print('❌ خطا در بررسی نوتیفیکیشن‌های سرور: $e');
    }
  }

  // حذف همه نوتیفیکیشن‌های محلی
  static Future<void> clearAllNotifications() async {
    try {
      await _flutterLocalNotificationsPlugin.cancelAll();
      print('✅ همه نوتیفیکیشن‌های محلی حذف شدند');
    } catch (e) {
      print('❌ خطا در حذف نوتیفیکیشن‌های محلی: $e');
      throw Exception('خطا در حذف نوتیفیکیشن‌های محلی: $e');
    }
  }
}
