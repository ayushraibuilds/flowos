import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Code-native, recognizable marks for the attention categories.
///
/// These deliberately describe the category rather than copying a vendor logo
/// exactly, so the tracker remains polished without depending on bitmap assets
/// or system emoji rendering.
enum DistractionAppIconType {
  instagram,
  youtube,
  tiktok,
  x,
  reddit,
  browser,
  games,
  other,
}

class DistractionAppIcon extends StatelessWidget {
  final DistractionAppIconType type;
  final Color color;
  final double size;

  const DistractionAppIcon({
    super.key,
    required this.type,
    required this.color,
    this.size = 32,
  });

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _DistractionAppIconPainter(type: type, color: color),
        ),
      ),
    );
  }
}

class _DistractionAppIconPainter extends CustomPainter {
  final DistractionAppIconType type;
  final Color color;

  const _DistractionAppIconPainter({required this.type, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final center = rect.center;
    final unit = size.shortestSide;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = unit * .085
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = color;
    final fill = Paint()..color = color;

    switch (type) {
      case DistractionAppIconType.instagram:
        _instagram(canvas, rect, stroke, fill);
      case DistractionAppIconType.youtube:
        _youtube(canvas, rect, fill);
      case DistractionAppIconType.tiktok:
        _tiktok(canvas, center, unit, stroke, fill);
      case DistractionAppIconType.x:
        _x(canvas, center, unit, stroke);
      case DistractionAppIconType.reddit:
        _reddit(canvas, center, unit, stroke, fill);
      case DistractionAppIconType.browser:
        _browser(canvas, center, unit, stroke);
      case DistractionAppIconType.games:
        _games(canvas, center, unit, stroke, fill);
      case DistractionAppIconType.other:
        _other(canvas, center, unit, fill);
    }
  }

  void _instagram(Canvas canvas, Rect rect, Paint stroke, Paint fill) {
    final outer = RRect.fromRectAndRadius(
      rect.deflate(rect.width * .08),
      Radius.circular(rect.width * .26),
    );
    canvas.drawRRect(outer, stroke);
    canvas.drawCircle(rect.center, rect.width * .18, stroke);
    canvas.drawCircle(
      Offset(
        rect.center.dx + rect.width * .23,
        rect.center.dy - rect.height * .23,
      ),
      rect.width * .045,
      fill,
    );
  }

  void _youtube(Canvas canvas, Rect rect, Paint fill) {
    final body = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: rect.center,
        width: rect.width * .9,
        height: rect.height * .62,
      ),
      Radius.circular(rect.height * .18),
    );
    canvas.drawRRect(body, fill);
    final play = Path()
      ..moveTo(
        rect.center.dx - rect.width * .10,
        rect.center.dy - rect.height * .17,
      )
      ..lineTo(
        rect.center.dx - rect.width * .10,
        rect.center.dy + rect.height * .17,
      )
      ..lineTo(rect.center.dx + rect.width * .18, rect.center.dy)
      ..close();
    canvas.drawPath(play, Paint()..color = Colors.white);
  }

  void _tiktok(
    Canvas canvas,
    Offset center,
    double unit,
    Paint stroke,
    Paint fill,
  ) {
    final shadow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke.strokeWidth * 1.1
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF55F3E6);
    final path = Path()
      ..moveTo(center.dx + unit * .10, center.dy - unit * .34)
      ..lineTo(center.dx + unit * .10, center.dy + unit * .16)
      ..cubicTo(
        center.dx - unit * .04,
        center.dy + unit * .06,
        center.dx - unit * .34,
        center.dy + unit * .16,
        center.dx - unit * .22,
        center.dy + unit * .34,
      );
    canvas.drawPath(path.shift(Offset(unit * .035, 0)), shadow);
    canvas.drawPath(path, stroke);
    canvas.drawCircle(
      Offset(center.dx - unit * .22, center.dy + unit * .22),
      unit * .12,
      fill,
    );
  }

  void _x(Canvas canvas, Offset center, double unit, Paint stroke) {
    final leftTop = Offset(center.dx - unit * .30, center.dy - unit * .34);
    final rightBottom = Offset(center.dx + unit * .30, center.dy + unit * .34);
    final leftBottom = Offset(center.dx - unit * .28, center.dy + unit * .34);
    final rightTop = Offset(center.dx + unit * .28, center.dy - unit * .34);
    canvas.drawLine(leftTop, rightBottom, stroke);
    canvas.drawLine(leftBottom, rightTop, stroke);
  }

  void _reddit(
    Canvas canvas,
    Offset center,
    double unit,
    Paint stroke,
    Paint fill,
  ) {
    final head = Rect.fromCenter(
      center: Offset(center.dx, center.dy + unit * .08),
      width: unit * .78,
      height: unit * .55,
    );
    canvas.drawOval(head, stroke);
    final eyePaint = Paint()..color = color;
    canvas.drawCircle(
      Offset(center.dx - unit * .16, center.dy + unit * .08),
      unit * .055,
      eyePaint,
    );
    canvas.drawCircle(
      Offset(center.dx + unit * .16, center.dy + unit * .08),
      unit * .055,
      eyePaint,
    );
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(center.dx, center.dy + unit * .10),
        width: unit * .32,
        height: unit * .22,
      ),
      0,
      math.pi,
      false,
      stroke,
    );
    canvas.drawLine(
      Offset(center.dx + unit * .14, center.dy - unit * .19),
      Offset(center.dx + unit * .29, center.dy - unit * .38),
      stroke,
    );
    canvas.drawCircle(
      Offset(center.dx + unit * .31, center.dy - unit * .40),
      unit * .06,
      fill,
    );
  }

  void _browser(Canvas canvas, Offset center, double unit, Paint stroke) {
    canvas.drawCircle(center, unit * .38, stroke);
    canvas.drawOval(
      Rect.fromCenter(center: center, width: unit * .34, height: unit * .76),
      stroke,
    );
    canvas.drawLine(
      Offset(center.dx - unit * .34, center.dy),
      Offset(center.dx + unit * .34, center.dy),
      stroke,
    );
  }

  void _games(
    Canvas canvas,
    Offset center,
    double unit,
    Paint stroke,
    Paint fill,
  ) {
    final body = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center, width: unit * .82, height: unit * .46),
      Radius.circular(unit * .20),
    );
    canvas.drawRRect(body, stroke);
    canvas.drawLine(
      Offset(center.dx - unit * .22, center.dy),
      Offset(center.dx - unit * .04, center.dy),
      stroke,
    );
    canvas.drawLine(
      Offset(center.dx - unit * .13, center.dy - unit * .09),
      Offset(center.dx - unit * .13, center.dy + unit * .09),
      stroke,
    );
    canvas.drawCircle(
      Offset(center.dx + unit * .19, center.dy - unit * .07),
      unit * .04,
      fill,
    );
    canvas.drawCircle(
      Offset(center.dx + unit * .28, center.dy + unit * .07),
      unit * .04,
      fill,
    );
  }

  void _other(Canvas canvas, Offset center, double unit, Paint fill) {
    for (final dx in [-.20, 0.0, .20]) {
      canvas.drawCircle(
        Offset(center.dx + unit * dx, center.dy),
        unit * .075,
        fill,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DistractionAppIconPainter oldDelegate) {
    return oldDelegate.type != type || oldDelegate.color != color;
  }
}
