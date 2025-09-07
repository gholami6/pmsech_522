// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ai_learning_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AILearningData _$AILearningDataFromJson(Map<String, dynamic> json) =>
    AILearningData(
      id: json['id'] as String,
      type: json['type'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      details: json['details'] as Map<String, dynamic>,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
      isActive: json['isActive'] as bool? ?? true,
    );

Map<String, dynamic> _$AILearningDataToJson(AILearningData instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      'title': instance.title,
      'description': instance.description,
      'details': instance.details,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
      'isActive': instance.isActive,
    };

EquipmentInfo _$EquipmentInfoFromJson(Map<String, dynamic> json) =>
    EquipmentInfo(
      name: json['name'] as String,
      description: json['description'] as String?,
      specifications: json['specifications'] as Map<String, dynamic>,
      capabilities: (json['capabilities'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      location: json['location'] as String?,
      department: json['department'] as String?,
    );

Map<String, dynamic> _$EquipmentInfoToJson(EquipmentInfo instance) =>
    <String, dynamic>{
      'name': instance.name,
      'description': instance.description,
      'specifications': instance.specifications,
      'capabilities': instance.capabilities,
      'location': instance.location,
      'department': instance.department,
    };

ProcessInfo _$ProcessInfoFromJson(Map<String, dynamic> json) => ProcessInfo(
      name: json['name'] as String,
      description: json['description'] as String,
      steps: (json['steps'] as List<dynamic>).map((e) => e as String).toList(),
      parameters: json['parameters'] as Map<String, dynamic>,
      category: json['category'] as String?,
    );

Map<String, dynamic> _$ProcessInfoToJson(ProcessInfo instance) =>
    <String, dynamic>{
      'name': instance.name,
      'description': instance.description,
      'steps': instance.steps,
      'parameters': instance.parameters,
      'category': instance.category,
    };
