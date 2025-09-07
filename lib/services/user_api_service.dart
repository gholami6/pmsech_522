import 'dart:convert';
import 'package:http/http.dart' as http;

class UserApiService {
  static const String _baseUrl = 'http://62.60.198.11';
  static const String _apiEndpoint = '/user_api.php'; // یا مسیر صحیح فایل
  static const String _apiKey = 'pmsech_user_api_2024';

  /// ثبت کاربر جدید در هاست
  static Future<Map<String, dynamic>> registerUser({
    required String username,
    required String password,
    required String mobile,
    required String email,
    required String fullName,
    required String position,
  }) async {
    try {
      final userData = {
        'username': username,
        'password': password,
        'mobile': mobile,
        'email': email,
        'fullName': fullName,
        'position': position,
      };

      print('=== شروع ثبت کاربر در هاست ===');
      print('آدرس: $_baseUrl$_apiEndpoint?action=register&api_key=$_apiKey');
      print('داده‌ها: $userData');

      final response = await http.post(
        Uri.parse('$_baseUrl$_apiEndpoint?action=register&api_key=$_apiKey'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: json.encode(userData),
      );

      print('کد وضعیت ثبت: ${response.statusCode}');
      print('بدنه پاسخ ثبت: ${response.body}');

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'message': data['message'],
          'user_id': data['user_id'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'خطا در ثبت کاربر',
          'error': data['error'],
        };
      }
    } catch (e) {
      print('خطا در ثبت کاربر: $e');
      return {
        'success': false,
        'message': 'خطا در ارتباط با سرور: $e',
      };
    }
  }

  /// ورود کاربر از هاست
  static Future<Map<String, dynamic>> loginUser({
    required String username,
    required String password,
  }) async {
    try {
      final userData = {
        'username': username,
        'password': password,
      };

      print('=== شروع ورود کاربر از هاست ===');
      print('آدرس: $_baseUrl$_apiEndpoint?action=login&api_key=$_apiKey');

      final response = await http.post(
        Uri.parse('$_baseUrl$_apiEndpoint?action=login&api_key=$_apiKey'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: json.encode(userData),
      );

      print('کد وضعیت ورود: ${response.statusCode}');
      print('بدنه پاسخ ورود: ${response.body}');

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'message': data['message'],
          'user': data['user'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'خطا در ورود',
          'error': data['error'],
        };
      }
    } catch (e) {
      print('خطا در ورود کاربر: $e');
      return {
        'success': false,
        'message': 'خطا در ارتباط با سرور: $e',
      };
    }
  }

  /// دریافت لیست همه کاربران از هاست
  static Future<Map<String, dynamic>> getAllUsers() async {
    try {
      print('=== شروع دریافت لیست کاربران از هاست ===');
      print('آدرس: $_baseUrl$_apiEndpoint?action=list&api_key=$_apiKey');

      final response = await http.get(
        Uri.parse('$_baseUrl$_apiEndpoint?action=list&api_key=$_apiKey'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
      );

      print('کد وضعیت دریافت: ${response.statusCode}');
      print('بدنه پاسخ دریافت: ${response.body}');

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'message': data['message'],
          'users': data['users'],
          'count': data['count'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'خطا در دریافت کاربران',
          'error': data['error'],
        };
      }
    } catch (e) {
      print('خطا در دریافت کاربران: $e');
      return {
        'success': false,
        'message': 'خطا در ارتباط با سرور: $e',
      };
    }
  }

  /// به‌روزرسانی کاربر در هاست
  static Future<Map<String, dynamic>> updateUser({
    required String userId,
    required String email,
    required String fullName,
    required String mobile,
    required String position,
  }) async {
    try {
      final userData = {
        'user_id': userId,
        'email': email,
        'fullName': fullName,
        'mobile': mobile,
        'position': position,
      };

      print('=== شروع به‌روزرسانی کاربر در هاست ===');
      print('آدرس: $_baseUrl$_apiEndpoint?action=update&api_key=$_apiKey');
      print('داده‌ها: $userData');

      final response = await http.post(
        Uri.parse('$_baseUrl$_apiEndpoint?action=update&api_key=$_apiKey'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: json.encode(userData),
      );

      print('کد وضعیت به‌روزرسانی: ${response.statusCode}');
      print('بدنه پاسخ به‌روزرسانی: ${response.body}');

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'message': data['message'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'خطا در به‌روزرسانی کاربر',
          'error': data['error'],
        };
      }
    } catch (e) {
      print('خطا در به‌روزرسانی کاربر: $e');
      return {
        'success': false,
        'message': 'خطا در ارتباط با سرور: $e',
      };
    }
  }

  /// حذف کاربر از هاست
  static Future<Map<String, dynamic>> deleteUser({
    required String userId,
  }) async {
    try {
      final userData = {
        'user_id': userId,
      };

      print('=== شروع حذف کاربر از هاست ===');
      print('آدرس: $_baseUrl$_apiEndpoint?action=delete&api_key=$_apiKey');
      print('شناسه کاربر: $userId');

      final response = await http.post(
        Uri.parse('$_baseUrl$_apiEndpoint?action=delete&api_key=$_apiKey'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: json.encode(userData),
      );

      print('کد وضعیت حذف: ${response.statusCode}');
      print('بدنه پاسخ حذف: ${response.body}');

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'message': data['message'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'خطا در حذف کاربر',
          'error': data['error'],
        };
      }
    } catch (e) {
      print('خطا در حذف کاربر: $e');
      return {
        'success': false,
        'message': 'خطا در ارتباط با سرور: $e',
      };
    }
  }
}
