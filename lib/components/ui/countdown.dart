import 'dart:async';

import 'package:flutter/material.dart';
import 'package:wibble/components/ui/shadow_container.dart';
import 'package:wibble/styles/text.dart';

class CountdownWidget extends StatefulWidget {
  final int durationInSeconds;
  final VoidCallback onCountdownComplete;

  const CountdownWidget({
    super.key,
    required this.durationInSeconds,
    required this.onCountdownComplete,
  });

  @override
  State<CountdownWidget> createState() => _CountdownWidgetState();
}

class _CountdownWidgetState extends State<CountdownWidget> {
  late int _remainingSeconds;
  Timer? _timer;
  bool _isVisible = true;

  @override
  Widget build(BuildContext context) {
    if (!_isVisible) {
      return const SizedBox.shrink();
    }

    return ShadowContainer(
      backgroundColor: Color(0xffF2EEDB),
      outlineColor: _getCountdownColor(),
      shadowColor: _getCountdownColor(),
      padding: 20,
      child: SizedBox(
        width: 80,
        child: Text(
          '$_remainingSeconds',
          textAlign: TextAlign.center,
          style: textStyle.copyWith(
            fontSize: 64,
            fontWeight: FontWeight.bold,
            color: _getCountdownColor(),
            height: 1.0,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.durationInSeconds;
    _startCountdown();
  }

  Color _getCountdownColor() {
    // Calculate progress as a value between 0 (time up) and 1 (full time)
    double progress = _remainingSeconds / widget.durationInSeconds;

    if (progress > 0.6) {
      // High time remaining - Red
      return Color(0xffFF2727);
    } else if (progress > 0.4) {
      // Medium-high time remaining - transition from red to orange
      return Color.lerp(
        Color(0xffFF7300),
        Color(0xffFF2727),
        (progress - 0.4) * 5,
      )!;
    } else if (progress > 0.2) {
      // Medium-low time remaining - transition from orange to yellow
      return Color.lerp(
        Color(0xffFFC700),
        Color(0xffFF7300),
        (progress - 0.2) * 5,
      )!;
    } else {
      // Low time remaining - transition from yellow to green
      return Color.lerp(Color(0xff10A958), Color(0xffFFC700), progress * 5)!;
    }
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          _timer?.cancel();
          widget.onCountdownComplete();
          _isVisible = false;
        }
      });
    });
  }
}
