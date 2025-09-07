import 'package:hive/hive.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:email_validator/email_validator.dart';
import '../models/user_model.dart';
import '../models/position_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import '../services/user_api_service.dart'; // Added import for UserApiService
import 'package:http/http.dart' as http; // Added import for http
import 'dart:io'; // Added import for InternetAddress

class AuthService extends ChangeNotifier {
  late Box<UserModel> _userBox;
  late Box<String> _currentUserBox;
  late Box<Map<String, dynamic>> _sessionBox;
  late SharedPreferences _prefs;
  UserModel? _currentUser;
  Timer? _sessionTimer;
  final int _maxLoginAttempts = 5;
  final Duration _lockoutDuration = const Duration(minutes: 15);
  Map<String, int> _loginAttempts = {};
  Map<String, DateTime> _lockoutTimes = {};

  Future<void> init() async {
    _userBox = await Hive.openBox<UserModel>('users');
    _currentUserBox = await Hive.openBox<String>('current_user');
    _sessionBox = await Hive.openBox<Map<String, dynamic>>('sessions');
    _prefs = await SharedPreferences.getInstance();

    // پاک کردن کاربران تکراری
    await _cleanupDuplicateUsers();

    // ایجاد کاربر پیش‌فرض مدیر مشاور (فقط در راه‌اندازی اولیه)
    await _createDefaultUsers();

    // تعمیر خودکار دیتابیس برای جلوگیری از مشکلات ورود
    try {
      print('=== تعمیر خودکار دیتابیس در راه‌اندازی ===');
      await repairDatabase();
      print('=== تعمیر خودکار تکمیل شد ===');
    } catch (e) {
      print('خطا در تعمیر خودکار دیتابیس: $e');
    }

    _loadCurrentUser();
  }

  Future<void> _createDefaultUsers() async {
    // بررسی وجود کاربر 1437
    final existingUser =
        _userBox.values.where((user) => user.username == '1437').firstOrNull;

    if (existingUser == null) {
      // فقط اگر کاربر 1437 وجود ندارد، آن را ایجاد کن
      final managerUser = UserModel(
        id: 'manager_1437',
        username: '1437',
        password: _hashPassword('1437'),
        mobile: '09123456789',
        email: 'manager@company.com',
        fullName: 'سرپرست مشاور سیستم',
        position: 'سرپرست مشاور',
      );

      await _userBox.add(managerUser);
      print('کاربر 1437 با نام سرپرست مشاور ایجاد شد');
    } else {
      print('کاربر 1437 قبلاً وجود دارد');
    }
  }

  Future<void> _loadCurrentUser() async {
    try {
      final username = _currentUserBox.get('current_user');
      if (username != null) {
        print('بارگذاری کاربر از session: $username');

        final users =
            _userBox.values.where((user) => user.username == username);
        final user = users.isNotEmpty ? users.first : null;
        if (user != null) {
          _currentUser = user;
          _startSessionTimer();
          print('کاربر با موفقیت بارگذاری شد: ${user.fullName}');
        } else {
          // کاربر یافت نشد، تلاش برای همگام‌سازی
          print('کاربر در دیتابیس یافت نشد، تلاش برای همگام‌سازی...');
          try {
            await forceSyncUsers();

            // دوباره بررسی کنیم
            final usersAfterSync =
                _userBox.values.where((user) => user.username == username);
            final userAfterSync =
                usersAfterSync.isNotEmpty ? usersAfterSync.first : null;

            if (userAfterSync != null) {
              _currentUser = userAfterSync;
              _startSessionTimer();
              print(
                  'کاربر بعد از همگام‌سازی بارگذاری شد: ${userAfterSync.fullName}');
            } else {
              // کاربر یافت نشد، پاک کردن session
              print('کاربر بعد از همگام‌سازی هم یافت نشد، پاک کردن session');
              await _currentUserBox.delete('current_user');
              _currentUser = null;
            }
          } catch (e) {
            print('خطا در همگام‌سازی: $e');
            await _currentUserBox.delete('current_user');
            _currentUser = null;
          }
        }
      } else {
        print('هیچ کاربری در session یافت نشد');
        _currentUser = null;
      }
    } catch (e) {
      print('خطا در بارگذاری کاربر فعلی: $e');
      _currentUser = null;
      await _currentUserBox.delete('current_user');
    }
  }

  void _startSessionTimer() {
    _sessionTimer?.cancel();
    _sessionTimer = Timer(const Duration(hours: 24), () {
      logout();
    });
  }

  Future<void> dispose() async {
    _sessionTimer?.cancel();
    await _userBox.close();
    await _currentUserBox.close();
    await _sessionBox.close();
  }

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  bool _validateMobile(String mobile) {
    final RegExp mobileRegex = RegExp(r'^09[0-9]{9}$');
    return mobileRegex.hasMatch(mobile);
  }

  bool _isPasswordStrong(String password) {
    return password.length >= 4;
  }

