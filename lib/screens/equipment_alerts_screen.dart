import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/alert_notification.dart';
import '../models/alert_reply.dart';
import '../models/user_seen_status.dart';
import '../services/server_alert_service.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../services/alert_service.dart';
import '../widgets/page_header.dart';
import '../config/app_colors.dart';
import '../config/modern_colors.dart';
import 'equipment_details_screen.dart';
import 'alert_detail_page.dart';
import '../models/user_model.dart';

class EquipmentAlertsScreen extends StatefulWidget {
  final String equipmentName;

  const EquipmentAlertsScreen({
    super.key,
    required this.equipmentName,
  });

  @override
  State<EquipmentAlertsScreen> createState() => _EquipmentAlertsScreenState();
}

class _EquipmentAlertsScreenState extends State<EquipmentAlertsScreen> {
  List<AlertNotification> _equipmentAlerts = [];
  List<AlertNotification> _filteredAlerts = [];
  bool _isLoading = true;
  String? _selectedAlertId;
  bool _isChatExpanded = false;

  // فیلترهای جدید
  String _selectedFilter = 'همه';
  String _searchQuery = '';
  bool _isKeyboardVisible = false;



  @override
  void initState() {
    super.initState();
    _loadEquipmentAlerts();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // تشخیص تغییرات کیبورد
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
      final isKeyboardVisible = keyboardHeight > 0;

      if (_isKeyboardVisible != isKeyboardVisible) {
        setState(() {
          _isKeyboardVisible = isKeyboardVisible;
        });
      }
    });
  }

  void _applyFilters() {
    setState(() {
      _filteredAlerts = _equipmentAlerts.where((alert) {
        // فیلتر وضعیت
        bool statusFilter = true;
        if (_selectedFilter == 'جدید') {
          final authService = Provider.of<AuthService>(context, listen: false);
          final currentUser = authService.currentUser;
          final currentUserId = currentUser?.id ?? '';
          statusFilter = !alert.seenBy.containsKey(currentUserId);
        } else if (_selectedFilter == 'قدیمی') {
          final authService = Provider.of<AuthService>(context, listen: false);
          final currentUser = authService.currentUser;
          final currentUserId = currentUser?.id ?? '';
          statusFilter = alert.seenBy.containsKey(currentUserId);
        }

        // فیلتر جستجو
        bool searchFilter = true;
        if (_searchQuery.isNotEmpty) {
          searchFilter =
              alert.message.toLowerCase().contains(_searchQuery.toLowerCase());
        }

        return statusFilter && searchFilter;
      }).toList();
    });
  }



  Future<void> _loadEquipmentAlerts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print(
          '📥 EquipmentAlertsScreen: شروع بارگذاری اعلان‌های ${widget.equipmentName}');

      // بارگذاری از سرور و همگام‌سازی
      try {
        final isConnected = await ServerAlertService.testConnection();
        if (isConnected) {
          final serverAlerts = await ServerAlertService.getAllAlerts();
          final equipmentAlerts = serverAlerts
              .where((alert) => alert.equipmentId == widget.equipmentName)
              .toList();
          print(
              '📥 EquipmentAlertsScreen: تعداد اعلان‌های سرور: ${equipmentAlerts.length}');

          // همگام‌سازی اعلان‌های سرور با حافظه محلی
          await NotificationService.initialize();
          await NotificationService.syncServerAlertsToLocal(equipmentAlerts);
        }
      } catch (serverError) {
        print('❌ EquipmentAlertsScreen: خطا در بارگذاری از سرور: $serverError');
      }

      // بارگذاری از محلی (بعد از همگام‌سازی)
      try {
        await NotificationService.initialize();
        final localAlerts = await NotificationService.getAllAlerts();
        final equipmentAlerts = localAlerts
            .where((alert) => alert.equipmentId == widget.equipmentName)
            .toList();
        print(
            '📥 EquipmentAlertsScreen: تعداد اعلان‌های محلی: ${equipmentAlerts.length}');

        // مرتب‌سازی بر اساس تاریخ
        equipmentAlerts.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        setState(() {
          _equipmentAlerts = equipmentAlerts;
          _isLoading = false;
          _applyFilters(); // Apply filters after loading data
        });

        print(
            '✅ EquipmentAlertsScreen: بارگذاری تکمیل شد. تعداد: ${equipmentAlerts.length}');
      } catch (localError) {
        print('❌ EquipmentAlertsScreen: خطا در بارگذاری محلی: $localError');
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ EquipmentAlertsScreen: خطا در بارگذاری: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _toggleChat(String alertId) async {
    // علامت‌گذاری اعلان به عنوان خوانده شده
    await _markAlertAsSeen(alertId);

    // پیدا کردن اعلان مورد نظر
    final alert = _equipmentAlerts.firstWhere((a) => a.id == alertId);

    // انتقال مستقیم به صفحه چت
    if (mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => AlertDetailPage(alert: alert),
        ),
      );
    }
  }

  Future<void> _markAlertAsSeen(String alertId) async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final currentUser = authService.currentUser;

      if (currentUser != null) {
        // علامت‌گذاری در سرور
        try {
          await ServerAlertService.markAsSeen(
            alertId: alertId,
            userId: currentUser.id,
          );
        } catch (serverError) {
          print('⚠️ خطا در علامت‌گذاری سرور: $serverError');
          // ادامه می‌دهیم تا در محلی ذخیره شود
        }

        // علامت‌گذاری در حافظه محلی
        await NotificationService.initialize();
        await NotificationService.markAsSeen(alertId, currentUser.id);

        // به‌روزرسانی UI
        setState(() {
          final alertIndex =
              _equipmentAlerts.indexWhere((a) => a.id == alertId);
          if (alertIndex != -1) {
            final alert = _equipmentAlerts[alertIndex];
            final updatedSeenBy =
                Map<String, UserSeenStatus>.from(alert.seenBy);
            updatedSeenBy[currentUser.id] = UserSeenStatus(
              seen: true,
              seenAt: DateTime.now(),
            );

            _equipmentAlerts[alertIndex] =
                alert.copyWith(seenBy: updatedSeenBy);
            _applyFilters(); // اعمال فیلترها برای به‌روزرسانی نمایش
          }
        });
      }
    } catch (e) {
      print('خطا در علامت‌گذاری اعلان به عنوان خوانده شده: $e');
    }
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _getUserName(String userId) {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final users = authService.getAllUsersSync();
      final user = users.firstWhere(
        (u) => u.id == userId,
        orElse: () => UserModel(
          id: '',
          username: '',
          password: '',
          email: '',
          fullName: 'کاربر ناشناس',
          mobile: '',
          position: '',
        ),
      );
      return user.fullName.isNotEmpty ? user.fullName : 'کاربر ناشناس';
    } catch (e) {
      return 'کاربر ناشناس';
    }
  }

  String _formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (messageDate == today) {
      return 'امروز';
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      return 'دیروز';
    } else {
      return '${dateTime.year}/${dateTime.month}/${dateTime.day}';
    }
  }

  Widget _buildAlertCard(AlertNotification alert) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUser = authService.currentUser;
    final currentUserId = currentUser?.id ?? '';
    final isNew = !alert.seenBy.containsKey(currentUserId);
    final isSelected = _selectedAlertId == alert.id;

    // منطق کشویی متن اعلان: اگر کیبورد باز باشد، متن را ببند
    final bool shouldCollapseText = _isKeyboardVisible;

    // پیدا کردن نام کاربر
    final users = authService.getAllUsersSync();
    final alertUser = users.firstWhere(
      (user) => user.id == alert.userId,
      orElse: () => UserModel(
        id: '',
        username: '',
        password: '',
        email: '',
        fullName: 'کاربر نامشخص',
        mobile: '',
        position: '',
      ),
    );

    // گرادیان‌های گرم و حرفه‌ای
    final LinearGradient readGradient = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFFFFFFF), Color(0xFFFFF8E1)],
    );

    final LinearGradient unreadGradient = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFFFFFFF), Color(0xFFFFCC80)],
    );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        gradient: isNew ? unreadGradient : readGradient,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFFFB74D).withOpacity(0.3),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF9800).withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // هدر اعلان
          InkWell(
            onTap: () => _toggleChat(alert.id),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // نشانگر وضعیت با آیکون
                  Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: isNew
                          ? const Color(0xFFFF9800)
                          : const Color(0xFF2196F3),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (isNew
                                  ? const Color(0xFFFF9800)
                                  : const Color(0xFF2196F3))
                              .withOpacity(0.2),
                          blurRadius: 3,
                        ),
                      ],
                    ),
                    child: Icon(
                      isNew ? Icons.mark_email_unread : Icons.mark_email_read,
                      size: 11,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // محتوای اعلان
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // متن اعلان
                        Text(
                          alert.message,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2E3A59),
                          ),
                          maxLines: shouldCollapseText ? 1 : 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.right,
                        ),
                        const SizedBox(height: 8),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              _formatTime(alert.createdAt),
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF8E9BA8),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _formatDate(alert.createdAt),
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF8E9BA8),
                              ),
                            ),
                            const Spacer(),
                            if (isNew)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      const Color(0xFFFF9800).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: const Color(0xFFFF9800)
                                        .withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  'جدید',
                                  style: TextStyle(
                                    color: const Color(0xFFFF9800),
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // چت کشویی
          if (isSelected)
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: _buildChatSection(alert),
            ),
        ],
      ),
    );
  }

  Widget _buildChatSection(AlertNotification alert) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          // هدر چت
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.stopsAppBar.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  color: AppColors.stopsAppBar,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'پرسش و پاسخ',
                  style: TextStyle(
                    color: AppColors.stopsAppBar,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                Text(
                  '${alert.replies.length} پاسخ',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _showFullScreenChat(alert),
                  icon: const Icon(
                    Icons.fullscreen,
                    size: 18,
                    color: Colors.grey,
                  ),
                  tooltip: 'نمایش تمام صفحه',
                ),
              ],
            ),
          ),

          // فضای چت
          Container(
            height: 300,
            padding: const EdgeInsets.all(12),
            child: alert.replies.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 48,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'هنوز پاسخی ثبت نشده است',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: alert.replies.length,
                    itemBuilder: (context, index) {
                      final reply = alert.replies[index];
                      final authService =
                          Provider.of<AuthService>(context, listen: false);
                      final currentUser = authService.currentUser;
                      final currentUserId = currentUser?.id ?? '';
                      final isMyMessage = reply.userId == currentUserId;
                      final isRead = alert.seenBy.containsKey(currentUserId);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          mainAxisAlignment: isMyMessage
                              ? MainAxisAlignment.end
                              : MainAxisAlignment.start,
                          children: [
                            if (!isMyMessage) ...[
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: AppColors.stopsAppBar,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.person,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 6),
                            ],
                            Flexible(
                              child: Container(
                                constraints: BoxConstraints(
                                  maxWidth:
                                      MediaQuery.of(context).size.width * 0.6,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: isMyMessage
                                      ? AppColors.stopsAppBar
                                      : (isRead
                                          ? Colors.orange.withOpacity(0.15)
                                          : Colors.white),
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(24),
                                    topRight: const Radius.circular(24),
                                    bottomLeft:
                                        Radius.circular(isMyMessage ? 12 : 4),
                                    bottomRight:
                                        Radius.circular(isMyMessage ? 4 : 12),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 2,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: isMyMessage
                                      ? CrossAxisAlignment.end
                                      : CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      reply.message,
                                      style: TextStyle(
                                        color: isMyMessage
                                            ? Colors.white
                                            : Colors.black87,
                                        fontSize: 13,
                                        height: 1.3,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _formatTime(reply.createdAt),
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: isMyMessage
                                            ? Colors.white.withOpacity(0.8)
                                            : Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (isMyMessage) ...[
                              const SizedBox(width: 6),
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: AppColors.stopsAppBar,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.person,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
          ),

          // نوار ورود پاسخ
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: _buildReplyInput(alert),
          ),
        ],
      ),
    );
  }

  void _showFullScreenChat(AlertNotification alert) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FullScreenChatPage(
          alert: alert,
          onReplyAdded: (newReply) {
            // فقط UI را به‌روزرسانی می‌کنیم (پاسخ قبلاً در حافظه محلی ذخیره شده)
            _applyFilters();
          },
        ),
      ),
    );
  }

  Widget _buildFullScreenChat(AlertNotification alert) {
    return Column(
      children: [
        // هدر اعلان
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.stopsAppBar.withOpacity(0.1),
                AppColors.stopsAppBar.withOpacity(0.05),
              ],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.stopsAppBar.withOpacity(0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.stopsAppBar.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.stopsAppBar,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'اعلان اصلی',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Text(
                    _formatTime(alert.createdAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                alert.message,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                  height: 1.4,
                ),
                textAlign: TextAlign.right,
              ),
            ],
          ),
        ),

        // فضای چت
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            child: alert.replies.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'هنوز پاسخی ثبت نشده است',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: alert.replies.length,
                    itemBuilder: (context, index) {
                      final reply = alert.replies[index];
                      final authService =
                          Provider.of<AuthService>(context, listen: false);
                      final currentUser = authService.currentUser;
                      final currentUserId = currentUser?.id ?? '';
                      final isMyMessage = reply.userId == currentUserId;
                      final isRead = alert.seenBy.containsKey(currentUserId);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          mainAxisAlignment: isMyMessage
                              ? MainAxisAlignment.end
                              : MainAxisAlignment.start,
                          children: [
                            if (!isMyMessage) ...[
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: AppColors.stopsAppBar,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.person,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            Flexible(
                              child: Container(
                                constraints: BoxConstraints(
                                  maxWidth:
                                      MediaQuery.of(context).size.width * 0.7,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: isMyMessage
                                      ? AppColors.stopsAppBar
                                      : Colors.white,
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(24),
                                    topRight: const Radius.circular(24),
                                    bottomLeft:
                                        Radius.circular(isMyMessage ? 16 : 4),
                                    bottomRight:
                                        Radius.circular(isMyMessage ? 4 : 16),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: isMyMessage
                                      ? CrossAxisAlignment.end
                                      : CrossAxisAlignment.start,
                                  children: [
                                    // نام کاربر
                                    Text(
                                      _getUserName(reply.userId),
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: isMyMessage
                                            ? Colors.white.withOpacity(0.9)
                                            : AppColors.stopsAppBar
                                                .withOpacity(0.8),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    // متن پیام
                                    Text(
                                      reply.message,
                                      style: TextStyle(
                                        color: isMyMessage
                                            ? Colors.white
                                            : Colors.black87,
                                        fontSize: 13,
                                        height: 1.4,
                                      ),
                                      textAlign: TextAlign.right,
                                    ),
                                    const SizedBox(height: 6),
                                    // زمان
                                    Text(
                                      _formatTime(reply.createdAt),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isMyMessage
                                            ? Colors.white.withOpacity(0.8)
                                            : Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (isMyMessage) ...[
                              const SizedBox(width: 8),
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: AppColors.stopsAppBar,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.person,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ),

        // نوار ورود پاسخ
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(color: Colors.grey.shade300),
            ),
          ),
          child: _buildReplyInput(alert),
        ),
      ],
    );
  }

  Widget _buildFiltersSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // جستجو
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(24),
            ),
            child: TextField(
              onChanged: (value) {
                _searchQuery = value;
                _applyFilters();
              },
              decoration: InputDecoration(
                hintText: 'جستجو در اعلان‌ها...',
                prefixIcon: const Icon(Icons.search),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
            ),
          ),

          const SizedBox(height: 12),

          // فیلترهای افقی - بدون اسکرول
          Row(
            children: [
              Expanded(
                child: _buildFilterChip('همه', _selectedFilter == 'همه'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildFilterChip('جدید', _selectedFilter == 'جدید'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildFilterChip('قدیمی', _selectedFilter == 'قدیمی'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : AppColors.stopsAppBar,
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
        textAlign: TextAlign.center,
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = label;
        });
        _applyFilters();
      },
      backgroundColor: Colors.white,
      selectedColor: AppColors.stopsAppBar,
      checkmarkColor: Colors.white,
      side: BorderSide(
        color: isSelected ? AppColors.stopsAppBar : Colors.grey.shade300,
      ),
    );
  }

  Widget _buildReplyInput(AlertNotification alert) {
    final replyController = TextEditingController();
    bool hasText = false;
    bool isTyping = false;

    return StatefulBuilder(
      builder: (context, setState) {
        return Column(
          children: [
            // نشانگر تایپ کردن
            if (isTyping)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: Row(
                  children: [
                    Icon(
                      Icons.keyboard,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'در حال تایپ...',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),

            // نوار ورود
            Row(
              children: [
                // دکمه پیوست
                IconButton(
                  onPressed: () {
                    _showAttachmentOptions(alert);
                  },
                  icon: const Icon(
                    Icons.attach_file,
                    color: Colors.grey,
                    size: 20,
                  ),
                ),

                // فیلد متن
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F2F5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: TextField(
                      controller: replyController,
                      decoration: InputDecoration(
                        hintText: 'پاسخ خود را بنویسید...',
                        hintStyle: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                      maxLines: null,
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                      style: const TextStyle(fontSize: 14),
                      onChanged: (value) {
                        setState(() {
                          hasText = value.trim().isNotEmpty;
                        });

                        // شبیه‌سازی تایپ کردن
                        if (value.isNotEmpty && !isTyping) {
                          setState(() {
                            isTyping = true;
                          });
                          Future.delayed(const Duration(seconds: 2), () {
                            if (mounted) {
                              setState(() {
                                isTyping = false;
                              });
                            }
                          });
                        }
                      },
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                // دکمه ارسال
                Container(
                  decoration: BoxDecoration(
                    color:
                        hasText ? AppColors.stopsAppBar : Colors.grey.shade300,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: hasText
                        ? () async {
                            if (replyController.text.trim().isNotEmpty) {
                              try {
                                final authService = Provider.of<AuthService>(
                                    context,
                                    listen: false);
                                final currentUser = authService.currentUser;

                                if (currentUser != null) {
                                  // ارسال به سرور
                                  try {
                                    await ServerAlertService.addReply(
                                      alertId: alert.id,
                                      userId: currentUser.id,
                                      message: replyController.text.trim(),
                                    );
                                  } catch (serverError) {
                                    print(
                                        '⚠️ خطا در ارسال به سرور: $serverError');
                                    // ادامه می‌دهیم تا در محلی ذخیره شود
                                  }

                                  // ذخیره در حافظه محلی
                                  try {
                                    await NotificationService.replyToAlert(
                                      alertId: alert.id,
                                      userId: currentUser.id,
                                      message: replyController.text.trim(),
                                    );

                                    // به‌روزرسانی UI
                                    _applyFilters();
                                  } catch (localError) {
                                    print('❌ خطا در ذخیره محلی: $localError');
                                    // ادامه می‌دهیم
                                  }

                                  replyController.clear();
                                  setState(() {
                                    hasText = false;
                                    isTyping = false;
                                  });

                                  // نمایش پیام موفقیت
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('پاسخ با موفقیت ارسال شد'),
                                      backgroundColor: Colors.green,
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                }
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('خطا در ارسال پاسخ: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          }
                        : null,
                    icon: const Icon(
                      Icons.send,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  void _showAttachmentOptions(AlertNotification alert) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'انتخاب نوع پیوست',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.photo),
              title: const Text('عکس'),
              onTap: () {
                Navigator.pop(context);
                _attachImage(alert);
              },
            ),
            ListTile(
              leading: const Icon(Icons.file_present),
              title: const Text('فایل'),
              onTap: () {
                Navigator.pop(context);
                _attachFile(alert);
              },
            ),
            ListTile(
              leading: const Icon(Icons.location_on),
              title: const Text('موقعیت مکانی'),
              onTap: () {
                Navigator.pop(context);
                _attachLocation(alert);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _attachImage(AlertNotification alert) {
    // پیاده‌سازی آپلود عکس
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('قابلیت آپلود عکس به زودی اضافه می‌شود')),
    );
  }

  void _attachFile(AlertNotification alert) {
    // پیاده‌سازی آپلود فایل
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('قابلیت آپلود فایل به زودی اضافه می‌شود')),
    );
  }

  void _attachLocation(AlertNotification alert) {
    // پیاده‌سازی آپلود موقعیت
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('قابلیت آپلود موقعیت به زودی اضافه می‌شود')),
    );
  }

  void _showManagementOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'گزینه‌های مدیریت',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.mark_email_read),
              title: const Text('علامت‌گذاری همه به عنوان خوانده شده'),
              onTap: () {
                Navigator.pop(context);
                _markAllAsRead();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_sweep),
              title: const Text('حذف اعلان‌های قدیمی'),
              onTap: () {
                Navigator.pop(context);
                _showDeleteOldAlertsDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.download),
              title: const Text('خروجی اکسل'),
              onTap: () {
                Navigator.pop(context);
                _exportToExcel();
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('تنظیمات اعلان‌ها'),
              onTap: () {
                Navigator.pop(context);
                _showNotificationSettings();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _markAllAsRead() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final currentUser = authService.currentUser;

      if (currentUser != null) {
        for (final alert in _equipmentAlerts) {
          await ServerAlertService.markAsSeen(
            alertId: alert.id,
            userId: currentUser.id,
          );
        }

        _loadEquipmentAlerts();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('همه اعلان‌ها به عنوان خوانده شده علامت‌گذاری شدند'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطا در علامت‌گذاری: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showDeleteOldAlertsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف اعلان‌های قدیمی'),
        content:
            const Text('آیا می‌خواهید اعلان‌های قدیمی‌تر از 30 روز حذف شوند؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('انصراف'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteOldAlerts();
            },
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  void _deleteOldAlerts() {
    // پیاده‌سازی حذف اعلان‌های قدیمی
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('قابلیت حذف اعلان‌های قدیمی به زودی اضافه می‌شود')),
    );
  }

  void _exportToExcel() {
    // پیاده‌سازی خروجی اکسل
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('قابلیت خروجی اکسل به زودی اضافه می‌شود')),
    );
  }

  void _showNotificationSettings() {
    // پیاده‌سازی تنظیمات اعلان‌ها
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('قابلیت تنظیمات اعلان‌ها به زودی اضافه می‌شود')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.stopsAppBar,
      body: SafeArea(
        child: Column(
          children: [
            PageHeader(
              title: 'اعلان‌های ${widget.equipmentName}',
              onBackPressed: null,
              backRoute: null,
              actions: [],
            ),
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.mainContainerBackground,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Column(
                  children: [
                    // فیلترها و جستجو
                    _buildFiltersSection(),

                    // آمار اعلان‌ها
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(
                            Icons.notifications,
                            color: AppColors.stopsAppBar,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'تعداد اعلان‌ها: ${_filteredAlerts.length}',
                            style: TextStyle(
                              color: AppColors.stopsAppBar,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.right,
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.stopsAppBar.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Text(
                              widget.equipmentName,
                              style: TextStyle(
                                color: AppColors.stopsAppBar,
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // لیست اعلان‌ها
                    Expanded(
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : _filteredAlerts.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.notifications_none,
                                        size: 64,
                                        color: Colors.grey.shade400,
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'هیچ اعلانی برای این تجهیز یافت نشد',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey.shade600,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'اولین اعلان را شما ثبت کنید',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey.shade500,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  itemCount: _filteredAlerts.length,
                                  itemBuilder: (context, index) {
                                    return _buildAlertCard(
                                        _filteredAlerts[index]);
                                  },
                                ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _isKeyboardVisible
          ? null // مخفی کردن FAB وقتی کیبورد باز است
          : Container(
              decoration: BoxDecoration(
                gradient: ModernColors.primaryGradient,
                borderRadius: BorderRadius.circular(24),
                boxShadow: ModernColors.mediumShadow,
              ),
              child: FloatingActionButton(
                onPressed: _showFloatingMenu,
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                elevation: 0,
                child: const Icon(Icons.more_vert, size: 24),
              ),
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  void _showFloatingMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: ModernColors.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          boxShadow: ModernColors.strongShadow,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              trailing: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: ModernColors.primaryGradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.refresh, color: Colors.white, size: 20),
              ),
              title: const Text(
                'به‌روزرسانی اعلان‌ها',
                style: TextStyle(fontWeight: FontWeight.w600),
                textAlign: TextAlign.right,
              ),
              onTap: () {
                Navigator.pop(context);
                _loadEquipmentAlerts();
              },
            ),
            ListTile(
              trailing: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: ModernColors.secondaryGradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.precision_manufacturing,
                    color: Colors.white, size: 20),
              ),
              title: const Text(
                'مشاهده تجهیز',
                style: TextStyle(fontWeight: FontWeight.w600),
                textAlign: TextAlign.right,
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => EquipmentDetailsScreen(
                      equipmentName: widget.equipmentName,
                      allData: [],
                    ),
                  ),
                );
              },
            ),
            ListTile(
              trailing: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: ModernColors.successGradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                child:
                    const Icon(Icons.download, color: Colors.white, size: 20),
              ),
              title: const Text(
                'خروجی اکسل',
                style: TextStyle(fontWeight: FontWeight.w600),
                textAlign: TextAlign.right,
              ),
              onTap: () {
                Navigator.pop(context);
                _exportToExcel();
              },
            ),
            ListTile(
              trailing: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: ModernColors.info,
                  borderRadius: BorderRadius.circular(8),
                ),
                child:
                    const Icon(Icons.settings, color: Colors.white, size: 20),
              ),
              title: const Text(
                'تنظیمات اعلان‌ها',
                style: TextStyle(fontWeight: FontWeight.w600),
                textAlign: TextAlign.right,
              ),
              onTap: () {
                Navigator.pop(context);
                _showNotificationSettings();
              },
            ),
            ListTile(
              trailing: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: ModernColors.textSecondary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child:
                    const Icon(Icons.dashboard, color: Colors.white, size: 20),
              ),
              title: const Text(
                'بازگشت به داشبورد',
                style: TextStyle(fontWeight: FontWeight.w600),
                textAlign: TextAlign.right,
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).pushReplacementNamed('/dashboard');
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// کلاس صفحه چت تمام صفحه
class FullScreenChatPage extends StatefulWidget {
  final AlertNotification alert;
  final Function(AlertReply) onReplyAdded;

  const FullScreenChatPage({
    super.key,
    required this.alert,
    required this.onReplyAdded,
  });

  @override
  State<FullScreenChatPage> createState() => _FullScreenChatPageState();
}

class _FullScreenChatPageState extends State<FullScreenChatPage> {
  final TextEditingController _replyController = TextEditingController();
  bool _hasText = false;
  bool _isLoading = false;
  late AlertNotification _currentAlert;

  @override
  void initState() {
    super.initState();
    _currentAlert = widget.alert;
    _setupTextController();
  }

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  void _setupTextController() {
    _replyController.addListener(() {
      setState(() {
        _hasText = _replyController.text.trim().isNotEmpty;
      });
    });
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _getUserName(String userId) {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final users = authService.getAllUsersSync();
      final user = users.firstWhere(
        (u) => u.id == userId,
        orElse: () => UserModel(
          id: '',
          username: '',
          password: '',
          email: '',
          fullName: 'کاربر ناشناس',
          mobile: '',
          position: '',
        ),
      );
      return user.fullName.isNotEmpty ? user.fullName : 'کاربر ناشناس';
    } catch (e) {
      return 'کاربر ناشناس';
    }
  }

  void _loadUpdatedAlert() {
    // فعلاً فقط UI را به‌روزرسانی می‌کنیم
    // اعلان از طریق callback به صفحه اصلی به‌روزرسانی می‌شود
  }

  Future<void> _submitReply() async {
    if (_replyController.text.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final currentUser = authService.currentUser;

      if (currentUser != null) {
        // ارسال به سرور
        try {
          await ServerAlertService.addReply(
            alertId: _currentAlert.id,
            userId: currentUser.id,
            message: _replyController.text.trim(),
          );
        } catch (serverError) {
          print('⚠️ خطا در ارسال به سرور: $serverError');
        }

        // ذخیره در حافظه محلی
        try {
          await NotificationService.replyToAlert(
            alertId: _currentAlert.id,
            userId: currentUser.id,
            message: _replyController.text.trim(),
          );

          // بارگذاری مجدد از حافظه محلی
          final updatedAlerts = await NotificationService.getAllAlerts();
          final updatedAlert = updatedAlerts.firstWhere(
            (a) => a.id == _currentAlert.id,
            orElse: () => _currentAlert,
          );

          setState(() {
            _currentAlert = updatedAlert;
          });

          // اطلاع‌رسانی به صفحه اصلی
          widget.onReplyAdded(AlertReply(
            userId: currentUser.id,
            message: _replyController.text.trim(),
          ));
        } catch (localError) {
          print('❌ خطا در ذخیره محلی: $localError');
        }

        _replyController.clear();
        setState(() {
          _hasText = false;
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('پاسخ با موفقیت ارسال شد'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطا در ارسال پاسخ: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.stopsAppBar,
      body: SafeArea(
        child: Column(
          children: [
            PageHeader(
              title: 'چت ${_currentAlert.equipmentId}',
              backRoute: '/equipment_alerts',
              actions: [],
            ),
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Column(
                  children: [
                    // هدر اعلان
                    Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.stopsAppBar.withOpacity(0.1),
                            AppColors.stopsAppBar.withOpacity(0.05),
                          ],
                          begin: Alignment.topRight,
                          end: Alignment.bottomLeft,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: AppColors.stopsAppBar.withOpacity(0.2),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.stopsAppBar.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.stopsAppBar,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  'اعلان اصلی',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              Text(
                                _formatTime(_currentAlert.createdAt),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _currentAlert.message,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                              height: 1.4,
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ],
                      ),
                    ),

                    // فضای چت
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        child: _currentAlert.replies.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.chat_bubble_outline,
                                      size: 64,
                                      color: Colors.grey.shade400,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'هنوز پاسخی ثبت نشده است',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                itemCount: _currentAlert.replies.length,
                                itemBuilder: (context, index) {
                                  final reply = _currentAlert.replies[index];
                                  final authService = Provider.of<AuthService>(
                                      context,
                                      listen: false);
                                  final currentUser = authService.currentUser;
                                  final currentUserId = currentUser?.id ?? '';
                                  final isMyMessage =
                                      reply.userId == currentUserId;
                                  final isRead = _currentAlert.seenBy
                                      .containsKey(currentUserId);

                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: Row(
                                      mainAxisAlignment: isMyMessage
                                          ? MainAxisAlignment.end
                                          : MainAxisAlignment.start,
                                      children: [
                                        if (!isMyMessage) ...[
                                          Container(
                                            width: 32,
                                            height: 32,
                                            decoration: BoxDecoration(
                                              color: AppColors.stopsAppBar,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.person,
                                              color: Colors.white,
                                              size: 20,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                        ],
                                        Flexible(
                                          child: Container(
                                            constraints: BoxConstraints(
                                              maxWidth: MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  0.7,
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 12,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isMyMessage
                                                  ? AppColors.stopsAppBar
                                                  : Colors.white,
                                              borderRadius: BorderRadius.only(
                                                topLeft:
                                                    const Radius.circular(24),
                                                topRight:
                                                    const Radius.circular(24),
                                                bottomLeft: Radius.circular(
                                                    isMyMessage ? 16 : 4),
                                                bottomRight: Radius.circular(
                                                    isMyMessage ? 4 : 16),
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withOpacity(0.1),
                                                  blurRadius: 4,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: Column(
                                              crossAxisAlignment: isMyMessage
                                                  ? CrossAxisAlignment.end
                                                  : CrossAxisAlignment.start,
                                              children: [
                                                // نام کاربر
                                                Text(
                                                  _getUserName(reply.userId),
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w600,
                                                    color: isMyMessage
                                                        ? Colors.white
                                                            .withOpacity(0.9)
                                                        : AppColors.stopsAppBar
                                                            .withOpacity(0.8),
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                // متن پیام
                                                Text(
                                                  reply.message,
                                                  style: TextStyle(
                                                    color: isMyMessage
                                                        ? Colors.white
                                                        : Colors.black87,
                                                    fontSize: 15,
                                                    height: 1.4,
                                                  ),
                                                  textAlign: TextAlign.right,
                                                ),
                                                const SizedBox(height: 6),
                                                // زمان
                                                Text(
                                                  _formatTime(reply.createdAt),
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: isMyMessage
                                                        ? Colors.white
                                                            .withOpacity(0.8)
                                                        : Colors.grey.shade600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        if (isMyMessage) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            width: 32,
                                            height: 32,
                                            decoration: BoxDecoration(
                                              color: AppColors.stopsAppBar,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.person,
                                              color: Colors.white,
                                              size: 20,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  );
                                },
                              ),
                      ),
                    ),

                    // نوار ورود پاسخ
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border(
                          top: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                      child: Row(
                        children: [
                          // دکمه پیوست
                          IconButton(
                            onPressed: () {
                              // TODO: اضافه کردن قابلیت پیوست
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'قابلیت پیوست به زودی اضافه خواهد شد'),
                                ),
                              );
                            },
                            icon: const Icon(
                              Icons.attach_file,
                              color: Colors.grey,
                              size: 20,
                            ),
                          ),

                          // فیلد متن
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0F2F5),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: TextField(
                                controller: _replyController,
                                decoration: InputDecoration(
                                  hintText: 'پاسخ خود را بنویسید...',
                                  hintStyle: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 14,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
                                  ),
                                ),
                                maxLines: null,
                                textAlign: TextAlign.right,
                                textDirection: TextDirection.rtl,
                                style: const TextStyle(fontSize: 14),
                                onChanged: (value) {
                                  setState(() {
                                    _hasText = value.trim().isNotEmpty;
                                  });
                                },
                              ),
                            ),
                          ),

                          const SizedBox(width: 8),

                          // دکمه ارسال
                          Container(
                            decoration: BoxDecoration(
                              color: _hasText && !_isLoading
                                  ? AppColors.stopsAppBar
                                  : Colors.grey.shade300,
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              onPressed:
                                  _hasText && !_isLoading ? _submitReply : null,
                              icon: _isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                Colors.white),
                                      ),
                                    )
                                  : const Icon(
                                      Icons.send,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
