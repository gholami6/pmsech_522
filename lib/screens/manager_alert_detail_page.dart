import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:shamsi_date/shamsi_date.dart';
import '../models/manager_alert.dart';
import '../models/alert_reply.dart';
import '../services/manager_alert_service.dart';
import '../services/server_manager_alert_service.dart';
import '../config/app_colors.dart';
import '../widgets/page_header.dart';

class ManagerAlertDetailPage extends StatefulWidget {
  final ManagerAlert alert;

  const ManagerAlertDetailPage({
    super.key,
    required this.alert,
  });

  @override
  State<ManagerAlertDetailPage> createState() => _ManagerAlertDetailPageState();
}

class _ManagerAlertDetailPageState extends State<ManagerAlertDetailPage> {
  final _replyController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isLoading = false;
  Timer? _autoRefreshTimer;
  int _lastRepliesCount = 0;
  late ManagerAlert _currentAlert;
  bool _isAlertInfoExpanded = true; // برای باز/بسته کردن باکس عنوان

  @override
  void initState() {
    super.initState();
    _currentAlert = widget.alert;
    _lastRepliesCount = _currentAlert.replies.length;
    _startAutoRefresh();
    _markAsSeen();
  }

  @override
  void dispose() {
    _replyController.dispose();
    _scrollController.dispose();
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _checkForNewReplies();
    });
  }

  Future<void> _checkForNewReplies() async {
    try {
      final updatedAlert =
          await ServerManagerAlertService.getManagerAlertById(_currentAlert.id);
      if (updatedAlert != null &&
          updatedAlert.replies.length > _lastRepliesCount) {
        setState(() {
          _currentAlert = updatedAlert;
          _lastRepliesCount = updatedAlert.replies.length;
        });

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
      }
    } catch (e) {
      print('❌ خطا در بررسی پاسخ‌های جدید: $e');
    }
  }

  Future<void> _markAsSeen() async {
    try {
      final managerAlertService =
          Provider.of<ManagerAlertService>(context, listen: false);
      await managerAlertService.markAsSeen(_currentAlert.id);
    } catch (e) {
      print('❌ خطا در علامت‌گذاری به عنوان مشاهده شده: $e');
    }
  }

  Future<void> _submitReply() async {
    if (_replyController.text.trim().isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final managerAlertService =
          Provider.of<ManagerAlertService>(context, listen: false);
      await managerAlertService.addReply(
        alertId: _currentAlert.id,
        message: _replyController.text.trim(),
      );

      _replyController.clear();
      FocusScope.of(context).unfocus();

      // به‌روزرسانی تعداد پاسخ‌ها
      _lastRepliesCount = _currentAlert.replies.length;
    } catch (e) {
      print('❌ خطا در ارسال پاسخ: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطا در ارسال پاسخ: ${e.toString()}'),
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

  String _getUserName(String userId) {
    if (userId.contains('manager')) {
      return 'مدیر ${userId.split('_').last}';
    } else if (userId.contains('expert')) {
      return 'کارشناس ${userId.split('_').last}';
    } else if (userId.contains('supervisor')) {
      return 'سرپرست ${userId.split('_').last}';
    } else if (userId.contains('director')) {
      return 'مدیرعامل ${userId.split('_').last}';
    } else {
      return 'کاربر ${userId.split('_').last}';
    }
  }

  String _formatDate(DateTime date) {
    // تبدیل به تاریخ شمسی
    final persianDate = Jalali.fromDateTime(date);
    return '${persianDate.year}/${persianDate.month.toString().padLeft(2, '0')}/${persianDate.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = Provider.of<ManagerAlertService>(context, listen: false)
        .getCurrentUser();
    final isMyAlert = currentUser?.id == _currentAlert.userId;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.stopsAppBar,
        body: SafeArea(
          child: Column(
            children: [
              PageHeader(
                title: 'جزئیات اعلان مدیریت',
                onBackPressed: () => Navigator.of(context).pop(true),
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
                      // اطلاعات اعلان (قابل باز/بسته شدن)
                      Container(
                        margin: const EdgeInsets.all(16),
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
                        child: ExpansionTile(
                          title: Row(
                            children: [
                              Icon(
                                Icons.admin_panel_settings,
                                color: const Color(0xFF4CAF50),
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _currentAlert.title,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2E3A59),
                                  ),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                            ],
                          ),
                          initiallyExpanded: _isAlertInfoExpanded,
                          onExpansionChanged: (expanded) {
                            setState(() {
                              _isAlertInfoExpanded = expanded;
                            });
                          },
                          iconColor: const Color(0xFF4CAF50),
                          collapsedIconColor: const Color(0xFF4CAF50),
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    _currentAlert.message,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[700],
                                    ),
                                    textAlign: TextAlign.right,
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        _formatDate(_currentAlert.createdAt),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF4CAF50)
                                              .withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          _currentAlert.category,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF4CAF50),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  // گروه‌های هدف فقط برای مدیران نمایش داده می‌شود
                                  if (currentUser?.id == _currentAlert.userId &&
                                      (_currentAlert.targetStakeholderTypes
                                              .isNotEmpty ||
                                          _currentAlert
                                              .targetRoleTypes.isNotEmpty)) ...[
                                    const SizedBox(height: 8),
                                    const Divider(),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'گروه‌های هدف:',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF2E3A59),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    if (_currentAlert
                                        .targetStakeholderTypes.isNotEmpty) ...[
                                      Wrap(
                                        spacing: 4,
                                        runSpacing: 4,
                                        children: _currentAlert
                                            .targetStakeholderTypes
                                            .map((type) => Chip(
                                                  label: Text(
                                                    type,
                                                    style: const TextStyle(
                                                        fontSize: 10),
                                                  ),
                                                  backgroundColor:
                                                      const Color(0xFF2196F3)
                                                          .withOpacity(0.1),
                                                  labelStyle: const TextStyle(
                                                      color: Color(0xFF2196F3)),
                                                ))
                                            .toList(),
                                      ),
                                    ],
                                    if (_currentAlert
                                        .targetRoleTypes.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Wrap(
                                        spacing: 4,
                                        runSpacing: 4,
                                        children: _currentAlert.targetRoleTypes
                                            .map((role) => Chip(
                                                  label: Text(
                                                    role,
                                                    style: const TextStyle(
                                                        fontSize: 10),
                                                  ),
                                                  backgroundColor:
                                                      const Color(0xFF9C27B0)
                                                          .withOpacity(0.1),
                                                  labelStyle: const TextStyle(
                                                      color: Color(0xFF9C27B0)),
                                                ))
                                            .toList(),
                                      ),
                                    ],
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // لیست پاسخ‌ها
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: _currentAlert.replies.isEmpty
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
                                  itemCount: _currentAlert.replies.length,
                                  itemBuilder: (context, index) {
                                    final reply = _currentAlert.replies[index];
                                    final isMyMessage =
                                        currentUser?.id == reply.userId;

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
                                            CircleAvatar(
                                              radius: 16,
                                              backgroundColor:
                                                  const Color(0xFF4CAF50),
                                              backgroundImage: const AssetImage('assets/images/profile.png'),
                                              child: _getUserName(reply.userId).isEmpty ? Text(
                                                'U',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ) : null,
                                            ),
                                            const SizedBox(width: 8),
                                          ],
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: isMyMessage
                                                  ? CrossAxisAlignment.end
                                                  : CrossAxisAlignment.start,
                                              children: [
                                                // نام کاربر
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
                                                // پیام
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                    horizontal: 12,
                                                    vertical: 8,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: isMyMessage
                                                        ? const Color(
                                                            0xFF4CAF50)
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
                                                // زمان
                                                Text(
                                                  _formatDate(reply.createdAt),
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
                                            CircleAvatar(
                                              radius: 16,
                                              backgroundColor:
                                                  const Color(0xFF4CAF50),
                                              backgroundImage: const AssetImage('assets/images/profile.png'),
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
                      ),

                      // فیلد پاسخ (فقط اگر اجازه پاسخ داده شده باشد)
                      if (_currentAlert.allowReplies) ...[
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
                              Expanded(
                                child: TextField(
                                  controller: _replyController,
                                  maxLines: null,
                                  textAlign: TextAlign.right,
                                  textDirection: TextDirection.rtl,
                                  decoration: const InputDecoration(
                                    hintText: 'پاسخ خود را بنویسید...',
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                  onSubmitted: (_) => _submitReply(),
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: _isLoading ? null : _submitReply,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: _isLoading
                                        ? Colors.grey[300]
                                        : const Color(0xFF4CAF50),
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
                                      : const Icon(
                                          Icons.send,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        Container(
                          margin: const EdgeInsets.all(16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Colors.grey,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'پاسخ‌دهی برای این اعلان غیرفعال شده است',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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
