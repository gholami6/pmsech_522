import 'package:flutter/material.dart';

class MessageDisplay extends StatelessWidget {
  final String message;
  final int maxLines;
  final TextStyle? style;
  final TextAlign textAlign;
  final bool showEllipsis;

  const MessageDisplay({
    super.key,
    required this.message,
    this.maxLines = 2,
    this.style,
    this.textAlign = TextAlign.right,
    this.showEllipsis = true,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      message,
      style: style ?? const TextStyle(
        fontSize: 14,
        color: Color(0xFF5A6C7D),
        height: 1.4,
      ),
      maxLines: maxLines,
      overflow: showEllipsis ? TextOverflow.ellipsis : null,
      textAlign: textAlign,
    );
  }
}

class AnimatedMessageDisplay extends StatefulWidget {
  final String message;
  final int maxLines;
  final TextStyle? style;
  final TextAlign textAlign;
  final bool showEllipsis;
  final Duration animationDuration;

  const AnimatedMessageDisplay({
    super.key,
    required this.message,
    this.maxLines = 2,
    this.style,
    this.textAlign = TextAlign.right,
    this.showEllipsis = true,
    this.animationDuration = const Duration(milliseconds: 300),
  });

  @override
  State<AnimatedMessageDisplay> createState() => _AnimatedMessageDisplayState();
}

class _AnimatedMessageDisplayState extends State<AnimatedMessageDisplay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: MessageDisplay(
          message: widget.message,
          maxLines: widget.maxLines,
          style: widget.style,
          textAlign: widget.textAlign,
          showEllipsis: widget.showEllipsis,
        ),
      ),
    );
  }
}

class ExpandableMessageDisplay extends StatefulWidget {
  final String message;
  final TextStyle? style;
  final TextAlign textAlign;
  final int initialLines;

  const ExpandableMessageDisplay({
    super.key,
    required this.message,
    this.style,
    this.textAlign = TextAlign.right,
    this.initialLines = 2,
  });

  @override
  State<ExpandableMessageDisplay> createState() => _ExpandableMessageDisplayState();
}

class _ExpandableMessageDisplayState extends State<ExpandableMessageDisplay> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MessageDisplay(
          message: widget.message,
          maxLines: _isExpanded ? 999 : widget.initialLines,
          style: widget.style,
          textAlign: widget.textAlign,
          showEllipsis: !_isExpanded,
        ),
        if (widget.message.length > 100) // فقط اگر پیام طولانی باشد
          GestureDetector(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: Container(
              margin: const EdgeInsets.only(top: 4),
              child: Text(
                _isExpanded ? 'کمتر' : 'بیشتر',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class AlertMessageDisplay extends StatelessWidget {
  final String message;
  final bool isNew;
  final TextStyle? style;

  const AlertMessageDisplay({
    super.key,
    required this.message,
    this.isNew = false,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedMessageDisplay(
      message: message,
      maxLines: 2,
      style: style ?? TextStyle(
        fontSize: 14,
        color: const Color(0xFF5A6C7D),
        height: 1.4,
        fontWeight: isNew ? FontWeight.w600 : FontWeight.normal,
      ),
      textAlign: TextAlign.right,
      animationDuration: const Duration(milliseconds: 500),
    );
  }
}
