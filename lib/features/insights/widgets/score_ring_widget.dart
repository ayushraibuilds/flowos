import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../features/xp/models/daily_score_calculator.dart';

/// Segment categories for the Score Ring.
enum ScorePillar { focus, intent, attention, care }

class ScoreRingWidget extends StatefulWidget {
  final DailyScoreResult result;
  final ValueChanged<ScorePillar>? onPillarTapped;
  final ScorePillar? selectedPillar;

  const ScoreRingWidget({
    super.key,
    required this.result,
    this.onPillarTapped,
    this.selectedPillar,
  });

  @override
  State<ScoreRingWidget> createState() => _ScoreRingWidgetState();
}

class _ScoreRingWidgetState extends State<ScoreRingWidget> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _revealAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _revealAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );

    final reduceMotion = WidgetsBinding.instance.platformDispatcher.accessibilityFeatures.disableAnimations;
    if (reduceMotion) {
      _animController.value = 1.0;
    } else {
      _animController.forward();
    }
  }

  @override
  void didUpdateWidget(covariant ScoreRingWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    if (reduceMotion) {
      _animController.value = 1.0;
    } else if (_animController.value < 1.0) {
      _animController.forward();
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _revealAnimation,
      builder: (context, child) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 220,
              height: 220,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Outer segments
                  GestureDetector(
                    onTapDown: (details) => _handleTap(details, context),
                    child: CustomPaint(
                      size: const Size(220, 220),
                      painter: _ScoreRingPainter(
                        result: widget.result,
                        revealProgress: _revealAnimation.value,
                        selectedPillar: widget.selectedPillar,
                      ),
                    ),
                  ),
                  // Score & grade center display
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (widget.result.isIncomplete) ...[
                        const Text(
                          '—',
                          style: TextStyle(
                            fontSize: 54,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ] else ...[
                        Text(
                          widget.result.grade ?? '—',
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: widget.result.grade != null
                                ? AppColors.gradeColor(widget.result.grade!)
                                : AppColors.textPrimary,
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        '${widget.result.score}',
                        style: AppTypography.monoSmall.copyWith(
                          fontSize: 24,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            // Coverage state label
            Text(
              widget.result.coverageLabel,
              style: AppTypography.bodySmall.copyWith(
                color: widget.result.isIncomplete ? AppColors.warningAmber : AppColors.emerald,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        );
      },
    );
  }

  void _handleTap(TapDownDetails details, BuildContext context) {
    if (widget.onPillarTapped == null) return;
    
    // Determine which sector was tapped based on angle from center
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final center = Offset(renderBox.size.width / 2, renderBox.size.height / 2);
    final tapPosition = renderBox.globalToLocal(details.globalPosition);
    final dx = tapPosition.dx - center.dx;
    final dy = tapPosition.dy - center.dy;
    
    // Calculate angle in radians: -pi to pi (starting from x axis)
    double angle = math.atan2(dy, dx);
    // Convert to 0 to 2*pi range
    if (angle < 0) angle += 2 * math.pi;

    // Map angle to score segments (starting at -90 degrees / 1.5*pi)
    // Adjust by adding pi/2 to align with top
    double adjustedAngle = angle + (math.pi / 2);
    if (adjustedAngle >= 2 * math.pi) adjustedAngle -= 2 * math.pi;

    // Segments:
    // Focus: Top to Right (0 to pi/2)
    // Intent: Right to Bottom (pi/2 to pi)
    // Attention: Bottom to Left (pi to 1.5*pi)
    // Care: Left to Top (1.5*pi to 2*pi)
    if (adjustedAngle < math.pi / 2) {
      widget.onPillarTapped!(ScorePillar.focus);
    } else if (adjustedAngle < math.pi) {
      widget.onPillarTapped!(ScorePillar.intent);
    } else if (adjustedAngle < 1.5 * math.pi) {
      widget.onPillarTapped!(ScorePillar.attention);
    } else {
      widget.onPillarTapped!(ScorePillar.care);
    }
  }
}

class _ScoreRingPainter extends CustomPainter {
  final DailyScoreResult result;
  final double revealProgress;
  final ScorePillar? selectedPillar;

  _ScoreRingPainter({
    required this.result,
    required this.revealProgress,
    this.selectedPillar,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 12;
    const strokeWidth = 10.0;

    // Angles config (with small gaps of 6 degrees = ~0.105 rad)
    const gapAngle = 0.08;
    const segmentSweep = (math.pi / 2) - gapAngle;

    // Start angles for the 4 segments (starting at top / -pi/2)
    const double startFocus = -math.pi / 2 + gapAngle / 2;
    const double startIntent = 0.0 + gapAngle / 2;
    const double startCare = math.pi / 2 + gapAngle / 2;
    const double startAttention = math.pi + gapAngle / 2;

    // Focus Pillar (Focus points raw range is 0-35)
    final double focusPercent = (result.focusPoints / 0.35) / 100.0;
    _drawSegment(
      canvas, center, radius, strokeWidth,
      startAngle: startFocus,
      sweepAngle: segmentSweep,
      fillPercent: focusPercent * revealProgress,
      color: AppColors.focusBlue,
      isSelected: selectedPillar == ScorePillar.focus,
    );

    // Intent Pillar (Intent points raw range is 0-25)
    final double intentPercent = (result.intentPoints / 0.25) / 100.0;
    _drawSegment(
      canvas, center, radius, strokeWidth,
      startAngle: startIntent,
      sweepAngle: segmentSweep,
      fillPercent: intentPercent * revealProgress,
      color: AppColors.emerald,
      isSelected: selectedPillar == ScorePillar.intent,
    );

    // Care Pillar (Care points raw range is 0-15)
    final double carePercent = (result.carePoints / 0.15) / 100.0;
    _drawSegment(
      canvas, center, radius, strokeWidth,
      startAngle: startCare,
      sweepAngle: segmentSweep,
      fillPercent: carePercent * revealProgress,
      color: AppColors.recoveryTeal,
      isSelected: selectedPillar == ScorePillar.care,
    );

    // Attention Pillar (Attention points raw range is 0-25, or omitted)
    if (result.isIncomplete || result.attentionPoints == null) {
      // Draw as a dashed gray track with no fill
      _drawDashedSegment(
        canvas, center, radius, strokeWidth,
        startAngle: startAttention,
        sweepAngle: segmentSweep,
        color: AppColors.textTertiary.withValues(alpha: 0.25),
        isSelected: selectedPillar == ScorePillar.attention,
      );
    } else {
      final double attentionPercent = (result.attentionPoints! / 0.25) / 100.0;
      _drawSegment(
        canvas, center, radius, strokeWidth,
        startAngle: startAttention,
        sweepAngle: segmentSweep,
        fillPercent: attentionPercent * revealProgress,
        color: AppColors.warningAmber,
        isSelected: selectedPillar == ScorePillar.attention,
      );
    }
  }

  void _drawSegment(
    Canvas canvas, Offset center, double radius, double strokeWidth, {
    required double startAngle,
    required double sweepAngle,
    required double fillPercent,
    required Color color,
    required bool isSelected,
  }) {
    // 1. Draw track background
    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = isSelected ? strokeWidth + 4 : strokeWidth
      ..color = color.withValues(alpha: 0.08)
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      trackPaint,
    );

    // 2. Draw active fill
    if (fillPercent > 0) {
      final fillPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? strokeWidth + 4 : strokeWidth
        ..color = color
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle * fillPercent.clamp(0.0, 1.0),
        false,
        fillPaint,
      );
    }
  }

  void _drawDashedSegment(
    Canvas canvas, Offset center, double radius, double strokeWidth, {
    required double startAngle,
    required double sweepAngle,
    required Color color,
    required bool isSelected,
  }) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = isSelected ? strokeWidth + 3 : strokeWidth - 2
      ..color = color
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromCircle(center: center, radius: radius);
    
    // Draw arc with dash pattern
    const int dashCount = 8;
    final dashSweep = sweepAngle / (dashCount * 2 - 1);

    for (int i = 0; i < dashCount; i++) {
      final start = startAngle + (i * 2 * dashSweep);
      canvas.drawArc(rect, start, dashSweep, false, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ScoreRingPainter oldDelegate) {
    return oldDelegate.result != result ||
        oldDelegate.revealProgress != revealProgress ||
        oldDelegate.selectedPillar != selectedPillar;
  }
}