  String _sanitizeInput(String input) {
    return input.trim().replaceAll(RegExp(r'[<>]'), '');
  }

  // پاک کردن کاربران تکراری
  Future<void> _cleanupDuplicateUsers() async {
    final users = _userBox.values.toList();
    final seenUsernames = <String>{};
    final seenMobiles = <String>{};
    final seenEmails = <String>{};
    final toDelete = <String>[];

    for (final user in users) {
      // بررسی نام کاربری تکراری
      if (seenUsernames.contains(user.username)) {
        toDelete.add(user.id);
        continue;
      }
      seenUsernames.add(user.username);

      // بررسی موبایل تکراری
      if (seenMobiles.contains(user.mobile)) {
        toDelete.add(user.id);
        continue;
      }
      seenMobiles.add(user.mobile);

      // بررسی ایمیل تکراری
      if (seenEmails.contains(user.email)) {
        toDelete.add(user.id);
        continue;
      }
      seenEmails.add(user.email);
    }

    // حذف کاربران تکراری
    for (final userId in toDelete) {
      await _userBox.delete(userId);
      print('کاربر تکراری حذف شد: $userId');
    }

    if (toDelete.isNotEmpty) {
      print('تعداد ${toDelete.length} کاربر تکراری حذف شد');
    }
  }

  Future<void> register({
    required String username,
    required String password,
    required String mobile,
    required String email,
    required String fullName,
    required String position,
  }) async {
    // Sanitize inputs
    username = _sanitizeInput(username);
    email = _sanitizeInput(email);
    fullName = _sanitizeInput(fullName);
    position = _sanitizeInput(position);

    // Validate inputs
    if (username.length < 3) {
      throw Exception('نام کاربری باید حداقل 3 کاراکتر باشد');
    }

    if (!_isPasswordStrong(password)) {
      throw Exception('رمز عبور باید حداقل 4 کاراکتر باشد');
    }

    if (!_validateMobile(mobile)) {
      throw Exception('شماره موبایل نامعتبر است');
    }

    if (!EmailValidator.validate(email)) {
      throw Exception('ایمیل نامعتبر است');
    }

    if (fullName.length < 3) {
      throw Exception('نام کامل باید حداقل 3 کاراکتر باشد');
    }

    if (position.isEmpty) {
      throw Exception('پوزیشن شغلی نمی‌تواند خالی باشد');
    }

    // ابتدا در سرور ثبت کنیم
    String? serverUserId;
    try {
      print('تلاش برای ثبت کاربر در سرور...');
      final result = await UserApiService.registerUser(
        username: username,
        password: password,
        mobile: mobile,
        email: email,
        fullName: fullName,
        position: position,
      );

      if (result['success'] == true) {
        print('کاربر با موفقیت در سرور ثبت شد');
        serverUserId = result['user_id'];
      } else {
        print('ثبت در سرور ناموفق بود: ${result['message']}');
        // بررسی اینکه آیا کاربر قبلاً در سرور وجود دارد
        if (result['message']?.contains('قبلاً استفاده شده') == true) {
          throw Exception(result['message']);
        }
      }
    } catch (e) {
      print('خطا در ثبت کاربر در سرور: $e');
      // اگر خطای شبکه است، ادامه می‌دهیم
      if (!e.toString().contains('قبلاً استفاده شده')) {
        print('خطای شبکه - ادامه ثبت محلی');
      } else {
        rethrow;
      }
    }

    // بررسی تکراری نبودن در محلی
    if (_userBox.values.any((user) => user.username == username)) {
      throw Exception('نام کاربری قبلاً استفاده شده است');
    }

    if (_userBox.values.any((user) => user.mobile == mobile)) {
      throw Exception('شماره موبایل قبلاً استفاده شده است');
    }

    if (_userBox.values.any((user) => user.email == email)) {
      throw Exception('ایمیل قبلاً استفاده شده است');
    }

    final hashedPassword = _hashPassword(password);
    final user = UserModel(
      id: serverUserId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      username: username,
      password: hashedPassword,
      mobile: mobile,
      email: email,
      fullName: fullName,
      position: position,
    );

    // ثبت در دیتابیس محلی
    await _userBox.add(user);
    print('کاربر در دیتابیس محلی ثبت شد: ${user.username}');
  }

