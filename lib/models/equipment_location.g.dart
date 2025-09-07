// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'equipment_location.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class EquipmentLocationAdapter extends TypeAdapter<EquipmentLocation> {
  @override
  final int typeId = 21;

  @override
  EquipmentLocation read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return EquipmentLocation(
      id: fields[0] as String,
      name: fields[1] as String,
      description: fields[2] as String,
      isActive: fields[3] as bool,
      createdAt: fields[4] as DateTime,
      createdBy: fields[5] as String,
    );
  }

  @override
  void write(BinaryWriter writer, EquipmentLocation obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.isActive)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.createdBy);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EquipmentLocationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
