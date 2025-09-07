import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:hive_flutter/hive_flutter.dart';
import '../models/chat_message.dart';
import '../models/production_data.dart';
import '../models/stop_data.dart';
import '../models/grade_data.dart';

// ==================== 1. AI Configuration ====================
class AIConfig {
  static const String geminiModel = 'gemini-pro';
  static const int maxTokens = 1000;
  static const double temperature = 0.7;
  static const int requestTimeoutSeconds = 30;
  static const int rateLimitSeconds = 2;
  static const int maxRetries = 3;

  // پیام‌های سیستم کوتاه و مؤثر
  static const String systemPrompt = '''
شما دستیار هوش مصنوعی کارخانه هستید. فقط به زبان فارسی پاسخ دهید.

وظایف:
- تحلیل دقیق داده‌های تولید و توقفات
- ارائه آمار واقعی (نه تخمینی)
- محاسبه دسترسی و بازده
- پیشنهادات بهبود

فرمول‌های مهم:
- دسترسی = (زمان کل - توقفات) / زمان کل × 100
- بازده = تولید واقعی / تولید برنامه × 100

همیشه از اعداد واقعی استفاده کنید.
''';
}

// ==================== 2. Enhanced AI Service ====================
class AIAssistantService {
  static AIAssistantService? _instance;
  static AIAssistantService get instance =>
      _instance ??= AIAssistantService._();
  AIAssistantService._();

  final _requestQueue = <AIRequest>[];
  bool _isProcessing = false;
  DateTime? _lastRequestTime;

  // کلید امن
  String get _apiKey => 'AIzaSyAuVvXKtZ1apf4OTDU3yJjWZnJHmFr0YfA';
  String get _baseUrl =>
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent';

  late Box<StopData> _stopDataBox;
  late Box<ProductionData> _productionDataBox;
  late Box<GradeData> _gradeDataBox;

  Future<void> initialize() async {
    _stopDataBox = await Hive.openBox<StopData>('stopData');
    _productionDataBox = await Hive.openBox<ProductionData>('productionData');
    _gradeDataBox = await Hive.openBox<GradeData>('gradeData');
  }

  // درخواست اصلی
  Future<String> getAIResponse(String userMessage) async {
    print('🤖 AI Request: $userMessage');

    // بررسی محدودیت زمانی
    if (!_canMakeRequest()) {
      return 'لطفاً کمی صبر کنید...';
    }

    try {
      _lastRequestTime = DateTime.now();

      // دریافت داده‌ها
      final stopData = _stopDataBox.values.toList();
      final productionData = _productionDataBox.values.toList();
      final gradeData = _gradeDataBox.values.toList();

      print(
          '📊 تعداد داده‌ها: توقفات=${stopData.length}, تولید=${productionData.length}, عیار=${gradeData.length}');

      // ساخت کانتکست
      final context = _buildDataContext(productionData, stopData, gradeData);
      final fullPrompt =
          '${AIConfig.systemPrompt}\n\nداده‌ها:\n$context\n\nسوال: $userMessage';

      print('📝 طول prompt: ${fullPrompt.length} کاراکتر');

      // درخواست HTTP با retry
      final result = await _makeRequestWithRetry(fullPrompt);
      return result;
    } catch (e) {
      print('❌ AI Error: $e');
      final stopData = _stopDataBox.values.toList();
      final productionData = _productionDataBox.values.toList();
      return _generateFallbackResponse(userMessage, productionData, stopData);
    }
  }

  // بررسی محدودیت درخواست
  bool _canMakeRequest() {
    if (_lastRequestTime == null) return true;

    final timeDiff = DateTime.now().difference(_lastRequestTime!);
    return timeDiff.inSeconds >= AIConfig.rateLimitSeconds;
  }

