import 'package:flutter/material.dart';

class TimeBadge extends StatelessWidget {
  final String timeText;
  final Color color;
  final IconData? icon;

  const TimeBadge({
    super.key,
    required this.timeText,
    required this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              color: color,
              size: 12,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            timeText,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class SmartTimeBadge extends StatelessWidget {
  final DateTime dateTime;

  const SmartTimeBadge({
    super.key,
    required this.dateTime,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    String timeText;
    Color color;
    IconData icon;

    if (difference.inMinutes < 1) {
      timeText = 'الان';
      color = const Color(0xFFE74C3C);
      icon = Icons.access_time;
    } else if (difference.inMinutes < 60) {
      timeText = '${difference.inMinutes} دقیقه';
      color = const Color(0xFFF39C12);
      icon = Icons.schedule;
    } else if (difference.inHours < 24) {
      timeText = '${difference.inHours} ساعت';
      color = const Color(0xFF3498DB);
      icon = Icons.access_time_filled;
    } else if (difference.inDays < 7) {
      timeText = '${difference.inDays} روز';
      color = const Color(0xFF9B59B6);
      icon = Icons.calendar_today;
    } else {
      timeText = '${dateTime.year}/${dateTime.month}/${dateTime.day}';
      color = const Color(0xFF95A5A6);
      icon = Icons.event;
    }

    return TimeBadge(
      timeText: timeText,
      color: color,
      icon: icon,
    );
  }
}
