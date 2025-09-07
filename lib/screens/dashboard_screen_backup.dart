import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/navigation_service.dart';
import '../config/app_colors.dart';
import '../providers/data_provider.dart';
import '../services/alert_service.dart';
import '../services/manager_alert_service.dart';
import 'profile_screen.dart';
import 'annual_plan_screen.dart';
import 'personnel_management_screen.dart';
import 'documents_screen.dart';
import 'equipment_list_screen.dart';
import 'grade_list_screen.dart';
import 'grade_batch_upload_screen.dart';
import '../services/grade_service.dart';
import '../widgets/professional_download_progress.dart';
import '../widgets/monthly_progress_box.dart';
import '../widgets/grade_continuous_chart.dart';
import 'grade_continuous_chart_screen.dart';
import '../widgets/test_modern_alert.dart';
import '../widgets/simple_test_card.dart';
import '../widgets/simple_alert_test.dart';
import '../widgets/alerts_box.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // متغیرهای نمایش پیشرفت دانلود
  bool _isUpdating = false;
  double _updateProgress = 0.0;
  String _updateStatus = 'آماده‌سازی...';

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;
    final screenHeight = MediaQuery.of(context).size.height;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (!didPop) {
          final navigationService = NavigationService();
          await navigationService.handleBackNavigation(context, '/dashboard');
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.mainBackground,
        body: Stack(
          children: [
            // محتوای اصلی
            CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // هدر با تصویر
                SliverAppBar(
                  expandedHeight: screenHeight * 0.33,
                  floating: false,
                  pinned: true,
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Stack(
                      children: [
                        // تصویر پس‌زمینه
                        Container(
                          width: double.infinity,
                          height: double.infinity,
                          decoration: const BoxDecoration(
                            image: DecorationImage(
                              image: AssetImage('assets/images/dash.jpg'),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        // گرادیان روی تصویر
                        Container(
                          width: double.infinity,
                          height: double.infinity,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.3),
                                Colors.black.withOpacity(0.6),
                              ],
                              stops: const [0.0, 0.6, 1.0],
                            ),
                          ),
                        ),

                        // ردیف اول - آیکن پروفایل و لوگو
                        Positioned(
                          top: MediaQuery.of(context).padding.top + 15,
                          left: 20,
                          right: 20,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // آیکن پروفایل
                              Container(
                                width: 51,
                                height: 51,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFBF9F7),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.15),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(25.5),
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const ProfileScreen(),
                                        ),
                                      );
                                    },
                                    child: const Icon(
                                      Icons.person,
                                      color: Color(0xFF1E3A8A),
                                      size: 25.5,
                                    ),
                                  ),
                                ),
                              ),

                              // لوگوی شرکت
                              Image.asset(
                                'assets/images/logo.png',
                                height: 50,
                                width: 50,
                                fit: BoxFit.contain,
                              ),
                            ],
                          ),
                        ),

                        // آیکن‌های اعلان در انتهای هدر
                        Positioned(
                          bottom: 15,
                          left: 0,
                          right: 0,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              // آیکن اعلان‌های مدیریت
                              Expanded(
                                child: Center(
                                  child: Consumer<ManagerAlertService>(
                                    builder:
                                        (context, managerAlertService, child) {
                                      return Consumer<AuthService>(
                                        builder: (context, authService, child) {
                                          final currentUser =
                                              authService.currentUser;
                                          if (currentUser == null)
                                            return const SizedBox();

                                          final unseenCount =
                                              managerAlertService
                                                  .getUnseenManagerAlerts()
                                                  .length;

                                          return _buildAlertIcon(
                                            icon: Icons.business_center_rounded,
                                            count: unseenCount,
                                            color: const Color(0xFF1976D2),
                                            onTap: () {
                                              Navigator.of(context)
                                                  .pushNamed('/manager-alerts');
                                            },
                                          );
                                        },
                                      );
                                    },
                                  ),
                                ),
                              ),
                              // آیکن منوی گزینه‌ها
                              Expanded(
                                child: Center(
                                  child: Container(
                                    width: 54,
                                    height: 54,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF4F2F0),
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.15),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(27),
                                        onTap: () {
                                          _showManagementMenu(context);
                                        },
                                        child: const Icon(
                                          Icons.menu,
                                          color: Color(0xFF1E3A8A),
                                          size: 27,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              // آیکن اعلان‌های کارشناسی
                              Expanded(
                                child: Center(
                                  child: Consumer<AlertService>(
                                    builder: (context, alertService, child) {
                                      return Consumer<AuthService>(
                                        builder: (context, authService, child) {
                                          final currentUser =
                                              authService.currentUser;
                                          if (currentUser == null)
                                            return const SizedBox();

                                          final unseenCount = alertService
                                              .getUnseenAlerts()
                                              .length;

                                          return _buildAlertIcon(
                                            icon: Icons.engineering_rounded,
                                            count: unseenCount,
                                            color: const Color(0xFF4CAF50),
                                            onTap: () {
                                              Navigator.of(context).pushNamed(
                                                  '/alerts-management');
                                            },
                                          );
                                        },
                                      );
                                    },
                                  ),
                                ),
                              ),
                              // آیکن به‌روزرسانی داده‌ها
                              Expanded(
                                child: Center(
                                  child: Container(
                                    width: 54,
                                    height: 54,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF4F2F0),
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.15),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(27),
                                        onTap: () async {
                                          if (_isUpdating) return;

                                          setState(() {
                                            _isUpdating = true;
                                            _updateProgress = 0.0;
                                            _updateStatus = 'آماده‌سازی...';
                                          });

                                          try {
                                            setState(() {
                                              _updateProgress = 0.2;
                                              _updateStatus =
                                                  'پاک کردن کش عیارها...';
                                            });

                                            final gradeSuccess =
                                                await GradeService
                                                    .forceClearAndSync();

                                            if (gradeSuccess) {
                                              setState(() {
                                                _updateProgress = 0.6;
                                                _updateStatus =
                                                    'به‌روزرسانی داده‌ها...';
                                              });

                                              await Provider.of<DataProvider>(
                                                      context,
                                                      listen: false)
                                                  .refreshData();

                                              if (mounted) {
                                                Provider.of<DataProvider>(
                                                        context,
                                                        listen: false)
                                                    .notifyDataUpdated();
                                              }

                                              setState(() {
                                                _updateProgress = 1.0;
                                                _updateStatus = 'تکمیل شد';
                                              });

                                              if (mounted) {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                        'داده‌های عیار، تولید و توقفات به‌روز شدند'),
                                                    backgroundColor:
                                                        Colors.green,
                                                    duration:
                                                        Duration(seconds: 3),
                                                  ),
                                                );
                                              }
                                            } else {
                                              setState(() {
                                                _updateProgress = 0.0;
                                                _updateStatus =
                                                    'خطا در به‌روزرسانی';
                                              });

                                              if (mounted) {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                        'خطا در به‌روزرسانی داده‌ها'),
                                                    backgroundColor:
                                                        Colors.orange,
                                                    duration:
                                                        Duration(seconds: 2),
                                                  ),
                                                );
                                              }
                                            }
                                          } catch (e) {
                                            setState(() {
                                              _updateProgress = 0.0;
                                              _updateStatus = 'خطا';
                                            });

                                            if (mounted) {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(
                                                  content: Text('خطا: $e'),
                                                  backgroundColor: Colors.red,
                                                  duration: const Duration(
                                                      seconds: 3),
                                                ),
                                              );
                                            }
                                          } finally {
                                            Future.delayed(
                                                const Duration(seconds: 2), () {
                                              if (mounted) {
                                                setState(() {
                                                  _isUpdating = false;
                                                  _updateProgress = 0.0;
                                                  _updateStatus =
                                                      'آماده‌سازی...';
                                                });
                                              }
                                            });
                                          }
                                        },
                                        child: const Icon(
                                          Icons.refresh,
                                          color: Color(0xFF1E3A8A),
                                          size: 27,
                                        ),
                                      ),
                                    ),
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
                // محتوای اصلی
                SliverToBoxAdapter(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: AppColors.mainBackground,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          // Monthly progress box - اضافه شده
                          Container(
                            margin: const EdgeInsets.only(bottom: 20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: const MonthlyProgressBox(),
                          ),

                          // نمودار پیوسته عیار خوراک و محصول
                          Container(
                            margin: const EdgeInsets.only(bottom: 20),
                            child: const GradeContinuousChart(),
                          ),

                          // فضای اضافی برای اسکرول
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // ویجت نمایش پیشرفت دانلود
            if (_isUpdating)
              Positioned.fill(
                child: Container(
                  color: Colors.black54,
                  child: Center(
                    child: ProfessionalDownloadProgress(
                      progress: _updateProgress,
                      fileName: 'به‌روزرسانی داده‌ها',
                      status: _updateStatus,
                      onCancel: () {
                        setState(() {
                          _isUpdating = false;
                          _updateProgress = 0.0;
                          _updateStatus = 'آماده‌سازی...';
                        });
                      },
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertIcon({
    required IconData icon,
    required int count,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: const Color(0xFFF4F2F0),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(27),
          onTap: onTap,
          child: Stack(
            children: [
              Center(
                child: Icon(
                  icon,
                  color: color,
                  size: 27,
                ),
              ),
              if (count > 0)
                Positioned(
                  right: 2,
                  top: 2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFFF4F2F0),
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      count.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showManagementMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.person, color: Color(0xFF1E3A8A)),
                    title: const Text('پروفایل'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const ProfileScreen(),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.calendar_today,
                        color: Color(0xFF1E3A8A)),
                    title: const Text('برنامه سالانه'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const AnnualPlanScreen(),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.people, color: Color(0xFF1E3A8A)),
                    title: const Text('مدیریت پرسنل'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) =>
                              const PersonnelManagementScreen(),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.folder, color: Color(0xFF1E3A8A)),
                    title: const Text('مدارک'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const DocumentsScreen(),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.build, color: Color(0xFF1E3A8A)),
                    title: const Text('لیست تجهیزات'),
                    onTap: () {
                      Navigator.pop(context);
                      final dataProvider =
                          Provider.of<DataProvider>(context, listen: false);
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => EquipmentListScreen(
                            allData: dataProvider.getProductionData(),
                          ),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading:
                        const Icon(Icons.analytics, color: Color(0xFF1E3A8A)),
                    title: const Text('لیست عیارها'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const GradeListScreen(),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading:
                        const Icon(Icons.upload_file, color: Color(0xFF1E3A8A)),
                    title: const Text('آپلود دسته‌ای عیارها'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const GradeBatchUploadScreen(),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading:
                        const Icon(Icons.show_chart, color: Color(0xFF1E3A8A)),
                    title: const Text('نمودار پیوسته عیارها'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) =>
                              const GradeContinuousChartScreen(),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.design_services,
                        color: Color(0xFF1E3A8A)),
                    title: const Text('تست کارت‌های جدید'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const TestModernAlert(),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.card_giftcard,
                        color: Color(0xFF1E3A8A)),
                    title: const Text('تست ساده کارت'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const SimpleTestCard(),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.notifications_active,
                        color: Color(0xFF1E3A8A)),
                    title: const Text('تست کارت‌های اعلان'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const SimpleAlertTest(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
