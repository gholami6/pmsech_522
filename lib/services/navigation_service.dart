import 'package:flutter/material.dart';

class NavigationService {
  static final NavigationService _instance = NavigationService._internal();
  factory NavigationService() => _instance;
  NavigationService._internal();

  // Navigator key برای ناوبری سراسری (برای واکنش به لمس نوتیف)
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  // نگهداری تاریخچه مسیرها
  final List<String> _navigationHistory = [];

  // مسیرهای اصلی که کاربر می‌تواند به آن‌ها برگردد
  static const List<String> _mainRoutes = [
    '/dashboard',
    '/production',
    '/stops',
    '/indicators',
    '/profile'
  ];

  // مسیرهای فرعی که نباید در تاریخچه ذخیره شوند
  static const List<String> _subRoutes = [
    '/new-alert',
    '/alerts-management',
    '/grade-entry',
    '/grade-import',
    '/grade-detail',
    '/document-upload',
    '/equipment-list',
    '/equipment-alerts',
    '/personnel-management',
    '/annual-plan',
    '/ai-assistant',
    '/documents',
    '/pdf-preview',
    '/alert-detail',
    '/equipment-details',
    '/quality-performance',
    '/general-report',
    '/feed-input',
    '/product',
    '/tailing'
  ];

  // اضافه کردن مسیر به تاریخچه
  void addToHistory(String route) {
    // فقط مسیرهای اصلی را در تاریخچه ذخیره کن
    if (!isMainRoute(route)) {
      return;
    }

    // اگر مسیر قبلاً وجود دارد، آن را حذف کن
    _navigationHistory.remove(route);
    // مسیر جدید را اضافه کن
    _navigationHistory.add(route);

    // حداکثر 10 مسیر در تاریخچه نگه دار
    if (_navigationHistory.length > 10) {
      _navigationHistory.removeAt(0);
    }
  }

  // پاک کردن تاریخچه
  void clearHistory() {
    _navigationHistory.clear();
  }

  // دریافت مسیر قبلی
  String? getPreviousRoute() {
    if (_navigationHistory.length > 1) {
      // مسیر فعلی را حذف کن
      _navigationHistory.removeLast();
      // مسیر قبلی را برگردان
      return _navigationHistory.last;
    }
    return null;
  }

  // بررسی اینکه آیا مسیر فعلی داشبورد است
  bool isCurrentRouteDashboard(String currentRoute) {
    return currentRoute == '/dashboard';
  }

  // بررسی اینکه آیا مسیر از مسیرهای اصلی است
  bool isMainRoute(String route) {
    return _mainRoutes.contains(route);
  }

  // دریافت مسیر داشبورد
  String getDashboardRoute() {
    return '/dashboard';
  }

  // مدیریت ناوبری برگشت
  Future<bool> handleBackNavigation(
      BuildContext context, String currentRoute) async {
    // اگر در داشبورد هستیم، دیالوگ خروج نمایش دهیم
    if (isCurrentRouteDashboard(currentRoute)) {
      return await _showExitDialog(context);
    }

    // مسیر فعلی را به تاریخچه اضافه کن (اگر از مسیرهای اصلی است)
    addToHistory(currentRoute);

    // اگر مسیر قبلی وجود دارد، به آن برگردیم
    String? previousRoute = getPreviousRoute();
    if (previousRoute != null && isMainRoute(previousRoute)) {
      Navigator.of(context).pushReplacementNamed(previousRoute);
      return false; // از خروج جلوگیری کنیم
    }

    // اگر مسیر قبلی وجود ندارد یا از مسیرهای اصلی نیست، به داشبورد برگردیم
    Navigator.of(context).pushReplacementNamed(getDashboardRoute());
    return false;
  }

  // نمایش دیالوگ تأیید خروج
  Future<bool> _showExitDialog(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text(
                'خروج از برنامه',
                style: TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: const Text(
                'آیا مطمئن هستید که می‌خواهید از برنامه خارج شوید؟',
                style: TextStyle(
                  fontFamily: 'Vazirmatn',
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text(
                    'انصراف',
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      color: Colors.grey,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text(
                    'خروج',
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      color: Colors.red,
                    ),
                  ),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  // ناوبری به صفحه جدید با ثبت در تاریخچه
  void navigateTo(BuildContext context, String route) {
    addToHistory(route);
    Navigator.of(context).pushNamed(route);
  }

  // ناوبری سراسری بدون context
  static void navigateToGlobal(String route, {Object? arguments}) {
    final state = navigatorKey.currentState;
    if (state != null) {
      state.pushNamed(route, arguments: arguments);
    }
  }

  // پوش به صورت مستقیم با ویجت (بدون نام مسیر)
  static void pushGlobalPage(Widget page) {
    final state = navigatorKey.currentState;
    if (state != null) {
      state.push(MaterialPageRoute(builder: (_) => page));
    }
  }

  // ناوبری جایگزینی با ثبت در تاریخچه
  void navigateReplacement(BuildContext context, String route) {
    addToHistory(route);
    Navigator.of(context).pushReplacementNamed(route);
  }

  // تنظیم مسیر فعلی (برای صفحاتی که مستقیماً باز می‌شوند)
  void setCurrentRoute(String route) {
    addToHistory(route);
  }

  // دریافت مسیر فعلی
  String? getCurrentRoute() {
    if (_navigationHistory.isNotEmpty) {
      return _navigationHistory.last;
    }
    return null;
  }
}
