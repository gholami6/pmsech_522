import 'package:hive_flutter/hive_flutter.dart';
import '../models/equipment_location.dart';

class EquipmentLocationService {
  static const String _boxName = 'equipment_locations';
  static Box<EquipmentLocation>? _box;

  static Future<Box<EquipmentLocation>> get _equipmentLocationBox async {
    if (_box == null || !_box!.isOpen) {
      _box = await Hive.openBox<EquipmentLocation>(_boxName);
    }
    return _box!;
  }

  /// مقداردهی اولیه
  static Future<void> initialize() async {
    await _equipmentLocationBox;
    await _initializeDefaultLocations();
  }

  /// ایجاد محل‌های پیش‌فرض
  static Future<void> _initializeDefaultLocations() async {
    final box = await _equipmentLocationBox;
    if (box.isEmpty) {
      final defaultLocations = [
        EquipmentLocation(
          id: '1',
          name: 'G3-NEW',
          description: 'محل باردهی جدید G3',
          createdAt: DateTime.now(),
          createdBy: 'system',
        ),
        EquipmentLocation(
          id: '2',
          name: 'G3-OLD',
          description: 'محل باردهی قدیمی G3',
          createdAt: DateTime.now(),
          createdBy: 'system',
        ),
        EquipmentLocation(
          id: '3',
          name: 'SS',
          description: 'محل باردهی SS',
          createdAt: DateTime.now(),
          createdBy: 'system',
        ),
        EquipmentLocation(
          id: '4',
          name: 'G5',
          description: 'محل باردهی G5',
          createdAt: DateTime.now(),
          createdBy: 'system',
        ),
      ];

      for (final location in defaultLocations) {
        await box.put(location.id, location);
      }
    }
  }

  /// دریافت تمام محل‌های باردهی
  static Future<List<EquipmentLocation>> getAllLocations() async {
    final box = await _equipmentLocationBox;
    return box.values.toList();
  }

  /// دریافت محل‌های فعال
  static Future<List<EquipmentLocation>> getActiveLocations() async {
    final box = await _equipmentLocationBox;
    return box.values.where((location) => location.isActive).toList();
  }

  /// دریافت نام‌های محل‌های فعال
  static Future<List<String>> getActiveLocationNames() async {
    final locations = await getActiveLocations();
    return locations.map((location) => location.name).toList();
  }

  /// افزودن محل جدید
  static Future<String> addLocation({
    required String name,
    required String description,
    required String userId,
  }) async {
    final box = await _equipmentLocationBox;
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    
    final location = EquipmentLocation(
      id: id,
      name: name,
      description: description,
      createdAt: DateTime.now(),
      createdBy: userId,
    );

    await box.put(id, location);
    return id;
  }

  /// آپدیت محل موجود
  static Future<void> updateLocation({
    required String id,
    required String name,
    required String description,
    required bool isActive,
  }) async {
    final box = await _equipmentLocationBox;
    final existingLocation = box.get(id);
    
    if (existingLocation != null) {
      final updatedLocation = existingLocation.copyWith(
        name: name,
        description: description,
        isActive: isActive,
      );
      await box.put(id, updatedLocation);
    }
  }

  /// حذف محل
  static Future<void> deleteLocation(String id) async {
    final box = await _equipmentLocationBox;
    await box.delete(id);
  }

  /// دریافت محل بر اساس ID
  static Future<EquipmentLocation?> getLocationById(String id) async {
    final box = await _equipmentLocationBox;
    return box.get(id);
  }

  /// بررسی وجود نام تکراری
  static Future<bool> isNameExists(String name, {String? excludeId}) async {
    final box = await _equipmentLocationBox;
    return box.values.any((location) => 
      location.name.toLowerCase() == name.toLowerCase() && 
      location.id != excludeId
    );
  }
}
