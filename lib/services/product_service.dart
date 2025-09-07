import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import '../models/production_data.dart';

class ProductService {
  static const String _fileName = 'product_data.json';

  /// ذخیره داده‌های محصول
  static Future<void> saveProductData(List<ProductionData> data) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$_fileName');

      final jsonData = data.map((item) => item.toJson()).toList();
      await file.writeAsString(jsonEncode(jsonData));
    } catch (e) {
      print('خطا در ذخیره داده‌های محصول: $e');
      rethrow;
    }
  }

  /// بارگذاری داده‌های محصول
  static Future<List<ProductionData>> loadProductData() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$_fileName');

      if (!await file.exists()) {
        return [];
      }

      final jsonString = await file.readAsString();
      final jsonData = jsonDecode(jsonString) as List;

      return jsonData.map((item) => ProductionData.fromJson(item)).toList();
    } catch (e) {
      print('خطا در بارگذاری داده‌های محصول: $e');
      return [];
    }
  }

  /// حذف داده‌های محصول
  static Future<void> deleteProductData() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$_fileName');

      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      print('خطا در حذف داده‌های محصول: $e');
      rethrow;
    }
  }

  /// بررسی وجود داده‌های محصول
  static Future<bool> hasProductData() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$_fileName');
      return await file.exists();
    } catch (e) {
      return false;
    }
  }

  /// دریافت آمار خلاصه محصول
  static Map<String, double> getProductSummary(List<ProductionData> data) {
    if (data.isEmpty) return {};

    final totalProduct =
        data.fold<double>(0, (sum, item) => sum + item.producedProduct);
    final totalFeed =
        data.fold<double>(0, (sum, item) => sum + item.inputTonnage);
    final recoveryRate = totalFeed > 0 ? (totalProduct / totalFeed) * 100 : 0;

    return {
      'totalProduct': totalProduct.toDouble(),
      'totalFeed': totalFeed.toDouble(),
      'recoveryRate': recoveryRate.toDouble(),
    };
  }
}
