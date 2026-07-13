import 'dart:math';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Code-native animated "fire" particle effect for streak milestones.
///
/// Uses CustomPainter + AnimationController to render rising flame-like
/// particles — no Lottie JSON dependency. Drop this widget into any
/// Stack to overlay a streak celebration.
class StreakFireWidget extends StatefulWidget {
  /// Duration of the fire animation before it fades out.
  final Duration duration;

  /// Number of concurrent particles.
  final int particleCount;

  /// Callback when the animation completes.
  final VoidCallback? onComplete;

  const StreakFireWidget({
    super.key,
    this.duration = const Duration(seconds: 3),
    this.particleCount = 40,
    this.onComplete,
  });

  @override
  State<StreakFireWidget> createState() => _StreakFireWidgetState();
}

class _StreakFireWidgetState extends State<StreakFireWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_FireParticle> _particles;
  final _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          widget.onComplete?.call();
        }
      });

    _particles = List.generate(widget.particleCount, (_) => _randomParticle());
    _controller.forward();
  }

  _FireParticle _randomParticle() {
    return _FireParticle(
      x: 0.3 + _random.nextDouble() * 0.4, // cluster near center
      startY: 0.85 + _random.nextDouble() * 0.15, // start from bottom
      speed: 0.3 + _random.nextDouble() * 0.7,
      size: 3.0 + _random.nextDouble() * 6.0,
      delay: _random.nextDouble() * 0.4, // staggered start
      color: _fireColors[_random.nextInt(_fireColors.length)],
      drift: (_random.nextDouble() - 0.5) * 0.15,
    );
  }

  static const _fireColors = [
    Color(0xFFFF6B35), // deep orange
    Color(0xFFFF8C42), // orange
    Color(0xFFFFD700), // gold
    Color(0xFFFFA726), // amber
    Color(0xFFFF5722), // red-orange
    Color(0xFFFFEB3B), // bright yellow
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return CustomPaint(
          painter: _FirePainter(
            particles: _particles,
            progress: _controller.value,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class _FireParticle {
  final double x; // horizontal position (0–1)
  final double startY; // start vertical position (0–1, bottom = 1)
  final double speed; // rise speed multiplier
  final double size; // radius in px
  final double delay; // delay before this particle starts (0–1)
  final Color color;
  final double drift; // horizontal sway

  _FireParticle({
    required this.x,
    required this.startY,
    required this.speed,
    required this.size,
    required this.delay,
    required this.color,
    required this.drift,
  });
}

class _FirePainter extends CustomPainter {
  final List<_FireParticle> particles;
  final double progress; // 0–1

  _FirePainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      // Skip particles whose delay hasn't elapsed yet
      final localProgress = (progress - p.delay).clamp(0.0, 1.0) /
          (1.0 - p.delay).clamp(0.01, 1.0);
      if (localProgress <= 0) continue;

      // Rise from bottom to top
      final riseAmount = localProgress * p.speed;
      final y = (p.startY - riseAmount) * size.height;

      // Horizontal drift with slight sine wave
      final x = (p.x + p.drift * sin(localProgress * pi * 2)) * size.width;

      // Fade out as particle rises and overall animation ends
      final fadeByRise = (1.0 - riseAmount.clamp(0.0, 1.0));
      final fadeByEnd = progress > 0.7 ? (1.0 - (progress - 0.7) / 0.3) : 1.0;
      final opacity = (fadeByRise * fadeByEnd).clamp(0.0, 1.0);

      if (opacity <= 0 || y < 0) continue;

      // Shrink as particle rises
      final currentSize = p.size * (1.0 - riseAmount * 0.6).clamp(0.3, 1.0);

      final paint = Paint()
        ..color = p.color.withValues(alpha: opacity)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, currentSize * 0.6);

      canvas.drawCircle(Offset(x, y), currentSize, paint);
    }
  }

  @override
  bool shouldRepaint(_FirePainter oldDelegate) =>
      oldDelegate.progress != progress;
}
