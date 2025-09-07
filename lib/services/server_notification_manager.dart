import 'dart:async';
import 'package:flutter/foundation.dart';
import 'server_notification_service.dart';
import 'notification_service.dart';
import 'auth_service.dart';

class ServerNotificationManager extends ChangeNotifier {
  static ServerNotificationManager? _instance;
  Timer? _notificationTimer;
  final AuthService _authService;
  bool _isInitialized = false;

  ServerNotificationManager._(this._authService);

  static ServerNotificationManager getInstance(AuthService authService) {
    _instance ??= ServerNotificationManager._(authService);
    return _instance!;
  }

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await NotificationService.initialize();
      await NotificationService.requestNotificationPermission();

      _isInitialized = true;
      print('✅ ServerNotificationManager: راه‌اندازی تکمیل شد');
    } catch (e) {
      print('❌ ServerNotificationManager: خطا در راه‌اندازی: $e');
    }
  }

  void startNotificationCheck() {
    if (!_isInitialized) {
      print('⚠️ ServerNotificationManager: ابتدا باید راه‌اندازی شود');
      return;
    }

    _notificationTimer?.cancel();

    _notificationTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _checkForNewNotifications();
    });

    print('✅ ServerNotificationManager: بررسی منظم نوتیفیکیشن‌ها شروع شد');
  }

  void stopNotificationCheck() {
    _notificationTimer?.cancel();
    _notificationTimer = null;
    print('✅ ServerNotificationManager: بررسی منظم نوتیفیکیشن‌ها متوقف شد');
  }

  Future<void> _checkForNewNotifications() async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) return;

      final isConnected = await ServerNotificationService.testConnection();
      if (!isConnected) {
        print('⚠️ ServerNotificationManager: سرور نوتیفیکیشن در دسترس نیست');
        return;
      }

      // فقط یک بار بررسی کنیم تا از حلقه بی‌نهایت جلوگیری شود
      await NotificationService.checkAndShowServerNotifications(currentUser.id);
      
    } catch (e) {
      print('❌ ServerNotificationManager: خطا در بررسی نوتیفیکیشن‌ها: $e');
    }
  }

  @override
  void dispose() {
    _notificationTimer?.cancel();
    super.dispose();
  }
}
