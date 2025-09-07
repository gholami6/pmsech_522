import 'package:hive/hive.dart';

part 'shift_info.g.dart';

@HiveType(typeId: 9)
class ShiftInfo extends HiveObject {
  @HiveField(0)
  final int year;

  @HiveField(1)
  final int month;

  @HiveField(2)
  final String shift;

  @HiveField(3)
  final String equipment;

  @HiveField(4)
  final double totalStopDuration;

  @HiveField(5)
  final double totalProduction;

  String get id => '$year-$month-$shift-$equipment';

  ShiftInfo({
    required this.year,
    required this.month,
    required this.shift,
    required this.equipment,
    required this.totalStopDuration,
    required this.totalProduction,
  });

  factory ShiftInfo.fromJson(Map<String, dynamic> json) {
    return ShiftInfo(
      year: json['year'] as int,
      month: json['month'] as int,
      shift: json['shift'] as String,
      equipment: json['equipment'] as String,
      totalStopDuration: (json['totalStopDuration'] as num).toDouble(),
      totalProduction: (json['totalProduction'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'year': year,
      'month': month,
      'shift': shift,
      'equipment': equipment,
      'totalStopDuration': totalStopDuration,
      'totalProduction': totalProduction,
    };
  }
}
