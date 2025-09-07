import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../providers/data_provider.dart';
import '../services/navigation_service.dart';
import 'dashboard_screen.dart';
import 'production_screen.dart';
import 'profile_screen.dart';
import 'annual_plan_screen.dart';

import 'equipment_list_screen.dart';
import 'comparison_demo_screen.dart';
import 'indicators_screen.dart';
import 'grade_entry_screen.dart';
import 'alerts_management_screen.dart';
import 'new_alert_page.dart';
import 'feed_input_screen.dart';
import 'product_screen.dart';
import 'tailing_screen.dart';
import 'stops_screen.dart';
import 'ai_assistant_page.dart';
import 'documents_screen.dart';
import 'document_upload_screen.dart';

import 'personnel_management_screen.dart';
import 'equipment_location_screen.dart';
import '../models/user_model.dart';
import '../models/position_model.dart';
import '../services/grade_service.dart';
import '../services/server_notification_manager.dart';
import '../config/app_colors.dart';

import 'package:flutter_speed_dial/flutter_speed_dial.dart';

class MainDashboardPage extends StatefulWidget {
  const MainDashboardPage({super.key});

  @override
  State<MainDashboardPage> createState() => _MainDashboardPageState();
}

class _MainDashboardPageState extends State<MainDashboardPage> {
  int _selectedIndex = 0;
  bool _hasTriedAutoSync = false;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const ProductionScreen(),
    const StopsScreen(),
    const IndicatorsScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _checkAndAutoSync();
    _startNotificationService();

    // ثبت مسیر اولیه در تاریخچه ناوبری
    final navigationService = NavigationService();
    navigationService.setCurrentRoute('/dashboard');
  }

  void _startNotificationService() {
    // سرویس نوتیفیکیشن خودکار غیرفعال شد - کاربر می‌تواند دستی چک کند
    print('ℹ️ سرویس نوتیفیکیشن خودکار غیرفعال شده است');
  }

  Future<void> _checkAndAutoSync() async {
    if (_hasTriedAutoSync) return;

    _hasTriedAutoSync = true;

    // همگام‌سازی خودکار فقط برای کاربران جدید - حذف شد
    // کاربران می‌توانند دستی همگام‌سازی کنند
    print(
        'ℹ️ همگام‌سازی خودکار غیرفعال شده است - کاربر می‌تواند دستی انجام دهد');
  }

  void _showSyncError(String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('خطا در به‌روزرسانی داده‌ها'),
        content: SingleChildScrollView(
          child: Text(
            error,
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 14),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('بستن'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dataProvider = Provider.of<DataProvider>(context);
    final isSyncing = dataProvider.isLoading;
    final error = dataProvider.error;
    final downloadProgress = dataProvider.downloadProgress;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (!didPop) {
          final navigationService = NavigationService();
          await navigationService.handleBackNavigation(context, '/dashboard');
        }
      },
      child: Stack(
        children: [
          Scaffold(
            body: IndexedStack(
              index: _selectedIndex,
              children: _screens,
            ),
          ),
        ],
      ),
    );
  }
}