  Future<void> login(String username, String password) async {
    username = _sanitizeInput(username);

    // Check for lockout
    if (_lockoutTimes.containsKey(username)) {
      final lockoutTime = _lockoutTimes[username]!;
      if (DateTime.now().difference(lockoutTime) < _lockoutDuration) {
        throw Exception(
            'حساب کاربری شما به دلیل تلاش‌های ناموفق قفل شده است. لطفاً ${_lockoutDuration.inMinutes} دقیقه صبر کنید.');
      } else {
        _lockoutTimes.remove(username);
        _loginAttempts.remove(username);
      }
    }

    final hashedPassword = _hashPassword(password);

    // ابتدا از دیتابیس محلی بررسی کنیم
    UserModel? localUser;
    try {
      // دیباگ: نمایش تمام کاربران موجود
      print('=== دیباگ ورود ===');
      print('نام کاربری ورودی: $username');
      print('رمز عبور هش شده: $hashedPassword');
      print('تعداد کاربران در دیتابیس محلی: ${_userBox.values.length}');

      for (var user in _userBox.values) {
        print('کاربر موجود: ${user.username} (${user.id})');
        print('  - رمز عبور: ${user.password}');
        print('  - تطابق نام کاربری: ${user.username == username}');
        print('  - تطابق رمز عبور: ${user.password == hashedPassword}');
      }

      localUser = _userBox.values.firstWhere(
        (user) => user.username == username && user.password == hashedPassword,
      );
      print('کاربر در دیتابیس محلی یافت شد: ${localUser.fullName}');
    } catch (e) {
      print('کاربر در دیتابیس محلی یافت نشد: $username');
      print('خطا: $e');
      localUser = null;
    }

    // اگر در محلی یافت نشد، تلاش برای همگام‌سازی و دوباره بررسی
    if (localUser == null) {
      print('کاربر در دیتابیس محلی یافت نشد، تلاش برای همگام‌سازی...');
      try {
        await forceSyncUsers();

        // دوباره بررسی کنیم
        try {
          localUser = _userBox.values.firstWhere(
            (user) =>
                user.username == username && user.password == hashedPassword,
          );
          print('کاربر بعد از همگام‌سازی یافت شد: ${localUser.fullName}');
        } catch (e) {
          print('کاربر بعد از همگام‌سازی هم یافت نشد: $e');
          localUser = null;
        }
      } catch (e) {
        print('خطا در همگام‌سازی: $e');
      }
    }

    // اگر هنوز یافت نشد، از سرور بررسی کنیم (موقتاً غیرفعال)
    if (localUser == null) {
      print('⚠️ ورود از سرور موقتاً غیرفعال شده است (هاست نیاز به شارژ دارد)');
      /*
      try {
        print('تلاش برای ورود از سرور...');
        final serverResult = await UserApiService.loginUser(
          username: username,
          password: password,
        );

        if (serverResult['success'] == true && serverResult['user'] != null) {
          print('کاربر در سرور یافت شد');

          // تبدیل کاربر سرور به UserModel و ذخیره در محلی
          final serverUser = UserModel(
            id: serverResult['user']['id'] ??
                DateTime.now().millisecondsSinceEpoch.toString(),
            username: serverResult['user']['username'] ?? username,
            password: hashedPassword, // استفاده از هش محلی
            mobile: serverResult['user']['mobile'] ?? '',
            email: serverResult['user']['email'] ?? '',
            fullName: serverResult['user']['fullName'] ?? '',
            position: serverResult['user']['position'] ?? '',
          );

          // ذخیره در دیتابیس محلی
          await _userBox.add(serverUser);
          localUser = serverUser;
          print('کاربر سرور در دیتابیس محلی ذخیره شد');
        } else {
          print('کاربر در سرور یافت نشد: ${serverResult['message']}');
        }
      } catch (e) {
        print('خطا در ارتباط با سرور: $e');
      }
      */
    }

    // اگر کاربر در هیچ جا یافت نشد
    if (localUser == null) {
      _loginAttempts[username] = (_loginAttempts[username] ?? 0) + 1;
      if (_loginAttempts[username]! >= _maxLoginAttempts) {
        _lockoutTimes[username] = DateTime.now();
        throw Exception(
            'حساب کاربری شما به دلیل تلاش‌های ناموفق قفل شده است. لطفاً ${_lockoutDuration.inMinutes} دقیقه صبر کنید.');
      }
      throw Exception('نام کاربری یا رمز عبور اشتباه است');
    }

    // ذخیره session و تنظیم کاربر فعلی
    await _currentUserBox.put('current_user', localUser.username);
    _currentUser = localUser;
    _loginAttempts.remove(username);
    _startSessionTimer();

    // بررسی کاربر جدید به صورت async (بدون await)
    _checkFirstTimeUserAsync(username);

    notifyListeners();
  }

  // تابع جدید برای بررسی کاربر جدید به صورت async
  Future<void> _checkFirstTimeUserAsync(String username) async {
    try {
      final isFirstTime = await isFirstTimeUser(username);
      if (isFirstTime) {
        await _prefs.setBool('is_new_user_$username', true);
      }
    } catch (e) {
      // خطا در بررسی کاربر جدید نباید روی ورود تاثیر بگذارد
      print('خطا در بررسی کاربر جدید: $e');
    }
  }

  Future<void> signIn(String email, String password) async {
    await login(email, password);
  }

  Future<void> signUp(String email, String password, String fullName) async {
    await register(
      username: email,
      password: password,
      mobile: '', // You might want to add mobile number collection in the UI
      email: email,
      fullName: fullName,
      position: '', // You might want to add position collection in the UI
    );
  }

