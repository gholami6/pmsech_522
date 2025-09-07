import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../models/manager_alert.dart';
import '../models/alert_reply.dart';
import '../models/user_seen_status.dart';
import '../models/position_model.dart';
import '../models/user_model.dart';
import 'auth_service.dart';
import 'server_manager_alert_service.dart';
import 'server_notification_service.dart';

class ManagerAlertService extends ChangeNotifier {
  static const String _boxName = 'manager_alerts';
  Box<ManagerAlert>? _managerAlertsBox;
  final AuthService _authService;

  ManagerAlertService(this._authService) {
    _initBox();
  }

  Future<void> _initBox() async {
    try {
      _managerAlertsBox = await Hive.openBox<ManagerAlert>(_boxName);
      notifyListeners();
    } catch (e) {
      print('❌ خطا در راه‌اندازی ManagerAlertBox: $e');
    }
  }

  bool get _isBoxReady =>
      _managerAlertsBox != null && _managerAlertsBox!.isOpen;

  Future<void> _ensureBoxReady() async {
    if (_managerAlertsBox == null || !_managerAlertsBox!.isOpen) {
      await _initBox();
    }
  }

  List<ManagerAlert> getAllManagerAlerts() {
    if (!_isBoxReady) {
      print('⚠️ ManagerAlertBox هنوز آماده نیست');
      return [];
    }
    return _managerAlertsBox!.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  List<ManagerAlert> getManagerAlertsForCurrentUser() {
    if (!_isBoxReady) {
      print('⚠️ ManagerAlertBox هنوز آماده نیست');
      return [];
    }

    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      print('🔍 ManagerAlertService: کاربر فعلی null است');
      return [];
    }

    try {
      final userPosition = PositionModel.fromTitle(currentUser.position);
      final userStakeholderType = userPosition.stakeholderType.title;
      final userRoleType = userPosition.roleType.title;

      final allAlerts = _managerAlertsBox!.values.toList();
      print(
          '🔍 ManagerAlertService: تعداد کل اعلان‌ها در باکس: ${allAlerts.length}');

      // دیباگ دقیق‌تر برای هر اعلان
      for (int i = 0; i < allAlerts.length; i++) {
        final alert = allAlerts[i];
        print('🔍 ManagerAlertService: اعلان $i: ${alert.title}');
        print('🔍 ManagerAlertService: - ID: ${alert.id}');
        print('🔍 ManagerAlertService: - UserID: ${alert.userId}');
        print(
            '🔍 ManagerAlertService: - TargetStakeholderTypes: ${alert.targetStakeholderTypes}');
        print(
            '🔍 ManagerAlertService: - TargetRoleTypes: ${alert.targetRoleTypes}');
        print(
            '🔍 ManagerAlertService: - SeenBy: ${alert.seenBy.keys.toList()}');
        print('🔍 ManagerAlertService: - CurrentUser: ${currentUser.id}');
        print(
            '🔍 ManagerAlertService: - UserStakeholderType: $userStakeholderType');
        print('🔍 ManagerAlertService: - UserRoleType: $userRoleType');
      }

      final userAlerts = allAlerts.where((alert) {
        // اعلان‌های ساخته‌شده توسط خودِ کاربر همیشه قابل مشاهده هستند
        if (alert.userId == currentUser.id) {
          return true;
        }

        final isTargetStakeholder = alert.targetStakeholderTypes.isEmpty ||
            alert.targetStakeholderTypes.contains(userStakeholderType);

        final isTargetRole = alert.targetRoleTypes.isEmpty ||
            alert.targetRoleTypes.contains(userRoleType);

        final isForUser = isTargetStakeholder && isTargetRole;

        if (isForUser) {
          print(
              '🔍 اعلان مطابق: ${alert.title} - برای ${userStakeholderType}/${userRoleType}');
        }

        return isForUser;
      }).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      print(
          '🔍 ManagerAlertService: تعداد اعلان‌های مطابق کاربر: ${userAlerts.length}');
      return userAlerts;
    } catch (e) {
      print('❌ خطا در پردازش عنوان پوزیشن: $e');
      return [];
    }
  }

  List<ManagerAlert> getUnseenManagerAlerts() {
    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      print('🔍 ManagerAlertService: کاربر فعلی null است');
      return [];
    }

    if (!_isBoxReady) {
      print('⚠️ ManagerAlertBox هنوز آماده نیست');
      return [];
    }

