import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shamsi_date/shamsi_date.dart';
import 'dart:ui';

import 'package:fl_chart/fl_chart.dart';

import '../services/auth_service.dart';
import '../services/navigation_service.dart';
import '../config/app_colors.dart';
import '../providers/data_provider.dart';
import '../services/alert_service.dart';
import '../services/manager_alert_service.dart';
import '../services/date_service.dart';

import 'profile_screen.dart';
import 'annual_plan_screen.dart';
import 'personnel_management_screen.dart';
import 'documents_screen.dart';
import 'equipment_list_screen.dart';
import 'grade_list_screen.dart';

import '../services/grade_service.dart';

import '../widgets/professional_download_progress.dart';
import '../widgets/draggable_app_icons.dart';
import '../widgets/monthly_progress_box.dart';
import '../widgets/grade_continuous_chart.dart';
import '../widgets/feed_tonnage_chart.dart';
import '../widgets/clock_widget.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  // متغیرهای نمایش پیشرفت دانلود
  bool _isUpdating = false;
  double _updateProgress = 0.0;
  String _updateStatus = 'آمادهسازی...';

  // متغیرهای gesture و انیمیشن
  bool _isDashboardOpen = false;
  bool _isHovering = false;
  bool _isRefreshing = false;
  late AnimationController _dashboardAnimationController;
  late AnimationController _hoverAnimationController;
  late AnimationController _refreshAnimationController;
  late Animation<double> _dashboardAnimation;
  late Animation<double> _hoverAnimation;
  late Animation<double> _refreshAnimation;
  double _dragStartY = 0.0;
  double _currentDragY = 0.0;

  @override
  void initState() {
    super.initState();
    print('=== دیباگ DashboardScreen - initState ===');
    print('GradeContinuousChart مستقل کار خواهد کرد');
    print('==========================================');

    // راه‌اندازی انیمیشن داشبورد
    _dashboardAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _dashboardAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _dashboardAnimationController,
      curve: Curves.easeInOut,
    ));

    // راه‌اندازی انیمیشن hover
    _hoverAnimationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _hoverAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _hoverAnimationController,
      curve: Curves.easeOut,
    ));

    // راه‌اندازی انیمیشن refresh
    _refreshAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _refreshAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _refreshAnimationController,
      curve: Curves.linear,
    ));
  }

  @override
  void dispose() {
    _dashboardAnimationController.dispose();
    _hoverAnimationController.dispose();
    _refreshAnimationController.dispose();
    super.dispose();
  }

  // متدهای gesture
  void _openDashboard() {
    if (!_isDashboardOpen) {
      setState(() {
        _isDashboardOpen = true;
      });
      _dashboardAnimationController.forward();
    }
  }

  void _closeDashboard() {
    if (_isDashboardOpen) {
      setState(() {
        _isDashboardOpen = false;
      });
      _dashboardAnimationController.reverse();
    }
  }

  void _handleDragStart(DragStartDetails details) {
    _dragStartY = details.globalPosition.dy;
    _currentDragY = _dragStartY;
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    _currentDragY = details.globalPosition.dy;
    final dragDistance = _currentDragY - _dragStartY;

    // اگر کشیدن به سمت بالا و داشبورد بسته است
    if (dragDistance < -50 && !_isDashboardOpen) {
      print('🔍 Opening dashboard with drag up');
      _openDashboard();
    }
    // اگر کشیدن به سمت پایین و داشبورد باز است
    else if (dragDistance > 50 && _isDashboardOpen) {
      print('🔍 Closing dashboard with drag down');
      _closeDashboard();
    }

    // اضافه کردن لاگ برای دیباگ
    print('🔍 Drag Update: distance=$dragDistance, isOpen=$_isDashboardOpen');
  }

  void _handleDragEnd(DragEndDetails details) {
    // بررسی سرعت swipe
    if (details.velocity.pixelsPerSecond.dy < -500 && !_isDashboardOpen) {
      _openDashboard();
    } else if (details.velocity.pixelsPerSecond.dy > 500 && _isDashboardOpen) {
      _closeDashboard();
    }
  }

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
        body: GestureDetector(
          onPanStart: _handleDragStart,
          onPanUpdate: _handleDragUpdate,
          onPanEnd: _handleDragEnd,
          child: Stack(
            children: [
              // تصویر پسزمینه پارالاکس - کل صفحه
              Container(
                width: double.infinity,
                height: double.infinity,
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/dash.jpg'),
                    fit: BoxFit.cover,
                  ),
                ),
                child: ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 3.0, sigmaY: 3.0),
                    child: Container(
                      color: Colors.transparent,
                    ),
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
              // لایه نیمهشفاف روی کل عکس پارالاکس
              Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.black.withOpacity(0.40),
              ),
              // لوگوی شرکت
              Positioned(
                top: MediaQuery.of(context).padding.top + 15,
                left: 20,
                child: Image.asset(
                  'assets/images/logo.png',
                  height: 75,
                  width: 75,
                  fit: BoxFit.contain,
                ),
              ),
              // ویجت ساعت و تاریخ
              Positioned(
                top: MediaQuery.of(context).padding.top + 15,
                right: 20,
                child: const ClockWidget(),
              ),
              // آیکنهای قابل جابجایی شبیه دسکتاپ اندروید - کل صفحه
              Positioned(
                top: MediaQuery.of(context).padding.top + 100,
                left: 0,
                right: 0,
                bottom: 56, // فاصله از نوار پایین
                child: DraggableAppIcons(
                  onIconTap: (String iconId) {
                    _handleIconTap(iconId);
                  },
                ),
              ),
              // کانتینر پایین صفحه برای هم‌ترازی المان‌ها
              Positioned(
                bottom: 30,
                left: 20,
                right: 20,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // باکس شناور داشبورد
                    Expanded(
                      flex: 3,
                      child: GestureDetector(
                        onTap: () {
                          _showDashboardBottomSheet(context);
                        },
                        onTapDown: (_) {
                          setState(() {
                            _isHovering = true;
                          });
                          _hoverAnimationController.forward();
                        },
                        onTapUp: (_) {
                          setState(() {
                            _isHovering = false;
                          });
                          _hoverAnimationController.reverse();
                        },
                        onTapCancel: () {
                          setState(() {
                            _isHovering = false;
                          });
                          _hoverAnimationController.reverse();
                        },
                        child: AnimatedBuilder(
                          animation: _hoverAnimation,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: 1.0 + (_hoverAnimation.value * 0.05),
                              child: Container(
                                height: 70,
                                decoration: BoxDecoration(
                                  color: Colors.grey[100], // خاکستری روشن
                                  borderRadius:
                                      BorderRadius.circular(20), // گوشه‌های گرد
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.15 +
                                          (_hoverAnimation.value * 0.05)),
                                      blurRadius:
                                          20 + (_hoverAnimation.value * 5),
                                      offset: Offset(
                                          0, 8 - (_hoverAnimation.value * 2)),
                                      spreadRadius: 2,
                                    ),
                                    BoxShadow(
                                      color: Colors.white.withOpacity(0.8),
                                      blurRadius: 1,
                                      offset: const Offset(0, -1),
                                    ),
                                  ],
                                  border: Border.all(
                                    color: Colors.grey[300]!,
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // آیکن داشبورد
                                    Container(
                                      width: 28,
                                      height: 28,
                                      margin: const EdgeInsets.only(right: 12),
                                      decoration: BoxDecoration(
                                        color: Colors.blue[600],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.dashboard,
                                        size: 18,
                                        color: Colors.white,
                                      ),
                                    ),
                                    // متن داشبورد
                                    const Text(
                                      'داشبورد',
                                      style: TextStyle(
                                        color: Colors.black87,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    // فلش به سمت بالا
                                    Container(
                                      margin: const EdgeInsets.only(left: 8),
                                      child: Icon(
                                        Icons.keyboard_arrow_up,
                                        color: Colors.grey[600],
                                        size: 24,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    // فاصله بین المان‌ها
                    const SizedBox(width: 20),
                    // آیکن بهروزرسانی
                    GestureDetector(
                      onTap: () {
                        _handleRefresh();
                      },
                      onTapDown: (_) {
                        setState(() {
                          _isHovering = true;
                        });
                        _hoverAnimationController.forward();
                      },
                      onTapUp: (_) {
                        setState(() {
                          _isHovering = false;
                        });
                        _hoverAnimationController.reverse();
                      },
                      onTapCancel: () {
                        setState(() {
                          _isHovering = false;
                        });
                        _hoverAnimationController.reverse();
                      },
                      child: AnimatedBuilder(
                        animation: Listenable.merge(
                            [_hoverAnimation, _refreshAnimation]),
                        builder: (context, child) {
                          return Transform.scale(
                            scale: 1.0 + (_hoverAnimation.value * 0.05),
                            child: Transform.rotate(
                              angle: _isRefreshing
                                  ? _refreshAnimation.value * 2 * 3.14159
                                  : 0,
                              child: Container(
                                width: 70,
                                height: 70,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Colors.blue.withOpacity(0.8),
                                      Colors.cyan.withOpacity(0.8),
                                    ],
                                  ),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(
                                          0.4 + (_hoverAnimation.value * 0.1)),
                                      blurRadius:
                                          15 + (_hoverAnimation.value * 3),
                                      offset: Offset(
                                          0, 6 - (_hoverAnimation.value * 2)),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.sync,
                                  size: 35,
                                  color: _isRefreshing
                                      ? Colors.orange
                                      : Colors.white,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              // ویجت نمایش پیشرفت دانلود
              if (_isUpdating)
                Positioned.fill(
                  child: Container(
                    color: Colors.black54,
                    child: Center(
                      child: ProfessionalDownloadProgress(
                        progress: _updateProgress,
                        fileName: 'بهروزرسانی دادهها',
                        status: _updateStatus,
                        onCancel: () {
                          setState(() {
                            _isUpdating = false;
                            _updateProgress = 0.0;
                            _updateStatus = 'آمادهسازی...';
                          });
                        },
                      ),
                    ),
                  ),
                ),
              // داشبورد انیمیشن‌دار
              AnimatedBuilder(
                animation: _dashboardAnimation,
                builder: (context, child) {
                  return _isDashboardOpen
                      ? Positioned(
                          top: MediaQuery.of(context).size.height *
                              (1 - _dashboardAnimation.value),
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: GestureDetector(
                            onPanStart: (details) {
                              print(
                                  '🔍 Dashboard Gesture Start: ${details.globalPosition.dy}');
                              _handleDragStart(details);
                            },
                            onPanUpdate: (details) {
                              print(
                                  '🔍 Dashboard Gesture Update: ${details.globalPosition.dy}');
                              _handleDragUpdate(details);
                            },
                            onPanEnd: (details) {
                              print(
                                  '🔍 Dashboard Gesture End: ${details.velocity.pixelsPerSecond.dy}');
                              _handleDragEnd(details);
                            },
                            child: Container(
                              height: MediaQuery.of(context).size.height * 0.9,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(20),
                                  topRight: Radius.circular(20),
                                ),
                              ),
                              child: Column(
                                children: [
                                  // Handle indicator با gesture
                                  GestureDetector(
                                    onPanStart: (details) {
                                      print(
                                          '🔍 Handle Gesture Start: ${details.globalPosition.dy}');
                                      _handleDragStart(details);
                                    },
                                    onPanUpdate: (details) {
                                      print(
                                          '🔍 Handle Gesture Update: ${details.globalPosition.dy}');
                                      _handleDragUpdate(details);
                                    },
                                    onPanEnd: (details) {
                                      print(
                                          '🔍 Handle Gesture End: ${details.velocity.pixelsPerSecond.dy}');
                                      _handleDragEnd(details);
                                    },
                                    child: Container(
                                      width: 40,
                                      height: 4,
                                      margin: const EdgeInsets.only(
                                          top: 12, bottom: 20),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[400],
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                  ),
                                  // Title با دکمه بستن
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20, vertical: 10),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          'داشبورد',
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        // دکمه بستن
                                        GestureDetector(
                                          onTap: () {
                                            print('🔍 Close button tapped');
                                            _closeDashboard();
                                          },
                                          child: Container(
                                            width: 32,
                                            height: 32,
                                            decoration: BoxDecoration(
                                              color: Colors.grey[200],
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                            ),
                                            child: const Icon(
                                              Icons.close,
                                              size: 20,
                                              color: Colors.black54,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Content
                                  Expanded(
                                    child: SingleChildScrollView(
                                      padding: const EdgeInsets.all(20),
                                      child: Column(
                                        children: [
                                          // Monthly progress box
                                          Container(
                                            height: 200,
                                            margin: const EdgeInsets.only(
                                                bottom: 20),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withOpacity(0.08),
                                                  blurRadius: 20,
                                                  offset: const Offset(0, 8),
                                                ),
                                              ],
                                            ),
                                            child: const MonthlyProgressBox(),
                                          ),
                                          // Grade continuous chart
                                          Container(
                                            height: 300,
                                            margin: const EdgeInsets.only(
                                                bottom: 20),
                                            child: const GradeContinuousChart(),
                                          ),
                                          // نمودار نرخ تناژ خوراک ورودی
                                          Container(
                                            height: 400,
                                            margin: const EdgeInsets.only(
                                                bottom: 20),
                                            child: const FeedTonnageChart(),
                                          ),
                                          const SizedBox(height: 50),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      : const SizedBox.shrink();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleIconTap(String iconId) {
    switch (iconId) {
      case 'production':
        Navigator.of(context).pushNamed('/production');
        break;
      case 'stoppages':
        Navigator.of(context).pushNamed('/stoppages');
        break;
      case 'indicators':
        Navigator.of(context).pushNamed('/indicators');
        break;
      case 'profile':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const ProfileScreen(),
          ),
        );
        break;
      case 'annual_plan':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const AnnualPlanScreen(),
          ),
        );
        break;
      case 'personnel':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const PersonnelManagementScreen(),
          ),
        );
        break;
      case 'documents_and_files':
        _showDocumentsMenu(context);
        break;
      case 'equipment':
        final dataProvider = Provider.of<DataProvider>(context, listen: false);
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => EquipmentListScreen(
              allData: dataProvider.getProductionData(),
            ),
          ),
        );
        break;
      case 'grades':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const GradeListScreen(),
          ),
        );
        break;
      case 'reports':
        Navigator.of(context).pushNamed('/reports');
        break;
      case 'alerts':
        _showAlertsMenu(context);
        break;
      case 'menu':
        _showManagementMenu(context);
        break;
      case 'refresh':
        _handleRefresh();
        break;
      case 'grade_entry':
        Navigator.of(context).pushNamed('/grade-entry');
        break;
      case 'ai_assistant':
        Navigator.of(context).pushNamed('/ai-assistant');
        break;
      case 'equipment_location':
        Navigator.of(context).pushNamed('/equipment-location');
        break;
    }
  }

  void _handleRefresh() async {
    if (_isUpdating) return;

    // شروع انیمیشن چرخش
    setState(() {
      _isRefreshing = true;
    });
    _refreshAnimationController.repeat();

    setState(() {
      _isUpdating = true;
      _updateProgress = 0.0;
      _updateStatus = 'شروع همگام‌سازی دستی...';
    });

    try {
      // مرحله 1: همگام‌سازی عیارها
      setState(() {
        _updateProgress = 0.2;
        _updateStatus = 'همگام‌سازی عیارها...';
      });

      final gradeSuccess = await GradeService.syncGradesFromServer();

      // مرحله 2: همگام‌سازی داده‌های تولید و توقف
      setState(() {
        _updateProgress = 0.6;
        _updateStatus = 'همگام‌سازی داده‌های تولید...';
      });

      await Provider.of<DataProvider>(context, listen: false).refreshData();

      // مرحله 3: به‌روزرسانی نوتیفیکیشن‌ها
      setState(() {
        _updateProgress = 0.8;
        _updateStatus = 'بررسی نوتیفیکیشن‌ها...';
      });

      // بررسی دستی نوتیفیکیشن‌ها - غیرفعال شده
      print('ℹ️ بررسی نوتیفیکیشن‌ها غیرفعال شده است');

      if (mounted) {
        Provider.of<DataProvider>(context, listen: false).notifyDataUpdated();

        setState(() {
          _updateProgress = 1.0;
          _updateStatus = 'همگام‌سازی تکمیل شد';
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ همه داده‌ها با موفقیت به‌روزرسانی شدند'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _updateProgress = 0.0;
        _updateStatus = 'خطا در همگام‌سازی';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ خطا در همگام‌سازی: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      // توقف انیمیشن چرخش
      _refreshAnimationController.stop();
      setState(() {
        _isRefreshing = false;
      });

      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _isUpdating = false;
            _updateProgress = 0.0;
            _updateStatus = 'آماده برای همگام‌سازی...';
          });
        }
      });
    }
  }

  void _showDashboardBottomSheet(BuildContext context) {
    print('=== دیباگ _showDashboardBottomSheet فراخوانی شد ===');
    print('==================================================');

    // استفاده از انیمیشن به جای showModalBottomSheet
    _openDashboard();
  }

  void _showAlertsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
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
              leading: const Icon(Icons.business_center_rounded,
                  color: Color(0xFF1976D2)),
              title: const Text('اعلانهای مدیریت'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).pushNamed('/manager-alerts');
              },
            ),
            ListTile(
              leading: const Icon(Icons.engineering_rounded,
                  color: Color(0xFF4CAF50)),
              title: const Text('اعلانهای کارشناسی'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).pushNamed('/alerts-management');
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showDocumentsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
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
              leading: const Icon(Icons.folder, color: Color(0xFF795548)),
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
              leading: const Icon(Icons.upload_file, color: Color(0xFFFF5722)),
              title: const Text('آپلود فایل'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).pushNamed('/document-upload');
              },
            ),
            const SizedBox(height: 20),
          ],
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
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'منوی مدیریت',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
