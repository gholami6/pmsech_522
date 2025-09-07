import 'dart:ui';
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/grade_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _rememberMe = false;
  // bool _hasLoggedInBefore = false; // حذف شد چون در splash_screen بررسی می‌شود
  String _currentDateTime = '';

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late AnimationController _typewriterController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _typewriterAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadRememberedUser();
    // _checkPreviousLogin(); // حذف شد چون در splash_screen بررسی می‌شود
    // حذف _updateDateTime() و Timer.periodic

    // به‌روزرسانی زمان هر دقیقه - حذف شد
    // Timer.periodic(const Duration(minutes: 1), (timer) {
    //   _updateDateTime();
    // });
  }

  // تابع جدید برای به‌روزرسانی تاریخ و زمان - حذف شد
  // void _updateDateTime() {
  //   final now = DateTime.now();
  //   final persianDate = _getPersianDate(now);
  //   final time = DateFormat('HH:mm').format(now);

  //   setState(() {
  //     _currentDateTime = '$persianDate _ $time';
  //   });
  // }

  // تابع جدید برای تبدیل تاریخ میلادی به فارسی - حذف شد
  // String _getPersianDate(DateTime date) {
  //   final persianWeekdays = [
  //     'شنبه',
  //     'یکشنبه',
  //     'دوشنبه',
  //     'سه‌شنبه',
  //     'چهارشنبه',
  //     'پنج‌شنبه',
  //     'جمعه'
  //   ];

  //   final persianMonths = [
  //     'فروردین',
  //     'اردیبهشت',
  //     'خرداد',
  //     'تیر',
  //     'مرداد',
  //     'شهریور',
  //     'مهر',
  //     'آبان',
  //     'آذر',
  //     'دی',
  //     'بهمن',
  //     'اسفند'
  //   ];

  //   final persianNumbers = [
  //     'اول',
  //     'دوم',
  //     'سوم',
  //     'چهارم',
  //     'پنجم',
  //     'ششم',
  //     'هفتم',
  //     'هشتم',
  //     'نهم',
  //     'دهم',
  //     'یازدهم',
  //     'دوازدهم',
  //     'سیزدهم',
  //     'چهاردهم',
  //     'پانزدهم',
  //     'شانزدهم',
  //     'هفدهم',
  //     'هجدهم',
  //     'نوزدهم',
  //     'بیستم',
  //     'بیست و یکم',
  //     'بیست و دوم',
  //     'بیست و سوم',
  //     'بیست و چهارم',
  //     'بیست و پنجم',
  //     'بیست و ششم',
  //     'بیست و هفتم',
  //     'بیست و هشتم',
  //     'بیست و نهم',
  //     'سی‌ام',
  //     'سی و یکم'
  //   ];

  //   // تبدیل تاریخ میلادی به شمسی (تقریبی)
  //   final gregorianYear = date.year;
  //   final gregorianMonth = date.month;
  //   final gregorianDay = date.day;

  //   // محاسبه تقریبی تاریخ شمسی
  //   int persianYear = gregorianYear - 621;
  //   int persianMonth = gregorianMonth + 2;
  //   int persianDay = gregorianDay + 10;

  //   if (persianMonth > 12) {
  //     persianMonth -= 12;
  //     persianYear += 1;
  //   }

  //   if (persianDay > 30) {
  //     persianDay -= 30;
  //     persianMonth += 1;
  //   }

  //   // محاسبه روز هفته
  //   final weekday = (date.weekday + 1) % 7; // تبدیل به فرمت فارسی

  //   final weekdayName = persianWeekdays[weekday];
  //   final dayName = persianNumbers[persianDay - 1];
  //   final monthName = persianMonths[persianMonth - 1];

  //   return '$weekdayName، $dayName $monthName ماه';
  // }

  // تابع جدید برای بررسی ورود قبلی - حذف شد چون در splash_screen بررسی می‌شود
  // Future<void> _checkPreviousLogin() async {
  //   final prefs = await SharedPreferences.getInstance();
  //   final hasLoggedIn = prefs.getBool('has_logged_in_before') ?? false;
  //   setState(() {
  //     _hasLoggedInBefore = hasLoggedIn;
  //   });
  // }

  // تابع جدید برای ذخیره وضعیت ورود
  Future<void> _saveLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_logged_in_before', true);
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _typewriterController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.9,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeOut,
    ));

    _typewriterAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _typewriterController,
      curve: Curves.easeInOut,
    ));

    _fadeController.forward();
    _slideController.forward();
    _scaleController.forward();
  }

  // تابع جدید برای نمایش/مخفی کردن باکس راهنما - حذف شد
  // void _toggleHelpBox() {
  //   setState(() {
  //     _showHelpBox = !_showHelpBox;
  //   });

  //   if (_showHelpBox) {
  //     _helpBoxController.forward();
  //   } else {
  //     _helpBoxController.reverse();
  //   }
  // }

  Future<void> _loadRememberedUser() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final rememberedUser = await authService.getRememberedUser();
      if (rememberedUser != null) {
        setState(() {
          _usernameController.text = rememberedUser;
          _rememberMe = true;
        });

        // بارگیری رمز عبور به صورت async
        _loadRememberedPasswordAsync(authService);
      }
    } catch (e) {
      print('خطا در بارگیری کاربر: $e');
    }
  }

  // تابع جدید برای بارگیری رمز عبور به صورت async
  Future<void> _loadRememberedPasswordAsync(AuthService authService) async {
    try {
      final rememberedPassword = await authService.getRememberedPassword();
      if (rememberedPassword != null && mounted) {
        setState(() {
          _passwordController.text = rememberedPassword;
        });
      }
    } catch (e) {
      print('خطا در بارگیری رمز عبور: $e');
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    _typewriterController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.login(
          _usernameController.text, _passwordController.text);

      // همگام‌سازی عیارها حذف شد - کاربر می‌تواند دستی انجام دهد
      // این تغییر باعث افزایش سرعت ورود می‌شود

      // عملیات ذخیره به صورت async (بدون await)
      _saveLoginDataAsync();

      // منتظر اتمام انیمیشن تایپ (0.5 ثانیه - بهینه‌سازی شده)
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/dashboard');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // تابع جدید برای ذخیره داده‌ها به صورت async
  Future<void> _saveLoginDataAsync() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);

      if (_rememberMe) {
        await authService.rememberUser(
            _usernameController.text, _passwordController.text);
      } else {
        await authService.forgetUser();
      }

      await _saveLoginStatus();
    } catch (e) {
      // خطا در ذخیره داده‌ها نباید روی ورود تاثیر بگذارد
      print('خطا در ذخیره داده‌ها: $e');
    }
  }

  void _showSuccessAnimation() {
    _scaleController.forward().then((_) {
      Navigator.pushReplacementNamed(context, '/dashboard');
    });
  }

  void _showErrorAnimation() {
    _scaleController.forward().then((_) {
      _scaleController.reverse();
    });
  }

  @override
  Widget build(BuildContext context) {
    // print('وضعیت ورود: _hasLoggedInBefore=$_hasLoggedInBefore'); // حذف شد
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: const AssetImage('assets/images/login_bg.jpg'),
              fit: BoxFit.cover,
              colorFilter: ColorFilter.mode(
                Colors.black.withOpacity(0.7),
                BlendMode.darken,
              ),
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height -
                      MediaQuery.of(context).padding.top -
                      MediaQuery.of(context).padding.bottom,
                ),
                child: IntrinsicHeight(
                  child: Stack(
                    children: [
                      // متن "ورود به سیستم" با موقعیت ثابت
                      Positioned(
                        top: 120, // فاصله ثابت از بالای صفحه
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.factory,
                                size: MediaQuery.of(context).size.width *
                                    0.12, // 12% از عرض صفحه
                                color: Colors.white,
                              ),
                              const SizedBox(height: 16), // فاصله ثابت
                              Text(
                                'ورود به سیستم',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: MediaQuery.of(context).size.width *
                                      0.07, // 7% از عرض صفحه
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Vazirmatn',
                                  shadows: [
                                    Shadow(
                                      offset: Offset(0, 2),
                                      blurRadius: 4,
                                      color: Colors.black54,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8), // فاصله ثابت
                              Text(
                                'سیستم مدیریت تولید',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.95),
                                  fontSize: MediaQuery.of(context).size.width *
                                      0.045, // 4.5% از عرض صفحه
                                  fontFamily: 'Vazirmatn',
                                  fontWeight: FontWeight.w500,
                                  shadows: [
                                    Shadow(
                                      offset: Offset(0, 1),
                                      blurRadius: 3,
                                      color: Colors.black45,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // کانتینر اصلی ورود با فاصله ثابت
                      Positioned(
                        top: 280, // فاصله ثابت از بالای صفحه
                        left: 0,
                        right: 0,
                        child: Center(
                          child: FadeTransition(
                            opacity: _fadeAnimation,
                            child: SlideTransition(
                              position: _slideAnimation,
                              child: ScaleTransition(
                                scale: _scaleAnimation,
                                child: Container(
                                  margin: EdgeInsets.all(
                                      MediaQuery.of(context).size.width *
                                          0.04), // 4% از عرض صفحه
                                  width: MediaQuery.of(context).size.width *
                                      0.85, // 85% از عرض صفحه
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(
                                        20), // کاهش از 24 به 20
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.2),
                                      width: 1,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.3),
                                        blurRadius: 15, // کاهش از 20 به 15
                                        offset: const Offset(
                                            0, 8), // کاهش از 10 به 8
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(
                                        20), // کاهش از 24 به 20
                                    child: BackdropFilter(
                                      filter: ImageFilter.blur(
                                          sigmaX: 8,
                                          sigmaY: 8), // کاهش از 10 به 8
                                      child: Container(
                                        padding: const EdgeInsets.all(
                                            16), // کاهش از 20 به 16
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.1),
                                        ),
                                        child: Form(
                                          key: _formKey,
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              // فیلدهای ورود
                                              Align(
                                                alignment:
                                                    Alignment.centerRight,
                                                child: Container(
                                                  margin: const EdgeInsets.only(
                                                      right: 8, bottom: 4),
                                                  child: Text(
                                                    'نام کاربری',
                                                    style: TextStyle(
                                                      color: Colors.white
                                                          .withOpacity(0.95),
                                                      fontSize: MediaQuery.of(
                                                                  context)
                                                              .size
                                                              .width *
                                                          0.035, // 3.5% از عرض صفحه
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      fontFamily: 'Vazirmatn',
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              _buildInputField(
                                                controller: _usernameController,
                                                label: '',
                                                icon: Icons.person_outline,
                                                validator: (value) {
                                                  if (value == null ||
                                                      value.isEmpty) {
                                                    return 'لطفا نام کاربری خود را وارد کنید';
                                                  }
                                                  return null;
                                                },
                                              ),
                                              const SizedBox(
                                                  height: 8), // کاهش بیشتر

                                              Align(
                                                alignment:
                                                    Alignment.centerRight,
                                                child: Container(
                                                  margin: const EdgeInsets.only(
                                                      right: 8, bottom: 4),
                                                  child: Text(
                                                    'رمز عبور',
                                                    style: TextStyle(
                                                      color: Colors.white
                                                          .withOpacity(0.95),
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      fontFamily: 'Vazirmatn',
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              _buildInputField(
                                                controller: _passwordController,
                                                label: '',
                                                icon: Icons.lock_outline,
                                                isPassword: true,
                                                validator: (value) {
                                                  if (value == null ||
                                                      value.isEmpty) {
                                                    return 'لطفا رمز عبور خود را وارد کنید';
                                                  }
                                                  return null;
                                                },
                                              ),
                                              const SizedBox(
                                                  height:
                                                      1), // فاصله 1 میلی‌متری

                                              // گزینه‌های اضافی
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.end,
                                                children: [
                                                  Text(
                                                    'مرا به خاطر بسپار',
                                                    style: TextStyle(
                                                      color: Colors.white
                                                          .withOpacity(0.95),
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      fontSize:
                                                          12, // کاهش از 13 به 12
                                                      fontFamily: 'Vazirmatn',
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Container(
                                                    decoration: BoxDecoration(
                                                      color: Colors.white
                                                          .withOpacity(0.1),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              4),
                                                    ),
                                                    child: Checkbox(
                                                      value: _rememberMe,
                                                      onChanged: (value) {
                                                        setState(() =>
                                                            _rememberMe =
                                                                value ?? false);
                                                      },
                                                      fillColor:
                                                          MaterialStateProperty
                                                              .resolveWith(
                                                        (states) => const Color(
                                                                0xFF2196F3)
                                                            .withOpacity(0.4),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(
                                                  height: 12), // کاهش بیشتر

                                              // دکمه ورود اصلی
                                              SizedBox(
                                                width: MediaQuery.of(context)
                                                        .size
                                                        .width *
                                                    0.7, // یکسان با فیلدهای ورود
                                                height:
                                                    48, // یکسان با فیلدهای ورود
                                                child: ElevatedButton(
                                                  onPressed: _isLoading
                                                      ? null
                                                      : _login,
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        const Color(0xFF2196F3)
                                                            .withOpacity(0.3),
                                                    foregroundColor:
                                                        Colors.white,
                                                    elevation: 0,
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              10), // کاهش از 12 به 10
                                                      side: BorderSide(
                                                        color: Colors.white
                                                            .withOpacity(0.3),
                                                      ),
                                                    ),
                                                  ),
                                                  child: _isLoading
                                                      ? const SizedBox(
                                                          height:
                                                              16, // کاهش از 18 به 16
                                                          width:
                                                              16, // کاهش از 18 به 16
                                                          child:
                                                              CircularProgressIndicator(
                                                            strokeWidth: 2,
                                                            valueColor:
                                                                AlwaysStoppedAnimation<
                                                                        Color>(
                                                                    Colors
                                                                        .white),
                                                          ),
                                                        )
                                                      : const Text(
                                                          'ورود',
                                                          style: TextStyle(
                                                            fontSize:
                                                                15, // کاهش از 16 به 15
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontFamily:
                                                                'Vazirmatn',
                                                          ),
                                                        ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // باکس "حساب کاربری ندارید..." در پایین سمت چپ
                      Positioned(
                        bottom: MediaQuery.of(context).size.height *
                            0.02, // 2% از پایین صفحه
                        left: MediaQuery.of(context).size.width *
                            0.02, // 2% از چپ صفحه
                        child: TextButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/register');
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              'حساب کاربری ندارید؟ ثبت نام کنید',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 11,
                                fontFamily: 'Vazirmatn',
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),

                      // آیکن راهنما در گوشه راست پایین - حذف شد
                      // Positioned(
                      //   bottom: 20,
                      //   right: 20,
                      //   child: GestureDetector(
                      //     onTap: _toggleHelpBox,
                      //     child: Container(
                      //       width: 36,
                      //       height: 36,
                      //       decoration: BoxDecoration(
                      //         color: Colors.white.withOpacity(0.1),
                      //         shape: BoxShape.circle,
                      //         border: Border.all(
                      //           color: Colors.white.withOpacity(0.2),
                      //           width: 1,
                      //         ),
                      //       ),
                      //       child: Icon(
                      //         Icons.help_outline,
                      //         size: 20,
                      //         color: Colors.white.withOpacity(0.9),
                      //       ),
                      //     ),
                      //   ),
                      // ),

                      // باکس راهنمای کشویی - حذف شد
                      // if (_showHelpBox)
                      //   Positioned(
                      //     bottom: 80,
                      //     left: 20,
                      //     right: 20,
                      //     child: AnimatedBuilder(
                      //       animation: _helpBoxAnimation,
                      //       builder: (context, child) {
                      //         return Transform.scale(
                      //           scale: _helpBoxAnimation.value,
                      //           child: Opacity(
                      //             opacity: _helpBoxAnimation.value,
                      //             child: Center(
                      //               child: Container(
                      //                 width: MediaQuery.of(context).size.width *
                      //                     0.5,
                      //                 padding: const EdgeInsets.all(20),
                      //                 decoration: BoxDecoration(
                      //                   color: Colors.black.withOpacity(0.3),
                      //                   borderRadius: BorderRadius.circular(24),
                      //                   border: Border.all(
                      //                     color: Colors.white.withOpacity(0.3),
                      //                     width: 1,
                      //                   ),
                      //                   boxShadow: [
                      //                     BoxShadow(
                      //                       color:
                      //                           Colors.black.withOpacity(0.3),
                      //                       blurRadius: 15,
                      //                       offset: const Offset(0, 8),
                      //                     ),
                      //                   ],
                      //                 ),
                      //                 child: Column(
                      //                   crossAxisAlignment:
                      //                       CrossAxisAlignment.end,
                      //                   mainAxisSize: MainAxisSize.min,
                      //                   children: [
                      //                     Row(
                      //                       mainAxisAlignment:
                      //                           MainAxisAlignment.end,
                      //                       children: [
                      //                         Text(
                      //                           'راهنمای ورود',
                      //                           style: TextStyle(
                      //                             color: Colors.white
                      //                                 .withOpacity(0.95),
                      //                             fontSize: 14,
                      //                             fontWeight: FontWeight.bold,
                      //                             fontFamily: 'Vazirmatn',
                      //                           ),
                      //                         ),
                      //                         const SizedBox(width: 8),
                      //                         Icon(
                      //                           Icons.lightbulb_outline,
                      //                           color: Colors.white
                      //                               .withOpacity(0.9),
                      //                           size: 20,
                      //                         ),
                      //                         const Spacer(),
                      //                         GestureDetector(
                      //                           onTap: _toggleHelpBox,
                      //                           child: Icon(
                      //                             Icons.close,
                      //                             color: Colors.white
                      //                                 .withOpacity(0.7),
                      //                             size: 20,
                      //                           ),
                      //                         ),
                      //                       ],
                      //                     ),
                      //                     const SizedBox(height: 16),
                      //                     Row(
                      //                       mainAxisAlignment:
                      //                           MainAxisAlignment.end,
                      //                       children: [
                      //                         Text(
                      //                           'نام کاربری:',
                      //                           style: TextStyle(
                      //                             color: Colors.white
                      //                                 .withOpacity(0.95),
                      //                             fontSize: 12,
                      //                             fontWeight: FontWeight.w500,
                      //                             fontFamily: 'Vazirmatn',
                      //                           ),
                      //                         ),
                      //                         const SizedBox(width: 8),
                      //                         Icon(
                      //                           Icons.person_outline,
                      //                           color: Colors.white
                      //                               .withOpacity(0.9),
                      //                           size: 16,
                      //                         ),
                      //                       ],
                      //                     ),
                      //                     const SizedBox(height: 4),
                      //                     Text(
                      //                       'کد پرسنلی خود را وارد کنید (مثال: 7287)',
                      //                       style: TextStyle(
                      //                         color:
                      //                             Colors.white.withOpacity(0.8),
                      //                         fontSize: 11,
                      //                         fontFamily: 'Vazirmatn',
                      //                       ),
                      //                       textAlign: TextAlign.right,
                      //                     ),
                      //                     const SizedBox(height: 12),
                      //                     Row(
                      //                       mainAxisAlignment:
                      //                           MainAxisAlignment.end,
                      //                       children: [
                      //                         Text(
                      //                           'رمز عبور:',
                      //                           style: TextStyle(
                      //                             color: Colors.white
                      //                                 .withOpacity(0.95),
                      //                             fontSize: 12,
                      //                             fontWeight: FontWeight.w500,
                      //                             fontFamily: 'Vazirmatn',
                      //                           ),
                      //                         ),
                      //                         const SizedBox(width: 8),
                      //                         Icon(
                      //                           Icons.lock_outline,
                      //                           color: Colors.white
                      //                               .withOpacity(0.9),
                      //                           size: 16,
                      //                         ),
                      //                       ],
                      //                     ),
                      //                     const SizedBox(height: 4),
                      //                     Text(
                      //                       'رمز عبور خود را وارد کنید (مثال: 7287)',
                      //                       style: TextStyle(
                      //                         color:
                      //                             Colors.white.withOpacity(0.8),
                      //                         fontSize: 11,
                      //                         fontFamily: 'Vazirmatn',
                      //                       ),
                      //                       textAlign: TextAlign.right,
                      //                     ),
                      //                     const SizedBox(height: 16),
                      //                     Container(
                      //                       padding: const EdgeInsets.all(12),
                      //                       decoration: BoxDecoration(
                      //                         color:
                      //                             Colors.white.withOpacity(0.1),
                      //                         borderRadius:
                      //                             BorderRadius.circular(8),
                      //                         border: Border.all(
                      //                           color: Colors.white
                      //                               .withOpacity(0.2),
                      //                         ),
                      //                       ),
                      //                       child: Row(
                      //                         mainAxisAlignment:
                      //                             MainAxisAlignment.end,
                      //                         children: [
                      //                           Expanded(
                      //                             child: Column(
                      //                               crossAxisAlignment:
                      //                                   CrossAxisAlignment.end,
                      //                               children: [
                      //                                 Text(
                      //                                   'پشتیبانی فنی:',
                      //                                   style: TextStyle(
                      //                                     color: Colors.white
                      //                                         .withOpacity(
                      //                                             0.95),
                      //                                     fontSize: 11,
                      //                                     fontWeight:
                      //                                         FontWeight.w500,
                      //                                     fontFamily:
                      //                                         'Vazirmatn',
                      //                                   ),
                      //                                 ),
                      //                                 const SizedBox(height: 2),
                      //                                 Text(
                      //                                   'support@pmsech.com',
                      //                                   style: TextStyle(
                      //                                     color: Colors.white
                      //                                         .withOpacity(0.8),
                      //                                     fontSize: 10,
                      //                                     fontFamily:
                      //                                         'Vazirmatn',
                      //                                   ),
                      //                                 ),
                      //                               ],
                      //                             ),
                      //                           ),
                      //                           const SizedBox(width: 8),
                      //                           Icon(
                      //                             Icons.support_agent,
                      //                             color: Colors.white
                      //                                 .withOpacity(0.9),
                      //                             size: 16,
                      //                           ),
                      //                         ],
                      //                       ),
                      //                     ),
                      //                   ],
                      //                 ),
                      //               ),
                      //             ),
                      //           );
                      //         },
                      //       ),
                      //     ),
                      //   ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    String? Function(String?)? validator,
  }) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.7,
      decoration: BoxDecoration(
        color: Colors.transparent, // شفاف کردن پس‌زمینه
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1.5, // حاشیه نازک
        ),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword ? _obscurePassword : false,
        textAlign: TextAlign.center, // وسط چین کردن متن
        style: const TextStyle(
          color: Colors.white, // سفید کردن متن
          fontWeight: FontWeight.bold, // بولد کردن متن
          fontFamily: 'Vazirmatn',
          fontSize: 16,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: Colors.white.withOpacity(0.8), // سفید کردن لیبل
            fontWeight: FontWeight.bold,
            fontFamily: 'Vazirmatn',
          ),
          prefixIcon: Icon(
            icon,
            color: Colors.white, // سفید کردن آیکن
          ),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: Colors.white, // سفید کردن آیکن
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          alignLabelWithHint: true,
          floatingLabelAlignment:
              FloatingLabelAlignment.center, // وسط چین کردن لیبل
          floatingLabelBehavior: FloatingLabelBehavior.auto,
        ),
        validator: validator,
      ),
    );
  }
}
