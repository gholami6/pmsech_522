import 'package:flutter/material.dart';

class AlertIconWidget extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  final bool isAnimated;
  final bool isNew;

  const AlertIconWidget({
    super.key,
    required this.icon,
    required this.color,
    this.size = 24,
    this.isAnimated = false,
    this.isNew = false,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // آیکن اصلی
        Container(
          width: size + 16,
          height: size + 16,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color,
                color.withOpacity(0.7),
              ],
            ),
            borderRadius: BorderRadius.circular((size + 16) / 2),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Icon(
              icon,
              color: Colors.white,
              size: size,
            ),
          ),
        ),

        // نشان جدید
        if (isNew)
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.fiber_manual_record,
                  color: Colors.white,
                  size: 8,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class AnimatedAlertIcon extends StatefulWidget {
  final IconData icon;
  final Color color;
  final double size;
  final bool isNew;

  const AnimatedAlertIcon({
    super.key,
    required this.icon,
    required this.color,
    this.size = 24,
    this.isNew = false,
  });

  @override
  State<AnimatedAlertIcon> createState() => _AnimatedAlertIconState();
}

class _AnimatedAlertIconState extends State<AnimatedAlertIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.1,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    if (widget.isNew) {
      _controller.repeat(reverse: true);
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
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Transform.rotate(
            angle: _rotationAnimation.value,
            child: AlertIconWidget(
              icon: widget.icon,
              color: widget.color,
              size: widget.size,
              isNew: widget.isNew,
            ),
          ),
        );
      },
    );
  }
}
