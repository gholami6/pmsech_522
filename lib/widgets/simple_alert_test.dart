import 'package:flutter/material.dart';
import '../models/alert_notification.dart';
import '../models/user_seen_status.dart';
import 'premium_alert_card.dart';

class SimpleAlertTest extends StatelessWidget {
  const SimpleAlertTest({super.key});

  @override
  Widget build(BuildContext context) {
    // ایجاد اعلان‌های تست
    final testAlerts = [
      AlertNotification(
        id: 'test1',
        equipmentId: 'خط هشت',
        message: 'خطا در سیستم برقی - نیاز به بررسی فوری',
        userId: 'user1',
        createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
        seenBy: {},
      ),
      AlertNotification(
        id: 'test2',
        equipmentId: 'آسیاب گلوله‌ای',
        message: 'هشدار: دمای بالا در بخش تولید',
        userId: 'user2',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        seenBy: {'user1': UserSeenStatus(seenAt: DateTime.now(), seen: true)},
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('تست ساده کارت‌های اعلان'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: Container(
        color: const Color(0xFFF5F5F5),
        child: Column(
          children: [
            // اطلاعات تست
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  const Text(
                    'تست کارت‌های اعلان جدید',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'تعداد اعلان‌های تست: ${testAlerts.length}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),

            // لیست کارت‌ها
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: testAlerts.length,
                itemBuilder: (context, index) {
                  final alert = testAlerts[index];
                  final isNew = alert.seenBy.isEmpty;

                  print('نمایش کارت تست ${index + 1}: ${alert.equipmentId}');

                  return PremiumAlertCard(
                    alert: alert,
                    isNew: isNew,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('کارت انتخاب شد: ${alert.equipmentId}'),
                          backgroundColor: const Color(0xFF2E7D32),
                        ),
                      );
                    },
                    onLongPress: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content:
                              Text('کارت نگه داشته شد: ${alert.equipmentId}'),
                          backgroundColor: const Color(0xFFF39C12),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
