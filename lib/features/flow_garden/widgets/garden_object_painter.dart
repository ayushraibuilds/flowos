import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/garden_day.dart';

/// A premium, code-native vector painter for Flow Garden objects.
/// Replaces low-resolution system emojis with highly-stylized vector illustrations.
class GardenObjectPainter extends CustomPainter {
  final GardenObjectKind kind;
  final String emoji;

  const GardenObjectPainter({required this.kind, required this.emoji});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final center = Offset(cx, cy);
    final radius = math.min(cx, cy);

    canvas.save();

    // Subtle drop shadow under objects for depth
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, cy + radius * 0.8),
        width: size.width * 0.7,
        height: size.height * 0.25,
      ),
      shadowPaint,
    );

    switch (kind) {
      case GardenObjectKind.tree:
        _paintTree(canvas, size, center, radius);
        break;
      case GardenObjectKind.flower:
        _paintFlower(canvas, size, center, radius);
        break;
      case GardenObjectKind.wildlife:
        _paintButterfly(canvas, size, center, radius);
        break;
      default:
        // Default seedling/sprout shape for light/water/resting/misc
        _paintDefaultSeedling(canvas, size, center, radius);
        break;
    }

    canvas.restore();
  }

  void _paintTree(Canvas canvas, Size size, Offset center, double radius) {
    final trunkWidth = radius * 0.18;
    final trunkHeight = radius * 0.7;
    final trunkRect = Rect.fromLTWH(
      center.dx - trunkWidth / 2,
      center.dy + radius * 0.1,
      trunkWidth,
      trunkHeight,
    );

    // 1. Draw Trunk
    final trunkPaint = Paint()
      ..shader = LinearGradient(
        colors: [const Color(0xFF5D4037), const Color(0xFF3E2723)],
      ).createShader(trunkRect);
    canvas.drawRRect(
      RRect.fromRectAndRadius(trunkRect, Radius.circular(trunkWidth * 0.3)),
      trunkPaint,
    );

    final leafPaint = Paint()..style = PaintingStyle.fill;

    // 2. Draw Foliage by Variant
    if (emoji == '🌲') {
      // Layered Pine Tree
      final pinePath = Path();
      final topY = center.dy - radius * 0.8;
      final bottomY = center.dy + radius * 0.15;
      final step = (bottomY - topY) / 3;

      for (int i = 0; i < 3; i++) {
        final currentTop = topY + i * step * 0.6;
        final currentBottom = currentTop + step * 1.3;
        final halfWidth = radius * (0.35 + i * 0.22);

        pinePath.moveTo(center.dx, currentTop);
        pinePath.lineTo(center.dx - halfWidth, currentBottom);
        pinePath.lineTo(center.dx + halfWidth, currentBottom);
        pinePath.close();
      }

      leafPaint.shader =
          LinearGradient(
            colors: [const Color(0xFF2E7D32), const Color(0xFF1B5E20)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ).createShader(
            Rect.fromLTRB(
              center.dx - radius,
              topY,
              center.dx + radius,
              bottomY,
            ),
          );

      canvas.drawPath(pinePath, leafPaint);
    } else if (emoji == '🌳') {
      // Fluffy rounded Oak Tree
      final foliageRect = Rect.fromCircle(
        center: Offset(center.dx, center.dy - radius * 0.15),
        radius: radius * 0.65,
      );
      leafPaint.shader = RadialGradient(
        colors: [const Color(0xFF4CAF50), const Color(0xFF2E7D32)],
        center: const Alignment(-0.2, -0.2),
      ).createShader(foliageRect);

      canvas.drawCircle(
        Offset(center.dx, center.dy - radius * 0.2),
        radius * 0.5,
        leafPaint,
      );
      canvas.drawCircle(
        Offset(center.dx - radius * 0.25, center.dy - radius * 0.1),
        radius * 0.38,
        leafPaint,
      );
      canvas.drawCircle(
        Offset(center.dx + radius * 0.28, center.dy - radius * 0.12),
        radius * 0.38,
        leafPaint,
      );
      canvas.drawCircle(
        Offset(center.dx, center.dy - radius * 0.42),
        radius * 0.38,
        leafPaint,
      );
    } else {
      // Palm Tree (🌴) or default palm leaves
      final palmPath = Path();
      final topCenter = Offset(center.dx, center.dy + radius * 0.1);

      // Feathered Palm Leaves
      leafPaint.color = const Color(0xFF0F9D58);
      leafPaint.style = PaintingStyle.stroke;
      leafPaint.strokeWidth = 3.5;
      leafPaint.strokeCap = StrokeCap.round;

      for (int angleDeg in [-40, -15, 10, 170, 195, 220]) {
        final angle = angleDeg * math.pi / 180;
        final controlX = topCenter.dx + math.cos(angle) * radius * 0.5;
        final controlY =
            topCenter.dy - radius * 0.3 + math.sin(angle) * radius * 0.2;
        final endX = topCenter.dx + math.cos(angle) * radius * 0.85;
        final endY = topCenter.dy + math.sin(angle) * radius * 0.65;

        palmPath.reset();
        palmPath.moveTo(topCenter.dx, topCenter.dy - radius * 0.55);
        palmPath.quadraticBezierTo(controlX, controlY, endX, endY);
        canvas.drawPath(palmPath, leafPaint);
      }
    }
  }

  void _paintFlower(Canvas canvas, Size size, Offset center, double radius) {
    // Stem
    final stemPaint = Paint()
      ..color = const Color(0xFF81C784)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(center.dx, center.dy),
      Offset(center.dx, center.dy + radius * 0.95),
      stemPaint,
    );

    // Leaves on the stem
    final leafPaint = Paint()..color = const Color(0xFF4CAF50);
    final leafLeft = Path()
      ..moveTo(center.dx, center.dy + radius * 0.5)
      ..quadraticBezierTo(
        center.dx - radius * 0.3,
        center.dy + radius * 0.35,
        center.dx,
        center.dy + radius * 0.2,
      )
      ..close();
    canvas.drawPath(leafLeft, leafPaint);

    final petalPaint = Paint()..style = PaintingStyle.fill;

    if (emoji == '🌸') {
      // Cherry Blossom (Pink, 5 Round Petals)
      petalPaint.color = const Color(0xFFF48FB1);
      final double petalRadius = radius * 0.38;
      for (int i = 0; i < 5; i++) {
        final angle = (i * 72) * math.pi / 180;
        final px = center.dx + math.cos(angle) * petalRadius * 0.7;
        final py = center.dy + math.sin(angle) * petalRadius * 0.7;
        canvas.drawCircle(Offset(px, py), petalRadius, petalPaint);
      }
      // Yellow Center
      canvas.drawCircle(
        center,
        radius * 0.22,
        Paint()..color = const Color(0xFFFFD54F),
      );
    } else if (emoji == '🌻') {
      // Sunflower (Yellow Radiating Petals, Dark center)
      petalPaint.color = const Color(0xFFFFCA28);
      final double petalWidth = radius * 0.16;
      final double petalHeight = radius * 0.55;

      for (int i = 0; i < 12; i++) {
        canvas.save();
        canvas.translate(center.dx, center.dy);
        canvas.rotate((i * 30) * math.pi / 180);
        final rect = Rect.fromCenter(
          center: Offset(0, -radius * 0.35),
          width: petalWidth,
          height: petalHeight,
        );
        canvas.drawOval(rect, petalPaint);
        canvas.restore();
      }
      // Dark Center
      canvas.drawCircle(
        center,
        radius * 0.32,
        Paint()..color = const Color(0xFF4E342E),
      );
    } else if (emoji == '🌷') {
      // Tulip (Red Cup Shape)
      final tulipRect = Rect.fromCenter(
        center: center,
        width: radius * 0.8,
        height: radius * 0.9,
      );
      petalPaint.shader = LinearGradient(
        colors: [const Color(0xFFEF5350), const Color(0xFFD32F2F)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(tulipRect);

      final path = Path()
        ..moveTo(center.dx - radius * 0.32, center.dy - radius * 0.3)
        ..quadraticBezierTo(
          center.dx - radius * 0.45,
          center.dy + radius * 0.3,
          center.dx,
          center.dy + radius * 0.42,
        )
        ..quadraticBezierTo(
          center.dx + radius * 0.45,
          center.dy + radius * 0.3,
          center.dx + radius * 0.32,
          center.dy - radius * 0.3,
        )
        ..quadraticBezierTo(
          center.dx,
          center.dy - radius * 0.05,
          center.dx - radius * 0.32,
          center.dy - radius * 0.3,
        )
        ..close();
      canvas.drawPath(path, petalPaint);

      // Center Petal overlay
      canvas.drawPath(
        Path()
          ..moveTo(center.dx - radius * 0.1, center.dy - radius * 0.38)
          ..quadraticBezierTo(
            center.dx - radius * 0.25,
            center.dy,
            center.dx,
            center.dy + radius * 0.4,
          )
          ..quadraticBezierTo(
            center.dx + radius * 0.25,
            center.dy,
            center.dx + radius * 0.1,
            center.dy - radius * 0.38,
          )
          ..quadraticBezierTo(
            center.dx,
            center.dy - radius * 0.2,
            center.dx - radius * 0.1,
            center.dy - radius * 0.38,
          )
          ..close(),
        Paint()..color = const Color(0xFFC62828),
      );
    } else {
      // Daisy (🌼) or Default Flower
      petalPaint.color = Colors.white;
      final double petalRadius = radius * 0.34;
      for (int i = 0; i < 8; i++) {
        final angle = (i * 45) * math.pi / 180;
        final px = center.dx + math.cos(angle) * petalRadius * 0.85;
        final py = center.dy + math.sin(angle) * petalRadius * 0.85;
        canvas.drawCircle(Offset(px, py), petalRadius, petalPaint);
      }
      // Orange Center
      canvas.drawCircle(
        center,
        radius * 0.25,
        Paint()..color = const Color(0xFFFFB300),
      );
    }
  }

  void _paintButterfly(Canvas canvas, Size size, Offset center, double radius) {
    // Left Wing
    final leftWing = Path()
      ..moveTo(center.dx, center.dy)
      ..cubicTo(
        center.dx - radius * 0.8,
        center.dy - radius * 0.8,
        center.dx - radius * 0.9,
        center.dy + radius * 0.1,
        center.dx - radius * 0.2,
        center.dy + radius * 0.2,
      )
      ..cubicTo(
        center.dx - radius * 0.7,
        center.dy + radius * 0.7,
        center.dx - radius * 0.3,
        center.dy + radius * 0.8,
        center.dx,
        center.dy + radius * 0.1,
      )
      ..close();

    // Right Wing
    final rightWing = Path()
      ..moveTo(center.dx, center.dy)
      ..cubicTo(
        center.dx + radius * 0.8,
        center.dy - radius * 0.8,
        center.dx + radius * 0.9,
        center.dy + radius * 0.1,
        center.dx + radius * 0.2,
        center.dy + radius * 0.2,
      )
      ..cubicTo(
        center.dx + radius * 0.7,
        center.dy + radius * 0.7,
        center.dx + radius * 0.3,
        center.dy + radius * 0.8,
        center.dx,
        center.dy + radius * 0.1,
      )
      ..close();

    final wingPaint = Paint()
      ..shader = LinearGradient(
        colors: [const Color(0xFF29B6F6), const Color(0xFF0288D1)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawPath(leftWing, wingPaint);
    canvas.drawPath(rightWing, wingPaint);

    // Body
    final bodyPaint = Paint()..color = const Color(0xFF263238);
    canvas.drawOval(
      Rect.fromCenter(
        center: center,
        width: radius * 0.14,
        height: radius * 0.8,
      ),
      bodyPaint,
    );

    // Antennae
    final antPaint = Paint()
      ..color = const Color(0xFF263238)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final lAnt = Path()
      ..moveTo(center.dx - radius * 0.03, center.dy - radius * 0.35)
      ..quadraticBezierTo(
        center.dx - radius * 0.15,
        center.dy - radius * 0.5,
        center.dx - radius * 0.22,
        center.dy - radius * 0.55,
      );
    final rAnt = Path()
      ..moveTo(center.dx + radius * 0.03, center.dy - radius * 0.35)
      ..quadraticBezierTo(
        center.dx + radius * 0.15,
        center.dy - radius * 0.5,
        center.dx + radius * 0.22,
        center.dy - radius * 0.55,
      );

    canvas.drawPath(lAnt, antPaint);
    canvas.drawPath(rAnt, antPaint);
  }

  void _paintDefaultSeedling(
    Canvas canvas,
    Size size,
    Offset center,
    double radius,
  ) {
    // A tiny green sprout in the soil
    final stemPaint = Paint()
      ..color = const Color(0xFF81C784)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    final stemPath = Path()
      ..moveTo(center.dx, center.dy + radius * 0.6)
      ..quadraticBezierTo(
        center.dx - radius * 0.1,
        center.dy + radius * 0.1,
        center.dx + radius * 0.05,
        center.dy - radius * 0.2,
      );
    canvas.drawPath(stemPath, stemPaint);

    // Tiny leaves
    final leafPaint = Paint()..color = const Color(0xFF4CAF50);
    final leafLeft = Path()
      ..moveTo(center.dx + radius * 0.02, center.dy - radius * 0.15)
      ..quadraticBezierTo(
        center.dx - radius * 0.35,
        center.dy - radius * 0.3,
        center.dx - radius * 0.15,
        center.dy - radius * 0.05,
      )
      ..close();
    final leafRight = Path()
      ..moveTo(center.dx + radius * 0.02, center.dy - radius * 0.15)
      ..quadraticBezierTo(
        center.dx + radius * 0.35,
        center.dy - radius * 0.3,
        center.dx + radius * 0.15,
        center.dy - radius * 0.05,
      )
      ..close();

    canvas.drawPath(leafLeft, leafPaint);
    canvas.drawPath(leafRight, leafPaint);
  }

  @override
  bool shouldRepaint(covariant GardenObjectPainter oldDelegate) {
    return oldDelegate.kind != kind || oldDelegate.emoji != emoji;
  }
}

/// A vector resting-day mark, kept separate from [GardenObjectPainter] because
/// rest is not a "missing" object in the Garden. It is a deliberate state.
class RestingMoonPainter extends CustomPainter {
  final double idleValue;

  const RestingMoonPainter({this.idleValue = 0});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide * .34;
    final drift = math.sin(idleValue * math.pi * 2) * size.height * .025;
    final moonCenter = Offset(center.dx, center.dy + drift);

    final glow = Paint()
      ..color = const Color(0xFFFFD65A).withValues(alpha: .16)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(moonCenter, radius * 1.22, glow);

    final moon = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFFF2A8), Color(0xFFEABF43)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromCircle(center: moonCenter, radius: radius));
    canvas.drawCircle(moonCenter, radius, moon);
    canvas.drawCircle(
      Offset(moonCenter.dx + radius * .42, moonCenter.dy - radius * .22),
      radius * .92,
      Paint()..color = const Color(0xFF13211F),
    );

    final crater = Paint()
      ..color = const Color(0xFFD7A938).withValues(alpha: .55);
    canvas.drawCircle(
      Offset(moonCenter.dx - radius * .34, moonCenter.dy + radius * .24),
      radius * .10,
      crater,
    );
    canvas.drawCircle(
      Offset(moonCenter.dx - radius * .06, moonCenter.dy + radius * .48),
      radius * .065,
      crater,
    );
  }

  @override
  bool shouldRepaint(covariant RestingMoonPainter oldDelegate) =>
      oldDelegate.idleValue != idleValue;
}

class RestingMoonArtwork extends StatelessWidget {
  final double size;
  final double idleValue;

  const RestingMoonArtwork({super.key, this.size = 42, this.idleValue = 0});

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: CustomPaint(painter: RestingMoonPainter(idleValue: idleValue)),
  );
}

class GardenObjectArtwork extends StatelessWidget {
  final GardenObject object;
  final double size;

  const GardenObjectArtwork({super.key, required this.object, this.size = 42});

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: CustomPaint(
      painter: GardenObjectPainter(kind: object.kind, emoji: object.emoji),
    ),
  );
}