  Future<void> logout() async {
    _sessionTimer?.cancel();
    await _currentUserBox.delete('current_user');
    _currentUser = null;
    notifyListeners();
  }

  /// پاک کردن session و دوباره بارگذاری کاربر
  Future<void> clearSessionAndReload() async {
    print('=== پاک کردن session و دوباره بارگذاری ===');

    // پاک کردن session
    await _currentUserBox.delete('current_user');
    _currentUser = null;

    // همگام‌سازی کاربران
    await forceSyncUsers();

    // دوباره بارگذاری کاربر
    await _loadCurrentUser();

    notifyListeners();
    print('=== session پاک شد و کاربر دوباره بارگذاری شد ===');
  }

  Future<void> changePassword(
      String currentPassword, String newPassword) async {
    if (_currentUser == null) {
      throw Exception('کاربر وارد نشده است');
    }

    final hashedCurrentPassword = _hashPassword(currentPassword);
    if (_currentUser!.password != hashedCurrentPassword) {
      throw Exception('رمز عبور فعلی اشتباه است');
    }

    if (!_isPasswordStrong(newPassword)) {
      throw Exception('رمز عبور جدید باید حداقل 4 کاراکتر باشد');
    }

    final hashedNewPassword = _hashPassword(newPassword);
    _currentUser!.password = hashedNewPassword;
    await _userBox.put(_currentUser!.id, _currentUser!);
    notifyListeners();
  }

  Future<void> rememberUser(String username, String password) async {
    await _prefs.setString('remembered_user', username);
    await _prefs.setString('remembered_password', password); // رمز واقعی
  }

  Future<void> forgetUser() async {
    await _prefs.remove('remembered_user');
    await _prefs.remove('remembered_password');
  }

  Future<String?> getRememberedUser() async {
    return _prefs.getString('remembered_user');
  }

  Future<String?> getRememberedPassword() async {
    return _prefs.getString('remembered_password'); // رمز واقعی
  }

  Future<bool> getHasLoggedInBefore() async {
    return _prefs.getBool('has_logged_in_before') ?? false;
  }

  /// تعمیر دیتابیس برای حل مشکلات ورود
  Future<void> repairDatabase() async {
    print('=== شروع تعمیر دیتابیس ===');

    try {
      // همگام‌سازی اجباری کاربران
      await forceSyncUsers();

      // بررسی کاربران موجود
      final users = _userBox.values.toList();
      print('تعداد کاربران در دیتابیس: ${users.length}');

      for (var user in users) {
        print('کاربر: ${user.username} (${user.id})');
      }

      // بررسی session
      final currentUser = _currentUserBox.get('current_user');
      if (currentUser != null) {
        print('کاربر فعلی در session: $currentUser');

        // بررسی وجود کاربر در دیتابیس
        final userExists = users.any((user) => user.username == currentUser);
        if (!userExists) {
          print('کاربر session در دیتابیس موجود نیست، پاک کردن session');
          await _currentUserBox.delete('current_user');
          _currentUser = null;
        }
      }

      print('=== تعمیر دیتابیس تکمیل شد ===');
    } catch (e) {
      print('خطا در تعمیر دیتابیس: $e');
    }
  }

  UserModel? get currentUser => _currentUser;

  bool isLoggedIn() => _currentUser != null;

  Future<void> signOut() async {
    await logout();
  }

  bool validateEmail(String email) {
    return EmailValidator.validate(email);
  }

  bool validatePassword(String password) {
    return _isPasswordStrong(password);
  }

  UserModel? getCurrentUser() {
    return _currentUser;
  }

  /// دریافت همه کاربران
  Future<List<UserModel>> getAllUsers() async {
    print('=== شروع دریافت همه کاربران ===');

    // ابتدا از هاست دریافت کنیم
    try {
      print('دریافت کاربران از هاست...');
      final hostResult = await UserApiService.getAllUsers();

      if (hostResult['success'] == true) {
        print(
            'کاربران هاست دریافت شد: ${hostResult['users']?.length ?? 0} کاربر');

        // تبدیل کاربران هاست به UserModel
        final hostUsers = <UserModel>[];
        if (hostResult['users'] != null) {
          for (var userData in hostResult['users']) {
            try {
              final hostUser = UserModel(
                id: userData['id'] ?? '',
                username: userData['username'] ?? '',
                password: userData['password'] ?? '', // رمز هش شده از هاست
                mobile: userData['mobile'] ?? '',
                email: userData['email'] ?? '',
                fullName: userData['fullName'] ?? '',
                position: userData['position'] ?? '',
              );
              hostUsers.add(hostUser);
            } catch (e) {
              print('خطا در تبدیل کاربر هاست: $e');
            }
          }
        }

        // همگام‌سازی با دیتابیس محلی
        await _syncUsersWithHost(hostUsers);

        print('همگام‌سازی تکمیل شد');
      } else {
        print('خطا در دریافت کاربران از هاست: ${hostResult['message']}');
      }
    } catch (e) {
      print('خطا در ارتباط با هاست: $e');
    }

    // در نهایت از دیتابیس محلی برگردانیم
    final localUsers = _userBox.values.toList();
    print('کاربران محلی: ${localUsers.length} کاربر');
    for (var user in localUsers) {
      print('  - ${user.username} (${user.id})');
    }

    print('=== پایان دریافت همه کاربران ===');
    return localUsers;
  }

