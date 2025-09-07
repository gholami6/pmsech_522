import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;

class DocumentUploadService {
  static const String baseUrl = 'https://sechah.liara.run'; // آدرس اصلی سرور
  static const String apiEndpoint =
      '$baseUrl/document_access_api.php'; // استفاده از API موجود

  /// آپلود فایل به سرور
  static Future<Map<String, dynamic>> uploadDocument({
    required File file,
    required String userId,
    required String userName,
    String description = '',
    String category = 'نامه‌های ارسالی',
    String equipment = '',
    bool isPublic = true,
  }) async {
    try {
      // بررسی اندازه فایل (50MB)
      final fileSize = await file.length();
      if (fileSize > 50 * 1024 * 1024) {
        return {
          'success': false,
          'message': 'حجم فایل بیش از 50 مگابایت است',
        };
      }

      // بررسی نوع فایل
      final extension = path.extension(file.path).toLowerCase();
      final allowedExtensions = [
        '.pdf',
        '.doc',
        '.docx',
        '.xls',
        '.xlsx',
        '.txt',
        '.jpg',
        '.jpeg',
        '.png',
        '.gif'
      ];

      if (!allowedExtensions.contains(extension)) {
        return {
          'success': false,
          'message': 'نوع فایل مجاز نیست',
        };
      }

      // ایجاد درخواست multipart
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(apiEndpoint),
      );

      // اضافه کردن action به فیلدها
      request.fields['action'] = 'upload';

      // اضافه کردن فایل
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          file.path,
        ),
      );

      // اضافه کردن فیلدهای متا
      request.fields.addAll({
        'user_id': userId,
        'user_name': userName,
        'description': description,
        'category': category,
        'equipment': equipment,
        'is_public': isPublic.toString(),
      });

      // ارسال درخواست
      final response = await request.send();
      final responseData = await response.stream.bytesToString();

      print('DocumentUploadService: Response status: ${response.statusCode}');
      print('DocumentUploadService: Response body: $responseData');

      try {
        final jsonResponse = json.decode(responseData);
        return jsonResponse;
      } catch (e) {
        print('DocumentUploadService: JSON parse error: $e');
        return {
          'success': false,
          'message': 'خطا در پاسخ سرور: $responseData',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'خطا در آپلود فایل: $e',
      };
    }
  }

  /// دریافت لیست فایل‌ها
  static Future<Map<String, dynamic>> getDocuments({
    String? category,
    String? userId,
    bool? isPublic,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (category != null) queryParams['category'] = category;
      if (userId != null) queryParams['user_id'] = userId;
      if (isPublic != null) queryParams['public'] = isPublic.toString();

      final uri = Uri.parse('$apiEndpoint?action=list').replace(
        queryParameters: queryParams,
      );

      final response = await http.get(uri);
      final jsonResponse = json.decode(response.body);

      return jsonResponse;
    } catch (e) {
      return {
        'success': false,
        'message': 'خطا در دریافت لیست فایل‌ها: $e',
        'documents': [],
      };
    }
  }

  /// دریافت اطلاعات دانلود فایل
  static Future<Map<String, dynamic>> getDownloadInfo(String documentId) async {
    try {
      final uri = Uri.parse('$apiEndpoint?action=download&id=$documentId');
      final response = await http.get(uri);
      final jsonResponse = json.decode(response.body);

      return jsonResponse;
    } catch (e) {
      return {
        'success': false,
        'message': 'خطا در دریافت اطلاعات دانلود: $e',
      };
    }
  }

  /// دانلود فایل
  static Future<File?> downloadDocument(
      String documentId, String savePath) async {
    try {
      // دریافت اطلاعات دانلود
      final downloadInfo = await getDownloadInfo(documentId);
      if (!downloadInfo['success']) {
        throw Exception(downloadInfo['message']);
      }

      // دانلود فایل
      final response = await http.get(
        Uri.parse('$baseUrl/${downloadInfo['download_url']}'),
      );

      if (response.statusCode == 200) {
        final file = File(savePath);
        await file.writeAsBytes(response.bodyBytes);
        return file;
      } else {
        throw Exception('خطا در دانلود فایل');
      }
    } catch (e) {
      print('خطا در دانلود فایل: $e');
      return null;
    }
  }

  /// حذف فایل
  static Future<Map<String, dynamic>> deleteDocument({
    required String documentId,
    required String userId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$apiEndpoint?action=delete'),
        body: {
          'id': documentId,
          'user_id': userId,
        },
      );

      final jsonResponse = json.decode(response.body);
      return jsonResponse;
    } catch (e) {
      return {
        'success': false,
        'message': 'خطا در حذف فایل: $e',
      };
    }
  }

  /// دریافت اطلاعات کلی
  static Future<Map<String, dynamic>> getInfo() async {
    try {
      final uri = Uri.parse('$apiEndpoint?action=info');
      final response = await http.get(uri);
      final jsonResponse = json.decode(response.body);

      return jsonResponse;
    } catch (e) {
      return {
        'success': false,
        'message': 'خطا در دریافت اطلاعات: $e',
      };
    }
  }

  /// انتخاب فایل از دستگاه
  static Future<File?> pickDocument({
    List<String>? allowedExtensions,
    bool allowMultiple = false,
  }) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: allowedExtensions ??
            [
              'pdf',
              'doc',
              'docx',
              'xls',
              'xlsx',
              'txt',
              'jpg',
              'jpeg',
              'png',
              'gif'
            ],
        allowMultiple: allowMultiple,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = File(result.files.first.path!);
        return file;
      }
      return null;
    } catch (e) {
      print('خطا در انتخاب فایل: $e');
      return null;
    }
  }

  /// فرمت کردن اندازه فایل
  static String formatFileSize(int bytes) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB"];
    var i = (log(bytes) / log(1024)).floor();
    return '${(bytes / pow(1024, i)).toStringAsFixed(1)} ${suffixes[i]}';
  }

  /// دریافت آیکن مناسب برای نوع فایل
  static String getFileIcon(String extension) {
    switch (extension.toLowerCase()) {
      case '.pdf':
        return '📄';
      case '.doc':
      case '.docx':
        return '📝';
      case '.xls':
      case '.xlsx':
        return '📊';
      case '.txt':
        return '📄';
      case '.jpg':
      case '.jpeg':
      case '.png':
      case '.gif':
        return '🖼️';
      default:
        return '📁';
    }
  }

  /// بررسی اتصال به اینترنت
  static Future<bool> checkConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }
}

// کلاس مدل برای فایل
class DocumentModel {
  final String id;
  final String name;
  final String size;
  final String extension;
  final String userName;
  final String description;
  final String category;
  final String uploadDate;
  final int downloadCount;
  final bool isPublic;

  DocumentModel({
    required this.id,
    required this.name,
    required this.size,
    required this.extension,
    required this.userName,
    required this.description,
    required this.category,
    required this.uploadDate,
    required this.downloadCount,
    required this.isPublic,
  });

  factory DocumentModel.fromJson(Map<String, dynamic> json) {
    return DocumentModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      size: json['size'] ?? '',
      extension: json['extension'] ?? '',
      userName: json['user_name'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      uploadDate: json['upload_date'] ?? '',
      downloadCount: json['download_count'] ?? 0,
      isPublic: json['is_public'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'size': size,
      'extension': extension,
      'user_name': userName,
      'description': description,
      'category': category,
      'upload_date': uploadDate,
      'download_count': downloadCount,
      'is_public': isPublic,
    };
  }
}
