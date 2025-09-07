import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../models/alert_notification.dart';
import '../models/alert_reply.dart';
import '../models/user_seen_status.dart';
import '../models/position_model.dart';
import 'auth_service.dart';
import 'server_alert_service.dart';
import 'server_notification_service.dart';

class AlertService extends ChangeNotifier {
  static const String _boxName = 'alerts';
  late Box<AlertNotification> _alertsBox;
  final AuthService _authService;

  AlertService(this._authService) {
    _initBox();
  }

  Future<void> _initBox() async {
    _alertsBox = await Hive.openBox<AlertNotification>(_boxName);
    notifyListeners();
  }

  List<AlertNotification> getAlerts() {
    return _alertsBox.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  List<AlertNotification> getUnseenAlerts() {
    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      print('🔍 AlertService: کاربر فعلی null است');
      return [];
    }

    final unseenAlerts = _alertsBox.values.where((alert) {
      final seenStatus = alert.seenBy[currentUser.id];
      return seenStatus == null || !seenStatus.seen;
    }).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    print(
        '🔍 AlertService: تعداد اعلان‌های خوانده نشده: ${unseenAlerts.length}');
    return unseenAlerts;
  }

  Future<void> createAlert({
    required String equipmentId,
    required String message,
    String? attachmentPath,
    String? category,
  }) async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      throw Exception('کاربر وارد نشده است');
    }

    try {
      final position = PositionModel.fromTitle(currentUser.position);
      if (!_canCreateAlert(position)) {
        throw Exception('شما مجاز به ایجاد اعلان نیستید');
      }

      // ارسال به سرور
      String alertId;
      try {
        alertId = await ServerAlertService.createAlert(
          userId: currentUser.id,
          equipmentId: equipmentId,
          message: message,
          attachmentPath: attachmentPath,
          category: category,
        );
        print('✅ اعلان در سرور ثبت شد. ID: $alertId');

        // ارسال نوتیفیکیشن فقط در زمان ایجاد اعلان جدید
        try {
          await ServerNotificationService.sendNotificationToAll(
            title: 'اعلان جدید',
            message: message,
            type: 'alert',
            data: {
              'alert_id': alertId,
              'equipment_id': equipmentId,
            },
            senderUserId: currentUser.id,
          );
          print('✅ نوتیفیکیشن اعلان جدید ارسال شد');
        } catch (notificationError) {
          print('❌ خطا در ارسال نوتیفیکیشن: $notificationError');
        }

        // ذخیره در حافظه محلی فقط در صورت موفقیت سرور
        final alert = AlertNotification(
          id: alertId,
          userId: currentUser.id,
          equipmentId: equipmentId,
          message: message,
          attachmentPath: attachmentPath,
          category: category,
        );

        await _alertsBox.put(alert.id, alert);
        notifyListeners();
        print('✅ اعلان با موفقیت ایجاد شد');
      } catch (serverError) {
        print('❌ خطا در ارسال به سرور: $serverError');
        throw serverError;
      }
    } catch (e) {
      print('❌ خطا در ایجاد اعلان: $e');
      throw Exception('خطا در ایجاد اعلان: $e');
    }
  }

  Future<void> addReplyToAlert({
    required String alertId,
    required String message,
  }) async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      throw Exception('کاربر وارد نشده است');
    }

    try {
      final alert = _alertsBox.get(alertId);
      if (alert == null) {
        throw Exception('اعلان مورد نظر یافت نشد');
      }

      // ارسال پاسخ به سرور
      try {
        await ServerAlertService.addReply(
          alertId: alertId,
          userId: currentUser.id,
          message: message,
        );
        print('✅ پاسخ در سرور ثبت شد');
      } catch (serverError) {
        print('❌ خطا در ارسال پاسخ به سرور: $serverError');
        throw serverError;
      }

      // ذخیره در حافظه محلی
      final reply = AlertReply(
        userId: currentUser.id,
        message: message,
      );

      alert.replies.add(reply);
      await _alertsBox.put(alert.id, alert);
      notifyListeners();
      print('✅ پاسخ با موفقیت اضافه شد');
    } catch (e) {
      print('❌ خطا در اضافه کردن پاسخ: $e');
      throw Exception('خطا در اضافه کردن پاسخ: $e');
    }
  }

  Future<void> markAsSeen(String alertId) async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      throw Exception('کاربر وارد نشده است');
    }

    final alert = _alertsBox.get(alertId);
    if (alert == null) {
      throw Exception('اعلان مورد نظر یافت نشد');
    }

    alert.seenBy[currentUser.id] = UserSeenStatus(
      seen: true,
      seenAt: DateTime.now(),
    );

    await _alertsBox.put(alert.id, alert);
    notifyListeners();
  }

  Future<void> deleteAlert(String alertId) async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      throw Exception('کاربر وارد نشده است');
    }

    // بررسی مجوز حذف - فقط صادرکننده اعلان می‌تواند آن را حذف کند
    final alert = _alertsBox.get(alertId);
    if (alert == null) {
      throw Exception('اعلان مورد نظر یافت نشد');
    }

    if (alert.userId != currentUser.id) {
      throw Exception('شما مجاز به حذف این اعلان نیستید');
    }

    try {
      await ServerAlertService.deleteAlert(
        alertId: alertId,
        userId: currentUser.id,
      );
      print('✅ اعلان از سرور حذف شد');
    } catch (serverError) {
      print('❌ خطا در حذف از سرور: $serverError');
      throw serverError;
    }

    await _alertsBox.delete(alertId);
    notifyListeners();
    print('✅ اعلان با موفقیت حذف شد');
  }

  Future<void> updateAlert({
    required String alertId,
    required String message,
    String? equipmentId,
    String? category,
  }) async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      throw Exception('کاربر وارد نشده است');
    }

    // بررسی مجوز ویرایش - فقط صادرکننده اعلان می‌تواند آن را ویرایش کند
    final alert = _alertsBox.get(alertId);
    if (alert == null) {
      throw Exception('اعلان مورد نظر یافت نشد');
    }

    if (alert.userId != currentUser.id) {
      throw Exception('شما مجاز به ویرایش این اعلان نیستید');
    }

    try {
      await ServerAlertService.updateAlert(
        alertId: alertId,
        userId: currentUser.id,
        message: message,
        equipmentId: equipmentId,
        category: category,
      );
      print('✅ اعلان در سرور به‌روزرسانی شد');
    } catch (serverError) {
      print('❌ خطا در به‌روزرسانی سرور: $serverError');
      throw serverError;
    }

    final updatedAlert = alert.copyWith(
      message: message,
      equipmentId: equipmentId ?? alert.equipmentId,
      category: category ?? alert.category,
    );

    await _alertsBox.put(alertId, updatedAlert);
    notifyListeners();
    print('✅ اعلان با موفقیت به‌روزرسانی شد');
  }

  bool _canCreateAlert(PositionModel position) {
    return true; // تمام کاربران دسترسی دارند
  }

  Future<void> syncWithServer() async {
    try {
      print('🔄 AlertService: شروع همگام‌سازی با سرور');

      final serverAlerts = await ServerAlertService.getAllAlerts();
      print('📥 تعداد اعلان‌های سرور: ${serverAlerts.length}');

      for (final serverAlert in serverAlerts) {
        final localAlert = _alertsBox.get(serverAlert.id);

        if (localAlert == null) {
          // اعلان جدید: به صورت نخوانده برای همه کاربران
          await _alertsBox.put(serverAlert.id, serverAlert);
        } else {
          // اعلان موجود: فقط محتوا به‌روزرسانی شود، وضعیت خوانده شدن حفظ شود
          final updatedAlert = serverAlert.copyWith(seenBy: localAlert.seenBy);
          await _alertsBox.put(serverAlert.id, updatedAlert);
        }
      }

      notifyListeners();
      print('✅ AlertService: همگام‌سازی تکمیل شد');
    } catch (e) {
      print('❌ AlertService: خطا در همگام‌سازی: $e');
      throw Exception('خطا در همگام‌سازی اعلان‌ها: $e');
    }
  }

  // حذف همه اعلان‌ها
  Future<void> clearAllAlerts() async {
    try {
      await _alertsBox.clear();
      notifyListeners();
      print('✅ همه اعلان‌ها حذف شدند');
    } catch (e) {
      print('❌ خطا در حذف اعلان‌ها: $e');
      throw Exception('خطا در حذف اعلان‌ها: $e');
    }
  }

  @override
  void dispose() {
    _alertsBox.close();
    super.dispose();
  }
}
