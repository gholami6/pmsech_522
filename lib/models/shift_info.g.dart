// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shift_info.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ShiftInfoAdapter extends TypeAdapter<ShiftInfo> {
  @override
  final int typeId = 9;

  @override
  ShiftInfo read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ShiftInfo(
      year: fields[0] as int,
      month: fields[1] as int,
      shift: fields[2] as String,
      equipment: fields[3] as String,
      totalStopDuration: fields[4] as double,
      totalProduction: fields[5] as double,
    );
  }

  @override
  void write(BinaryWriter writer, ShiftInfo obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.year)
      ..writeByte(1)
      ..write(obj.month)
      ..writeByte(2)
      ..write(obj.shift)
      ..writeByte(3)
      ..write(obj.equipment)
      ..writeByte(4)
      ..write(obj.totalStopDuration)
      ..writeByte(5)
      ..write(obj.totalProduction);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShiftInfoAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
