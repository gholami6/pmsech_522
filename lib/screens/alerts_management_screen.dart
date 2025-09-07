import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/alert_notification.dart';
import '../models/user_model.dart';
import '../models/user_seen_status.dart';
import '../services/server_alert_service.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';

import 'equipment_alerts_screen.dart';
import 'new_alert_page.dart';
import '../config/app_colors.dart';
import '../config/modern_colors.dart';
import '../config/standard_page_config.dart';
import 'package:hive/hive.dart';
import '../models/stop_data.dart';
import '../services/alert_service.dart';
import '../services/manager_alert_service.dart';
import '../widgets/premium_alert_card.dart';

class AlertsManagementScreen extends StatefulWidget {
  const AlertsManagementScreen({super.key});

  @override
  State<AlertsManagementScreen> createState() => _AlertsManagementScreenState();
}

class _AlertsManagementScreenState extends State<AlertsManagementScreen> {
  List<AlertNotification> _alerts = [];
  List<AlertNotification> _filteredAlerts = [];
  bool _isLoading = true;
  String _selectedFilter = 'همه'; // فیلتر: همه، جدید، قدیمی

  // فیلترهای پیشرفته
  String? _selectedUser;
  String? _selectedCategory;
  String? _selectedEquipment;

  @override
  void initState() {
    super.initState();
    _loadAlerts();
  }

  Future<void> _loadAlerts() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      print('📥 AlertsManagementScreen: شروع بارگذاری اعلان‌ها');

      // ابتدا همگام‌سازی با سرور برای حذف اعلان‌های قدیمی
      try {
        final isConnected = await ServerAlertService.testConnection();
        if (isConnected) {
          print('🔄 AlertsManagementScreen: شروع همگام‌سازی با سرور');
          await NotificationService.syncWithServer();
        } else {
          print('⚠️ AlertsManagementScreen: سرور در دسترس نیست');
        }
      } catch (syncError) {
        print('❌ AlertsManagementScreen: خطا در همگام‌سازی: $syncError');
      }

      // بارگذاری اعلان‌های همگام‌سازی شده از حافظه محلی
      try {
        await NotificationService.initialize();
        final localAlerts = await NotificationService.getAllAlerts();
        print(
            '📥 AlertsManagementScreen: تعداد اعلان‌های محلی: ${localAlerts.length}');

        // مرتب‌سازی بر اساس تاریخ (جدیدترین اول)
        localAlerts.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        // اضافه کردن اعلان تست برای نمایش کارت جدید
        if (localAlerts.isEmpty) {
          print('📝 AlertsManagementScreen: اضافه کردن اعلان تست');
          final testAlert = AlertNotification(
            userId: 'user_1',
            equipmentId: 'سنگ‌شکن فکی',
            message: 'مشکل در عملکرد سنگ‌شکن فکی - نیاز به بررسی فوری دارد',
            category: 'مکانیک',
          );
          localAlerts.add(testAlert);
        }

        if (mounted) {
          setState(() {
            _alerts = localAlerts;
            _filteredAlerts = localAlerts;
            _isLoading = false;
          });
        }
      } catch (localError) {
        print('❌ AlertsManagementScreen: خطا در بارگذاری محلی: $localError');
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }

