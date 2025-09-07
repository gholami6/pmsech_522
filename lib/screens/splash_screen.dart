import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _fadeController;
  late Animation<double> _logoAnimation;
  late Animation<double> _textAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // کنترلر انیمیشن لوگو
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // کنترلر انیمیشن متن
    _textController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // کنترلر انیمیشن fade out
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // انیمیشن لوگو
    _logoAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeInOut,
    ));

    // انیمیشن متن
    _textAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.easeInOut,
    ));

    // انیمیشن fade out
    _fadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _startAnimations();
  }

  void _startAnimations() async {
    // شروع همزمان انیمیشن لوگو و متن
    _logoController.forward();
    _textController.forward();

    // بررسی وضعیت ورود کاربر
    final authService = Provider.of<AuthService>(context, listen: false);
    final hasLoggedInBefore = await authService.getHasLoggedInBefore();
    final isLoggedIn = authService.isLoggedIn();

    // انتقال به صفحه مناسب بعد از 2.25 ثانیه با انیمیشن fade out نرم
    await Future.delayed(const Duration(milliseconds: 2250));
    if (mounted) {
      // انیمیشن fade out نرم
      _fadeController.forward();

      // انتقال نرم به صفحه مناسب
      await Future.delayed(const Duration(milliseconds: 1000));
      if (mounted) {
        String route = '/login';

        if (isLoggedIn) {
          // کاربر وارد شده است
          route = '/dashboard';
          print('کاربر وارد شده است، انتقال به داشبورد');
        } else if (hasLoggedInBefore) {
          // کاربر قبلاً وارد شده اما حالا خارج شده
          route = '/login';
          print('کاربر قبلاً وارد شده بود، انتقال به لاگین');
        } else {
          // کاربر جدید
          route = '/login';
          print('کاربر جدید، انتقال به لاگین');
        }

        Navigator.of(context).pushReplacementNamed(route);
      }
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // پس‌زمینه سیاه
      body: AnimatedBuilder(
        animation: _fadeAnimation,
        builder: (context, child) {
          return Opacity(
            opacity: _fadeAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: const AssetImage('assets/images/register_bg.jpg'),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Colors.black.withOpacity(0.8), // 80% مات
                    BlendMode.darken,
                  ),
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // لوگو با انیمیشن
                    AnimatedBuilder(
                      animation: _logoAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _logoAnimation.value,
                          child: Opacity(
                            opacity: _logoAnimation.value,
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 20,
                                    spreadRadius: 5,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Image.asset(
                                'assets/images/logo.png',
                                width: 140,
                                height: 140,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 40),

                    // متن دو خطی با انیمیشن - کاملاً شفاف و وسط چین
                    AnimatedBuilder(
                      animation: _textAnimation,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _textAnimation.value,
                          child: Transform.translate(
                            offset: Offset(0, 20 * (1 - _textAnimation.value)),
                            child: Column(
                              children: [
                                // متن اصلی - کاملاً شفاف
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 15,
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        'سیستم مدیریت اطلاعات',
                                        style: TextStyle(
                                          fontSize: 24, // کاهش از 32 به 24
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          fontFamily: 'Vazirmatn',
                                          shadows: [
                                            Shadow(
                                              color:
                                                  Colors.black.withOpacity(0.5),
                                              blurRadius: 6,
                                              offset: const Offset(2, 2),
                                            ),
                                          ],
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'کارخانه خردایش و پرعیار سازی سه چاهون',
                                        style: TextStyle(
                                          fontSize: 14, // کاهش از 20 به 14
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white.withOpacity(0.9),
                                          fontFamily: 'Vazirmatn',
                                          shadows: [
                                            Shadow(
                                              color:
                                                  Colors.black.withOpacity(0.4),
                                              blurRadius: 4,
                                              offset: const Offset(1, 1),
                                            ),
                                          ],
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 30),

                                // نشانگر بارگذاری
                                Container(
                                  width: 60,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(2),
                                    color: Colors.white.withOpacity(0.8),
                                  ),
                                  child: LinearProgressIndicator(
                                    backgroundColor: Colors.transparent,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
