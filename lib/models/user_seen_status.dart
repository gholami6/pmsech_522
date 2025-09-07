import 'package:hive/hive.dart';

part 'user_seen_status.g.dart';

@HiveType(typeId: 14)
class UserSeenStatus extends HiveObject {
  @HiveField(0)
  final bool seen;

  @HiveField(1)
  final DateTime seenAt;

  UserSeenStatus({
    required this.seen,
    required this.seenAt,
  });

  UserSeenStatus copyWith({
    bool? seen,
    DateTime? seenAt,
  }) {
    return UserSeenStatus(
      seen: seen ?? this.seen,
      seenAt: seenAt ?? this.seenAt,
    );
  }
}
