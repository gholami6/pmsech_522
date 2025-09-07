// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'alert_notification.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AlertNotificationAdapter extends TypeAdapter<AlertNotification> {
  @override
  final int typeId = 3;

  @override
  AlertNotification read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AlertNotification(
      id: fields[0] as String?,
      userId: fields[1] as String,
      equipmentId: fields[2] as String,
      message: fields[3] as String,
      attachmentPath: fields[4] as String?,
      createdAt: fields[5] as DateTime?,
      replies: (fields[6] as List?)?.cast<AlertReply>(),
      seenBy: (fields[7] as Map?)?.cast<String, UserSeenStatus>(),
      category: fields[8] as String?,
      allowReplies: fields[9] as bool?,
    );
  }

  @override
  void write(BinaryWriter writer, AlertNotification obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.equipmentId)
      ..writeByte(3)
      ..write(obj.message)
      ..writeByte(4)
      ..write(obj.attachmentPath)
      ..writeByte(5)
      ..write(obj.createdAt)
      ..writeByte(6)
      ..write(obj.replies)
      ..writeByte(7)
      ..write(obj.seenBy)
      ..writeByte(8)
      ..write(obj.category)
      ..writeByte(9)
      ..write(obj.allowReplies);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AlertNotificationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