  /// دریافت همه کاربران (همزمان)
  List<UserModel> getAllUsersSync() {
    return _userBox.values.toList();
  }

  /// همگام‌سازی کاربران محلی با هاست
  Future<void> _syncUsersWithHost(List<UserModel> hostUsers) async {
    print('=== شروع همگام‌سازی کاربران ===');

    final localUsers = _userBox.values.toList();
    print('کاربران محلی: ${localUsers.length}');
    print('کاربران هاست: ${hostUsers.length}');

    // اضافه کردن کاربران هاست که در محلی نیستند
    for (var hostUser in hostUsers) {
      final existsLocally = localUsers.any((localUser) =>
          localUser.username == hostUser.username ||
          localUser.id == hostUser.id);

      if (!existsLocally) {
        print('اضافه کردن کاربر هاست به محلی: ${hostUser.username}');

        // ایجاد کاربر جدید با اطلاعات هاست (نه همان شیء)
        final newUser = UserModel(
          id: hostUser.id,
          username: hostUser.username,
          password: hostUser.password, // رمز عبور از هاست قبلاً هش شده
          mobile: hostUser.mobile,
          email: hostUser.email,
          fullName: hostUser.fullName,
          position: hostUser.position,
        );

        await _userBox.add(newUser);
      }
    }

    // بررسی کاربران محلی که در هاست نیستند
    for (var localUser in localUsers) {
      final existsInHost = hostUsers.any((hostUser) =>
          hostUser.username == localUser.username ||
          hostUser.id == localUser.id);

      if (!existsInHost) {
        // حذف نکن اگر کاربر سرپرست است (1437)
        if (localUser.username == '1437') {
          print('کاربر سرپرست 1437 در هاست نیست اما حذف نمی‌شود');
          continue;
        }
        
        print(
            'کاربر محلی در هاست نیست، حذف از دیتابیس محلی: ${localUser.username}');
        // حذف کاربر از دیتابیس محلی اگر در سرور موجود نیست
        await _userBox.delete(localUser.id);
        print('کاربر ${localUser.username} از دیتابیس محلی حذف شد');
      }
    }

    print('=== پایان همگام‌سازی کاربران ===');
  }

  /// همگام‌سازی اجباری کاربران
  Future<void> forceSyncUsers() async {
    try {
      print('=== شروع همگام‌سازی اجباری کاربران ===');

      final result = await UserApiService.getAllUsers();
      if (result['success'] == true && result['users'] != null) {
        final hostUsers = <UserModel>[];
        for (var userData in result['users']) {
          try {
            final hostUser = UserModel(
              id: userData['id'] ?? '',
              username: userData['username'] ?? '',
              password: userData['password'] ?? '', // رمز هش شده از هاست
              mobile: userData['mobile'] ?? '',
              email: userData['email'] ?? '',
              fullName: userData['fullName'] ?? '',
              position: userData['position'] ?? '',
            );
            hostUsers.add(hostUser);
          } catch (e) {
            print('خطا در تبدیل کاربر هاست: $e');
          }
        }

        await _syncUsersWithHost(hostUsers);
        print('همگام‌سازی اجباری تکمیل شد');
      } else {
        print('خطا در دریافت کاربران از سرور: ${result['message']}');
      }
    } catch (e) {
      print('خطا در همگام‌سازی اجباری: $e');
    }
  }

