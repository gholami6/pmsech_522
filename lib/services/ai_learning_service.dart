import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/ai_learning_data.dart';

class AILearningService {
  static const String _learningDataKey = 'ai_learning_data';
  static const String _sessionMemoryKey = 'ai_session_memory';

  // ذخیره اطلاعات یادگیری جدید
  Future<void> saveLearningData(AILearningData data) async {
    final prefs = await SharedPreferences.getInstance();
    final existingData = await getAllLearningData();

    // بررسی تکراری نبودن
    final existingIndex = existingData.indexWhere(
        (item) => item.type == data.type && item.title == data.title);

    if (existingIndex != -1) {
      // به‌روزرسانی داده موجود
      existingData[existingIndex] = data.copyWith(
        updatedAt: DateTime.now(),
      );
    } else {
      // اضافه کردن داده جدید
      existingData.add(data);
    }

    final jsonData = existingData.map((item) => item.toJson()).toList();
    await prefs.setString(_learningDataKey, jsonEncode(jsonData));
  }

  // دریافت تمام اطلاعات یادگیری
  Future<List<AILearningData>> getAllLearningData() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_learningDataKey);

    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }

    try {
      final jsonList = jsonDecode(jsonString) as List;
      return jsonList
          .map((json) => AILearningData.fromJson(json as Map<String, dynamic>))
          .where((data) => data.isActive)
          .toList();
    } catch (e) {
      print('خطا در بارگیری اطلاعات یادگیری: $e');
      return [];
    }
  }

  // دریافت اطلاعات یادگیری بر اساس نوع
  Future<List<AILearningData>> getLearningDataByType(String type) async {
    final allData = await getAllLearningData();
    return allData.where((data) => data.type == type).toList();
  }

  // جستجو در اطلاعات یادگیری
  Future<List<AILearningData>> searchLearningData(String query) async {
    final allData = await getAllLearningData();
    final lowerQuery = query.toLowerCase();

    return allData
        .where((data) =>
            data.title.toLowerCase().contains(lowerQuery) ||
            data.description.toLowerCase().contains(lowerQuery) ||
            data.details.values.any(
                (value) => value.toString().toLowerCase().contains(lowerQuery)))
        .toList();
  }

  // حذف اطلاعات یادگیری
  Future<void> deleteLearningData(String id) async {
    final allData = await getAllLearningData();
    final updatedData = allData.where((data) => data.id != id).toList();

    final prefs = await SharedPreferences.getInstance();
    final jsonData = updatedData.map((item) => item.toJson()).toList();
    await prefs.setString(_learningDataKey, jsonEncode(jsonData));
  }

  // غیرفعال کردن اطلاعات یادگیری
  Future<void> deactivateLearningData(String id) async {
    final allData = await getAllLearningData();
    final updatedData = allData.map((data) {
      if (data.id == id) {
        return data.copyWith(isActive: false, updatedAt: DateTime.now());
      }
      return data;
    }).toList();

    final prefs = await SharedPreferences.getInstance();
    final jsonData = updatedData.map((item) => item.toJson()).toList();
    await prefs.setString(_learningDataKey, jsonEncode(jsonData));
  }

  // ذخیره حافظه جلسه
  Future<void> saveSessionMemory(
      String sessionId, Map<String, dynamic> memory) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '${_sessionMemoryKey}_$sessionId';
    await prefs.setString(key, jsonEncode(memory));
  }

  // دریافت حافظه جلسه
  Future<Map<String, dynamic>> getSessionMemory(String sessionId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '${_sessionMemoryKey}_$sessionId';
    final jsonString = prefs.getString(key);

    if (jsonString == null || jsonString.isEmpty) {
      return {};
    }

    try {
      return Map<String, dynamic>.from(jsonDecode(jsonString));
    } catch (e) {
      print('خطا در بارگیری حافظه جلسه: $e');
      return {};
    }
  }

  // پاک کردن حافظه جلسه
  Future<void> clearSessionMemory(String sessionId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '${_sessionMemoryKey}_$sessionId';
    await prefs.remove(key);
  }

  // تولید متن برای AI بر اساس اطلاعات یادگیری
  String generateLearningContext(List<AILearningData> learningData) {
    if (learningData.isEmpty) {
      return '';
    }

    final buffer = StringBuffer();
    buffer.writeln('\n**LEARNED INFORMATION:**');

    // گروه‌بندی بر اساس نوع
    final equipmentData =
        learningData.where((d) => d.type == 'equipment').toList();
    final processData = learningData.where((d) => d.type == 'process').toList();
    final ruleData = learningData.where((d) => d.type == 'rule').toList();
    final knowledgeData =
        learningData.where((d) => d.type == 'knowledge').toList();

    if (equipmentData.isNotEmpty) {
      buffer.writeln('\n**EQUIPMENT INFORMATION:**');
      for (final data in equipmentData) {
        buffer.writeln('- ${data.title}: ${data.description}');
        if (data.details.isNotEmpty) {
          data.details.forEach((key, value) {
            buffer.writeln('  * $key: $value');
          });
        }
      }
    }

    if (processData.isNotEmpty) {
      buffer.writeln('\n**PROCESS INFORMATION:**');
      for (final data in processData) {
        buffer.writeln('- ${data.title}: ${data.description}');
        if (data.details.isNotEmpty) {
          data.details.forEach((key, value) {
            buffer.writeln('  * $key: $value');
          });
        }
      }
    }

    if (ruleData.isNotEmpty) {
      buffer.writeln('\n**RULES AND GUIDELINES:**');
      for (final data in ruleData) {
        buffer.writeln('- ${data.title}: ${data.description}');
      }
    }

    if (knowledgeData.isNotEmpty) {
      buffer.writeln('\n**GENERAL KNOWLEDGE:**');
      for (final data in knowledgeData) {
        buffer.writeln('- ${data.title}: ${data.description}');
      }
    }

    return buffer.toString();
  }

  // تشخیص نوع یادگیری از متن کاربر
  String detectLearningType(String userMessage) {
    final lowerMessage = userMessage.toLowerCase();

    if (lowerMessage.contains('تجهیز') ||
        lowerMessage.contains('ماشین') ||
        lowerMessage.contains('دستگاه') ||
        lowerMessage.contains('کوره') ||
        lowerMessage.contains('سنگ شکن') ||
        lowerMessage.contains('نوار نقاله')) {
      return 'equipment';
    }

    if (lowerMessage.contains('فرآیند') ||
        lowerMessage.contains('مرحله') ||
        lowerMessage.contains('روش') ||
        lowerMessage.contains('پروسه')) {
      return 'process';
    }

    if (lowerMessage.contains('قانون') ||
        lowerMessage.contains('مقررات') ||
        lowerMessage.contains('دستورالعمل')) {
      return 'rule';
    }

    return 'knowledge';
  }

  // استخراج اطلاعات از متن کاربر
  Map<String, dynamic> extractDetailsFromMessage(
      String userMessage, String type) {
    final details = <String, dynamic>{};

    switch (type) {
      case 'equipment':
        // استخراج مشخصات تجهیز
        if (userMessage.contains('ظرفیت')) {
          final capacityMatch =
              RegExp(r'ظرفیت\s*(\d+(?:\.\d+)?)\s*(تن|کیلوگرم|گرم)')
                  .firstMatch(userMessage);
          if (capacityMatch != null) {
            details['capacity'] =
                '${capacityMatch.group(1)} ${capacityMatch.group(2)}';
          }
        }

        if (userMessage.contains('مصرف برق') || userMessage.contains('توان')) {
          final powerMatch =
              RegExp(r'(مصرف برق|توان)\s*(\d+(?:\.\d+)?)\s*(کیلووات|وات)')
                  .firstMatch(userMessage);
          if (powerMatch != null) {
            details['power_consumption'] =
                '${powerMatch.group(2)} ${powerMatch.group(3)}';
          }
        }

        if (userMessage.contains('دما')) {
          final tempMatch =
              RegExp(r'دما\s*(\d+(?:\.\d+)?)\s*درجه').firstMatch(userMessage);
          if (tempMatch != null) {
            details['temperature'] = '${tempMatch.group(1)} درجه';
          }
        }
        break;

      case 'process':
        // استخراج مراحل فرآیند
        final steps = <String>[];
        final stepMatches =
            RegExp(r'(\d+)[\.\)]\s*(.+?)(?=\d+[\.\)]|$)', dotAll: true)
                .allMatches(userMessage);
        for (final match in stepMatches) {
          steps.add(match.group(2)!.trim());
        }
        if (steps.isNotEmpty) {
          details['steps'] = steps;
        }
        break;
    }

    return details;
  }
}
