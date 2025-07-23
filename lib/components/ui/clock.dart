import 'package:flutter/material.dart';
import 'package:wibble/styles/text.dart';

class ClockWidget extends StatelessWidget {
  final int remainingSeconds;
  final double size;

  const ClockWidget({
    super.key,
    required this.remainingSeconds,
    this.size = 64,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Center(
        child: Text(
          _formatTime(remainingSeconds),
          style: textStyle.copyWith(fontSize: size * 0.28),
        ),
      ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}
