// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stop_data.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class StopDataAdapter extends TypeAdapter<StopData> {
  @override
  final int typeId = 8;

  @override
  StopData read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return StopData(
      year: fields[0] as int,
      month: fields[1] as int,
      day: fields[2] as int,
      shift: fields[3] as String,
      equipment: fields[4] as String,
      stopType: fields[5] as String,
      stopDuration: fields[6] as double,
      equipmentName: fields[7] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, StopData obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.year)
      ..writeByte(1)
      ..write(obj.month)
      ..writeByte(2)
      ..write(obj.day)
      ..writeByte(3)
      ..write(obj.shift)
      ..writeByte(4)
      ..write(obj.equipment)
      ..writeByte(5)
      ..write(obj.stopType)
      ..writeByte(6)
      ..write(obj.stopDuration)
      ..writeByte(7)
      ..write(obj.equipmentName);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StopDataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
