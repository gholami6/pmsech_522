import 'package:hive/hive.dart';

part 'equipment_location.g.dart';

@HiveType(typeId: 21)
class EquipmentLocation extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String description;

  @HiveField(3)
  final bool isActive;

  @HiveField(4)
  final DateTime createdAt;

  @HiveField(5)
  final String createdBy;

  EquipmentLocation({
    required this.id,
    required this.name,
    required this.description,
    this.isActive = true,
    required this.createdAt,
    required this.createdBy,
  });

  EquipmentLocation copyWith({
    String? id,
    String? name,
    String? description,
    bool? isActive,
    DateTime? createdAt,
    String? createdBy,
  }) {
    return EquipmentLocation(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'createdBy': createdBy,
    };
  }

  factory EquipmentLocation.fromJson(Map<String, dynamic> json) {
    return EquipmentLocation(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      isActive: json['isActive'] ?? true,
      createdAt: DateTime.parse(json['createdAt']),
      createdBy: json['createdBy'],
    );
  }
}
