import 'package:json_annotation/json_annotation.dart';
import 'package:hive/hive.dart';

part 'production_data.g.dart';

@HiveType(typeId: 1)
@JsonSerializable()
class ProductionData extends HiveObject {
  @HiveField(0)
  @JsonKey(name: 'shamsi_date')
  final String shamsiDate; // ستون اول: تاریخ شمسی

  @HiveField(1)
  @JsonKey(name: 'year')
  final int year; // ستون دوم: سال

  @HiveField(2)
  @JsonKey(name: 'month')
  final int month; // ستون سوم: ماه

  @HiveField(3)
  @JsonKey(name: 'day')
  final int day; // ستون چهارم: روز

  @HiveField(4)
  @JsonKey(name: 'shift')
  final String shift; // ستون پنجم: شیفت

  @HiveField(5)
  @JsonKey(name: 'stop_description')
  final String stopDescription; // ستون ششم: شرح توقف

  @HiveField(6)
  @JsonKey(name: 'equipment_name')
  final String equipmentName; // ستون هفتم: نام تجهیزات

  @HiveField(7)
  @JsonKey(name: 'equipment_code_1')
  final String? equipmentCode1; // ستون هشتم: کد تجهیز 1 (غیرقابل استفاده)

  @HiveField(8)
  @JsonKey(name: 'equipment_code_2')
  final String? equipmentCode2; // ستون نهم: کد تجهیز 2 (غیرقابل استفاده)

  @HiveField(9)
  @JsonKey(name: 'sub_equipment')
  final String subEquipment; // ستون دهم: ریز تجهیزات

  @HiveField(10)
  @JsonKey(name: 'sub_equipment_code')
  final String? subEquipmentCode; // ستون یازدهم: کد ریز تجهیز (غیرقابل استفاده)

  @HiveField(11)
  @JsonKey(name: 'stop_reason')
  final String stopReason; // ستون دوازدهم: علت توقف

  @HiveField(12)
  @JsonKey(name: 'stop_type')
  final String stopType; // ستون سیزدهم: نوع توقف

  @HiveField(13)
  @JsonKey(name: 'stop_start_time')
  final String stopStartTime; // ستون چهاردهم: شروع توقف

  @HiveField(14)
  @JsonKey(name: 'stop_end_time')
  final String stopEndTime; // ستون پانزدهم: پایان توقف

  @HiveField(15)
  @JsonKey(name: 'stop_duration')
  final String stopDuration; // ستون شانزدهم: مدت توقف

  @HiveField(16)
  @JsonKey(name: 'service_count')
  final int serviceCount; // ستون هفدهم: تعداد سرویس

  @HiveField(17)
  @JsonKey(name: 'input_tonnage')
  final double inputTonnage; // ستون هجدهم: تناژ ورودی

  @HiveField(18)
  @JsonKey(name: 'scale_3')
  final double scale3; // ستون نوزدهم: اسکیل 3

  @HiveField(19)
  @JsonKey(name: 'scale_4')
  final double scale4; // ستون بیستم: اسکیل 4

  @HiveField(20)
  @JsonKey(name: 'scale_5')
  final double scale5; // ستون بیست و یکم: اسکیل 5

  @HiveField(21)
  @JsonKey(name: 'group')
  final int group; // ستون بیست و دوم: گروه (1-4)

  @HiveField(22)
  @JsonKey(name: 'direct_feed')
  final int directFeed; // ستون بیست و سوم: فید مستقیم (0 یا 1)

  // فیلد محاسبه شده برای خروجی اسکیل تسمه
  double get beltScaleOutput => producedProduct;

  ProductionData({
    required this.shamsiDate,
    required this.year,
    required this.month,
    required this.day,
    required this.shift,
    required this.stopDescription,
    required this.equipmentName,
    this.equipmentCode1,
    this.equipmentCode2,
    required this.subEquipment,
    this.subEquipmentCode,
    required this.stopReason,
    required this.stopType,
    required this.stopStartTime,
    required this.stopEndTime,
    required this.stopDuration,
    required this.serviceCount,
    required this.inputTonnage,
    required this.scale3,
    required this.scale4,
    required this.scale5,
    required this.group,
    required this.directFeed,
  });

  factory ProductionData.fromJson(Map<String, dynamic> json) =>
      _$ProductionDataFromJson(json);

  Map<String, dynamic> toJson() => _$ProductionDataToJson(this);

  // محاسبه محصول تولید شده بر اساس فید مستقیم
  double get producedProduct {
    if (directFeed == 1) {
      // فید مستقیم: محصول تولید شده برابر تناژ ورودی است
      return inputTonnage;
    } else {
      // پرعیارسازی: محصول تولید شده فقط برابر اسکیل 5 است
      return scale5;
    }
  }

  // محاسبه باطله تولید شده
  double get waste {
    if (directFeed == 1) {
      // فید مستقیم: باطله‌ای تولید نمی‌شود
      return 0;
    } else {
      // پرعیارسازی: باطله برابر تفاوت تناژ ورودی و محصول تولید شده است
      return inputTonnage - producedProduct;
    }
  }

  // بررسی نوع توقف اضطراری
  bool get isEmergencyStop {
    return stopType == 'مکانیکی' ||
        stopType == 'برقی' ||
        stopType == 'تاسیساتی';
  }

  // بررسی نوع توقف فنی
  bool get isTechnicalStop {
    return isEmergencyStop || stopType == 'برنامه ای';
  }

  // تبدیل زمان متنی به دقیقه
  int get stopDurationMinutes {
    try {
      // دیباگ: نمایش مقدار خام stopDuration
      if (stopDuration.isNotEmpty && stopDuration != "0") {
        print('دیباگ stopDuration: "$stopDuration"');
      }

      List<String> parts = stopDuration.split(':');
      if (parts.length >= 2) {
        int hours = int.tryParse(parts[0]) ?? 0;
        int minutes = int.tryParse(parts[1]) ?? 0;
        final result = hours * 60 + minutes;

        // دیباگ: نمایش نتیجه تبدیل
        if (result > 0) {
          print('تبدیل موفق: $stopDuration -> $result دقیقه');
        }

        return result;
      }
      return 0;
    } catch (e) {
      print('خطا در تبدیل stopDuration: $stopDuration - $e');
      return 0;
    }
  }

  // تاریخ کامل شمسی
  String get fullShamsiDate {
    return '$year/$month/$day';
  }

  // نام کامل تجهیز با ریز تجهیز
  String get fullEquipmentName {
    return '$equipmentName - $subEquipment';
  }
}
