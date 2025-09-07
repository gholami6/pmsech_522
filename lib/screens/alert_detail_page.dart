import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/alert_notification.dart';
import '../services/server_alert_service.dart';
import '../services/auth_service.dart';
import 'dart:io';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';
import '../screens/equipment_details_screen.dart';
import '../config/app_colors.dart';
import '../widgets/page_header.dart';

class AlertDetailPage extends StatefulWidget {
  final AlertNotification alert;

  const AlertDetailPage({
    super.key,
    required this.alert,
  });

  @override
  State<AlertDetailPage> createState() => _AlertDetailPageState();
}

class _AlertDetailPageState extends State<AlertDetailPage> {
  final _replyController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  bool _hasText = false;
  Timer? _autoRefreshTimer;
  int _lastRepliesCount = 0;

  // متغیر برای کنترل باز/بسته بودن متن اعلان
  bool _isMessageExpanded = false;

  @override
  void initState() {
    super.initState();
    _markAsSeen();
    _setupTextController();
    _startAutoRefresh();
    _lastRepliesCount = widget.alert.replies.length;
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    _replyController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _setupTextController() {
    _replyController.addListener(() {
      setState(() {
        _hasText = _replyController.text.trim().isNotEmpty;
      });
    });
  }

  // شروع به‌روزرسانی خودکار
  void _startAutoRefresh() {
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted) {
        _checkForNewReplies();
      }
    });
  }

  // بررسی پیام‌های جدید
  Future<void> _checkForNewReplies() async {
    try {
      final updatedAlert =
          await ServerAlertService.getAlertById(widget.alert.id);
      if (updatedAlert != null && mounted) {
        final newRepliesCount = updatedAlert.replies.length;

        // اگر تعداد پاسخ‌ها تغییر کرده، به‌روزرسانی کن
        if (newRepliesCount > _lastRepliesCount) {
          setState(() {
            // به‌روزرسانی اعلان با داده‌های جدید
            final newAlert = widget.alert.copyWith(
              replies: updatedAlert.replies,
              seenBy: updatedAlert.seenBy,
            );
            // به‌روزرسانی widget.alert
            widget.alert.replies.clear();
            widget.alert.replies.addAll(newAlert.replies);
            widget.alert.seenBy.clear();
            widget.alert.seenBy.addAll(newAlert.seenBy);
            _lastRepliesCount = newRepliesCount;
          });

          // اسکرول به پایین برای نمایش پیام‌های جدید
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scrollController.hasClients) {
              _scrollController.animateTo(
                _scrollController.position.maxScrollExtent,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            }
          });
        }
      }
    } catch (e) {
      print('⚠️ خطا در بررسی پیام‌های جدید: $e');
    }
  }

  Future<void> _markAsSeen() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final currentUser = authService.currentUser;

      if (currentUser != null) {
        await ServerAlertService.markAsSeen(
          alertId: widget.alert.id,
          userId: currentUser.id,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  Future<void> _submitReply() async {
    if (_replyController.text.trim().isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final currentUser = authService.currentUser;

      if (currentUser != null) {
        await ServerAlertService.addReply(
          alertId: widget.alert.id,
          userId: currentUser.id,
          message: _replyController.text.trim(),
        );

        _replyController.clear();

        // همگام‌سازی خودکار پس از ارسال
        await _refreshAlertData();
        _lastRepliesCount = widget.alert.replies.length;

        // اسکرول به پایین
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });

        // بستن کیبورد
        FocusScope.of(context).unfocus();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطا در ارسال پاسخ: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // همگام‌سازی خودکار داده‌های اعلان
  Future<void> _refreshAlertData() async {
    try {
      final updatedAlert =
          await ServerAlertService.getAlertById(widget.alert.id);
      if (updatedAlert != null && mounted) {
        setState(() {
          // به‌روزرسانی اعلان با داده‌های جدید
          final newAlert = widget.alert.copyWith(
            replies: updatedAlert.replies,
            seenBy: updatedAlert.seenBy,
          );
          // به‌روزرسانی widget.alert
          widget.alert.replies.clear();
          widget.alert.replies.addAll(newAlert.replies);
          widget.alert.seenBy.clear();
          widget.alert.seenBy.addAll(newAlert.seenBy);
        });
      }
    } catch (e) {
      print('⚠️ خطا در همگام‌سازی اعلان: $e');
    }
  }

  Future<void> _openAttachment() async {
    if (widget.alert.attachmentPath == null) return;

    final file = File(widget.alert.attachmentPath!);
    if (!await file.exists()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('فایل پیوست یافت نشد')),
        );
      }
      return;
    }

    final uri = Uri.file(file.path);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('نمی‌توان فایل را باز کرد')),
        );
      }
    }
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
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

  // دریافت نام کاربر بر اساس ID
  String _getUserName(String userId) {
    // در اینجا می‌توانید از دیتابیس یا کش نام کاربر را دریافت کنید
    // فعلاً از ID استفاده می‌کنیم
    if (userId.contains('manager')) {
      return 'مدیر ${userId.split('_').last}';
    } else if (userId.contains('expert')) {
      return 'کارشناس ${userId.split('_').last}';
    } else if (userId.contains('supervisor')) {
      return 'سرپرست ${userId.split('_').last}';
    } else {
      return 'کاربر ${userId.split('_').last}';
    }
  }

  // متد برای تغییر وضعیت باز/بسته بودن متن اعلان
  void _toggleMessageExpansion() {
    setState(() {
      _isMessageExpanded = !_isMessageExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUser = authService.currentUser;
    final currentUserId = currentUser?.id ?? '';

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.stopsAppBar,
        body: SafeArea(
          child: Column(
            children: [
              PageHeader(
                title: 'جزئیات اعلان کارشناسان',
                onBackPressed: () => Navigator.of(context).pop(true),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.precision_manufacturing,
                        color: Colors.white),
                    tooltip: 'مشاهده تجهیز',
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => EquipmentDetailsScreen(
                            equipmentName: widget.alert.equipmentId,
                            allData: [],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFCFD8DC),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    children: [
                      // هدر اعلان اصلی
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.stopsAppBar.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: AppColors.stopsAppBar.withOpacity(0.2),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Icon(
                                        Icons.notifications_active,
                                        color: AppColors.stopsAppBar,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'اعلان اصلی',
                                        style: TextStyle(
                                          color: AppColors.stopsAppBar,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  // متن اعلان با قابلیت باز/بسته کردن
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.7),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.grey.withOpacity(0.2),
                                        width: 1,
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        // متن اعلان
                                        Padding(
                                          padding: const EdgeInsets.all(12),
                                          child: Text(
                                            widget.alert.message,
                                            style: const TextStyle(
                                              fontSize: 15,
                                              height: 1.4,
                                            ),
                                            maxLines:
                                                _isMessageExpanded ? null : 3,
                                            overflow: _isMessageExpanded
                                                ? null
                                                : TextOverflow.ellipsis,
                                            textAlign: TextAlign.right,
                                          ),
                                        ),
                                        // آیکن باز/بسته کردن در وسط پایین
                                        Container(
                                          width: double.infinity,
                                          child: Center(
                                            child: InkWell(
                                              onTap: _toggleMessageExpansion,
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 4,
                                                        horizontal: 8),
                                                child: Icon(
                                                  _isMessageExpanded
                                                      ? Icons.keyboard_arrow_up
                                                      : Icons
                                                          .keyboard_arrow_down,
                                                  color: AppColors.stopsAppBar,
                                                  size: 20,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Text(
                                        _formatTime(widget.alert.createdAt),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        _formatDate(widget.alert.createdAt),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            if (widget.alert.attachmentPath != null) ...[
                              const SizedBox(height: 12),
                              InkWell(
                                onTap: _openAttachment,
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color:
                                        AppColors.stopsAppBar.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: AppColors.stopsAppBar
                                          .withOpacity(0.3),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.attach_file,
                                        color: AppColors.stopsAppBar,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'فایل پیوست',
                                        style: TextStyle(
                                          color: AppColors.stopsAppBar,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      // فضای چت
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: widget.alert.replies.isEmpty
                              ? const Center(
                                  child: Text(
                                    'هنوز پاسخی ثبت نشده است',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 16,
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  controller: _scrollController,
                                  padding: const EdgeInsets.all(16),
                                  itemCount: widget.alert.replies.length,
                                  itemBuilder: (context, index) {
                                    final reply = widget.alert.replies[index];
                                    final isMyMessage =
                                        reply.userId == currentUserId;

                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      child: Row(
                                        mainAxisAlignment: isMyMessage
                                            ? MainAxisAlignment.end
                                            : MainAxisAlignment.start,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
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
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: isMyMessage
                                                  ? CrossAxisAlignment.end
                                                  : CrossAxisAlignment.start,
                                              children: [
                                                if (!isMyMessage) ...[
                                                  Text(
                                                    _getUserName(reply.userId),
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color:
                                                          Colors.grey.shade700,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                ],
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                    horizontal: 12,
                                                    vertical: 8,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: isMyMessage
                                                        ? AppColors.stopsAppBar
                                                        : Colors.grey[200],
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                  ),
                                                  child: Text(
                                                    reply.message,
                                                    style: TextStyle(
                                                      color: isMyMessage
                                                          ? Colors.white
                                                          : Colors.black87,
                                                      fontSize: 14,
                                                    ),
                                                    textAlign: TextAlign.right,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  _formatTime(reply.createdAt),
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                              ],
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

                      // نوار ورود پیام (مشابه مدیریت)
                      Container(
                        margin: const EdgeInsets.all(16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
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
                            IconButton(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'قابلیت پیوست فایل به زودی اضافه خواهد شد'),
                                  ),
                                );
                              },
                              icon: Icon(
                                Icons.attach_file,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            Expanded(
                              child: TextField(
                                controller: _replyController,
                                maxLines: null,
                                textAlign: TextAlign.right,
                                textDirection: TextDirection.rtl,
                                decoration: const InputDecoration(
                                  hintText: 'پیام خود را بنویسید...',
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.zero,
                                ),
                                onSubmitted: (_) => _submitReply(),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: _hasText && !_isLoading
                                    ? AppColors.stopsAppBar
                                    : Colors.grey[300],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : GestureDetector(
                                      onTap: _hasText && !_isLoading
                                          ? _submitReply
                                          : null,
                                      child: const Icon(
                                        Icons.send,
                                        color: Colors.white,
                                        size: 20,
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
      ),
    );
  }
}
