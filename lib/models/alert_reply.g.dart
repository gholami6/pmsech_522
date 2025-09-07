// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'alert_reply.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AlertReplyAdapter extends TypeAdapter<AlertReply> {
  @override
  final int typeId = 13;

  @override
  AlertReply read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AlertReply(
      id: fields[0] as String?,
      userId: fields[1] as String,
      message: fields[2] as String,
      createdAt: fields[3] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, AlertReply obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.message)
      ..writeByte(3)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AlertReplyAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
