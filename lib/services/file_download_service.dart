import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class FileDownloadService {
  static const String baseUrl =
      'https://your-server.com/files/'; // آدرس سرور شما

  /// دانلود فایل CSV از سرور
  static Future<String?> downloadCsvFile(String fileName) async {
    try {
      print('=== شروع دانلود فایل $fileName ===');

      final url = Uri.parse('$baseUrl$fileName');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        // ذخیره فایل در پوشه موقت
        final directory = await getTemporaryDirectory();
        final file = File('${directory.path}/$fileName');
        await file.writeAsBytes(response.bodyBytes);

        print('فایل $fileName با موفقیت دانلود شد');
        return file.path;
      } else {
        print('خطا در دانلود فایل: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('خطا در دانلود فایل $fileName: $e');
      return null;
    }
  }

  /// بررسی وجود فایل در پوشه موقت
  static Future<bool> fileExists(String fileName) async {
    try {
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/$fileName');
      return await file.exists();
    } catch (e) {
      return false;
    }
  }

  /// خواندن محتوای فایل CSV
  static Future<String?> readCsvFile(String fileName) async {
    try {
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/$fileName');

      if (await file.exists()) {
        return await file.readAsString();
      } else {
        print('فایل $fileName یافت نشد');
        return null;
      }
    } catch (e) {
      print('خطا در خواندن فایل $fileName: $e');
      return null;
    }
  }
}
