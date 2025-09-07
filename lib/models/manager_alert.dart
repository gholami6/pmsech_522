import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import 'alert_reply.dart';
import 'user_seen_status.dart';

part 'manager_alert.g.dart';

@HiveType(typeId: 17)
class ManagerAlert extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String userId;

  @HiveField(2)
  final String title;

  @HiveField(3)
  final String message;

  @HiveField(4)
  final String category; // جلسات، مناسبت ها، دستورات، اطلاعیه ها

  @HiveField(5)
  final String? attachmentPath;

  @HiveField(6)
  final DateTime createdAt;

  @HiveField(7)
  final List<String> targetStakeholderTypes; // کارفرما، پیمانکار، مشاور

  @HiveField(8)
  final List<String>
      targetRoleTypes; // کارشناس مکانیک، کارشناس صنایع، رئیس تولید و غیره

  @HiveField(9)
  final Map<String, UserSeenStatus> seenBy;

  @HiveField(10)
  final List<AlertReply> replies;

  @HiveField(11)
  final bool allowReplies;

  ManagerAlert({
    String? id,
    required this.userId,
    required this.title,
    required this.message,
    required this.category,
    this.attachmentPath,
    DateTime? createdAt,
    List<String>? targetStakeholderTypes,
    List<String>? targetRoleTypes,
    Map<String, UserSeenStatus>? seenBy,
    List<AlertReply>? replies,
    bool? allowReplies,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        targetStakeholderTypes = targetStakeholderTypes ?? [],
        targetRoleTypes = targetRoleTypes ?? [],
        seenBy = seenBy ?? {},
        replies = replies ?? [],
        allowReplies = allowReplies ?? true;

  ManagerAlert copyWith({
    String? id,
    String? userId,
    String? title,
    String? message,
    String? category,
    String? attachmentPath,
    DateTime? createdAt,
    List<String>? targetStakeholderTypes,
    List<String>? targetRoleTypes,
    Map<String, UserSeenStatus>? seenBy,
    List<AlertReply>? replies,
    bool? allowReplies,
  }) {
    return ManagerAlert(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      message: message ?? this.message,
      category: category ?? this.category,
      attachmentPath: attachmentPath ?? this.attachmentPath,
      createdAt: createdAt ?? this.createdAt,
      targetStakeholderTypes:
          targetStakeholderTypes ?? this.targetStakeholderTypes,
      targetRoleTypes: targetRoleTypes ?? this.targetRoleTypes,
      seenBy: seenBy ?? this.seenBy,
      replies: replies ?? this.replies,
      allowReplies: allowReplies ?? this.allowReplies,
    );
  }

  // متد fromJson برای تبدیل JSON به شیء
  factory ManagerAlert.fromJson(Map<String, dynamic> json) {
    return ManagerAlert(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      category: json['category'] as String,
      attachmentPath: json['attachment_path'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      targetStakeholderTypes:
          (json['target_stakeholder_types'] as List<dynamic>?)
                  ?.map((type) => type as String)
                  .toList() ??
              [],
      targetRoleTypes: (json['target_role_types'] as List<dynamic>?)
              ?.map((type) => type as String)
              .toList() ??
          [],
      replies: (json['replies'] as List<dynamic>?)
              ?.map((replyJson) =>
                  AlertReply.fromJson(replyJson as Map<String, dynamic>))
              .toList() ??
          [],
      seenBy: parseSeenBy(json['seen_by']),
      allowReplies: json['allow_replies'] as bool? ?? true,
    );
  }

  // متد toJson برای تبدیل شیء به JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'message': message,
      'category': category,
      'attachment_path': attachmentPath,
      'created_at': createdAt.toIso8601String(),
      'target_stakeholder_types': targetStakeholderTypes,
      'target_role_types': targetRoleTypes,
      'replies': replies.map((reply) => reply.toJson()).toList(),
      'seen_by': seenBy.keys.toList(),
      'allow_replies': allowReplies,
    };
  }

  // متد کمکی برای پارس کردن seen_by
  static Map<String, UserSeenStatus> parseSeenBy(dynamic seenByData) {
    try {
      print('🔍 ManagerAlert: شروع پارس کردن seen_by: $seenByData');

      if (seenByData == null) {
        print('🔍 ManagerAlert: seen_by null است');
        return {};
      }

      if (seenByData is List) {
        print(
            '🔍 ManagerAlert: seen_by یک List است با ${seenByData.length} آیتم');
        final Map<String, UserSeenStatus> result = {};
        for (final item in seenByData) {
          if (item != null) {
            final userId = item.toString();
            result[userId] = UserSeenStatus(
              seen: true,
              seenAt: DateTime.now(),
            );
            print(
                '🔍 ManagerAlert: کاربر $userId به عنوان خوانده شده اضافه شد');
          }
        }
        print('🔍 ManagerAlert: نتیجه نهایی پارس: ${result.keys.toList()}');
        return result;
      }

      if (seenByData is Map) {
        print('🔍 ManagerAlert: seen_by یک Map است');
        final Map<String, UserSeenStatus> result = {};
        seenByData.forEach((key, value) {
          if (key != null) {
            final userId = key.toString();
            result[userId] = UserSeenStatus(
              seen: true,
              seenAt: DateTime.now(),
            );
            print(
                '🔍 ManagerAlert: کاربر $userId از Map به عنوان خوانده شده اضافه شد');
          }
        });
        print(
            '🔍 ManagerAlert: نتیجه نهایی پارس از Map: ${result.keys.toList()}');
        return result;
      }

      print('🔍 ManagerAlert: seen_by نوع نامشخص: ${seenByData.runtimeType}');
      return {};
    } catch (e) {
      print('❌ خطا در پارس کردن seen_by: $e');
      print('❌ نوع داده: ${seenByData.runtimeType}');
      print('❌ محتوای داده: $seenByData');
      return {};
    }
  }
}
