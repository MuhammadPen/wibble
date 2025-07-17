import 'package:flutter/material.dart';
import 'dart:async';

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

class _CountdownWidgetState extends State<CountdownWidget>
    with TickerProviderStateMixin {
  late int _remainingSeconds;
  Timer? _timer;
  bool _isVisible = true;
  late AnimationController _scaleController;
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.durationInSeconds;

    // Initialize animation controllers
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _startCountdown();
  }

  void _startCountdown() {
    _scaleController.forward();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
          // Trigger scale animation for each second change
          _scaleController.reset();
          _scaleController.forward();

          // Add pulse effect when time is running low
          if (_remainingSeconds <= 10) {
            _pulseController.repeat(reverse: true);
          }
        } else {
          _timer?.cancel();
          _scaleController.stop();
          _pulseController.stop();
          widget.onCountdownComplete();
          _isVisible = false;
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scaleController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Color _getCountdownColor() {
    // Calculate progress as a value between 0 (time up) and 1 (full time)
    double progress = _remainingSeconds / widget.durationInSeconds;

    if (progress > 0.5) {
      // Red to orange transition (high time remaining)
      return Color.lerp(Colors.orange, Colors.red, (progress - 0.5) * 2)!;
    } else if (progress > 0.2) {
      // Orange to yellow transition (medium time remaining)
      return Color.lerp(
        Colors.yellow.shade700,
        Colors.orange,
        (progress - 0.2) * 2.5,
      )!;
    } else {
      // Yellow to green transition (low time remaining - closer to zero)
      return Color.lerp(Colors.green, Colors.yellow.shade700, progress * 5)!;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVisible) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: Listenable.merge([_scaleAnimation, _pulseAnimation]),
      builder: (context, child) {
        return Transform.scale(
          scale:
              _scaleAnimation.value *
              (_remainingSeconds <= 10 ? _pulseAnimation.value : 1.0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: _getCountdownColor().withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _getCountdownColor(), width: 2),
              boxShadow: [
                BoxShadow(
                  color: _getCountdownColor().withValues(alpha: 0.3),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return SlideTransition(
                  position:
                      Tween<Offset>(
                        begin: const Offset(0, -0.5),
                        end: Offset.zero,
                      ).animate(
                        CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOutBack,
                        ),
                      ),
                  child: FadeTransition(opacity: animation, child: child),
                );
              },
              child: Text(
                '$_remainingSeconds',
                key: ValueKey<int>(_remainingSeconds),
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: _getCountdownColor(),
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