  // درخواست با تلاش مجدد
  Future<String> _makeRequestWithRetry(String prompt) async {
    for (int attempt = 1; attempt <= AIConfig.maxRetries; attempt++) {
      try {
        print('🔄 تلاش $attempt از ${AIConfig.maxRetries}');

        final response = await http
            .post(
              Uri.parse('$_baseUrl?key=$_apiKey'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'contents': [
                  {
                    'parts': [
                      {'text': prompt}
                    ]
                  }
                ],
                'generationConfig': {
                  'temperature': AIConfig.temperature,
                  'maxOutputTokens': AIConfig.maxTokens,
                }
              }),
            )
            .timeout(Duration(seconds: AIConfig.requestTimeoutSeconds));

        print('📡 Response Status: ${response.statusCode}');

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final aiText = data['candidates'][0]['content']['parts'][0]['text'];
          print('✅ AI Response received');
          return aiText;
        } else {
          print('⚠️ API Error ${response.statusCode}: ${response.body}');
          if (attempt < AIConfig.maxRetries) {
            await Future.delayed(Duration(seconds: attempt));
            continue;
          }
        }
      } catch (e) {
        print('⚠️ Request attempt $attempt failed: $e');
        if (attempt < AIConfig.maxRetries) {
          await Future.delayed(Duration(seconds: attempt));
          continue;
        }
      }
    }
    throw Exception('تمام تلاش‌ها ناموفق بود');
  }

  // ساخت کانتکست داده (خلاصه)
  String _buildDataContext(List<ProductionData> production,
      List<StopData> stops, List<GradeData> grades) {
    final buffer = StringBuffer();

    // آمار کلی
    buffer.writeln('📊 آمار کلی:');
    buffer.writeln('- تولید: ${production.length} رکورد');
    buffer.writeln('- توقفات: ${stops.length} رکورد');
    buffer.writeln('- عیارها: ${grades.length} رکورد');

    // آمار تولید
    if (production.isNotEmpty) {
      final totalProduction =
          production.fold<double>(0, (sum, p) => sum + p.producedProduct);
      buffer.writeln('\n🏭 تولید: ${totalProduction.toStringAsFixed(1)} تن');

      // تولید بر اساس تجهیز
      final equipmentProduction = <String, double>{};
      for (final prod in production) {
        equipmentProduction[prod.equipmentName] =
            (equipmentProduction[prod.equipmentName] ?? 0) +
                prod.producedProduct;
      }

      equipmentProduction.entries.take(3).forEach((entry) {
        buffer.writeln('- ${entry.key}: ${entry.value.toStringAsFixed(1)} تن');
      });
    }

    // آمار توقفات
    if (stops.isNotEmpty) {
      final totalStopTime =
          stops.fold<double>(0, (sum, s) => sum + s.stopDuration);
      buffer.writeln('\n⏹️ توقفات: ${_formatDuration(totalStopTime)}');

      // توقفات بر اساس نوع
      final stopTypes = <String, int>{};
      for (final stop in stops) {
        stopTypes[stop.stopType] = (stopTypes[stop.stopType] ?? 0) + 1;
      }

      stopTypes.entries.take(3).forEach((entry) {
        buffer.writeln('- ${entry.key}: ${entry.value} مورد');
      });
    }

    return buffer.toString();
  }

  // پاسخ پیش‌فرض
  String _generateFallbackResponse(
      String message, List<ProductionData> production, List<StopData> stops) {
    final analyzer = DataAnalyzer();

    if (message.contains('تولید')) {
      return analyzer.analyzeProduction(production);
    }

    if (message.contains('توقف')) {
      return analyzer.analyzeStops(stops);
    }

    if (message.contains('دسترسی')) {
      return analyzer.calculateAvailability(stops, production);
    }

    return '''
🤖 متأسفانه در حال حاضر به سرویس هوش مصنوعی دسترسی ندارم.
ولی می‌توانم آمار پایه‌ای ارائه دهم:

📊 داده‌های موجود:
• تولید: ${production.length} رکورد
• توقفات: ${stops.length} رکورد

سوالات پیشنهادی:
• "آمار تولید"
• "تحلیل توقفات"  
• "محاسبه دسترسی"
    ''';
  }

  String _formatDuration(double minutes) {
    final hours = (minutes / 60).floor();
    final mins = (minutes % 60).round();
    return '${hours}:${mins.toString().padLeft(2, '0')}';
  }

  void dispose() {
    _stopDataBox.close();
    _productionDataBox.close();
    _gradeDataBox.close();
  }
}

// ==================== 3. Response Model ====================
class AIRequest {
  final String message;
  final Completer<String> completer;
  final DateTime timestamp;

  AIRequest(this.message)
      : completer = Completer<String>(),
        timestamp = DateTime.now();
}

// ==================== 4. Data Analyzer ====================
class DataAnalyzer {
  String analyzeProduction(List<ProductionData> data) {
    if (data.isEmpty) return '❌ داده‌های تولید موجود نیست';

    final total = data.fold<double>(0, (sum, p) => sum + p.producedProduct);
    final avg = total / data.length;

    // بهترین تجهیز
    final equipmentMap = <String, double>{};
    for (final prod in data) {
      equipmentMap[prod.equipmentName] =
          (equipmentMap[prod.equipmentName] ?? 0) + prod.producedProduct;
    }

    final topEquipment =
        equipmentMap.entries.reduce((a, b) => a.value > b.value ? a : b);

    return '''
🏭 **تحلیل تولید:**

📊 **آمار کلی:**
• مجموع تولید: ${total.toStringAsFixed(1)} تن
• میانگین: ${avg.toStringAsFixed(1)} تن
• تعداد رکوردها: ${data.length}

🏆 **بهترین تجهیز:**
• ${topEquipment.key}: ${topEquipment.value.toStringAsFixed(1)} تن
• سهم: ${((topEquipment.value / total) * 100).toStringAsFixed(1)}%

📈 **پیشنهادات:**
• بررسی عملکرد ${topEquipment.key}
• بهینه‌سازی سایر تجهیزات
    ''';
  }

