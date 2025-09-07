// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_seen_status.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserSeenStatusAdapter extends TypeAdapter<UserSeenStatus> {
  @override
  final int typeId = 14;

  @override
  UserSeenStatus read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserSeenStatus(
      seen: fields[0] as bool,
      seenAt: fields[1] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, UserSeenStatus obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.seen)
      ..writeByte(1)
      ..write(obj.seenAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserSeenStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
