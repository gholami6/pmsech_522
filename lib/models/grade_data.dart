import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'grade_data.g.dart';

@HiveType(typeId: 15)
@JsonSerializable()
class GradeData extends HiveObject {
  @HiveField(0)
  @JsonKey(name: 'id')
  final String id;

  @HiveField(1)
  @JsonKey(name: 'year')
  final int year;

  @HiveField(2)
  @JsonKey(name: 'month')
  final int month;

  @HiveField(3)
  @JsonKey(name: 'day')
  final int day;

  @HiveField(4)
  @JsonKey(name: 'shift')
  final int shift;

  @HiveField(5)
  @JsonKey(name: 'grade_type')
  final String gradeType; // 'خوراک', 'محصول', 'باطله'

  @HiveField(6)
  @JsonKey(name: 'grade_value')
  final double gradeValue; // درصد عیار با دو رقم اعشار

  @HiveField(7)
  @JsonKey(name: 'recorded_by')
  final String recordedBy; // شناسه کاربر ثبت‌کننده

  @HiveField(8)
  @JsonKey(name: 'recorded_at')
  final DateTime recordedAt;

  @HiveField(9)
  @JsonKey(name: 'equipment_id')
  final String? equipmentId; // اختیاری - برای ارتباط با تجهیز

  @HiveField(10)
  @JsonKey(name: 'work_group', defaultValue: 1)
  final int workGroup; // گروه کاری (1 تا 4)

  GradeData({
    required this.id,
    required this.year,
    required this.month,
    required this.day,
    required this.shift,
    required this.gradeType,
    required this.gradeValue,
    required this.recordedBy,
    required this.recordedAt,
    this.equipmentId,
    required this.workGroup,
  });

  factory GradeData.fromJson(Map<String, dynamic> json) =>
      _$GradeDataFromJson(json);

  Map<String, dynamic> toJson() => _$GradeDataToJson(this);

  // تاریخ کامل شمسی
  String get fullShamsiDate => '$year/$month/$day';

  // نام نوع عیار
  String get gradeTypeName {
    switch (gradeType) {
      case 'خوراک':
        return 'عیار خوراک';
      case 'محصول':
        return 'عیار محصول';
      case 'باطله':
        return 'عیار باطله';
      default:
        return 'نامشخص';
    }
  }

  // فرمت عیار با دو رقم اعشار
  String get formattedGradeValue => '${gradeValue.toStringAsFixed(2)}%';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GradeData &&
        other.id == id &&
        other.year == year &&
        other.month == month &&
        other.day == day &&
        other.shift == shift &&
        other.gradeType == gradeType;
  }

  @override
  int get hashCode => Object.hash(id, year, month, day, shift, gradeType);
}
