import 'package:flutter/material.dart';
import '../models/alert_notification.dart';
import '../models/user_seen_status.dart';
import 'premium_alert_card.dart';

class TestModernAlert extends StatelessWidget {
  const TestModernAlert({super.key});

  @override
  Widget build(BuildContext context) {
    // ایجاد اعلان‌های تست
    final testAlerts = [
      AlertNotification(
        id: '1',
        equipmentId: 'تجهیزات A-001',
        message: 'خطا در سیستم خنک‌کننده - نیاز به بررسی فوری',
        userId: 'user1',
        createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
        seenBy: {},
      ),
      AlertNotification(
        id: '2',
        equipmentId: 'تجهیزات B-002',
        message: 'هشدار: دمای بالا در بخش تولید',
        userId: 'user2',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        seenBy: {'user1': UserSeenStatus(seenAt: DateTime.now(), seen: true)},
      ),
      AlertNotification(
        id: '3',
        equipmentId: 'تجهیزات C-003',
        message: 'اطلاعیه: تعمیرات برنامه‌ریزی شده فردا',
        userId: 'user3',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        seenBy: {
          'user1': UserSeenStatus(seenAt: DateTime.now(), seen: true),
          'user2': UserSeenStatus(seenAt: DateTime.now(), seen: true)
        },
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('تست کارت‌های اعلان جدید'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: Container(
        color: const Color(0xFFF5F5F5),
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: testAlerts.length,
          itemBuilder: (context, index) {
            final alert = testAlerts[index];
            final isNew = alert.seenBy.isEmpty;

            return PremiumAlertCard(
              alert: alert,
              isNew: isNew,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('اعلان انتخاب شد: ${alert.equipmentId}'),
                    backgroundColor: const Color(0xFF2E7D32),
                  ),
                );
              },
              onLongPress: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('اعلان نگه داشته شد: ${alert.equipmentId}'),
                    backgroundColor: const Color(0xFFF39C12),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
