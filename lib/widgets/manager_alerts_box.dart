import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/manager_alert.dart';
import '../services/manager_alert_service.dart';
import '../services/auth_service.dart';
// حذف فراخوانی مستقیم سرور؛ همگام‌سازی فقط از طریق سرویس انجام می‌شود

class ManagerAlertsBox extends StatefulWidget {
  const ManagerAlertsBox({super.key});

  @override
  State<ManagerAlertsBox> createState() => _ManagerAlertsBoxState();
}

class _ManagerAlertsBoxState extends State<ManagerAlertsBox> {
  List<ManagerAlert> _recentAlerts = [];
  int _newAlertsCount = 0;
  bool _isLoading = true;
  bool _isSyncingWithServer = false;
  DateTime? _lastServerSync;

  @override
  void initState() {
    super.initState();
    _loadRecentAlerts();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // گوش دادن به تغییرات ManagerAlertService
    try {
      final managerAlertService =
          Provider.of<ManagerAlertService>(context, listen: false);
      managerAlertService.addListener(_onManagerAlertServiceChanged);
    } catch (e) {
      print('⚠️ ManagerAlertsBox: ManagerAlertService در دسترس نیست: $e');
    }
  }

  @override
  void dispose() {
    try {
      final managerAlertService =
          Provider.of<ManagerAlertService>(context, listen: false);
      managerAlertService.removeListener(_onManagerAlertServiceChanged);
    } catch (e) {
      print('⚠️ ManagerAlertsBox: خطا در حذف listener: $e');
    }
    super.dispose();
  }

  void _onManagerAlertServiceChanged() {
    if (mounted) {
      _loadRecentAlerts();
    }
  }

