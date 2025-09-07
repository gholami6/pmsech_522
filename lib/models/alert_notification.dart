import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import 'alert_reply.dart';
import 'user_seen_status.dart';

part 'alert_notification.g.dart';

@HiveType(typeId: 3)
class AlertNotification extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String userId;

  @HiveField(2)
  final String equipmentId;

  @HiveField(3)
  final String message;

  @HiveField(4)
  final String? attachmentPath;

  @HiveField(5)
  final DateTime createdAt;

  @HiveField(6)
  final List<AlertReply> replies;

  @HiveField(7)
  final Map<String, UserSeenStatus> seenBy;

  @HiveField(8)
  final String category; // دسته‌بندی اعلان (مکانیک، برق، پروسس، و غیره)

  @HiveField(9)
  final bool allowReplies; // اجازه پاسخ‌دهی به اعلان

  AlertNotification({
    String? id,
    required this.userId,
    required this.equipmentId,
    required this.message,
    this.attachmentPath,
    DateTime? createdAt,
    List<AlertReply>? replies,
    Map<String, UserSeenStatus>? seenBy,
    String? category,
    bool? allowReplies,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        replies = replies ?? [],
        seenBy = seenBy ?? {},
        category = category ?? 'عمومی',
        allowReplies = allowReplies ?? true;

  AlertNotification copyWith({
    String? id,
    String? userId,
    String? equipmentId,
    String? message,
    String? attachmentPath,
    DateTime? createdAt,
    List<AlertReply>? replies,
    Map<String, UserSeenStatus>? seenBy,
    String? category,
    bool? allowReplies,
  }) {
    return AlertNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      equipmentId: equipmentId ?? this.equipmentId,
      message: message ?? this.message,
      attachmentPath: attachmentPath ?? this.attachmentPath,
      createdAt: createdAt ?? this.createdAt,
      replies: replies ?? this.replies,
      seenBy: seenBy ?? this.seenBy,
      category: category ?? this.category,
      allowReplies: allowReplies ?? this.allowReplies,
    );
  }

  // متد fromJson برای تبدیل JSON به شیء
  factory AlertNotification.fromJson(Map<String, dynamic> json) {
    return AlertNotification(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      equipmentId: json['equipment_id'] as String,
      message: json['message'] as String,
      attachmentPath: json['attachment_path'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      replies: (json['replies'] as List<dynamic>?)
              ?.map((replyJson) =>
                  AlertReply.fromJson(replyJson as Map<String, dynamic>))
              .toList() ??
          [],
      seenBy: (json['seen_by'] as List<dynamic>?)
              ?.asMap()
              .map((key, value) => MapEntry(
                    value as String,
                    UserSeenStatus(
                      seen: true,
                      seenAt: DateTime.now(),
                    ),
                  )) ??
          {},
      category: json['category'] as String? ?? 'عمومی',
      allowReplies: json['allow_replies'] as bool? ?? true,
    );
  }

  // متد toJson برای تبدیل شیء به JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'equipment_id': equipmentId,
      'message': message,
      'attachment_path': attachmentPath,
      'created_at': createdAt.toIso8601String(),
      'replies': replies.map((reply) => reply.toJson()).toList(),
      'seen_by': seenBy.keys.toList(),
      'category': category,
      'allow_replies': allowReplies,
    };
  }
}
