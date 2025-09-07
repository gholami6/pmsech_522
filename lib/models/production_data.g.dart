// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'production_data.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ProductionDataAdapter extends TypeAdapter<ProductionData> {
  @override
  final int typeId = 1;

  @override
  ProductionData read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ProductionData(
      shamsiDate: fields[0] as String,
      year: fields[1] as int,
      month: fields[2] as int,
      day: fields[3] as int,
      shift: fields[4] as String,
      stopDescription: fields[5] as String,
      equipmentName: fields[6] as String,
      equipmentCode1: fields[7] as String?,
      equipmentCode2: fields[8] as String?,
      subEquipment: fields[9] as String,
      subEquipmentCode: fields[10] as String?,
      stopReason: fields[11] as String,
      stopType: fields[12] as String,
      stopStartTime: fields[13] as String,
      stopEndTime: fields[14] as String,
      stopDuration: fields[15] as String,
      serviceCount: fields[16] as int,
      inputTonnage: fields[17] as double,
      scale3: fields[18] as double,
      scale4: fields[19] as double,
      scale5: fields[20] as double,
      group: fields[21] as int,
      directFeed: fields[22] as int,
    );
  }

  @override
  void write(BinaryWriter writer, ProductionData obj) {
    writer
      ..writeByte(23)
      ..writeByte(0)
      ..write(obj.shamsiDate)
      ..writeByte(1)
      ..write(obj.year)
      ..writeByte(2)
      ..write(obj.month)
      ..writeByte(3)
      ..write(obj.day)
      ..writeByte(4)
      ..write(obj.shift)
      ..writeByte(5)
      ..write(obj.stopDescription)
      ..writeByte(6)
      ..write(obj.equipmentName)
      ..writeByte(7)
      ..write(obj.equipmentCode1)
      ..writeByte(8)
      ..write(obj.equipmentCode2)
      ..writeByte(9)
      ..write(obj.subEquipment)
      ..writeByte(10)
      ..write(obj.subEquipmentCode)
      ..writeByte(11)
      ..write(obj.stopReason)
      ..writeByte(12)
      ..write(obj.stopType)
      ..writeByte(13)
      ..write(obj.stopStartTime)
      ..writeByte(14)
      ..write(obj.stopEndTime)
      ..writeByte(15)
      ..write(obj.stopDuration)
      ..writeByte(16)
      ..write(obj.serviceCount)
      ..writeByte(17)
      ..write(obj.inputTonnage)
      ..writeByte(18)
      ..write(obj.scale3)
      ..writeByte(19)
      ..write(obj.scale4)
      ..writeByte(20)
      ..write(obj.scale5)
      ..writeByte(21)
      ..write(obj.group)
      ..writeByte(22)
      ..write(obj.directFeed);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductionDataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProductionData _$ProductionDataFromJson(Map<String, dynamic> json) =>
    ProductionData(
      shamsiDate: json['shamsi_date'] as String,
      year: (json['year'] as num).toInt(),
      month: (json['month'] as num).toInt(),
      day: (json['day'] as num).toInt(),
      shift: json['shift'] as String,
      stopDescription: json['stop_description'] as String,
      equipmentName: json['equipment_name'] as String,
      equipmentCode1: json['equipment_code_1'] as String?,
      equipmentCode2: json['equipment_code_2'] as String?,
      subEquipment: json['sub_equipment'] as String,
      subEquipmentCode: json['sub_equipment_code'] as String?,
      stopReason: json['stop_reason'] as String,
      stopType: json['stop_type'] as String,
      stopStartTime: json['stop_start_time'] as String,
      stopEndTime: json['stop_end_time'] as String,
      stopDuration: json['stop_duration'] as String,
      serviceCount: (json['service_count'] as num).toInt(),
      inputTonnage: (json['input_tonnage'] as num).toDouble(),
      scale3: (json['scale_3'] as num).toDouble(),
      scale4: (json['scale_4'] as num).toDouble(),
      scale5: (json['scale_5'] as num).toDouble(),
      group: (json['group'] as num).toInt(),
      directFeed: (json['direct_feed'] as num).toInt(),
    );

Map<String, dynamic> _$ProductionDataToJson(ProductionData instance) =>
    <String, dynamic>{
      'shamsi_date': instance.shamsiDate,
      'year': instance.year,
      'month': instance.month,
      'day': instance.day,
      'shift': instance.shift,
      'stop_description': instance.stopDescription,
      'equipment_name': instance.equipmentName,
      'equipment_code_1': instance.equipmentCode1,
      'equipment_code_2': instance.equipmentCode2,
      'sub_equipment': instance.subEquipment,
      'sub_equipment_code': instance.subEquipmentCode,
      'stop_reason': instance.stopReason,
      'stop_type': instance.stopType,
      'stop_start_time': instance.stopStartTime,
      'stop_end_time': instance.stopEndTime,
      'stop_duration': instance.stopDuration,
      'service_count': instance.serviceCount,
      'input_tonnage': instance.inputTonnage,
      'scale_3': instance.scale3,
      'scale_4': instance.scale4,
      'scale_5': instance.scale5,
      'group': instance.group,
      'direct_feed': instance.directFeed,
    };
