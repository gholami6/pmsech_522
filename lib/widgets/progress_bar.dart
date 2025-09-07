import 'package:flutter/material.dart';

class ModernProgressBar extends StatelessWidget {
  final double progress;
  final Color color;
  final double height;
  final bool showAnimation;

  const ModernProgressBar({
    super.key,
    required this.progress,
    required this.color,
    this.height = 4,
    this.showAnimation = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.2),
        borderRadius: BorderRadius.circular(height / 2),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerRight,
        widthFactor: progress.clamp(0.0, 1.0),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerRight,
              end: Alignment.centerLeft,
              colors: [
                color,
                color.withOpacity(0.7),
              ],
            ),
            borderRadius: BorderRadius.circular(height / 2),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AnimatedProgressBar extends StatefulWidget {
  final double progress;
  final Color color;
  final double height;
  final Duration duration;

  const AnimatedProgressBar({
    super.key,
    required this.progress,
    required this.color,
    this.height = 4,
    this.duration = const Duration(milliseconds: 800),
  });

  @override
  State<AnimatedProgressBar> createState() => _AnimatedProgressBarState();
}

class _AnimatedProgressBarState extends State<AnimatedProgressBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _animation = Tween<double>(
      begin: 0.0,
      end: widget.progress,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _controller.forward();
  }

  @override
  void didUpdateWidget(AnimatedProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress != widget.progress) {
      _animation = Tween<double>(
        begin: oldWidget.progress,
        end: widget.progress,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ));
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ModernProgressBar(
          progress: _animation.value,
          color: widget.color,
          height: widget.height,
        );
      },
    );
  }
}

class TimeBasedProgressBar extends StatelessWidget {
  final DateTime startTime;
  final DateTime endTime;
  final Color color;
  final double height;

  const TimeBasedProgressBar({
    super.key,
    required this.startTime,
    required this.endTime,
    required this.color,
    this.height = 4,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final totalDuration = endTime.difference(startTime).inMilliseconds;
    final elapsedDuration = now.difference(startTime).inMilliseconds;
    
    double progress = 0.0;
    if (totalDuration > 0) {
      progress = (elapsedDuration / totalDuration).clamp(0.0, 1.0);
    }

    return AnimatedProgressBar(
      progress: progress,
      color: color,
      height: height,
    );
  }
}

class AlertProgressBar extends StatelessWidget {
  final DateTime createdAt;
  final Color color;
  final double height;

  const AlertProgressBar({
    super.key,
    required this.createdAt,
    required this.color,
    this.height = 4,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    
    double progress = 1.0;
    if (difference.inHours < 1) {
      progress = 1.0;
    } else if (difference.inHours < 6) {
      progress = 0.8;
    } else if (difference.inHours < 24) {
      progress = 0.6;
    } else if (difference.inDays < 3) {
      progress = 0.4;
    } else {
      progress = 0.2;
    }

    return ModernProgressBar(
      progress: progress,
      color: color,
      height: height,
    );
  }
}