  /// به‌روزرسانی اطلاعات کاربر
  Future<void> updateUser({
    required String userId,
    required String email,
    required String fullName,
    required String mobile,
    required String position,
  }) async {
    print('=== شروع به‌روزرسانی کاربر ===');
    print('شناسه کاربر: $userId');

    final user = _userBox.values.firstWhere(
      (user) => user.id == userId,
      orElse: () => throw Exception('کاربر یافت نشد'),
    );

    print('کاربر یافت شد: ${user.username}');

    // بررسی تکراری نبودن ایمیل و موبایل
    if (email != user.email && _userBox.values.any((u) => u.email == email)) {
      throw Exception('ایمیل قبلاً استفاده شده است');
    }

    if (mobile != user.mobile &&
        _userBox.values.any((u) => u.mobile == mobile)) {
      throw Exception('شماره موبایل قبلاً استفاده شده است');
    }

    // ابتدا در هاست به‌روزرسانی کنیم
    bool hostUpdateSuccess = false;
    try {
      print('به‌روزرسانی کاربر در هاست...');
      final result = await UserApiService.updateUser(
        userId: userId,
        email: email,
        fullName: fullName,
        mobile: mobile,
        position: position,
      );

      hostUpdateSuccess = result['success'] == true;
      print('نتیجه به‌روزرسانی در هاست: $result');
    } catch (e) {
      print('خطا در به‌روزرسانی کاربر در هاست: $e');
    }

    // سپس در دیتابیس محلی به‌روزرسانی کنیم
    user.email = email;
    user.fullName = fullName;
    user.mobile = mobile;
    user.position = position;

    await _userBox.put(userId, user);
    print('کاربر در دیتابیس محلی به‌روزرسانی شد');

    // اگر به‌روزرسانی در هاست ناموفق بود، تغییرات را برگردانیم
    if (!hostUpdateSuccess) {
      print('برگرداندن تغییرات به دلیل عدم موفقیت در هاست');
      // تغییرات را برگردانیم
      user.email = user.email; // این خط اضافی است، فقط برای نشان دادن منطق
      await _userBox.put(userId, user);
      throw Exception(
          'خطا در به‌روزرسانی کاربر در سرور. لطفاً دوباره تلاش کنید.');
    }

    notifyListeners();
    print('=== پایان به‌روزرسانی کاربر ===');
  }

  /// حذف کاربر
  Future<void> deleteUser(String userId) async {
    print('=== شروع حذف کاربر ===');
    print('شناسه کاربر: $userId');

    final user = _userBox.values.firstWhere(
      (user) => user.id == userId,
      orElse: () => throw Exception('کاربر یافت نشد'),
    );

    print('کاربر یافت شد: ${user.username}');

    // جلوگیری از حذف خود کاربر فعلی
    if (user.id == _currentUser?.id) {
      throw Exception('نمی‌توانید خودتان را حذف کنید');
    }

    // ابتدا از هاست حذف کنیم
    bool hostDeleteSuccess = false;
    try {
      print('حذف از هاست...');
      final result = await UserApiService.deleteUser(userId: userId);
      print('نتیجه حذف از هاست: $result');
      hostDeleteSuccess = result['success'] == true;
    } catch (e) {
      print('خطا در حذف کاربر از هاست: $e');
    }

    // سپس از دیتابیس محلی حذف کنیم
    print('حذف از دیتابیس محلی...');
    await _userBox.delete(userId);
    print('کاربر از دیتابیس محلی حذف شد');

    // اگر حذف از هاست ناموفق بود، کاربر جدیدی با همان اطلاعات ایجاد کنیم
    if (!hostDeleteSuccess) {
      print('بازگرداندن کاربر به دلیل عدم موفقیت در حذف از هاست');

      // ایجاد کاربر جدید با همان اطلاعات (نه همان شیء)
      final newUser = UserModel(
        id: user.id,
        username: user.username,
        password: user.password,
        mobile: user.mobile,
        email: user.email,
        fullName: user.fullName,
        position: user.position,
      );

      await _userBox.add(newUser);
      throw Exception('خطا در حذف کاربر از سرور. لطفاً دوباره تلاش کنید.');
    }

    // پاک کردن has_logged_in_before برای این کاربر
    try {
      await _prefs.remove('has_logged_in_before');
      print('پاک کردن وضعیت ورود قبلی کاربر');
    } catch (e) {
      print('خطا در پاک کردن وضعیت ورود: $e');
    }

    // پاک کردن remembered user اگر همین کاربر باشد
    try {
      final rememberedUser = _prefs.getString('remembered_user');
      if (rememberedUser == user.username) {
        await forgetUser();
        print('پاک کردن یادآوری کاربر حذف شده');
      }
    } catch (e) {
      print('خطا در پاک کردن یادآوری کاربر: $e');
    }

    notifyListeners();
    print('=== پایان حذف کاربر ===');
  }

  /// حذف امن کاربر (بدون بازگردانی در صورت خطای سرور)
  Future<void> deleteUserSafely(String userId) async {
    print('=== شروع حذف امن کاربر ===');
    print('شناسه کاربر: $userId');

    final user = _userBox.values.firstWhere(
      (user) => user.id == userId,
      orElse: () => throw Exception('کاربر یافت نشد'),
    );

    print('کاربر یافت شد: ${user.username}');

    // جلوگیری از حذف خود کاربر فعلی
    if (user.id == _currentUser?.id) {
      throw Exception('نمی‌توانید خودتان را حذف کنید');
    }

    // تلاش برای حذف از سرور (اختیاری)
    try {
      print('تلاش برای حذف از سرور...');
      final result = await UserApiService.deleteUser(userId: userId);
      print('نتیجه حذف از سرور: $result');
    } catch (e) {
      print('خطا در حذف از سرور (ادامه حذف محلی): $e');
    }

    // حذف از دیتابیس محلی (قطعاً)
    print('حذف از دیتابیس محلی...');
    await _userBox.delete(userId);
    print('کاربر از دیتابیس محلی حذف شد');

    // پاک کردن has_logged_in_before برای این کاربر
    try {
      await _prefs.remove('has_logged_in_before');
      print('پاک کردن وضعیت ورود قبلی کاربر');
    } catch (e) {
      print('خطا در پاک کردن وضعیت ورود: $e');
    }

    // پاک کردن remembered user اگر همین کاربر باشد
    try {
      final rememberedUser = _prefs.getString('remembered_user');
      if (rememberedUser == user.username) {
        await forgetUser();
        print('پاک کردن یادآوری کاربر حذف شده');
      }
    } catch (e) {
      print('خطا در پاک کردن یادآوری کاربر: $e');
    }

    notifyListeners();
    print('=== پایان حذف امن کاربر ===');
  }

