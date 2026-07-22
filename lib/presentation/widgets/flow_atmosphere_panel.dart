import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';

/// A small piece of the Garden's atmospheric visual language for utility
/// screens. It provides depth without turning every screen into another card.
class FlowAtmospherePanel extends StatelessWidget {
  final Widget child;
  final Color accent;
  final double height;
  final BorderRadiusGeometry? borderRadius;

  const FlowAtmospherePanel({
    super.key,
    required this.child,
    required this.accent,
    this.height = 154,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(AppSpacing.radiusCard);
    return SizedBox(
      height: height,
      width: double.infinity,
      child: ClipRRect(
        borderRadius: radius,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFF102027),
            border: Border.all(color: accent.withValues(alpha: .22)),
            borderRadius: radius,
          ),
          child: CustomPaint(
            painter: _FlowAtmospherePainter(accent),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _FlowAtmospherePainter extends CustomPainter {
  final Color accent;

  const _FlowAtmospherePainter(this.accent);

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    canvas.drawRect(
      bounds,
      Paint()
        ..shader = LinearGradient(
          colors: [
            const Color(0xFF102A34),
            Color.lerp(const Color(0xFF102A34), accent, .18)!,
            const Color(0xFF0D1718),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(bounds),
    );

    final bloom = Paint()..color = accent.withValues(alpha: .12);
    canvas.drawCircle(
      Offset(size.width * .86, -size.height * .04),
      size.height * .75,
      bloom,
    );
    canvas.drawCircle(
      Offset(size.width * .76, size.height * .17),
      size.height * .35,
      Paint()..color = accent.withValues(alpha: .06),
    );

    final ground = Path()
      ..moveTo(0, size.height * .82)
      ..quadraticBezierTo(
        size.width * .30,
        size.height * .56,
        size.width * .60,
        size.height * .82,
      )
      ..quadraticBezierTo(
        size.width * .82,
        size.height * .98,
        size.width,
        size.height * .72,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      ground,
      Paint()..color = const Color(0xFF11251F).withValues(alpha: .88),
    );

    final dotPaint = Paint()..color = Colors.white.withValues(alpha: .16);
    for (final point in const [
      Offset(.18, .26),
      Offset(.48, .18),
      Offset(.69, .41),
    ]) {
      canvas.drawCircle(
        Offset(size.width * point.dx, size.height * point.dy),
        math.max(1.2, size.shortestSide * .012),
        dotPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _FlowAtmospherePainter oldDelegate) =>
      oldDelegate.accent != accent;
}
