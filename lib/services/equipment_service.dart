import 'package:hive/hive.dart';
import '../models/stop_data.dart';
import '../models/production_data.dart';

class EquipmentService {
  static final EquipmentService _instance = EquipmentService._internal();
  factory EquipmentService() => _instance;
  EquipmentService._internal();

  List<String> _equipmentList = [];
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    try {
      print('🔧 EquipmentService: شروع بارگذاری تجهیزات از دیتابیس...');

      Set<String> allEquipments = {};

      // تلاش برای بارگذاری از StopData
      try {
        final stopDataBox = await Hive.openBox<StopData>('stopData');
        print(
            '📊 EquipmentService: تعداد رکوردهای StopData: ${stopDataBox.length}');

        final stopDataEquipments = <String>{};
        for (final stopData in stopDataBox.values) {
          // اول از equipmentName استفاده کن، اگر نبود از equipment
          String equipmentName = stopData.equipmentName ?? stopData.equipment;
          if (equipmentName.isNotEmpty) {
            stopDataEquipments.add(equipmentName);
          }
        }

        print('📊 EquipmentService: تجهیزات از StopData: $stopDataEquipments');
        allEquipments.addAll(stopDataEquipments);
      } catch (e) {
        print('⚠️ EquipmentService: خطا در بارگذاری از StopData: $e');
      }

      // تلاش برای بارگذاری از ProductionData
      try {
        final productionBox =
            await Hive.openBox<ProductionData>('productionData');
        print(
            '📊 EquipmentService: تعداد رکوردهای ProductionData: ${productionBox.length}');

        final productionEquipments = <String>{};
        for (final productionData in productionBox.values) {
          if (productionData.equipmentName.isNotEmpty) {
            productionEquipments.add(productionData.equipmentName);
          }
        }

        print(
            '📊 EquipmentService: تجهیزات از ProductionData: $productionEquipments');
        allEquipments.addAll(productionEquipments);
      } catch (e) {
        print('⚠️ EquipmentService: خطا در بارگذاری از ProductionData: $e');
      }

      // اگر هیچ تجهیزی یافت نشد، از لیست پیش‌فرض استفاده کن
      if (allEquipments.isEmpty) {
        print(
            '⚠️ EquipmentService: هیچ تجهیزی در دیتابیس یافت نشد، استفاده از لیست پیش‌فرض');
        allEquipments = {
          'خط یک',
          'خط دو',
          'سنگ شکن',
          'تلشکی',
          'سرند',
          'بی سنگی',
          'تعویض شیفت',
          'کنترل',
        };
      }

      _equipmentList = allEquipments.toList()..sort();

      // اضافه کردن گزینه "سایر" در انتها
      if (!_equipmentList.contains('سایر')) {
        _equipmentList.add('سایر');
      }

      print(
          '✅ EquipmentService: بارگذاری تکمیل شد. تعداد تجهیزات: ${_equipmentList.length}');
      print('📋 EquipmentService: لیست نهایی: $_equipmentList');

      _isInitialized = true;
    } catch (e) {
      print('❌ EquipmentService: خطا در بارگذاری: $e');
      // در صورت خطا، لیست پیش‌فرض استفاده کن
      _equipmentList = [
        'خط یک',
        'خط دو',
        'سنگ شکن',
        'تلشکی',
        'سرند',
        'بی سنگی',
        'تعویض شیفت',
        'کنترل',
        'سایر'
      ];
      _isInitialized = true;
    }
  }

  List<String> getEquipmentList() {
    if (!_isInitialized) {
      throw Exception('EquipmentService not initialized. Call init() first.');
    }
    return List<String>.from(_equipmentList);
  }

  Future<void> refreshEquipmentList() async {
    print('🔄 EquipmentService: شروع بارگذاری مجدد...');
    _isInitialized = false;
    await init();
  }

  /// استخراج لیست تجهیزات منحصر به فرد از StopData (متد استاتیک)
  static List<String> getUniqueEquipments() {
    try {
      final box = Hive.box<StopData>('stopData');
      final equipments = <String>{};

      // استخراج تمام تجهیزات منحصر به فرد
      for (final stopData in box.values) {
        String equipmentName = stopData.equipmentName ?? stopData.equipment;
        if (equipmentName.isNotEmpty) {
          equipments.add(equipmentName);
        }
      }

      // تبدیل به لیست و مرتب‌سازی
      final sortedEquipments = equipments.toList()..sort();

      // اضافه کردن گزینه "سایر" در انتها
      if (!sortedEquipments.contains('سایر')) {
        sortedEquipments.add('سایر');
      }

      return sortedEquipments;
    } catch (e) {
      print('EquipmentService: Error getting equipments: $e');
      // در صورت خطا، لیست پیش‌فرض برگردان
      return [
        'خط یک',
        'خط دو',
        'سنگ شکن',
        'تلشکی',
        'سرند',
        'بی سنگی',
        'تعویض شیفت',
        'کنترل',
        'سایر'
      ];
    }
  }

  /// بررسی وجود تجهیز در دیتابیس
  static bool hasEquipmentData() {
    try {
      final box = Hive.box<StopData>('stopData');
      return box.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}
