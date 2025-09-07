import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  final String text;
  final Color color;
  final IconData? icon;
  final bool isAnimated;

  const StatusBadge({
    super.key,
    required this.text,
    required this.color,
    this.icon,
    this.isAnimated = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color,
            color.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              color: Colors.white,
              size: 14,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class AnimatedStatusBadge extends StatefulWidget {
  final String text;
  final Color color;
  final IconData? icon;

  const AnimatedStatusBadge({
    super.key,
    required this.text,
    required this.color,
    this.icon,
  });

  @override
  State<AnimatedStatusBadge> createState() => _AnimatedStatusBadgeState();
}

class _AnimatedStatusBadgeState extends State<AnimatedStatusBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: StatusBadge(
            text: widget.text,
            color: widget.color,
            icon: widget.icon,
          ),
        );
      },
    );
  }
}

// کامپوننت‌های آماده برای انواع مختلف وضعیت
class NewStatusBadge extends StatelessWidget {
  const NewStatusBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedStatusBadge(
      text: 'جدید',
      color: const Color(0xFFE74C3C),
      icon: Icons.fiber_new,
    );
  }
}

class ReadStatusBadge extends StatelessWidget {
  const ReadStatusBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return StatusBadge(
      text: 'خوانده شده',
      color: const Color(0xFF27AE60),
      icon: Icons.check_circle,
    );
  }
}

class UrgentStatusBadge extends StatelessWidget {
  const UrgentStatusBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedStatusBadge(
      text: 'فوری',
      color: const Color(0xFFFF6B35),
      icon: Icons.priority_high,
    );
  }
}

class InfoStatusBadge extends StatelessWidget {
  const InfoStatusBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return StatusBadge(
      text: 'اطلاعیه',
      color: const Color(0xFF3498DB),
      icon: Icons.info,
    );
  }
}
