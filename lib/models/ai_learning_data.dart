import 'package:json_annotation/json_annotation.dart';

part 'ai_learning_data.g.dart';

@JsonSerializable()
class AILearningData {
  final String id;
  final String type; // 'equipment', 'process', 'rule', 'knowledge'
  final String title;
  final String description;
  final Map<String, dynamic> details;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isActive;

  AILearningData({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.details,
    required this.createdAt,
    this.updatedAt,
    this.isActive = true,
  });

  factory AILearningData.fromJson(Map<String, dynamic> json) =>
      _$AILearningDataFromJson(json);

  Map<String, dynamic> toJson() => _$AILearningDataToJson(this);

  AILearningData copyWith({
    String? id,
    String? type,
    String? title,
    String? description,
    Map<String, dynamic>? details,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return AILearningData(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      details: details ?? this.details,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }
}

@JsonSerializable()
class EquipmentInfo {
  final String name;
  final String? description;
  final Map<String, dynamic> specifications;
  final List<String> capabilities;
  final String? location;
  final String? department;

  EquipmentInfo({
    required this.name,
    this.description,
    required this.specifications,
    required this.capabilities,
    this.location,
    this.department,
  });

  factory EquipmentInfo.fromJson(Map<String, dynamic> json) =>
      _$EquipmentInfoFromJson(json);

  Map<String, dynamic> toJson() => _$EquipmentInfoToJson(this);
}

@JsonSerializable()
class ProcessInfo {
  final String name;
  final String description;
  final List<String> steps;
  final Map<String, dynamic> parameters;
  final String? category;

  ProcessInfo({
    required this.name,
    required this.description,
    required this.steps,
    required this.parameters,
    this.category,
  });

  factory ProcessInfo.fromJson(Map<String, dynamic> json) =>
      _$ProcessInfoFromJson(json);

  Map<String, dynamic> toJson() => _$ProcessInfoToJson(this);
}
