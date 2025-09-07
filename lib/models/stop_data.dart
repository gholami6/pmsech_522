import 'package:hive/hive.dart';

part 'stop_data.g.dart';

@HiveType(typeId: 8)
class StopData {
  @HiveField(0)
  final int year;

  @HiveField(1)
  final int month;

  @HiveField(2)
  final int day;

  @HiveField(3)
  final String shift;

  @HiveField(4)
  final String equipment;

  @HiveField(5)
  final String stopType;

  @HiveField(6)
  final double stopDuration;

  @HiveField(7)
  final String? equipmentName;

  StopData({
    required this.year,
    required this.month,
    required this.day,
    required this.shift,
    required this.equipment,
    required this.stopType,
    required this.stopDuration,
    this.equipmentName,
  });

  factory StopData.fromJson(Map<String, dynamic> json) {
    return StopData(
      year: json['year'] as int,
      month: json['month'] as int,
      day: json['day'] as int,
      shift: json['shift']?.toString() ?? '',
      equipment: json['equipment'] as String,
      stopType: json['stop_type'] as String,
      stopDuration: (json['stop_duration'] as num).toDouble(),
      equipmentName: json['equipment_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'year': year,
      'month': month,
      'day': day,
      'shift': shift,
      'equipment': equipment,
      'stop_type': stopType,
      'stop_duration': stopDuration,
      'equipment_name': equipmentName,
    };
  }
}
