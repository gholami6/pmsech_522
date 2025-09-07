import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/alert_notification.dart';
import '../models/user_model.dart';
import '../services/server_alert_service.dart';
import '../services/auth_service.dart';
import '../providers/data_provider.dart';
import '../widgets/page_header.dart';
import 'alert_detail_page.dart';
import '../config/app_colors.dart';

class AlertsManagementScreen extends StatefulWidget {
  const AlertsManagementScreen({super.key});

  @override
  State<AlertsManagementScreen> createState() => _AlertsManagementScreenState();
}

class _AlertsManagementScreenState extends State<AlertsManagementScreen> {
  List<AlertNotification> _alerts = [];
  List<AlertNotification> _filteredAlerts = [];
  bool _isLoading = true;
  bool _showArchived = false;

  // فیلترها
  String? _selectedEquipment;
  String? _selectedStatus;
  String? _selectedCategory;
  String _searchQuery = '';

  // کنترلر جستجو
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadAlerts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAlerts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final alerts = await ServerAlertService.getAllAlerts(
        includeArchived: _showArchived,
        equipmentId: _selectedEquipment,
        status: _selectedStatus,
        category: _selectedCategory,
        searchQuery: _searchQuery.isNotEmpty ? _searchQuery : null,
      );

      setState(() {
        _alerts = alerts;
        _filteredAlerts = alerts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
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

  void _applyFilters() {
    _loadAlerts();
  }

  void _clearFilters() {
    setState(() {
      _selectedEquipment = null;
      _selectedStatus = null;
      _selectedCategory = null;
      _searchQuery = '';
      _searchController.clear();
    });
    _loadAlerts();
  }

  Future<void> _archiveAlert(AlertNotification alert) async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final currentUser = authService.currentUser;

      if (currentUser != null) {
        await ServerAlertService.archiveAlert(
          alertId: alert.id,
          userId: currentUser.id,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('اعلان آرشیو شد'),
              backgroundColor: Colors.green,
            ),
          );
          _loadAlerts();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطا در آرشیو کردن: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateAlertStatus(
      AlertNotification alert, String newStatus) async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final currentUser = authService.currentUser;

      if (currentUser != null) {
        await ServerAlertService.updateAlertStatus(
          alertId: alert.id,
          status: newStatus,
          resolvedBy: newStatus == 'resolved' ? currentUser.id : null,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('وضعیت اعلان به ${alert.statusText} تغییر یافت'),
              backgroundColor: Colors.green,
            ),
          );
          _loadAlerts();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطا در بروزرسانی وضعیت: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildFilterSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.filter_list, color: AppColors.stopsAppBar),
              const SizedBox(width: 8),
              const Text(
                'فیلترها',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.stopsAppBar,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: _clearFilters,
                icon: const Icon(Icons.clear, size: 16),
                label: const Text('پاک کردن'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // جستجو
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'جستجو در اعلان‌ها...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                  _searchQuery = '';
                  _applyFilters();
                },
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onSubmitted: (value) {
              _searchQuery = value;
              _applyFilters();
            },
          ),
          const SizedBox(height: 12),

          // فیلترهای دیگر
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedStatus,
                  decoration: const InputDecoration(
                    labelText: 'وضعیت',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('همه')),
                    const DropdownMenuItem(
                        value: 'active', child: Text('فعال')),
                    const DropdownMenuItem(
                        value: 'pending', child: Text('در انتظار')),
                    const DropdownMenuItem(
                        value: 'resolved', child: Text('حل شده')),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedStatus = value);
                    _applyFilters();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'دسته‌بندی',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('همه')),
                    const DropdownMenuItem(
                        value: 'technical', child: Text('فنی')),
                    const DropdownMenuItem(
                        value: 'process', child: Text('پروسس')),
                    const DropdownMenuItem(
                        value: 'maintenance', child: Text('نگهداری')),
                    const DropdownMenuItem(
                        value: 'general', child: Text('عمومی')),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedCategory = value);
                    _applyFilters();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // نمایش آرشیو
          Row(
            children: [
              Switch(
                value: _showArchived,
                onChanged: (value) {
                  setState(() => _showArchived = value);
                  _loadAlerts();
                },
              ),
              const SizedBox(width: 8),
              const Text('نمایش اعلان‌های آرشیو شده'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAlertCard(AlertNotification alert) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUser = authService.getCurrentUser();
    final currentUserId = currentUser?.id ?? '';
    final isNew = !alert.seenBy.containsKey(currentUserId);
    final isRecent = DateTime.now().difference(alert.createdAt).inDays < 7;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: isNew ? Colors.blue : Colors.grey.shade300,
          width: isNew ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => AlertDetailPage(alert: alert),
            ),
          );
        },
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // هدر کارت
              Row(
                children: [
                  // نشان وضعیت
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(alert.status),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Text(
                      alert.statusText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // نشان اولویت
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getPriorityColor(alert.priority),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Text(
                      alert.priorityText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // نشان دسته‌بندی
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade600,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Text(
                      alert.categoryText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const Spacer(),

                  // منوی عملیات
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'archive':
                          _archiveAlert(alert);
                          break;
                        case 'resolve':
                          _updateAlertStatus(alert, 'resolved');
                          break;
                        case 'pending':
                          _updateAlertStatus(alert, 'pending');
                          break;
                        case 'active':
                          _updateAlertStatus(alert, 'active');
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      if (!alert.isArchived)
                        const PopupMenuItem(
                          value: 'archive',
                          child: Row(
                            children: [
                              Icon(Icons.archive),
                              SizedBox(width: 8),
                              Text('آرشیو'),
                            ],
                          ),
                        ),
                      if (alert.status != 'resolved')
                        const PopupMenuItem(
                          value: 'resolve',
                          child: Row(
                            children: [
                              Icon(Icons.check_circle),
                              SizedBox(width: 8),
                              Text('حل شده'),
                            ],
                          ),
                        ),
                      if (alert.status != 'pending')
                        const PopupMenuItem(
                          value: 'pending',
                          child: Row(
                            children: [
                              Icon(Icons.schedule),
                              SizedBox(width: 8),
                              Text('در انتظار'),
                            ],
                          ),
                        ),
                      if (alert.status != 'active')
                        const PopupMenuItem(
                          value: 'active',
                          child: Row(
                            children: [
                              Icon(Icons.play_circle),
                              SizedBox(width: 8),
                              Text('فعال'),
                            ],
                          ),
                        ),
                    ],
                    child: const Icon(Icons.more_vert),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // متن اعلان
              Text(
                alert.message,
                style: TextStyle(
                  fontSize: 14,
                  color: isNew
                      ? Colors.blue.shade700
                      : (isRecent
                          ? Colors.orange.shade700
                          : Colors.grey.shade700),
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 8),

              // اطلاعات اضافی
              Row(
                children: [
                  Icon(
                    Icons.precision_manufacturing,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    alert.equipmentId,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.comment_outlined,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${alert.replies.length} پاسخ',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // نشان اعلان جدید
                  if (isNew)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'جدید',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 8),

              // تاریخ
              Text(
                '${alert.createdAt.year}/${alert.createdAt.month.toString().padLeft(2, '0')}/${alert.createdAt.day.toString().padLeft(2, '0')} ${alert.createdAt.hour.toString().padLeft(2, '0')}:${alert.createdAt.minute.toString().padLeft(2, '0')}',
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'active':
        return Colors.orange;
      case 'resolved':
        return Colors.green;
      case 'pending':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Color _getPriorityColor(int priority) {
    switch (priority) {
      case 1:
        return Colors.green;
      case 2:
        return Colors.blue;
      case 3:
        return Colors.orange;
      case 4:
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.stopsAppBar,
        body: SafeArea(
          child: Column(
            children: [
              PageHeader(
                title: _showArchived
                    ? 'اعلان‌های آرشیو شده'
                    : 'اعلان‌های کارشناسان',
                backRoute: '/dashboard',
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
                      // بخش فیلتر
                      _buildFilterSection(),

                      // لیست اعلان‌ها
                      Expanded(
                        child: _isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : _filteredAlerts.isEmpty
                                ? const Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.notifications_none,
                                          size: 64,
                                          color: Colors.grey,
                                        ),
                                        SizedBox(height: 16),
                                        Text(
                                          'هیچ اعلانی یافت نشد',
                                          style: TextStyle(
                                            fontSize: 18,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : ListView.builder(
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
      ),
    );
  }
}
