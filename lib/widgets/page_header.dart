import 'package:flutter/material.dart';
import '../services/navigation_service.dart';

class PageHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onBackPressed;
  final String? backRoute;
  final List<Widget>? actions;
  final String? currentRoute;

  const PageHeader({
    Key? key,
    required this.title,
    this.onBackPressed,
    this.backRoute,
    this.actions,
    this.currentRoute,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          if (onBackPressed != null || backRoute != null)
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(24),
              ),
              child: IconButton(
                onPressed: onBackPressed ??
                    () {
                      _handleBackNavigation(context);
                    },
                icon:
                    const Icon(Icons.arrow_back, color: Colors.white, size: 24),
                iconSize: 24,
              ),
            ),
          Expanded(
            child: Center(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Vazirmatn',
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          if (actions != null) ...actions!,
        ],
      ),
    );
  }

  void _handleBackNavigation(BuildContext context) {
    final navigationService = NavigationService();

    // اگر مسیر برگشت مشخص شده، از آن استفاده کن
    if (backRoute != null) {
      navigationService.navigateReplacement(context, backRoute!);
      return;
    }

    // اگر مسیر فعلی مشخص شده، از سرویس ناوبری استفاده کن
    if (currentRoute != null) {
      navigationService.handleBackNavigation(context, currentRoute!);
      return;
    }

    // در غیر این صورت، به صفحه قبل برگرد
    Navigator.of(context).pop();
  }
}
