import 'package:flutter/material.dart';

class Loading extends StatefulWidget {
  final Color color;
  const Loading({super.key, this.color = Colors.white});

  @override
  State<Loading> createState() => _LoadingWidgetState();
}

class _LoadingWidgetState extends State<Loading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildDot(bool isVisible) {
    return Container(
      width: 12,
      height: 12,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: isVisible ? widget.color : Colors.transparent,
        shape: BoxShape.circle,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Divide the animation into 3 equal phases (0.0-0.33, 0.33-0.66, 0.66-1.0)
        double progress = _controller.value;
        int visibleDots;

        if (progress < 0.33) {
          visibleDots = 1;
        } else if (progress < 0.66) {
          visibleDots = 2;
        } else {
          visibleDots = 3;
        }

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDot(visibleDots >= 1),
            _buildDot(visibleDots >= 2),
            _buildDot(visibleDots >= 3),
          ],
        );
      },
    );
  }
}