  // تمام توابع دسترسی حذف شدند - برای تعریف مجدد

  /// بررسی اینکه آیا کاربر برای اولین بار وارد شده یا نه
  Future<bool> isFirstTimeUser(String username) async {
    final key = 'first_time_$username';
    final isFirstTime = _prefs.getBool(key) ?? true;

    if (isFirstTime) {
      // علامت‌گذاری که کاربر برای اولین بار وارد شده
      await _prefs.setBool(key, false);
    }

    return isFirstTime;
  }

  /// بازنشانی وضعیت کاربر جدید (برای تست)
  Future<void> resetFirstTimeStatus(String username) async {
    final key = 'first_time_$username';
    await _prefs.setBool(key, true);
  }

  /// حذف همه کاربران به جز مدیران اصلی و افزودن مدیر 1437
  Future<void> resetToOnlyManagers() async {
    // حذف همه کاربران به جز 1437
    final usersToKeep =
        _userBox.values.where((user) => user.username == '1437').toList();
    await _userBox.clear();
    for (final user in usersToKeep) {
      await _userBox.add(user);
    }

    // اطمینان از وجود مدیر 1437
    if (!_userBox.values.any((user) => user.username == '1437')) {
      final manager1437 = UserModel(
        id: 'manager_1437',
        username: '1437',
        password: _hashPassword('1437'),
        mobile: '09123456789',
        email: 'manager1437@company.com',
        fullName: 'مدیر مشاور سیستم',
        position: 'مدیر مشاور',
      );
      await _userBox.add(manager1437);
    }
    notifyListeners();
  }

  // بازنشانی کامل دیتابیس کاربران (برای حل مشکلات)
  Future<void> resetUserDatabase() async {
    try {
      print('شروع بازنشانی دیتابیس کاربران...');

      // پاک کردن تمام کاربران
      await _userBox.clear();
      print('تمام کاربران پاک شدند');

      // پاک کردن session فعلی
      await _currentUserBox.clear();
      await _sessionBox.clear();
      _currentUser = null;
      print('Session پاک شد');

      // ایجاد مجدد کاربران پیش‌فرض
      // await _createDefaultUsers(); // حذف شد تا کاربر 1437 دوباره ایجاد نشود
      print('کاربران پیش‌فرض ایجاد شدند');

      print('بازنشانی دیتابیس کاربران تکمیل شد');
    } catch (e) {
      print('خطا در بازنشانی دیتابیس کاربران: $e');
      rethrow;
    }
  }

  /// پاک کردن کامل دیتابیس و راه‌اندازی مجدد (برای حل مشکلات Hive)
  Future<void> clearAndReinitializeDatabase() async {
    try {
      print('=== شروع پاک کردن کامل دیتابیس ===');

      // بستن باکس‌ها
      await _userBox.close();
      await _currentUserBox.close();
      await _sessionBox.close();

      // پاک کردن فایل‌های دیتابیس
      await Hive.deleteBoxFromDisk('users');
      await Hive.deleteBoxFromDisk('current_user');
      await Hive.deleteBoxFromDisk('sessions');

      print('فایل‌های دیتابیس پاک شدند');

      // راه‌اندازی مجدد
      await init();

      print('=== دیتابیس مجدداً راه‌اندازی شد ===');
    } catch (e) {
      print('خطا در پاک کردن دیتابیس: $e');
      rethrow;
    }
  }

