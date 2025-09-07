import 'package:flutter/material.dart';
import '../services/server_alert_service.dart';
import '../models/alert_notification.dart';

import '../screens/new_alert_page.dart';
import '../services/auth_service.dart';
import 'package:provider/provider.dart';
import '../services/notification_service.dart';
import '../services/alert_service.dart';
import '../models/user_seen_status.dart';
import 'premium_alert_card.dart';

class AlertsBox extends StatefulWidget {
  const AlertsBox({super.key});

  @override
  State<AlertsBox> createState() => _AlertsBoxState();
}

class _AlertsBoxState extends State<AlertsBox> {
  List<AlertNotification> _recentAlerts = [];
  int _newAlertsCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecentAlerts();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // گوش دادن به تغییرات AlertService
    try {
      final alertService = Provider.of<AlertService>(context, listen: false);
      alertService.addListener(_onAlertServiceChanged);
    } catch (e) {
      print('⚠️ AlertsBox: AlertService در دسترس نیست: $e');
    }
  }

  @override
  void dispose() {
    try {
      final alertService = Provider.of<AlertService>(context, listen: false);
      alertService.removeListener(_onAlertServiceChanged);
    } catch (e) {
      print('⚠️ AlertsBox: خطا در حذف listener: $e');
    }
    super.dispose();
  }

  void _onAlertServiceChanged() {
    if (mounted) {
      _loadRecentAlerts();
    }
  }

  Future<void> _loadRecentAlerts() async {
    try {
      print('📥 AlertsBox: شروع بارگذاری اعلان‌ها');

      List<AlertNotification> allAlerts = [];

      // تلاش برای بارگذاری از سرور
      try {
        final isConnected = await ServerAlertService.testConnection();
        if (isConnected) {
          final serverAlerts = await ServerAlertService.getAllAlerts();
          print('📥 AlertsBox: تعداد اعلان‌های سرور: ${serverAlerts.length}');
          allAlerts.addAll(serverAlerts);
        } else {
          print('⚠️ AlertsBox: سرور در دسترس نیست');
        }
      } catch (serverError) {
        print('❌ AlertsBox: خطا در بارگذاری از سرور: $serverError');
      }

      // بارگذاری از حافظه محلی
      try {
        await NotificationService.initialize();
        final localAlerts = await NotificationService.getAllAlerts();
        print('📥 AlertsBox: تعداد اعلان‌های محلی: ${localAlerts.length}');
        allAlerts.addAll(localAlerts);
      } catch (localError) {
        print('❌ AlertsBox: خطا در بارگذاری محلی: $localError');
      }

      // اگر هیچ اعلانی وجود ندارد، یک اعلان تست اضافه کن
      if (allAlerts.isEmpty) {
        print('📝 AlertsBox: اضافه کردن اعلان تست');
        final testAlert = AlertNotification(
          id: 'test_alert_${DateTime.now().millisecondsSinceEpoch}',
          equipmentId: 'تجهیزات تست A-001',
          message: 'خطا در سیستم خنک‌کننده - نیاز به بررسی فوری',
          userId: 'test_user',
          createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
          seenBy: {},
        );
        allAlerts.add(testAlert);

        // اعلان تست دوم
        final testAlert2 = AlertNotification(
          id: 'test_alert_2_${DateTime.now().millisecondsSinceEpoch}',
          equipmentId: 'تجهیزات تست B-002',
          message: 'هشدار: دمای بالا در بخش تولید',
          userId: 'test_user',
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
          seenBy: {
            'user_1': UserSeenStatus(seenAt: DateTime.now(), seen: true)
          },
        );
        allAlerts.add(testAlert2);
      }

      // حذف تکرارها بر اساس ID
      final uniqueAlerts = <String, AlertNotification>{};
      for (final alert in allAlerts) {
        uniqueAlerts[alert.id] = alert;
      }

      final finalAlerts = uniqueAlerts.values.toList();
      print(
          '📥 AlertsBox: تعداد کل اعلان‌های منحصر به فرد: ${finalAlerts.length}');

      // مرتب‌سازی بر اساس تاریخ (جدیدترین اول)
      finalAlerts.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      // آخرین 3 اعلان
      final recentAlerts = finalAlerts.take(3).toList();
      print('📥 AlertsBox: آخرین 3 اعلان بارگذاری شد');

      // تعداد اعلان‌های جدید
      int newCount = 0;
      try {
        final authService = Provider.of<AuthService>(context, listen: false);
        final currentUser = authService.currentUser;

        if (currentUser != null) {
          // شمارش اعلان‌های جدید از سرور
          try {
            newCount = await ServerAlertService.getUnseenCount(currentUser.id);
          } catch (e) {
            print('⚠️ AlertsBox: خطا در شمارش اعلان‌های جدید از سرور: $e');
          }

          // شمارش اعلان‌های جدید از محلی
          try {
            final localNewCount =
                await NotificationService.getNewAlertsCount(currentUser.id);
            newCount += localNewCount;
          } catch (e) {
            print('⚠️ AlertsBox: خطا در شمارش اعلان‌های جدید محلی: $e');
          }

          print('📥 AlertsBox: تعداد اعلان‌های جدید: $newCount');
        }
      } catch (e) {
        print('⚠️ AlertsBox: خطا در دریافت کاربر: $e');
      }

      setState(() {
        _recentAlerts = recentAlerts;
        _newAlertsCount = newCount;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ AlertsBox: خطا در بارگذاری اعلان‌ها: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'دیروز';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} روز پیش';
    } else {
      return '${date.year}/${date.month}/${date.day}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 400,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // هدر باکس
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF2E7D32),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // آیکن اعلان
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.notifications_active_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),

                const SizedBox(width: 12),

                // عنوان و تعداد
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'اعلان‌های کارشناسان',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_recentAlerts.length} اعلان جدید',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),

                // آیکن‌های عملیات
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.refresh_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.add_alert_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // محتوای اصلی
          Expanded(
            child: _buildAlertsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertsList() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_recentAlerts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.notifications_none_rounded,
                size: 40,
                color: Colors.grey.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'هیچ اعلانی موجود نیست',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'اعلان‌های جدید اینجا نمایش داده می‌شوند',
              style: TextStyle(
                color: Colors.grey.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // لیست اعلان‌ها
        Expanded(
          child: ListView.builder(
            itemCount: _recentAlerts.length,
            itemBuilder: (context, index) {
              final alert = _recentAlerts[index];
              final currentUserId = 'user_1';
              final isNew = !alert.seenBy.containsKey(currentUserId);

              print('نمایش اعلان ${index + 1}: ${alert.equipmentId}');

              return PremiumAlertCard(
                alert: alert,
                isNew: isNew,
                onTap: () {
                  // نمایش جزئیات اعلان
                  print('اعلان انتخاب شد: ${alert.equipmentId}');
                },
                onLongPress: () {
                  // عملیات اضافی
                  print('اعلان نگه داشته شد: ${alert.equipmentId}');
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