    final userAlerts = getManagerAlertsForCurrentUser();
    final unseenAlerts = userAlerts.where((alert) {
      // اعلان‌هایی که کاربر خودش ایجاد کرده را به عنوان خوانده نشده در نظر نمی‌گیریم
      if (alert.userId == currentUser.id) {
        return false;
      }

      final seenStatus = alert.seenBy[currentUser.id];
      return seenStatus == null || !seenStatus.seen;
    }).toList();

    print(
        '🔍 ManagerAlertService: تعداد اعلان‌های مدیریت خوانده نشده: ${unseenAlerts.length}');
    return unseenAlerts;
  }

  Future<void> createManagerAlert({
    required String title,
    required String message,
    required String category,
    required List<String> targetStakeholderTypes,
    required List<String> targetRoleTypes,
    String? attachmentPath,
    bool? allowReplies,
  }) async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      throw Exception('کاربر وارد نشده است');
    }

    try {
      final position = PositionModel.fromTitle(currentUser.position);
      if (!_canCreateManagerAlert(position)) {
        throw Exception('شما مجاز به ایجاد اعلان مدیریت نیستید');
      }

      // 1) ذخیره فوری محلی برای نمایش آنی به سازنده
      await _ensureBoxReady();
      if (_managerAlertsBox == null) {
        throw Exception('ManagerAlertBox آماده نیست');
      }

      final DateTime now = DateTime.now();
      final localTempAlert = ManagerAlert(
        userId: currentUser.id,
        title: title,
        message: message,
        category: category,
        targetStakeholderTypes: targetStakeholderTypes,
        targetRoleTypes: targetRoleTypes,
        attachmentPath: attachmentPath,
        allowReplies: allowReplies ?? true,
        createdAt: now,
      );
      // سازنده همیشه خوانده است
      localTempAlert.seenBy[currentUser.id] = UserSeenStatus(
        seen: true,
        seenAt: now,
      );
      await _managerAlertsBox!.put(localTempAlert.id, localTempAlert);
      notifyListeners();
      print(
          '✅ اعلان مدیریت به‌صورت محلی و فوری ذخیره شد (ID موقت: ${localTempAlert.id})');

      // 2) ارسال به سرور و به‌روزرسانی ID محلی پس از موفقیت
      String alertId;
      try {
        alertId = await ServerManagerAlertService.createManagerAlert(
          userId: currentUser.id,
          title: title,
          message: message,
          category: category,
          targetStakeholderTypes: targetStakeholderTypes,
          targetRoleTypes: targetRoleTypes,
          attachmentPath: attachmentPath,
        );
        print('✅ اعلان مدیریت در سرور ثبت شد. ID: $alertId');

        final updatedAlert = localTempAlert.copyWith(id: alertId);
        if (updatedAlert.id != localTempAlert.id) {
          await _managerAlertsBox!.delete(localTempAlert.id);
        }
        await _managerAlertsBox!.put(updatedAlert.id, updatedAlert);
        notifyListeners();
        print('🔄 ID محلی با ID سرور جایگزین شد');

        // 3) ارسال نوتیف به همه (به‌جز سازنده سمت سرور مدیریت می‌شود)
        try {
          await ServerNotificationService.sendNotificationToAll(
            title: 'اعلان مدیریت جدید',
            message: title,
            type: 'manager_alert',
            data: {
              'alert_id': alertId,
              'category': category,
              'target_stakeholder_types': targetStakeholderTypes,
              'target_role_types': targetRoleTypes,
            },
            senderUserId: currentUser.id,
          );
          print('✅ نوتیفیکیشن اعلان جدید ارسال شد');
        } catch (notificationError) {
          print('❌ خطا در ارسال نوتیفیکیشن: $notificationError');
        }

        // 4) ثبت وضعیت خوانده‌شدن برای سازنده در سرور
        try {
          await ServerManagerAlertService.markManagerAlertAsSeen(
            alertId: alertId,
            userId: currentUser.id,
          );
          print('✅ وضعیت خوانده شده برای سازنده در سرور ثبت شد');
        } catch (seenError) {
          print('⚠️ خطا در ثبت وضعیت خوانده شده: $seenError');
        }

        // 5) همگام‌سازی سایر دستگاه‌ها
        try {
          await syncWithServer();
          print('✅ همگام‌سازی خودکار انجام شد');
        } catch (syncError) {
          print('⚠️ خطا در همگام‌سازی خودکار: $syncError');
        }
      } catch (serverError) {
        // در صورت خطای سرور، رکورد محلی باقی می‌ماند تا کاربر اعلان را ببیند
        print('❌ خطا در ارسال به سرور: $serverError');
        // عدم پرتاب مجدد تا UX حفظ شود؛ همگام‌سازی بعداً تلاش می‌شود
      }
    } catch (e) {
      print('❌ خطا در ایجاد اعلان مدیریت: $e');
      throw Exception('خطا در ایجاد اعلان مدیریت: $e');
    }
  }

  Future<void> addReplyToManagerAlert({
    required String alertId,
    required String message,
  }) async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      throw Exception('کاربر وارد نشده است');
    }

    try {
      await _ensureBoxReady();
      final alert = _managerAlertsBox!.get(alertId);
      if (alert == null) {
        throw Exception('اعلان مورد نظر یافت نشد');
      }

      if (!alert.allowReplies) {
        throw Exception('این اعلان اجازه پاسخ ندارد');
      }

      // ابتدا در حافظه محلی ذخیره کنیم
      final reply = AlertReply(
        userId: currentUser.id,
        message: message,
      );

      alert.replies.add(reply);
      await _managerAlertsBox!.put(alert.id, alert);
      notifyListeners();
      print('✅ پاسخ در حافظه محلی ذخیره شد');

      // سپس به سرور ارسال کنیم
      try {
        await ServerManagerAlertService.addReplyToManagerAlert(
          alertId: alertId,
          userId: currentUser.id,
          message: message,
        );
        print('✅ پاسخ در سرور ثبت شد');
      } catch (serverError) {
        print('❌ خطا در ارسال پاسخ به سرور: $serverError');
        // حذف پاسخ از حافظه محلی در صورت خطا
        alert.replies.removeLast();
        await _managerAlertsBox!.put(alert.id, alert);
        notifyListeners();
        throw serverError;
      }
    } catch (e) {
      print('❌ خطا در اضافه کردن پاسخ: $e');
      throw Exception('خطا در اضافه کردن پاسخ: $e');
    }
  }

  Future<void> addReply({
    required String alertId,
    required String message,
  }) async {
    await addReplyToManagerAlert(alertId: alertId, message: message);
  }

  Future<void> markAsSeen(String alertId) async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      throw Exception('کاربر وارد نشده است');
    }

    await _ensureBoxReady();
    final alert = _managerAlertsBox!.get(alertId);
    if (alert == null) {
      throw Exception('اعلان مورد نظر یافت نشد');
    }

    // ذخیره محلی
    alert.seenBy[currentUser.id] = UserSeenStatus(
      seen: true,
      seenAt: DateTime.now(),
    );

    await _managerAlertsBox!.put(alert.id, alert);
    notifyListeners();

    // ارسال به سرور
    try {
      await ServerManagerAlertService.markManagerAlertAsSeen(
        alertId: alertId,
        userId: currentUser.id,
      );
      print('✅ وضعیت خوانده شد به سرور ارسال شد');
    } catch (serverError) {
      print('⚠️ خطا در ارسال وضعیت خوانده شد به سرور: $serverError');
      // خطا در سرور نباید روی عملکرد محلی تأثیر بگذارد
    }
  }

  Future<void> deleteManagerAlert(String alertId) async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      throw Exception('کاربر وارد نشده است');
    }

    try {
      await ServerManagerAlertService.deleteManagerAlert(
        alertId: alertId,
        userId: currentUser.id,
      );
      print('✅ اعلان مدیریت از سرور حذف شد');
    } catch (serverError) {
      print('❌ خطا در حذف از سرور: $serverError');
      throw serverError;
    }

    await _ensureBoxReady();
    await _managerAlertsBox!.delete(alertId);
    notifyListeners();
    print('✅ اعلان مدیریت با موفقیت حذف شد');

    // اجباری کردن همگام‌سازی برای سایر دستگاه‌ها
    try {
      await syncWithServer();
    } catch (e) {
      print('⚠️ خطا در همگام‌سازی بعد از حذف: $e');
    }
  }

  Future<void> updateManagerAlert({
    required String alertId,
    required String title,
    required String message,
    required String category,
    required List<String> targetStakeholderTypes,
    required List<String> targetRoleTypes,
    bool? allowReplies,
  }) async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      throw Exception('کاربر وارد نشده است');
    }

    try {
      await ServerManagerAlertService.updateManagerAlert(
        alertId: alertId,
        userId: currentUser.id,
        title: title,
        message: message,
        category: category,
        targetStakeholderTypes: targetStakeholderTypes,
        targetRoleTypes: targetRoleTypes,
        allowReplies: allowReplies,
      );
      print('✅ اعلان مدیریت در سرور به‌روزرسانی شد');
    } catch (serverError) {
      print('❌ خطا در به‌روزرسانی سرور: $serverError');
      throw serverError;
    }

    await _ensureBoxReady();
    final alert = _managerAlertsBox!.get(alertId);
    if (alert != null) {
      final updatedAlert = alert.copyWith(
        title: title,
        message: message,
        category: category,
        targetStakeholderTypes: targetStakeholderTypes,
        targetRoleTypes: targetRoleTypes,
        allowReplies: allowReplies ?? alert.allowReplies,
      );

      await _managerAlertsBox!.put(alertId, updatedAlert);
      notifyListeners();
      print('✅ اعلان مدیریت با موفقیت به‌روزرسانی شد');
    }
  }

  bool _canCreateManagerAlert(PositionModel position) {
    return true; // تمام کاربران دسترسی دارند
  }

  Future<void> syncWithServer() async {
    try {
      print('🔄 ManagerAlertService: شروع همگام‌سازی با سرور');

      // تلاش مستقیم برای دریافت اعلان‌ها از سرور؛ در خطا به داده‌های محلی برمی‌گردیم
      final serverAlerts =
          await ServerManagerAlertService.getAllManagerAlerts();
      print('📥 تعداد اعلان‌های سرور: ${serverAlerts.length}');

      await _ensureBoxReady();

      // دریافت ID های اعلان‌های سرور
      final serverAlertIds = serverAlerts.map((alert) => alert.id).toSet();

      // حذف اعلان‌هایی که در سرور نیستند (حذف شده‌اند)
      final localAlertIds = _managerAlertsBox!.keys.cast<String>();
      for (final localAlertId in localAlertIds) {
        if (!serverAlertIds.contains(localAlertId)) {
          await _managerAlertsBox!.delete(localAlertId);
          print('🗑️ اعلان حذف شده از محلی: $localAlertId');
        }
      }

      // اضافه/به‌روزرسانی اعلان‌های سرور
      for (final serverAlert in serverAlerts) {
        final localAlert = _managerAlertsBox!.get(serverAlert.id);

        if (localAlert == null) {
          // اعلان جدید: به صورت نخوانده برای همه کاربران
          await _managerAlertsBox!.put(serverAlert.id, serverAlert);
        } else {
          // اعلان موجود: محتوای سرور مرجع است اما وضعیت خوانده‌شدن باید ادغام شود
          final mergedSeenBy = <String, UserSeenStatus>{}
            ..addAll(serverAlert.seenBy)
            ..addAll(localAlert.seenBy);
          final updatedAlert = serverAlert.copyWith(seenBy: mergedSeenBy);
          await _managerAlertsBox!.put(serverAlert.id, updatedAlert);
        }
      }

      notifyListeners();
      print('✅ ManagerAlertService: همگام‌سازی تکمیل شد');
    } catch (e) {
      print('❌ ManagerAlertService: خطا در همگام‌سازی: $e');

      // در صورت خطا، از داده‌های محلی استفاده می‌کنیم
      print('⚠️ استفاده از داده‌های محلی به دلیل خطای سرور');
      notifyListeners();
    }
  }

  // حذف همه اعلان‌های مدیریت
  Future<void> clearAllManagerAlerts() async {
    try {
      await _ensureBoxReady();
      await _managerAlertsBox!.clear();
      notifyListeners();
      print('✅ همه اعلان‌های مدیریت حذف شدند');
    } catch (e) {
      print('❌ خطا در حذف اعلان‌های مدیریت: $e');
      throw Exception('خطا در حذف اعلان‌های مدیریت: $e');
    }
  }

  Future<void> syncServerAlertsToLocal(List<ManagerAlert> serverAlerts) async {
    await syncWithServer();
  }

  static List<String> getAlertCategories() {
    return [
      'دستورات و بخشنامه‌ها',
      'اطلاعیه‌های عمومی',
      'هشدارهای ایمنی',
      'تغییرات سازمانی',
      'اخبار و رویدادها',
      'سایر',
    ];
  }

  static List<String> getStakeholderTypes() {
    return [
      'کارفرما',
      'پیمانکار',
      'مشاور',
      'تامین‌کننده',
      'سایر',
    ];
  }

  static List<String> getRoleTypes() {
    return [
      'مدیرعامل',
      'مدیر',
      'سرپرست',
      'کارشناس',
      'کارگر',
      'سایر',
    ];
  }

  UserModel? getCurrentUser() {
    return _authService.currentUser;
  }

  @override
  void dispose() {
    _managerAlertsBox?.close();
    super.dispose();
  }
}