  // بررسی و تعمیر یکپارچگی دیتابیس
  Future<Map<String, dynamic>> checkDatabaseIntegrity() async {
    try {
      print('=== شروع بررسی یکپارچگی دیتابیس ===');

      final allUsers = _userBox.values.toList();
      final issues = <String>[];
      final fixes = <String>[];

      // بررسی کاربران تکراری
      final seenUsernames = <String>{};
      final seenMobiles = <String>{};
      final seenEmails = <String>{};
      final duplicateUsers = <String>[];

      for (final user in allUsers) {
        if (seenUsernames.contains(user.username)) {
          duplicateUsers.add(user.username);
          issues.add('نام کاربری تکراری: ${user.username}');
        }
        seenUsernames.add(user.username);

        if (seenMobiles.contains(user.mobile)) {
          issues.add('موبایل تکراری: ${user.mobile}');
        }
        seenMobiles.add(user.mobile);

        if (seenEmails.contains(user.email)) {
          issues.add('ایمیل تکراری: ${user.email}');
        }
        seenEmails.add(user.email);
      }

      // بررسی session
      final currentUsername = _currentUserBox.get('current_user');
      if (currentUsername != null) {
        final userExists =
            allUsers.any((user) => user.username == currentUsername);
        if (!userExists) {
          issues.add('کاربر session در دیتابیس وجود ندارد: $currentUsername');
          fixes.add('پاک کردن session نامعتبر');
          await _currentUserBox.delete('current_user');
        }
      }

      // بررسی کاربران پیش‌فرض
      final hasDefaultManager = allUsers.any((user) => user.username == '1437');
      if (!hasDefaultManager) {
        issues.add('کاربر پیش‌فرض مدیر مشاور وجود ندارد');
        fixes.add('ایجاد کاربر پیش‌فرض مدیر مشاور');
        // await _createDefaultUsers(); // حذف شد تا کاربر 1437 دوباره ایجاد نشود
      }

      print('=== پایان بررسی یکپارچگی دیتابیس ===');

      return {
        'totalUsers': allUsers.length,
        'issues': issues,
        'fixes': fixes,
        'hasIssues': issues.isNotEmpty,
        'duplicateUsers': duplicateUsers,
      };
    } catch (e) {
      print('خطا در بررسی یکپارچگی دیتابیس: $e');
      return {
        'error': e.toString(),
        'hasIssues': true,
      };
    }
  }

  /// تست اتصال به سرور
  static Future<bool> testServerConnection() async {
    try {
      print('🌐 AuthService: تست اتصال سرور');

      // تست اولیه اتصال
      final testResponse = await http
          .get(Uri.parse('https://sechah.liara.run'))
          .timeout(const Duration(seconds: 2));

      if (testResponse.statusCode != 200) {
        print('❌ سرور اصلی در دسترس نیست: ${testResponse.statusCode}');
        return false;
      }

      print('تست DNS برای sechah.liara.run...');
      try {
        final addresses = await InternetAddress.lookup('sechah.liara.run');
        print('✅ DNS حل شد: ${addresses.first.address}');
      } catch (e) {
        print('❌ مشکل DNS: $e');
      }

      // تست اتصال HTTP
      final response = await http
          .get(Uri.parse('https://sechah.liara.run'))
          .timeout(const Duration(seconds: 5));

      print('کد پاسخ سرور: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 404) {
        print('✅ اتصال به سرور برقرار است');
        return true;
      } else {
        print('❌ سرور پاسخ نامعتبر داد: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ خطا در تست اتصال به سرور: $e');
      return false;
    }
  }

  /// تست مستقیم اتصال به سرور با جزئیات بیشتر
  Future<bool> testDirectConnection() async {
    try {
      print('=== تست مستقیم اتصال به سرور ===');

      // تست DNS
      print('تست DNS برای sechahoon.liara.run...');
      try {
        final addresses = await InternetAddress.lookup('sechahoon.liara.run');
        print('✅ DNS حل شد: ${addresses.map((a) => a.address).join(', ')}');
      } catch (e) {
        print('❌ خطا در حل DNS: $e');
        return false;
      }

      // تست اتصال HTTP
      print('تست اتصال HTTP...');
      final response = await http.get(
        Uri.parse('https://sechahoon.liara.run'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 15));

      print('✅ کد پاسخ HTTP: ${response.statusCode}');
      print('✅ اندازه پاسخ: ${response.body.length} کاراکتر');

      return response.statusCode == 200 || response.statusCode == 404;
    } catch (e) {
      print('❌ خطا در تست مستقیم: $e');
      return false;
    }
  }

  /// تست کامل سیستم احراز هویت
  Future<Map<String, dynamic>> testAuthSystem() async {
    try {
      print('=== تست کامل سیستم احراز هویت ===');

      final results = <String, dynamic>{};

      // تست اتصال سرور
      results['server_connection'] = await testServerConnection();

      // تست اتصال مستقیم
      results['direct_connection'] = await testDirectConnection();

      // بررسی کاربران محلی
      final localUsers = _userBox.values.toList();
      results['local_users_count'] = localUsers.length;
      results['local_users'] = localUsers
          .map((u) => {
                'username': u.username,
                'id': u.id,
                'has_password': u.password.isNotEmpty,
              })
          .toList();

      // بررسی session
      final currentUsername = _currentUserBox.get('current_user');
      results['current_session'] = currentUsername;
      results['has_session'] = currentUsername != null;

      // تست همگام‌سازی
      try {
        await forceSyncUsers();
        results['sync_success'] = true;
      } catch (e) {
        results['sync_success'] = false;
        results['sync_error'] = e.toString();
      }

      print('=== پایان تست سیستم احراز هویت ===');
      return results;
    } catch (e) {
      print('خطا در تست سیستم احراز هویت: $e');
      return {'error': e.toString()};
    }
  }
}
