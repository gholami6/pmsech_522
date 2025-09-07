import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/manager_alert.dart';
import '../models/alert_reply.dart';
import 'auth_service.dart';

class ManagerAlertWebSocketService {
  static const String _baseUrl = 'http://62.60.198.11';
  static const String _endpoint = '/manager_alerts_ws.php';

  Timer? _pollingTimer;
  StreamController<ManagerAlert>? _alertController;
  StreamController<AlertReply>? _replyController;
  bool _isConnected = false;
  final AuthService _authService;

  ManagerAlertWebSocketService(this._authService) {
    _alertController = StreamController<ManagerAlert>.broadcast();
    _replyController = StreamController<AlertReply>.broadcast();
  }

  bool get isConnected => _isConnected;

  Stream<ManagerAlert> get alertStream => _alertController!.stream;
  Stream<AlertReply> get replyStream => _replyController!.stream;

  Future<void> connect() async {
    if (_isConnected) return;

    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        print('❌ کاربر وارد نشده است');
        return;
      }

      // Start polling
      _startPolling();
      _isConnected = true;
      print('✅ اتصال HTTP polling برای اعلان‌های مدیریت برقرار شد');
    } catch (e) {
      print('❌ خطا در اتصال HTTP polling: $e');
      _scheduleReconnect();
    }
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _pollForAlerts();
    });

    // Initial poll
    _pollForAlerts();
  }

  Future<void> _pollForAlerts() async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) return;

      final url = '$_baseUrl$_endpoint?user_id=${currentUser.id}';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['alerts'] != null && data['alerts'] is List) {
          for (final alertData in data['alerts']) {
            try {
              final alert = ManagerAlert.fromJson(alertData);
              _alertController!.add(alert);
            } catch (e) {
              print('❌ خطا در پردازش اعلان: $e');
            }
          }
        }
      }
    } catch (e) {
      print('❌ خطا در polling اعلان‌ها: $e');
    }
  }

  void _scheduleReconnect() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer(const Duration(seconds: 5), () {
      if (!_isConnected) {
        print('🔄 تلاش برای اتصال مجدد HTTP polling...');
        connect();
      }
    });
  }

  Future<void> sendReply({
    required String alertId,
    required String message,
  }) async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) return;

      final url = '$_baseUrl/manager_alert_api.php';
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'action': 'send_reply',
          'alert_id': alertId,
          'user_id': currentUser.id,
          'message': message,
        }),
      );

      if (response.statusCode == 200) {
        print('✅ پاسخ اعلان ارسال شد');
      } else {
        print('❌ خطا در ارسال پاسخ اعلان');
      }
    } catch (e) {
      print('❌ خطا در ارسال پاسخ از طریق HTTP: $e');
    }
  }

  Future<void> markAsSeen(String alertId) async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) return;

      final url = '$_baseUrl/manager_alert_api.php';
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'action': 'mark_as_seen',
          'alert_id': alertId,
          'user_id': currentUser.id,
        }),
      );

      if (response.statusCode == 200) {
        print('✅ وضعیت خوانده شد ثبت شد');
      } else {
        print('❌ خطا در ثبت وضعیت خوانده شد');
      }
    } catch (e) {
      print('❌ خطا در ارسال وضعیت خوانده شد از طریق HTTP: $e');
    }
  }

  void disconnect() {
    _isConnected = false;
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  void dispose() {
    disconnect();
    _alertController?.close();
    _replyController?.close();
  }
}
