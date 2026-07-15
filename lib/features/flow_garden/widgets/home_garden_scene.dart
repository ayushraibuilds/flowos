import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/motion_tokens.dart';
import '../models/garden_day.dart';

/// A lightweight, code-native illustration for the Home Garden.
///
/// This deliberately derives every visual state from [GardenDay] instead of
/// persisting an additional pet, score, or animation state. It can later be
/// replaced with commissioned layered artwork without changing its API.
class HomeGardenScene extends StatefulWidget {
  final GardenDay day;
  final VoidCallback onFocusTap;
  final VoidCallback onRecoveryTap;
  final VoidCallback onGardenTap;
  final bool isHero;

  const HomeGardenScene({
    super.key,
    required this.day,
    required this.onFocusTap,
    required this.onRecoveryTap,
    required this.onGardenTap,
    this.isHero = false,
  });

  @override
  State<HomeGardenScene> createState() => _HomeGardenSceneState();
}

class _HomeGardenSceneState extends State<HomeGardenScene>
    with TickerProviderStateMixin {
  late final AnimationController _idleController;
  late final AnimationController _eventController;
  _GardenSceneEvent _event = _GardenSceneEvent.none;
  bool _reduceMotion = false;
  bool _actionInFlight = false;

  @override
  void initState() {
    super.initState();
    _idleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7),
    )..repeat();
    _eventController = AnimationController(
      vsync: this,
      duration: MotionTokens.celebration,
    )
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) {
          setState(() => _event = _GardenSceneEvent.none);
        }
      });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    if (reduceMotion == _reduceMotion) return;
    _reduceMotion = reduceMotion;
    if (_reduceMotion) {
      _idleController.stop();
      _eventController.stop();
    } else {
      _idleController.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant HomeGardenScene oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_reduceMotion) return;

    final oldFocusIds = _focusObjectIds(oldWidget.day);
    final newFocusIds = _focusObjectIds(widget.day);
    if (newFocusIds.difference(oldFocusIds).isNotEmpty) {
      _play(_GardenSceneEvent.growth);
    } else if (widget.day.recoveryCount > oldWidget.day.recoveryCount) {
      _play(_GardenSceneEvent.recovery);
    }
  }

  Set<String> _focusObjectIds(GardenDay day) => day.objects
      .where(
        (object) =>
            object.kind == GardenObjectKind.tree ||
            object.kind == GardenObjectKind.flower,
      )
      .map((object) => object.id)
      .toSet();

  void _play(_GardenSceneEvent event) {
    if (_reduceMotion) return;
    setState(() => _event = event);
    _eventController.forward(from: 0);
  }

  Future<void> _openFocus() async {
    if (_actionInFlight) return;
    _actionInFlight = true;
    HapticFeedback.selectionClick();
    _play(_GardenSceneEvent.tend);
    await Future<void>.delayed(MotionTokens.quick);
    if (mounted) widget.onFocusTap();
    _actionInFlight = false;
  }

  Future<void> _openRecovery() async {
    if (_actionInFlight) return;
    _actionInFlight = true;
    HapticFeedback.selectionClick();
    _play(_GardenSceneEvent.recovery);
    await Future<void>.delayed(MotionTokens.quick);
    if (mounted) widget.onRecoveryTap();
    _actionInFlight = false;
  }

  @override
  void dispose() {
    _idleController.dispose();
    _eventController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasCompanion = widget.day.objects.any(
      (object) => object.kind == GardenObjectKind.wildlife,
    );
    final isThirsty = widget.day.vitality == GardenVitality.thirsty;
    final actionLabel = isThirsty ? 'Offer a two-minute reset' : 'Start focus';

    return Semantics(
      container: true,
      label: 'Today’s Garden. ${widget.day.headline}. '
          '${widget.day.supportingText}',
      child: Container(
        height: widget.isHero ? double.infinity : 188,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: widget.isHero
              ? const BorderRadius.vertical(bottom: Radius.circular(AppSpacing.radiusCard))
              : BorderRadius.circular(AppSpacing.radiusCard),
          border: widget.isHero
              ? null
              : Border.all(color: AppColors.emerald.withValues(alpha: 0.26)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.20),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: AnimatedBuilder(
          animation: Listenable.merge([_idleController, _eventController]),
          builder: (context, _) {
            final idle = _reduceMotion ? 0.0 : _idleController.value;
            final event = _reduceMotion ? 0.0 : _eventController.value;
            return Stack(
              children: [
                Positioned.fill(
                  child: RepaintBoundary(
                    child: CustomPaint(
                      painter: _HomeGardenPainter(
                        vitality: widget.day.vitality,
                        hasCompanion: hasCompanion,
                        idleValue: idle,
                        eventValue: event,
                        event: _event,
                      ),
                    ),
                  ),
                ),
                if (!widget.isHero) ...[
                  Positioned(
                    top: AppSpacing.md,
                    left: AppSpacing.lg,
                    right: 74,
                    child: IgnorePointer(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.day.headline,
                            style: AppTypography.h3.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            widget.day.supportingText,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 6,
                    right: 4,
                    child: Semantics(
                      button: true,
                      label: 'Open full Garden',
                      child: IconButton(
                        onPressed: widget.onGardenTap,
                        tooltip: 'Open Garden',
                        color: AppColors.emerald,
                        icon: const Icon(Icons.arrow_outward_rounded),
                      ),
                    ),
                  ),
                ],
                Align(
                  alignment: const Alignment(-0.10, 0.30),
                  child: Semantics(
                    button: true,
                    label: '$actionLabel with your garden',
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _openFocus,
                      child: const SizedBox(width: 136, height: 122),
                    ),
                  ),
                ),
                if (hasCompanion)
                  Align(
                    alignment: const Alignment(0.58, 0.02),
                    child: Semantics(
                      button: true,
                      label: 'Spend two minutes recovering with your companion',
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: _openRecovery,
                        child: const SizedBox(width: 64, height: 64),
                      ),
                    ),
                  ),
                if (isThirsty)
                  Align(
                    alignment: const Alignment(0.68, 0.63),
                    child: Semantics(
                      button: true,
                      label: 'Offer a two-minute reset',
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: _openRecovery,
                        child: const SizedBox(width: 58, height: 54),
                      ),
                    ),
                  ),
                if (!widget.isHero)
                  Positioned(
                    left: AppSpacing.lg,
                    bottom: AppSpacing.sm,
                    child: IgnorePointer(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.20),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          isThirsty
                              ? 'A small reset is enough'
                              : 'Tap the plant to focus',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textPrimary.withValues(alpha: 0.88),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

enum _GardenSceneEvent { none, tend, growth, recovery }

class _HomeGardenPainter extends CustomPainter {
  final GardenVitality vitality;
  final bool hasCompanion;
  final double idleValue;
  final double eventValue;
  final _GardenSceneEvent event;

  const _HomeGardenPainter({
    required this.vitality,
    required this.hasCompanion,
    required this.idleValue,
    required this.eventValue,
    required this.event,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    final profile = _GardenProfile.forVitality(vitality);
    final idleWave = math.sin(idleValue * math.pi * 2);
    final eventPulse = math.sin(eventValue * math.pi);
    final centerX = size.width * 0.47;
    final soilY = size.height * 0.79;
    final plantHeight = size.height * profile.height;
    final plantScale = 1.0 +
        (event == _GardenSceneEvent.growth ? eventPulse * 0.16 : 0.0) +
        (event == _GardenSceneEvent.tend ? eventPulse * 0.04 : 0.0);

    canvas.drawRect(
      bounds,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF0D2B37), Color(0xFF102119), Color(0xFF151817)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(bounds),
    );

    canvas.drawCircle(
      Offset(size.width * 0.80, size.height * 0.08),
      size.height * 0.38,
      Paint()..color = profile.glow.withValues(alpha: 0.16),
    );
    canvas.drawCircle(
      Offset(size.width * 0.83, size.height * 0.12),
      size.height * 0.045,
      Paint()..color = const Color(0xFFE6F4EA).withValues(alpha: 0.72),
    );

    _drawStars(canvas, size, profile.glow);
    _drawSoil(canvas, size, soilY);
    _drawPlant(
      canvas,
      Offset(centerX, soilY),
      plantHeight,
      profile,
      idleWave,
      plantScale,
    );

    if (vitality == GardenVitality.resting) {
      _drawRestingRoots(canvas, Offset(centerX, soilY), profile.glow);
    }
    if (vitality == GardenVitality.thirsty ||
        vitality == GardenVitality.recovering ||
        event == _GardenSceneEvent.recovery) {
      _drawWater(canvas, size, eventPulse);
    }
    if (hasCompanion) {
      _drawCompanion(canvas, size, idleWave, eventPulse);
    }
  }

  void _drawStars(Canvas canvas, Size size, Color glow) {
    final stars = <Offset>[
      Offset(size.width * 0.12, size.height * 0.22),
      Offset(size.width * 0.28, size.height * 0.12),
      Offset(size.width * 0.66, size.height * 0.24),
      Offset(size.width * 0.92, size.height * 0.35),
    ];
    final pulse = 0.55 + math.sin(idleValue * math.pi * 2) * 0.18;
    for (final star in stars) {
      canvas.drawCircle(
        star,
        1.4,
        Paint()..color = glow.withValues(alpha: pulse),
      );
    }
  }

  void _drawSoil(Canvas canvas, Size size, double soilY) {
    final soil = Path()
      ..moveTo(-10, soilY + size.height * 0.23)
      ..quadraticBezierTo(
        size.width * 0.22,
        soilY - size.height * 0.15,
        size.width * 0.50,
        soilY + size.height * 0.01,
      )
      ..quadraticBezierTo(
        size.width * 0.78,
        soilY - size.height * 0.12,
        size.width + 10,
        soilY + size.height * 0.20,
      )
      ..lineTo(size.width + 10, size.height + 10)
      ..lineTo(-10, size.height + 10)
      ..close();
    canvas.drawPath(soil, Paint()..color = const Color(0xFF213A27));
    canvas.drawPath(
      soil,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = AppColors.emerald.withValues(alpha: 0.16),
    );
  }

  void _drawPlant(
    Canvas canvas,
    Offset base,
    double height,
    _GardenProfile profile,
    double idleWave,
    double scale,
  ) {
    canvas.save();
    canvas.translate(base.dx, base.dy);
    canvas.rotate(idleWave * 0.045);
    canvas.scale(scale);

    final stemEnd = Offset(0, -height);
    canvas.drawLine(
      Offset.zero,
      stemEnd,
      Paint()
        ..color = profile.stem
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 6,
    );
    canvas.drawLine(
      Offset(0, -height * 0.48),
      Offset(-height * 0.25, -height * 0.66),
      Paint()
        ..color = profile.stem
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 4,
    );
    canvas.drawLine(
      Offset(0, -height * 0.33),
      Offset(height * 0.24, -height * 0.48),
      Paint()
        ..color = profile.stem
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 4,
    );

    _drawLeaf(
      canvas,
      Offset(-height * 0.27, -height * 0.68),
      -0.52,
      profile.leafSize,
      profile.leaf,
    );
    _drawLeaf(
      canvas,
      Offset(height * 0.26, -height * 0.50),
      0.52,
      profile.leafSize * 0.90,
      profile.leaf.withValues(alpha: 0.94),
    );
    _drawLeaf(
      canvas,
      Offset(-height * 0.20, -height * 0.38),
      -0.62,
      profile.leafSize * 0.78,
      profile.leaf.withValues(alpha: 0.85),
    );
    if (profile.extraLeaf) {
      _drawLeaf(
        canvas,
        Offset(height * 0.18, -height * 0.77),
        0.46,
        profile.leafSize * 0.80,
        profile.leaf.withValues(alpha: 0.88),
      );
    }
    if (profile.hasFlower) {
      _drawFlower(canvas, stemEnd, profile.flower);
    } else {
      canvas.drawCircle(
        stemEnd,
        6,
        Paint()..color = profile.leaf.withValues(alpha: 0.95),
      );
    }
    canvas.restore();
  }

  void _drawLeaf(
    Canvas canvas,
    Offset center,
    double rotation,
    double scale,
    Color color,
  ) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: 34 * scale, height: 14 * scale),
      Paint()..color = color,
    );
    canvas.drawLine(
      Offset(-13 * scale, 0),
      Offset(13 * scale, 0),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.16)
        ..strokeWidth = 1,
    );
    canvas.restore();
  }

  void _drawFlower(Canvas canvas, Offset center, Color color) {
    for (var index = 0; index < 5; index++) {
      final angle = (math.pi * 2 / 5) * index;
      canvas.drawCircle(
        center + Offset(math.cos(angle) * 7, math.sin(angle) * 7),
        5.5,
        Paint()..color = color,
      );
    }
    canvas.drawCircle(center, 4, Paint()..color = AppColors.warningAmber);
  }

  void _drawRestingRoots(Canvas canvas, Offset base, Color glow) {
    canvas.drawCircle(
      base + const Offset(0, 7),
      18 + math.sin(idleValue * math.pi * 2) * 2,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = glow.withValues(alpha: 0.34),
    );
  }

  void _drawWater(Canvas canvas, Size size, double eventPulse) {
    final falling = event == _GardenSceneEvent.recovery ? eventValue : 0.48;
    final dropY = size.height * (0.26 + falling * 0.38);
    final dropX = size.width * 0.72;
    final paint = Paint()..color = AppColors.recoveryTeal.withValues(alpha: 0.90);
    final drop = Path()
      ..moveTo(dropX, dropY - 8)
      ..quadraticBezierTo(dropX - 8, dropY + 3, dropX, dropY + 12)
      ..quadraticBezierTo(dropX + 8, dropY + 3, dropX, dropY - 8)
      ..close();
    canvas.drawPath(drop, paint);
    if (event == _GardenSceneEvent.recovery) {
      canvas.drawCircle(
        Offset(size.width * 0.49, size.height * 0.78),
        18 + eventPulse * 24,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = AppColors.recoveryTeal.withValues(alpha: 0.42 * (1 - eventValue)),
      );
    }
  }

  void _drawCompanion(
    Canvas canvas,
    Size size,
    double idleWave,
    double eventPulse,
  ) {
    final x = size.width * 0.76;
    final y = size.height * 0.55 - idleWave * 4 - eventPulse * 5;
    final body = Paint()..color = const Color(0xFFFFD166);
    final wing = Paint()..color = const Color(0xFFB7F5E6).withValues(alpha: 0.85);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(x - 6, y - 1), width: 16, height: 8),
      wing,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(x + 6, y + 1), width: 16, height: 8),
      wing,
    );
    canvas.drawCircle(Offset(x, y), 6, body);
    canvas.drawCircle(Offset(x + 2, y - 1), 1.2, Paint()..color = AppColors.background0);
  }

  @override
  bool shouldRepaint(covariant _HomeGardenPainter oldDelegate) {
    return oldDelegate.vitality != vitality ||
        oldDelegate.hasCompanion != hasCompanion ||
        oldDelegate.idleValue != idleValue ||
        oldDelegate.eventValue != eventValue ||
        oldDelegate.event != event;
  }
}

