import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/manager_alert.dart';
import '../services/manager_alert_service.dart';
import '../services/auth_service.dart';
import '../config/app_colors.dart';
import '../config/alert_card_config.dart';

import 'manager_alert_detail_page.dart';

class ManagerAlertsScreen extends StatefulWidget {
  const ManagerAlertsScreen({super.key});

  @override
  State<ManagerAlertsScreen> createState() => _ManagerAlertsScreenState();
}

class _ManagerAlertsScreenState extends State<ManagerAlertsScreen> {
  List<ManagerAlert> _alerts = [];
  List<ManagerAlert> _filteredAlerts = [];
  bool _isLoading = true;
  String _selectedFilter = 'همه';
  String _selectedCategory = 'همه';

  @override
  void initState() {
    super.initState();
    _loadAlerts();
  }

  Future<void> _loadAlerts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('📥 ManagerAlertsScreen: شروع بارگذاری اعلان‌های مدیریت');

      final managerAlertService =
          Provider.of<ManagerAlertService>(context, listen: false);
      final authService = Provider.of<AuthService>(context, listen: false);
      final currentUser = authService.currentUser;

      // همگام‌سازی با سرور
      await managerAlertService.syncWithServer();

      // دریافت اعلان‌ها
      List<ManagerAlert> alerts = [];
      if (currentUser != null) {
        alerts = managerAlertService.getManagerAlertsForCurrentUser();
        print('📥 ManagerAlertsScreen: کاربر فعلی: ${currentUser.id}');
        print('📥 ManagerAlertsScreen: پوزیشن کاربر: ${currentUser.position}');
      } else {
        print('📥 ManagerAlertsScreen: کاربر فعلی null است');
      }

      print(
          '📥 ManagerAlertsScreen: تعداد اعلان‌های دریافت شده: ${alerts.length}');

      // دیباگ دقیق‌تر برای هر اعلان
      for (int i = 0; i < alerts.length; i++) {
        final alert = alerts[i];
        print('📥 ManagerAlertsScreen: اعلان $i: ${alert.title}');
        print(
            '📥 ManagerAlertsScreen: - SeenBy: ${alert.seenBy.keys.toList()}');
        if (currentUser != null) {
          final isSeen = alert.seenBy.containsKey(currentUser.id);
          print('📥 ManagerAlertsScreen: - آیا کاربر فعلی خوانده: $isSeen');
        }
      }

      if (mounted) {
        setState(() {
          _alerts = alerts;
          _filteredAlerts = alerts;
          _isLoading = false;
        });
      }

