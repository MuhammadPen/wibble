// a container with shadow, takes a child widget and shadow color, and background color, outline color

import 'package:flutter/material.dart';

class ShadowContainer extends StatelessWidget {
  final Widget child;
  final Color? shadowColor;
  final Color? backgroundColor;
  final Color? outlineColor;
  final double? width;

  const ShadowContainer({
    super.key,
    required this.child,
    this.shadowColor,
    this.backgroundColor,
    this.outlineColor,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: outlineColor ?? Colors.black, width: 4),
        boxShadow: [
          BoxShadow(color: shadowColor ?? Colors.black, offset: Offset(-3, 3)),
        ],
      ),
      child: child,
    );
  }
}
