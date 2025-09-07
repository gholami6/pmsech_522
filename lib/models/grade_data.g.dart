// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'grade_data.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class GradeDataAdapter extends TypeAdapter<GradeData> {
  @override
  final int typeId = 15;

  @override
  GradeData read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return GradeData(
      id: fields[0] as String,
      year: fields[1] as int,
      month: fields[2] as int,
      day: fields[3] as int,
      shift: fields[4] as int,
      gradeType: fields[5] as String,
      gradeValue: fields[6] as double,
      recordedBy: fields[7] as String,
      recordedAt: fields[8] as DateTime,
      equipmentId: fields[9] as String?,
      workGroup: fields[10] as int,
    );
  }

  @override
  void write(BinaryWriter writer, GradeData obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.year)
      ..writeByte(2)
      ..write(obj.month)
      ..writeByte(3)
      ..write(obj.day)
      ..writeByte(4)
      ..write(obj.shift)
      ..writeByte(5)
      ..write(obj.gradeType)
      ..writeByte(6)
      ..write(obj.gradeValue)
      ..writeByte(7)
      ..write(obj.recordedBy)
      ..writeByte(8)
      ..write(obj.recordedAt)
      ..writeByte(9)
      ..write(obj.equipmentId)
      ..writeByte(10)
      ..write(obj.workGroup);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GradeDataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GradeData _$GradeDataFromJson(Map<String, dynamic> json) => GradeData(
      id: json['id'] as String,
      year: (json['year'] as num).toInt(),
      month: (json['month'] as num).toInt(),
      day: (json['day'] as num).toInt(),
      shift: (json['shift'] as num).toInt(),
      gradeType: json['grade_type'] as String,
      gradeValue: (json['grade_value'] as num).toDouble(),
      recordedBy: json['recorded_by'] as String,
      recordedAt: DateTime.parse(json['recorded_at'] as String),
      equipmentId: json['equipment_id'] as String?,
      workGroup: (json['work_group'] as num?)?.toInt() ?? 1,
    );

Map<String, dynamic> _$GradeDataToJson(GradeData instance) => <String, dynamic>{
      'id': instance.id,
      'year': instance.year,
      'month': instance.month,
      'day': instance.day,
      'shift': instance.shift,
      'grade_type': instance.gradeType,
      'grade_value': instance.gradeValue,
      'recorded_by': instance.recordedBy,
      'recorded_at': instance.recordedAt.toIso8601String(),
      'equipment_id': instance.equipmentId,
      'work_group': instance.workGroup,
    };
