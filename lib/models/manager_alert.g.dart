// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'manager_alert.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ManagerAlertAdapter extends TypeAdapter<ManagerAlert> {
  @override
  final int typeId = 17;

  @override
  ManagerAlert read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ManagerAlert(
      id: fields[0] as String?,
      userId: fields[1] as String,
      title: fields[2] as String,
      message: fields[3] as String,
      category: fields[4] as String,
      attachmentPath: fields[5] as String?,
      createdAt: fields[6] as DateTime?,
      targetStakeholderTypes: (fields[7] as List?)?.cast<String>(),
      targetRoleTypes: (fields[8] as List?)?.cast<String>(),
      seenBy: (fields[9] as Map?)?.cast<String, UserSeenStatus>(),
      replies: (fields[10] as List?)?.cast<AlertReply>(),
      allowReplies: fields[11] as bool?,
    );
  }

  @override
  void write(BinaryWriter writer, ManagerAlert obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.title)
      ..writeByte(3)
      ..write(obj.message)
      ..writeByte(4)
      ..write(obj.category)
      ..writeByte(5)
      ..write(obj.attachmentPath)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.targetStakeholderTypes)
      ..writeByte(8)
      ..write(obj.targetRoleTypes)
      ..writeByte(9)
      ..write(obj.seenBy)
      ..writeByte(10)
      ..write(obj.replies)
      ..writeByte(11)
      ..write(obj.allowReplies);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ManagerAlertAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