class _GardenProfile {
  final double height;
  final double leafSize;
  final Color stem;
  final Color leaf;
  final Color glow;
  final Color flower;
  final bool hasFlower;
  final bool extraLeaf;

  const _GardenProfile({
    required this.height,
    required this.leafSize,
    required this.stem,
    required this.leaf,
    required this.glow,
    required this.flower,
    required this.hasFlower,
    required this.extraLeaf,
  });

  factory _GardenProfile.forVitality(GardenVitality vitality) {
    return switch (vitality) {
      GardenVitality.resting => _GardenProfile(
          height: 0.30,
          leafSize: 0.58,
          stem: const Color(0xFF4A7C5B),
          leaf: const Color(0xFF5C8B68),
          glow: AppColors.recoveryTeal,
          flower: AppColors.warningAmber,
          hasFlower: false,
          extraLeaf: false,
        ),
      GardenVitality.growing => _GardenProfile(
          height: 0.42,
          leafSize: 0.78,
          stem: const Color(0xFF3F9B64),
          leaf: const Color(0xFF67C587),
          glow: AppColors.emerald,
          flower: AppColors.warningAmber,
          hasFlower: false,
          extraLeaf: false,
        ),
      GardenVitality.flourishing => _GardenProfile(
          height: 0.52,
          leafSize: 1.10,
          stem: const Color(0xFF2E8754),
          leaf: const Color(0xFF2ECF83),
          glow: AppColors.emerald,
          flower: const Color(0xFFFF8FA3),
          hasFlower: true,
          extraLeaf: true,
        ),
      GardenVitality.thirsty => _GardenProfile(
          height: 0.38,
          leafSize: 0.75,
          stem: const Color(0xFF63745A),
          leaf: const Color(0xFF849368),
          glow: AppColors.warningAmber,
          flower: AppColors.warningAmber,
          hasFlower: false,
          extraLeaf: false,
        ),
      GardenVitality.recovering => _GardenProfile(
          height: 0.46,
          leafSize: 0.94,
          stem: const Color(0xFF328A62),
          leaf: const Color(0xFF46D3A0),
          glow: AppColors.recoveryTeal,
          flower: const Color(0xFFFFC46B),
          hasFlower: true,
          extraLeaf: true,
        ),
    };
  }
}
