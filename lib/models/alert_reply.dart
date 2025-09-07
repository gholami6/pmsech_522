import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'alert_reply.g.dart';

@HiveType(typeId: 13)
class AlertReply extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String userId;

  @HiveField(2)
  final String message;

  @HiveField(3)
  final DateTime createdAt;

  AlertReply({
    String? id,
    required this.userId,
    required this.message,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  AlertReply copyWith({
    String? id,
    String? userId,
    String? message,
    DateTime? createdAt,
  }) {
    return AlertReply(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'message': message,
        'created_at': createdAt.toIso8601String(),
      };

  factory AlertReply.fromJson(Map<String, dynamic> json) => AlertReply(
        id: json['id'] as String? ?? const Uuid().v4(),
        userId: json['user_id'] as String? ?? json['userId'] as String? ?? '',
        message: json['message'] as String? ?? '',
        createdAt: DateTime.parse(json['created_at'] as String? ?? json['createdAt'] as String? ?? DateTime.now().toIso8601String()),
      );
}
