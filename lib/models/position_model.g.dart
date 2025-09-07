// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'position_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PositionModelAdapter extends TypeAdapter<PositionModel> {
  @override
  final int typeId = 12;

  @override
  PositionModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PositionModel(
      stakeholderType: fields[0] as StakeholderType,
      roleType: fields[1] as RoleType,
    );
  }

  @override
  void write(BinaryWriter writer, PositionModel obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.stakeholderType)
      ..writeByte(1)
      ..write(obj.roleType);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PositionModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class RoleTypeAdapter extends TypeAdapter<RoleType> {
  @override
  final int typeId = 10;

  @override
  RoleType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return RoleType.manager;
      case 1:
        return RoleType.supervisor;
      case 2:
        return RoleType.industrialExpert;
      case 3:
        return RoleType.mechanicalExpert;
      case 4:
        return RoleType.electricalExpert;
      case 5:
        return RoleType.designExpert;
      case 6:
        return RoleType.processExpert;
      case 7:
        return RoleType.director;
      default:
        return RoleType.manager;
    }
  }

  @override
  void write(BinaryWriter writer, RoleType obj) {
    switch (obj) {
      case RoleType.manager:
        writer.writeByte(0);
        break;
      case RoleType.supervisor:
        writer.writeByte(1);
        break;
      case RoleType.industrialExpert:
        writer.writeByte(2);
        break;
      case RoleType.mechanicalExpert:
        writer.writeByte(3);
        break;
      case RoleType.electricalExpert:
        writer.writeByte(4);
        break;
      case RoleType.designExpert:
        writer.writeByte(5);
        break;
      case RoleType.processExpert:
        writer.writeByte(6);
        break;
      case RoleType.director:
        writer.writeByte(7);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RoleTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class StakeholderTypeAdapter extends TypeAdapter<StakeholderType> {
  @override
  final int typeId = 11;

  @override
  StakeholderType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return StakeholderType.employer;
      case 1:
        return StakeholderType.consultant;
      case 2:
        return StakeholderType.contractor;
      default:
        return StakeholderType.employer;
    }
  }

  @override
  void write(BinaryWriter writer, StakeholderType obj) {
    switch (obj) {
      case StakeholderType.employer:
        writer.writeByte(0);
        break;
      case StakeholderType.consultant:
        writer.writeByte(1);
        break;
      case StakeholderType.contractor:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StakeholderTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