      print('✅ AlertsManagementScreen: بارگذاری اعلان‌ها تکمیل شد');
    } catch (e) {
      print('❌ AlertsManagementScreen: خطا در بارگذاری اعلان‌ها: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطا در بارگذاری اعلان‌ها: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _applyFilter(String filter) {
    setState(() {
      _selectedFilter = filter;

      // اعمال فیلترهای پیشرفته
      var filteredAlerts = _alerts;

      // فیلتر بر اساس وضعیت (جدید/قدیمی)
      switch (filter) {
        case 'جدید':
          filteredAlerts = filteredAlerts.where((alert) {
            final authService =
                Provider.of<AuthService>(context, listen: false);
            final currentUser = authService.currentUser;
            final currentUserId = currentUser?.id ?? '';
            return !alert.seenBy.containsKey(currentUserId);
          }).toList();
          break;
        case 'قدیمی':
          filteredAlerts = filteredAlerts.where((alert) {
            final authService =
                Provider.of<AuthService>(context, listen: false);
            final currentUser = authService.currentUser;
            final currentUserId = currentUser?.id ?? '';
            return alert.seenBy.containsKey(currentUserId);
          }).toList();
          break;
        default:
          // همه اعلان‌ها
          break;
      }

      // فیلتر بر اساس کاربر
      if (_selectedUser != null && _selectedUser!.isNotEmpty) {
        filteredAlerts = filteredAlerts.where((alert) {
          return alert.userId == _selectedUser;
        }).toList();
      }

      // فیلتر بر اساس دسته‌بندی
      if (_selectedCategory != null && _selectedCategory!.isNotEmpty) {
        filteredAlerts = filteredAlerts.where((alert) {
          return alert.category == _selectedCategory;
        }).toList();
      }

      // فیلتر بر اساس تجهیز
      if (_selectedEquipment != null && _selectedEquipment!.isNotEmpty) {
        filteredAlerts = filteredAlerts.where((alert) {
          return alert.equipmentId == _selectedEquipment;
        }).toList();
      }

      _filteredAlerts = filteredAlerts;
    });
  }

  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('همه', _selectedFilter == 'همه'),
            const SizedBox(width: 8),
            _buildFilterChip('جدید', _selectedFilter == 'جدید'),
            const SizedBox(width: 8),
            _buildFilterChip('قدیمی', _selectedFilter == 'قدیمی'),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow:
            isSelected ? ModernColors.primaryShadow : ModernColors.softShadow,
      ),
      child: FilterChip(
        label: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : ModernColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        selected: isSelected,
        onSelected: (selected) {
          _applyFilter(label);
        },
        backgroundColor: ModernColors.surface,
        selectedColor: ModernColors.primary,
        checkmarkColor: Colors.white,
        side: BorderSide(
          color: isSelected ? ModernColors.primary : ModernColors.textLight,
          width: 1.5,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        elevation: 0,
        pressElevation: 2,
      ),
    );
  }

  Widget _buildAlertCard(AlertNotification alert) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUser = authService.currentUser;
    final currentUserId = currentUser?.id ?? '';
    final isNew = !alert.seenBy.containsKey(currentUserId);

    return PremiumAlertCard(
      alert: alert,
      isNew: isNew,
      onTap: () async {
        // علامت‌گذاری اعلان به عنوان خوانده شده
        await ServerAlertService.markAsSeen(
          alertId: alert.id,
          userId: currentUserId,
        );

        // ذخیره در حافظه محلی
        await _saveAlertToLocalStorage(alert.id, currentUserId);

        // به‌روزرسانی محلی
        if (mounted) {
          setState(() {
            final alertIndex = _alerts.indexWhere((a) => a.id == alert.id);
            if (alertIndex != -1) {
              final alert = _alerts[alertIndex];
              final updatedSeenBy =
                  Map<String, UserSeenStatus>.from(alert.seenBy);
              updatedSeenBy[currentUserId] = UserSeenStatus(
                seen: true,
                seenAt: DateTime.now(),
              );

              _alerts[alertIndex] = alert.copyWith(seenBy: updatedSeenBy);
              _applyFilter(
                  _selectedFilter); // اعمال فیلترها برای به‌روزرسانی نمایش
            }
          });
        }

        Navigator.of(context)
            .push(
          MaterialPageRoute(
            builder: (context) => EquipmentAlertsScreen(
              equipmentName: alert.equipmentId,
            ),
          ),
        )
            .then((_) {
          _loadAlerts();
        });
      },
    );
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

  void _showAdvancedFilters() {
    final authService = Provider.of<AuthService>(context, listen: false);
    final users = authService.getAllUsersSync();

    // لیست دسته‌بندی‌ها
    final categories = [
      'عمومی',
      'مکانیک',
      'برق',
      'پروسس',
      'کنترل',
      'ایمنی',
      'کیفیت',
      'نگهداری',
      'تعمیرات',
      'سایر',
    ];

    // لیست تجهیزات منحصر به فرد
    final equipments = _alerts
        .map((alert) => alert.equipmentId)
        .where((equipment) => equipment.isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'فیلترهای پیشرفته',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // فیلتر بر اساس کاربر
            DropdownButtonFormField<String>(
              value: _selectedUser,
              decoration: const InputDecoration(
                labelText: 'فیلتر بر اساس کاربر',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              items: [
                const DropdownMenuItem<String>(
                  value: null,
                  child: Text('همه کاربران'),
                ),
                ...users.map((user) => DropdownMenuItem<String>(
                      value: user.id,
                      child: Text(user.fullName),
                    )),
              ],
              onChanged: (value) {
                if (mounted) {
                  setState(() {
                    _selectedUser = value;
                  });
                }
                _applyFilter(_selectedFilter);
              },
            ),
            const SizedBox(height: 16),

            // فیلتر بر اساس دسته‌بندی
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'فیلتر بر اساس دسته‌بندی',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
              ),
              items: [
                const DropdownMenuItem<String>(
                  value: null,
                  child: Text('همه دسته‌بندی‌ها'),
                ),
                ...categories.map((category) => DropdownMenuItem<String>(
                      value: category,
                      child: Text(category),
                    )),
              ],
              onChanged: (value) {
                if (mounted) {
                  setState(() {
                    _selectedCategory = value;
                  });
                }
                _applyFilter(_selectedFilter);
              },
            ),
            const SizedBox(height: 16),

            // فیلتر بر اساس تجهیز
            DropdownButtonFormField<String>(
              value: _selectedEquipment,
              decoration: const InputDecoration(
                labelText: 'فیلتر بر اساس تجهیز',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.build),
              ),
              items: [
                const DropdownMenuItem<String>(
                  value: null,
                  child: Text('همه تجهیزات'),
                ),
                ...equipments.map((equipment) => DropdownMenuItem<String>(
                      value: equipment,
                      child: Text(equipment),
                    )),
              ],
              onChanged: (value) {
                if (mounted) {
                  setState(() {
                    _selectedEquipment = value;
                  });
                }
                _applyFilter(_selectedFilter);
              },
            ),
            const SizedBox(height: 16),

            // دکمه پاک کردن فیلترها
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (mounted) {
                    setState(() {
                      _selectedUser = null;
                      _selectedCategory = null;
                      _selectedEquipment = null;
                    });
                  }
                  _applyFilter(_selectedFilter);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('پاک کردن همه فیلترها'),
              ),
            ),
            const SizedBox(height: 16),

            // دکمه بستن
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('بستن'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showExportOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'گزینه‌های خروجی',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.table_chart),
              title: const Text('خروجی اکسل'),
              onTap: () {
                Navigator.pop(context);
                _exportToExcel();
              },
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf),
              title: const Text('خروجی PDF'),
              onTap: () {
                Navigator.pop(context);
                _exportToPDF();
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('اشتراک‌گذاری'),
              onTap: () {
                Navigator.pop(context);
                _shareAlerts();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _exportToExcel() {
    // پیاده‌سازی خروجی اکسل
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('قابلیت خروجی اکسل به زودی اضافه می‌شود')),
    );
  }

  void _exportToPDF() {
    // پیاده‌سازی خروجی PDF
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('قابلیت خروجی PDF به زودی اضافه می‌شود')),
    );
  }

  void _shareAlerts() {
    // پیاده‌سازی اشتراک‌گذاری
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('قابلیت اشتراک‌گذاری به زودی اضافه می‌شود')),
    );
  }

  void _showEditAlertDialog(AlertNotification alert) {
    final TextEditingController messageController =
        TextEditingController(text: alert.message);
    String? selectedEquipment = alert.equipmentId;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Center(
          child: Text(
            'ویرایش اعلان',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // انتخاب تجهیز
              FutureBuilder<List<String>>(
                future: _getEquipmentListFromDatabase(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  }

                  final equipmentList = snapshot.data ?? [];

                  // بررسی اینکه آیا تجهیز فعلی در لیست موجود است
                  if (!equipmentList.contains(selectedEquipment)) {
                    selectedEquipment = 'سایر';
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'تجهیز:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.right,
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: selectedEquipment,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: equipmentList.map((equipment) {
                          return DropdownMenuItem<String>(
                            value: equipment,
                            child: Text(equipment),
                          );
                        }).toList(),
                        onChanged: (value) {
                          selectedEquipment = value;
                        },
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              // متن اعلان
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'متن اعلان:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.right,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: messageController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('انصراف'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (messageController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('لطفاً متن اعلان را وارد کنید')),
                );
                return;
              }

              Navigator.of(context).pop();

              // ویرایش اعلان
              final success = await NotificationService.updateAlert(
                alertId: alert.id,
                currentUserId: Provider.of<AuthService>(context, listen: false)
                        .currentUser
                        ?.id ??
                    '',
                message: messageController.text.trim(),
                equipmentId: selectedEquipment,
              );

              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('اعلان با موفقیت ویرایش شد')),
                );
                if (mounted) {
                  setState(() {
                    _loadAlerts();
                  });
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('خطا در ویرایش اعلان')),
                );
              }
            },
            child: const Text('ذخیره'),
          ),
        ],
      ),
    );
  }

  /// دریافت لیست تجهیزات از دیتابیس StopData
  Future<List<String>> _getEquipmentListFromDatabase() async {
    try {
      final stopBox = await Hive.openBox<StopData>('stopData');
      Set<String> uniqueEquipments = {};

      for (var stopData in stopBox.values) {
        // اول از equipmentName استفاده کن، اگر نبود از equipment
        String equipmentName = stopData.equipmentName ?? stopData.equipment;
        if (equipmentName.isNotEmpty) {
          uniqueEquipments.add(equipmentName);
        }
      }

      final result = uniqueEquipments.toList()..sort();

      // اگر هیچ تجهیزی یافت نشد، لیست پیش‌فرض استفاده کن
      if (result.isEmpty) {
        return [
          'خط یک',
          'خط دو',
          'خط سه',
          'خط چهار',
          'خط پنج',
          'خط شش',
          'خط هفت',
          'خط هشت',
          'سنگ‌شکن فکی',
          'سنگ‌شکن مخروطی',
          'آسیاب گلوله‌ای',
          'آسیاب میله‌ای',
          'هیدروسیکلون',
          'فیلترپرس',
          'کوره دوار',
          'کولر',
          'الواتور',
          'کانوایر',
          'پمپ',
          'کمپرسور',
          'موتور',
          'ژنراتور',
          'تابلو برق',
          'سیستم کنترل',
          'سایر',
        ];
      }

      return result;
    } catch (e) {
      print('خطا در دریافت لیست تجهیزات: $e');
      // در صورت خطا، لیست پیش‌فرض استفاده کن
      return [
        'خط یک',
        'خط دو',
        'خط سه',
        'خط چهار',
        'خط پنج',
        'خط شش',
        'خط هفت',
        'خط هشت',
        'سنگ‌شکن فکی',
        'سنگ‌شکن مخروطی',
        'آسیاب گلوله‌ای',
        'آسیاب میله‌ای',
        'هیدروسیکلون',
        'فیلترپرس',
        'کوره دوار',
        'کولر',
        'الواتور',
        'کانوایر',
        'پمپ',
        'کمپرسور',
        'موتور',
        'ژنراتور',
        'تابلو برق',
        'سیستم کنترل',
        'سایر',
      ];
    }
  }

  void _showDeleteAlertDialog(AlertNotification alert) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف اعلان'),
        content: const Text('آیا از حذف این اعلان اطمینان دارید؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('انصراف'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteAlert(alert);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateAlert(
      AlertNotification alert, String message, String equipmentId) async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final currentUser = authService.currentUser;

      if (currentUser != null) {
        // تلاش برای بروزرسانی در سرور
        try {
          final isConnected = await ServerAlertService.testConnection();
          if (isConnected) {
            await ServerAlertService.updateAlert(
              alertId: alert.id,
              userId: currentUser.id,
              message: message,
              equipmentId: equipmentId,
            );
          }
        } catch (serverError) {
          print('⚠️ خطا در بروزرسانی سرور: $serverError');
        }

        // بروزرسانی در حافظه محلی
        try {
          await NotificationService.updateAlert(
            alertId: alert.id,
            currentUserId: currentUser.id,
            message: message,
            equipmentId: equipmentId,
          );
        } catch (localError) {
          print('❌ خطا در بروزرسانی محلی: $localError');
        }

        _loadAlerts();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('اعلان با موفقیت ویرایش شد'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطا در ویرایش اعلان: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteAlert(AlertNotification alert) async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final currentUser = authService.currentUser;

      if (currentUser != null) {
        // تلاش برای حذف از سرور
        try {
          final isConnected = await ServerAlertService.testConnection();
          if (isConnected) {
            await ServerAlertService.deleteAlert(
              alertId: alert.id,
              userId: currentUser.id,
            );
          }
        } catch (serverError) {
          print('⚠️ خطا در حذف از سرور: $serverError');
        }

        // حذف از حافظه محلی
        try {
          await NotificationService.deleteAlert(alert.id, currentUser.id);
        } catch (localError) {
          print('❌ خطا در حذف محلی: $localError');
        }

        _loadAlerts();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('اعلان با موفقیت حذف شد'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطا در حذف اعلان: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
                _loadAlerts();
              },
            ),
            ListTile(
              trailing: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: ModernColors.secondaryGradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.tune, color: Colors.white, size: 20),
              ),
              title: const Text(
                'فیلترهای پیشرفته',
                style: TextStyle(fontWeight: FontWeight.w600),
                textAlign: TextAlign.right,
              ),
              onTap: () {
                Navigator.pop(context);
                _showAdvancedFilters();
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
                'خروجی',
                style: TextStyle(fontWeight: FontWeight.w600),
                textAlign: TextAlign.right,
              ),
              onTap: () {
                Navigator.pop(context);
                _showExportOptions();
              },
            ),
            ListTile(
              trailing: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: ModernColors.secondaryGradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                child:
                    const Icon(Icons.add_alert, color: Colors.white, size: 20),
              ),
              title: const Text(
                'ثبت اعلان جدید',
                style: TextStyle(fontWeight: FontWeight.w600),
                textAlign: TextAlign.right,
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const NewAlertPage(),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StandardPageConfig.buildStandardPage(
      title: 'اعلان‌های کارشناسی',
      content: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.mainContainerBackground,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                    boxShadow: ModernColors.softShadow,
                  ),
                  child: Column(
                    children: [
                      // فیلترها
                      _buildFilterChips(),

                      // آمار
                      Container(
                        margin: const EdgeInsets.all(16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: ModernColors.primaryGradient,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: ModernColors.primaryShadow,
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: const Icon(
                                Icons.notifications_active,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'تعداد اعلان‌ها',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.8),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    textAlign: TextAlign.right,
                                  ),
                                  Text(
                                    '${_filteredAlerts.length}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                    ),
                                    textAlign: TextAlign.right,
                                  ),
                                ],
                              ),
                            ),
                            if (_selectedFilter != 'همه')
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  'فیلتر: $_selectedFilter',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
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
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.notifications_none,
                                          size: 64,
                                          color: Colors.grey,
                                        ),
                                        const SizedBox(height: 16),
                                        const Text(
                                          'هیچ اعلانی یافت نشد',
                                          style: TextStyle(
                                            fontSize: 18,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'تعداد اعلان‌های بارگذاری شده: ${_alerts.length}',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        ElevatedButton.icon(
                                          onPressed: _loadAlerts,
                                          icon: const Icon(Icons.refresh),
                                          label: const Text('بارگذاری مجدد'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                AppColors.stopsAppBar,
                                            foregroundColor: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : RefreshIndicator(
                                    onRefresh: _loadAlerts,
                                    color: AppColors.stopsAppBar,
                                    backgroundColor: Colors.white,
                                    child: ListView.builder(
                                      itemCount: _filteredAlerts.length,
                                      itemBuilder: (context, index) {
                                        return _buildAlertCard(
                                            _filteredAlerts[index]);
                                      },
                                    ),
                                  ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // FloatingActionButton
          Positioned(
            bottom: 16,
            right: 16,
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF2E7D32),
                    Color(0xFF66BB6A),
                  ],
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2E7D32).withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: FloatingActionButton.extended(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const NewAlertPage(),
                    ),
                  );
                },
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                elevation: 0,
                icon: const Icon(Icons.add_alert, size: 20),
                label: const Text(
                  'اعلان جدید',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveAlertToLocalStorage(String alertId, String userId) async {
    try {
      await NotificationService.initialize();

      // استفاده از تابع markAsSeen برای ذخیره در حافظه محلی
      await NotificationService.markAsSeen(alertId, userId);
    } catch (e) {
      print('خطا در ذخیره اعلان در حافظه محلی: $e');
    }
  }
}