  Future<void> _loadRecentAlerts() async {
    try {
      print('📥 ManagerAlertsBox: شروع بارگذاری اعلان‌های مدیریت');

      // همگام‌سازی کنترل‌شده با سرور (در صورت گذشت زمان کافی)
      final now = DateTime.now();
      final shouldSync = _lastServerSync == null ||
          now.difference(_lastServerSync!).inSeconds > 15;

      if (shouldSync && !_isSyncingWithServer) {
        try {
          _isSyncingWithServer = true;
          final managerAlertService =
              Provider.of<ManagerAlertService>(context, listen: false);
          await managerAlertService.syncWithServer();
          _lastServerSync = now;
        } catch (e) {
          print('❌ ManagerAlertsBox: خطا در همگام‌سازی با سرور: $e');
        } finally {
          _isSyncingWithServer = false;
        }
      }

      // بارگذاری فقط از داده‌های محلی و فیلترشده برای کاربر فعلی
      final managerAlertService =
          Provider.of<ManagerAlertService>(context, listen: false);
      final authService = Provider.of<AuthService>(context, listen: false);
      final currentUser = authService.currentUser;

      List<ManagerAlert> finalAlerts = [];
      if (currentUser != null) {
        finalAlerts = managerAlertService.getManagerAlertsForCurrentUser();
      }

      // مرتب‌سازی بر اساس تاریخ (جدیدترین اول)
      finalAlerts.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      // آخرین 2 اعلان
      final recentAlerts = finalAlerts.take(2).toList();

      // تعداد اعلان‌های جدید
      final newCount = managerAlertService.getUnseenManagerAlerts().length;

      print(
          '📥 ManagerAlertsBox: تعداد کل اعلان‌های مدیریت (محلی): ${finalAlerts.length}');
      print('📥 ManagerAlertsBox: تعداد اعلان‌های جدید: $newCount');

      if (mounted) {
        setState(() {
          _recentAlerts = recentAlerts;
          _newAlertsCount = newCount;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ ManagerAlertsBox: خطا در بارگذاری اعلان‌های مدیریت: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshAlerts() async {
    setState(() {
      _isLoading = true;
    });
    await _loadRecentAlerts();
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

  void _navigateToManagerAlerts() {
    Navigator.pushNamed(context, '/manager-alerts').then((_) {
      _refreshAlerts();
    });
  }

  void _navigateToNewManagerAlert() {
    Navigator.pushNamed(context, '/new-manager-alert').then((_) {
      _refreshAlerts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // باکس اصلی
        Container(
          width: double.infinity,
          height: 168, // افزایش 1 سانتی متر (38 پیکسل) برای نمایش بهتر اعلان‌ها
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0x8000879E), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.18),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // هدر باکس (بدون ناوبری سریع)
                GestureDetector(
                  onTap: null,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.bottomLeft,
                        end: Alignment.topRight,
                        colors: [
                          Color(0xFF1A237E), // سرمه‌ای تیره
                          Color(0xFF3949AB), // سرمه‌ای روشن
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1A237E).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          // آیکن‌ها
                          IconButton(
                            icon: const Icon(
                              Icons.refresh,
                              color: Colors.white,
                              size: 18,
                            ),
                            onPressed: _refreshAlerts,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 28,
                              minHeight: 28,
                            ),
                          ),
                          const SizedBox(width: 1),
                          const SizedBox(width: 1),
                          IconButton(
                            icon: const Icon(
                              Icons.add_alert,
                              color: Colors.white,
                              size: 18,
                            ),
                            onPressed: _navigateToNewManagerAlert,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 28,
                              minHeight: 28,
                            ),
                          ),
                          const SizedBox(width: 4),
                          if (_newAlertsCount > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.red.withOpacity(0.3),
                                    blurRadius: 2,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Text(
                                '$_newAlertsCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          const SizedBox(width: 8),
                          // عنوان (قابل کلیک برای ناوبری)
                          Expanded(
                            child: GestureDetector(
                              onTap: _navigateToManagerAlerts,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: const Text(
                                  'اعلان‌های مدیریت',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    shadows: [
                                      Shadow(
                                        offset: Offset(0, 1),
                                        blurRadius: 2,
                                        color: Colors.black54,
                                      ),
                                    ],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // محتوای باکس با اسکرول
                Expanded(
                  child: _buildAlertsList(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAlertsList() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_recentAlerts.isEmpty) {
      return const Center(
        child: Text(
          'هیچ اعلانی موجود نیست',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 14,
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: _recentAlerts.length,
      itemBuilder: (context, index) {
        final alert = _recentAlerts[index];
        final authService = Provider.of<AuthService>(context, listen: false);
        final currentUser = authService.currentUser;
        final isNew =
            currentUser != null && !alert.seenBy.containsKey(currentUser.id);

        // گرادیان‌های سبز و حرفه‌ای
        final LinearGradient readGradient = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFFFFF), Color(0xFFE0F2F1)],
        );

        final LinearGradient unreadGradient = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFFFFF), Color(0xFFB2DFDB)],
        );

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.only(bottom: 6),
          decoration: BoxDecoration(
            gradient: isNew ? unreadGradient : readGradient,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: const Color(0x8000879E),
              width: 0.8,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0x8000879E).withOpacity(0.15),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListTile(
            dense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            leading: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color:
                    isNew ? const Color(0x8000879E) : const Color(0xFF2196F3),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (isNew
                            ? const Color(0x8000879E)
                            : const Color(0xFF2196F3))
                        .withOpacity(0.2),
                    blurRadius: 2,
                  ),
                ],
              ),
              child: Icon(
                isNew ? Icons.mark_email_unread : Icons.mark_email_read,
                size: 7,
                color: Colors.white,
              ),
            ),
            title: Text(
              alert.title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isNew ? FontWeight.bold : FontWeight.normal,
                color: const Color(0xFF2E3A59),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
            ),
            subtitle: Text(
              alert.message,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF5A6C7D),
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.right,
            ),
            trailing: Text(
              _formatDate(alert.createdAt),
              style: TextStyle(
                fontSize: 10,
                color: const Color(0xFF8E9BA8),
              ),
            ),
            onTap: () {
              _navigateToManagerAlerts();
            },
          ),
        );
      },
    );
  }
}