      print('✅ ManagerAlertsScreen: بارگذاری اعلان‌ها تکمیل شد');
    } catch (e) {
      print('❌ ManagerAlertsScreen: خطا در بارگذاری اعلان‌ها: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _applyFilter(String filter) {
    setState(() {
      _selectedFilter = filter;
      _filteredAlerts = _alerts.where((alert) {
        final authService = Provider.of<AuthService>(context, listen: false);
        final currentUser = authService.currentUser;

        if (currentUser == null) return true;

        final isNew = !alert.seenBy.containsKey(currentUser.id);

        switch (filter) {
          case 'جدید':
            return isNew;
          case 'قدیمی':
            return !isNew;
          default:
            return true;
        }
      }).toList();
    });
  }

  void _applyCategoryFilter(String category) {
    setState(() {
      _selectedCategory = category;
      _filteredAlerts = _alerts.where((alert) {
        if (category == 'همه') return true;
        return alert.category == category;
      }).toList();
    });
  }

  void _showAlertDetail(ManagerAlert alert) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUser = authService.currentUser;

    if (currentUser != null) {
      final managerAlertService =
          Provider.of<ManagerAlertService>(context, listen: false);
      await managerAlertService.markAsSeen(alert.id);
    }

    if (mounted) {
      final result = await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ManagerAlertDetailPage(alert: alert),
        ),
      );

      if (result == true) {
        _loadAlerts();
      }
    }
  }

  void _showEditAlertDialog(ManagerAlert alert) {
    Navigator.of(context).pushNamed('/new-manager-alert', arguments: {
      'isEditing': true,
      'alert': alert,
    });
  }

  void _showDeleteAlertDialog(ManagerAlert alert) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف اعلان'),
        content: const Text('آیا از حذف این اعلان اطمینان دارید؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('انصراف'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _deleteAlert(alert);
            },
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAlert(ManagerAlert alert) async {
    try {
      final managerAlertService =
          Provider.of<ManagerAlertService>(context, listen: false);
      await managerAlertService.deleteManagerAlert(alert.id);

      if (mounted) {
        setState(() {
          _alerts.removeWhere((a) => a.id == alert.id);
          _applyFilter(_selectedFilter);
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('اعلان با موفقیت حذف شد'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطا در حذف اعلان: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
        _applyFilter(label);
      },
      backgroundColor: Colors.white,
      selectedColor: AppColors.stopsAppBar,
      checkmarkColor: Colors.white,
      side: BorderSide(
        color: isSelected ? AppColors.stopsAppBar : Colors.grey.shade300,
      ),
    );
  }

  Widget _buildAlertCard(ManagerAlert alert) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUser = authService.currentUser;
    final isNew =
        currentUser != null && !alert.seenBy.containsKey(currentUser.id);
    final canDelete = currentUser?.id == alert.userId;
    final canEdit = currentUser?.id == alert.userId;

    // تعیین رنگ آکسان بر اساس دسته‌بندی
    final accentColor = _getCategoryAccentColor(alert.category);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        margin: ModernAlertCardConfig.cardMargin,
        decoration: BoxDecoration(
          borderRadius:
              BorderRadius.circular(ModernAlertCardConfig.cardBorderRadius),
          boxShadow: ModernAlertCardConfig.cardShadow,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _showAlertDetail(alert),
            onLongPress: (canDelete || canEdit)
                ? () => _showOptionsMenu(alert, canEdit, canDelete)
                : null,
            borderRadius:
                BorderRadius.circular(ModernAlertCardConfig.cardBorderRadius),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(
                    ModernAlertCardConfig.cardBorderRadius),
                gradient: isNew
                    ? ModernAlertCardConfig.getNewCardGradient()
                    : ModernAlertCardConfig.getReadCardGradient(),
              ),
              child: Stack(
                children: [
                  // پس‌زمینه گرافیکی
                  Positioned(
                    top: -ModernAlertCardConfig.backgroundCircleOffset,
                    right: -ModernAlertCardConfig.backgroundCircleOffset,
                    child: Container(
                      width: ModernAlertCardConfig.backgroundCircleSize,
                      height: ModernAlertCardConfig.backgroundCircleSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient:
                            ModernAlertCardConfig.getBackgroundCircleGradient(
                                accentColor),
                      ),
                    ),
                  ),

                  // نوار رنگی کناری
                  Positioned(
                    right: 0,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      width: ModernAlertCardConfig.accentBarWidth,
                      decoration: BoxDecoration(
                        color: accentColor,
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(
                              ModernAlertCardConfig.cardBorderRadius),
                          bottomRight: Radius.circular(
                              ModernAlertCardConfig.cardBorderRadius),
                        ),
                        boxShadow: ModernAlertCardConfig.getAccentBarShadow(
                            accentColor),
                      ),
                    ),
                  ),

                  // محتوای اصلی
                  Padding(
                    padding: ModernAlertCardConfig.contentPadding,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // عنوان و منو
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            // آیکن دسته‌بندی
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: accentColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                _getCategoryIcon(alert.category),
                                color: accentColor,
                                size: ModernAlertCardConfig.iconSize,
                              ),
                            ),

                            const SizedBox(
                                width: ModernAlertCardConfig.iconSpacing),

                            // عنوان
                            Expanded(
                              child: Text(
                                alert.title,
                                style:
                                    ModernAlertCardConfig.getTitleStyle(isNew),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.end,
                              ),
                            ),

                            const SizedBox(width: 8),

                            // منو (فقط برای نویسنده)
                            if (canDelete || canEdit)
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Icon(
                                  Icons.more_vert,
                                  size: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                          ],
                        ),

                        SizedBox(
                            height: ModernAlertCardConfig.titleTimeSpacing),

                        // دسته‌بندی و تاریخ
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // تاریخ
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.access_time,
                                    size: 14,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _formatTime(alert.createdAt),
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey[700],
                                      fontFamily: 'Vazirmatn',
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // دسته‌بندی
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: accentColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: accentColor.withOpacity(0.4),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: accentColor.withOpacity(0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _getCategoryIcon(alert.category),
                                    size: 14,
                                    color: accentColor,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    alert.category,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: accentColor,
                                      fontFamily: 'Vazirmatn',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: ModernAlertCardConfig.messageSpacing),

                        // دستور اداری (پیام)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[200]!),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              // عنوان بخش
                              Row(
                                children: [
                                  Icon(
                                    Icons.description,
                                    size: 16,
                                    color: accentColor,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'دستور اداری',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: accentColor,
                                      fontFamily: 'Vazirmatn',
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              // متن پیام
                              Text(
                                alert.message,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                  color: const Color(0xFF2C3E50),
                                  fontFamily: 'Vazirmatn',
                                  height: 1.4,
                                ),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.end,
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: ModernAlertCardConfig.messageSpacing),

                        // فوتر - تعداد پاسخ‌ها و وضعیت
                        Row(
                          children: [
                            // تعداد پاسخ‌ها
                            if (alert.replies.isNotEmpty)
                              Row(
                                children: [
                                  Text(
                                    '${alert.replies.length} پاسخ',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                      fontFamily: 'Vazirmatn',
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.reply,
                                    size: 14,
                                    color: Colors.grey[600],
                                  ),
                                ],
                              ),

                            const Spacer(),

                            // وضعیت جدید/قدیمی
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isNew ? Colors.orange : Colors.grey[300],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                isNew ? 'جدید' : 'خوانده شده',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color:
                                      isNew ? Colors.white : Colors.grey[700],
                                  fontFamily: 'Vazirmatn',
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
        ),
      ),
    );
  }

  void _showOptionsMenu(ManagerAlert alert, bool canEdit, bool canDelete) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (canEdit)
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.blue),
                title: const Text('ویرایش'),
                onTap: () {
                  Navigator.pop(context);
                  _showEditAlertDialog(alert);
                },
              ),
            if (canDelete)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('حذف'),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteAlertDialog(alert);
                },
              ),
          ],
        ),
      ),
    );
  }

  Color _getCategoryAccentColor(String category) {
    // استفاده از رنگ سبز یکسان برای همه دسته‌بندی‌ها
    return const Color(0xFF2ECC71); // سبز
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'جلسات':
        return Icons.meeting_room;
      case 'مناسبت ها':
        return Icons.event;
      case 'دستورات':
        return Icons.assignment;
      case 'اطلاعیه ها':
        return Icons.announcement;
      default:
        return Icons.notifications;
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}د';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}س';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}روز';
    } else {
      return '${dateTime.month}/${dateTime.day}';
    }
  }

  void _resetFilters() {
    setState(() {
      _selectedFilter = 'همه';
      _selectedCategory = 'همه';
      _filteredAlerts = _alerts;
    });
    print('🔄 فیلترها ریست شدند');
    print('🔍 _alerts.length = ${_alerts.length}');
    print('🔍 _filteredAlerts.length = ${_filteredAlerts.length}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mainContainerBackground,
      appBar: AppBar(
        title: const Text('اعلان‌های مدیریت'),
        backgroundColor: AppColors.stopsAppBar,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: AppColors.mainContainerBackground,
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Wrap(
                          spacing: 8,
                          children: [
                            _buildFilterChip('همه', _selectedFilter == 'همه'),
                            _buildFilterChip('جدید', _selectedFilter == 'جدید'),
                            _buildFilterChip(
                                'قدیمی', _selectedFilter == 'قدیمی'),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: _resetFilters,
                        icon: const Icon(Icons.refresh, size: 16),
                        label:
                            const Text('ریست', style: TextStyle(fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedCategory,
                              isExpanded: true,
                              items: [
                                'همه',
                                ...ManagerAlertService.getAlertCategories()
                              ].map((category) {
                                return DropdownMenuItem<String>(
                                  value: category,
                                  child: Text(category),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  _applyCategoryFilter(value);
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
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
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _filteredAlerts.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.notifications_none,
                                  size: 64,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'هیچ اعلانی موجود نیست',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadAlerts,
                            child: ListView.builder(
                              itemCount: _filteredAlerts.length,
                              itemBuilder: (context, index) {
                                return _buildAlertCard(_filteredAlerts[index]);
                              },
                            ),
                          ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/new-manager-alert').then((_) {
            _loadAlerts();
          });
        },
        backgroundColor: AppColors.stopsAppBar,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}