  String analyzeStops(List<StopData> data) {
    if (data.isEmpty) return '❌ داده‌های توقف موجود نیست';

    final totalDuration =
        data.fold<double>(0, (sum, s) => sum + s.stopDuration);
    final avgDuration = totalDuration / data.length;

    // بدترین تجهیز
    final equipmentMap = <String, double>{};
    for (final stop in data) {
      final equipName = stop.equipmentName ?? stop.equipment ?? 'نامشخص';
      equipmentMap[equipName] =
          (equipmentMap[equipName] ?? 0) + stop.stopDuration;
    }

    final worstEquipment =
        equipmentMap.entries.reduce((a, b) => a.value > b.value ? a : b);

    // انواع توقف
    final stopTypes = <String, int>{};
    for (final stop in data) {
      stopTypes[stop.stopType] = (stopTypes[stop.stopType] ?? 0) + 1;
    }

    return '''
⏹️ **تحلیل توقفات:**

📊 **آمار کلی:**
• تعداد کل: ${data.length} مورد
• مدت کل: ${_formatDuration(totalDuration)}
• میانگین: ${_formatDuration(avgDuration)}

🚨 **بدترین تجهیز:**
• ${worstEquipment.key}: ${_formatDuration(worstEquipment.value)}

📋 **انواع توقف:**
${stopTypes.entries.take(3).map((e) => '• ${e.key}: ${e.value} مورد').join('\n')}

💡 **پیشنهادات:**
• تعمیرات پیشگیرانه ${worstEquipment.key}
• بررسی علل توقفات ${stopTypes.keys.first}
    ''';
  }

  String calculateAvailability(
      List<StopData> stops, List<ProductionData> production) {
    if (stops.isEmpty) return '❌ داده‌های توقف برای محاسبه دسترسی موجود نیست';

    // تعداد شیفت‌های منحصربه‌فرد
    final uniqueShifts =
        stops.map((s) => '${s.year}-${s.month}-${s.day}-${s.shift}').toSet();
    final totalAvailableTime =
        uniqueShifts.length * 480.0; // 8 ساعت = 480 دقیقه

    final totalStopTime =
        stops.fold<double>(0, (sum, s) => sum + s.stopDuration);
    final totalAvailability =
        ((totalAvailableTime - totalStopTime) / totalAvailableTime) * 100;

    // توقفات فنی و غیرفنی
    final technicalStops = stops
        .where((s) =>
            ['برنامه‌ای', 'برقی', 'مکانیکی', 'تاسیساتی'].contains(s.stopType))
        .toList();
    final nonTechnicalStops = stops
        .where((s) => ['معدنی', 'بهره‌برداری', 'عمومی', 'بارگیری', 'مجاز']
            .contains(s.stopType))
        .toList();

    final technicalTime =
        technicalStops.fold<double>(0, (sum, s) => sum + s.stopDuration);
    final nonTechnicalTime =
        nonTechnicalStops.fold<double>(0, (sum, s) => sum + s.stopDuration);

    final equipmentAvailability = ((totalAvailableTime - totalStopTime) /
            (totalAvailableTime - nonTechnicalTime)) *
        100;

    return '''
⚡ **تحلیل دسترسی:**

📊 **دسترسی کل:**
• زمان در دسترس: ${(totalAvailableTime / 60).toStringAsFixed(1)} ساعت
• زمان توقف: ${(totalStopTime / 60).toStringAsFixed(1)} ساعت
• دسترسی کل: ${totalAvailability.toStringAsFixed(1)}%

🔧 **دسترسی تجهیزات:**
• توقفات فنی: ${(technicalTime / 60).toStringAsFixed(1)} ساعت  
• توقفات غیرفنی: ${(nonTechnicalTime / 60).toStringAsFixed(1)} ساعت
• دسترسی تجهیزات: ${equipmentAvailability.toStringAsFixed(1)}%

🎯 **هدف‌گذاری:**
• هدف دسترسی کل: 85%
• وضعیت فعلی: ${totalAvailability > 85 ? '✅ مطلوب' : '⚠️ نیاز به بهبود'}
    ''';
  }

  String _formatDuration(double minutes) {
    final hours = (minutes / 60).floor();
    final mins = (minutes % 60).round();
    return '${hours}:${mins.toString().padLeft(2, '0')}';
  }
}
