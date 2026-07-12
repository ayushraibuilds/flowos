import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../features/flow_garden/providers/garden_providers.dart';
import '../../widgets/flow_surface.dart';

/// Immersive visual garden representing lifetime focus hours.
class GardenScreen extends ConsumerStatefulWidget {
  const GardenScreen({super.key});

  @override
  ConsumerState<GardenScreen> createState() => _GardenScreenState();
}

class _BreakStage {
  final int minMinutes;
  final String name;
  final String emoji;
  final String description;

  const _BreakStage({
    required this.minMinutes,
    required this.name,
    required this.emoji,
    required this.description,
  });
}

class _GardenScreenState extends ConsumerState<GardenScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _swayController;

  static const List<_BreakStage> stages = [
    _BreakStage(
      minMinutes: 0,
      name: 'Seed',
      emoji: '🌱',
      description: 'Your focus journey is beginning. Cultivate daily habits to sprout.',
    ),
    _BreakStage(
      minMinutes: 60,
      name: 'Sprout',
      emoji: '🌿',
      description: 'First leaves have appeared! You are showing showing up consistently.',
    ),
    _BreakStage(
      minMinutes: 300,
      name: 'Sapling',
      emoji: '🌳',
      description: 'Branches are forming. Your resilience and focus block are solid.',
    ),
    _BreakStage(
      minMinutes: 1200,
      name: 'Flow Tree',
      emoji: '🌲',
      description: 'A mature tree with deep roots. You command your time and energy.',
    ),
    _BreakStage(
      minMinutes: 4800,
      name: 'Golden Grove',
      emoji: '✨',
      description: 'A legendary grove of calm. You have entered the state of flow mastery.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _swayController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _swayController.dispose();
    super.dispose();
  }

  _BreakStage _getStage(int minutes) {
    for (int i = stages.length - 1; i >= 0; i--) {
      if (minutes >= stages[i].minMinutes) {
        return stages[i];
      }
    }
    return stages.first;
  }

  @override
  Widget build(BuildContext context) {
    final focusMinutesAsync = ref.watch(lifetimeFocusMinutesProvider);

    return Scaffold(
      backgroundColor: AppColors.background0,
      body: focusMinutesAsync.when(
        data: (minutes) {
          final stage = _getStage(minutes);
          final hours = minutes ~/ 60;
          final remainingMins = minutes % 60;

          return Stack(
            children: [
              // ─── Visual Canvas ─────────────────────────────────────
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _swayController,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: GardenPainter(
                        swayValue: _swayController.value,
                        focusMinutes: minutes,
                        emeraldColor: AppColors.emerald,
                        accentColor: AppColors.emerald.withValues(alpha: 0.8),
                        backgroundColor: AppColors.background0,
                      ),
                    );
                  },
                ),
              ),

              // ─── Overlay UI ────────────────────────────────────────
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => context.pop(),
                            icon: const Icon(Icons.arrow_back_ios_new_rounded),
                            color: AppColors.textPrimary,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            'Flow Garden',
                            style: AppTypography.h1.copyWith(
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Garden state card
                      FlowSurface(
                        variant: FlowSurfaceVariant.standard,
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  stage.emoji,
                                  style: const TextStyle(fontSize: 28),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Text(
                                  stage.name,
                                  style: AppTypography.h2.copyWith(
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.md,
                                    vertical: AppSpacing.xs,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.emerald.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(
                                      AppSpacing.radiusPill,
                                    ),
                                    border: Border.all(
                                      color: AppColors.emerald.withValues(alpha: 0.3),
                                      width: 0.5,
                                    ),
                                  ),
                                  child: Text(
                                    '${hours}h ${remainingMins}m',
                                    style: AppTypography.monoSmall.copyWith(
                                      color: AppColors.emerald,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              stage.description,
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (e, s) => Center(
          child: Text(
            'Error loading garden: $e',
            style: const TextStyle(color: Colors.red),
          ),
        ),
      ),
    );
  }
}

/// Custom Painter drawing growth phases and wind sway.
class GardenPainter extends CustomPainter {
  final double swayValue;
  final int focusMinutes;
  final Color emeraldColor;
  final Color accentColor;
  final Color backgroundColor;

  GardenPainter({
    required this.swayValue,
    required this.focusMinutes,
    required this.emeraldColor,
    required this.accentColor,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..isAntiAlias = true
      ..strokeCap = StrokeCap.round;

    final centerX = size.width / 2;
    final bottomY = size.height * 0.85;

    // Draw background gradient sky
    final skyGradient = LinearGradient(
      colors: [
        backgroundColor,
        backgroundColor.withValues(alpha: 0.6),
      ],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );
    canvas.drawRect(
      Offset.zero & size,
      Paint()..shader = skyGradient.createShader(Offset.zero & size),
    );

    // Draw Soil
    final soilPath = Path()
      ..moveTo(0, bottomY + 20)
      ..quadraticBezierTo(centerX, bottomY, size.width, bottomY + 20)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(
      soilPath,
      Paint()
        ..color = Color.lerp(backgroundColor, Colors.brown, 0.08) ?? Colors.black,
    );

    // Soil boundary line
    canvas.drawPath(
      soilPath,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.05)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    // Wind sway calculation
    final swayAngle = (math.sin(swayValue * math.pi * 2) * 0.04);

    if (focusMinutes < 60) {
      // ─── STAGE 1: Seed ───────────────────────────────────────
      final seedX = centerX;
      final seedY = bottomY + 5;
      canvas.drawOval(
        Rect.fromCenter(center: Offset(seedX, seedY), width: 12, height: 8),
        Paint()..color = Colors.brown.shade400,
      );
      canvas.drawOval(
        Rect.fromCenter(center: Offset(seedX, seedY), width: 8, height: 5),
        Paint()..color = emeraldColor.withValues(alpha: 0.6),
      );
    } else if (focusMinutes < 300) {
      // ─── STAGE 2: Sprout ─────────────────────────────────────
      final stemPath = Path()
        ..moveTo(centerX, bottomY)
        ..quadraticBezierTo(
          centerX + swayAngle * 100,
          bottomY - 40,
          centerX + swayAngle * 120,
          bottomY - 80,
        );

      canvas.drawPath(
        stemPath,
        paint
          ..color = emeraldColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );

      // Leaves
      final topX = centerX + swayAngle * 120;
      final topY = bottomY - 80;

      // Left leaf
      canvas.save();
      canvas.translate(topX, topY);
      canvas.rotate(-math.pi / 4 + swayAngle);
      canvas.drawOval(
        const Rect.fromLTWH(0, -6, 16, 12),
        Paint()..color = emeraldColor,
      );
      canvas.restore();

      // Right leaf
      canvas.save();
      canvas.translate(topX, topY);
      canvas.rotate(math.pi / 4 + swayAngle);
      canvas.drawOval(
        const Rect.fromLTWH(-16, -6, 16, 12),
        Paint()..color = emeraldColor,
      );
      canvas.restore();
    } else if (focusMinutes < 1200) {
      // ─── STAGE 3: Sapling ────────────────────────────────────
      final trunkPath = Path()
        ..moveTo(centerX, bottomY)
        ..quadraticBezierTo(
          centerX + swayAngle * 80,
          bottomY - 60,
          centerX + swayAngle * 100,
          bottomY - 120,
        );

      canvas.drawPath(
        trunkPath,
        paint
          ..color = Colors.brown.shade600
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6,
      );

      // Left branch
      final forkX = centerX + swayAngle * 100;
      final forkY = bottomY - 120;

      canvas.drawPath(
        Path()
          ..moveTo(forkX, forkY)
          ..quadraticBezierTo(
            forkX - 30 + swayAngle * 40,
            forkY - 40,
            forkX - 50 + swayAngle * 60,
            forkY - 60,
          ),
        paint
          ..color = Colors.brown.shade600
          ..strokeWidth = 3,
      );

      // Right branch
      canvas.drawPath(
        Path()
          ..moveTo(forkX, forkY)
          ..quadraticBezierTo(
            forkX + 30 + swayAngle * 40,
            forkY - 40,
            forkX + 50 + swayAngle * 60,
            forkY - 60,
          ),
        paint..strokeWidth = 3,
      );

      // Foliage clusters
      canvas.drawCircle(
        Offset(forkX - 50 + swayAngle * 60, forkY - 60),
        16,
        Paint()..color = emeraldColor.withValues(alpha: 0.9),
      );
      canvas.drawCircle(
        Offset(forkX + 50 + swayAngle * 60, forkY - 60),
        16,
        Paint()..color = emeraldColor.withValues(alpha: 0.9),
      );
      canvas.drawCircle(
        Offset(forkX + swayAngle * 20, forkY - 30),
        12,
        Paint()..color = accentColor.withValues(alpha: 0.8),
      );
    } else if (focusMinutes < 4800) {
      // ─── STAGE 4: Flow Tree ──────────────────────────────────
      _drawTree(canvas, paint, centerX, bottomY, swayAngle, scale: 1.0, isGolden: false);
    } else {
      // ─── STAGE 5: Golden Grove ───────────────────────────────
      // Draw background smaller left tree
      _drawTree(canvas, paint, centerX - 80, bottomY + 10, swayAngle * 0.8, scale: 0.7, isGolden: true);
      // Draw background smaller right tree
      _drawTree(canvas, paint, centerX + 80, bottomY + 10, swayAngle * 0.9, scale: 0.7, isGolden: true);
      // Draw primary main tree
      _drawTree(canvas, paint, centerX, bottomY, swayAngle, scale: 1.1, isGolden: true);

      // Draw floating golden aura particles
      final rng = math.Random(42);
      for (int i = 0; i < 20; i++) {
        final double x = size.width * rng.nextDouble();
        final double yBase = bottomY - 50 - (rng.nextDouble() * 200);
        // Animate floating up/down
        final double y = yBase - (swayValue * 20);
        final double radius = 2 + rng.nextDouble() * 4;

        canvas.drawCircle(
          Offset(x, y),
          radius,
          Paint()
            ..color = Colors.amber.withValues(alpha: 0.3 + (math.sin(swayValue * math.pi) * 0.2))
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
        );
      }
    }
  }

  void _drawTree(
    Canvas canvas,
    Paint paint,
    double startX,
    double startY,
    double swayAngle, {
    required double scale,
    required bool isGolden,
  }) {
    final leafColor = isGolden ? Colors.amber.shade300 : emeraldColor;
    final secondLeafColor = isGolden ? Colors.yellow.shade600 : accentColor;

    // Draw main trunk
    final double trunkTopX = startX + swayAngle * 120 * scale;
    final double trunkTopY = startY - 160 * scale;

    final trunkPath = Path()
      ..moveTo(startX - 10 * scale, startY)
      ..lineTo(startX + 10 * scale, startY)
      ..quadraticBezierTo(
        startX + 6 * scale + swayAngle * 60 * scale,
        startY - 80 * scale,
        trunkTopX + 4 * scale,
        trunkTopY,
      )
      ..lineTo(trunkTopX - 4 * scale, trunkTopY)
      ..quadraticBezierTo(
        startX - 6 * scale + swayAngle * 60 * scale,
        startY - 80 * scale,
        startX - 10 * scale,
        startY,
      )
      ..close();

    canvas.drawPath(
      trunkPath,
      Paint()..color = Colors.brown.shade700,
    );

    // Left primary branch
    final leftForkX = trunkTopX - 40 * scale + swayAngle * 40 * scale;
    final leftForkY = trunkTopY - 50 * scale;
    canvas.drawPath(
      Path()
        ..moveTo(trunkTopX, trunkTopY + 10)
        ..quadraticBezierTo(
          trunkTopX - 20 * scale,
          trunkTopY - 20 * scale,
          leftForkX,
          leftForkY,
        ),
      paint
        ..color = Colors.brown.shade700
        ..strokeWidth = 5 * scale,
    );

    // Right primary branch
    final rightForkX = trunkTopX + 40 * scale + swayAngle * 40 * scale;
    final rightForkY = trunkTopY - 50 * scale;
    canvas.drawPath(
      Path()
        ..moveTo(trunkTopX, trunkTopY + 10)
        ..quadraticBezierTo(
          trunkTopX + 20 * scale,
          trunkTopY - 20 * scale,
          rightForkX,
          rightForkY,
        ),
      paint..strokeWidth = 5 * scale,
    );

    // Top central branch
    final centerForkX = trunkTopX + swayAngle * 30 * scale;
    final centerForkY = trunkTopY - 80 * scale;
    canvas.drawPath(
      Path()
        ..moveTo(trunkTopX, trunkTopY)
        ..quadraticBezierTo(
          trunkTopX,
          trunkTopY - 40 * scale,
          centerForkX,
          centerForkY,
        ),
      paint..strokeWidth = 4 * scale,
    );

    // Foliage clusters - overlapping transparent circles for organic depth
    final leafPaint = Paint()..color = leafColor.withValues(alpha: 0.85);
    final shadowLeafPaint = Paint()..color = secondLeafColor.withValues(alpha: 0.70);

    // Left foliage
    canvas.drawCircle(Offset(leftForkX, leftForkY), 32 * scale, shadowLeafPaint);
    canvas.drawCircle(Offset(leftForkX - 10 * scale, leftForkY - 15 * scale), 24 * scale, leafPaint);
    canvas.drawCircle(Offset(leftForkX + 15 * scale, leftForkY - 20 * scale), 20 * scale, leafPaint);

    // Right foliage
    canvas.drawCircle(Offset(rightForkX, rightForkY), 32 * scale, shadowLeafPaint);
    canvas.drawCircle(Offset(rightForkX + 10 * scale, rightForkY - 15 * scale), 24 * scale, leafPaint);
    canvas.drawCircle(Offset(rightForkX - 15 * scale, rightForkY - 20 * scale), 20 * scale, leafPaint);

    // Center foliage
    canvas.drawCircle(Offset(centerForkX, centerForkY), 36 * scale, shadowLeafPaint);
    canvas.drawCircle(Offset(centerForkX, centerForkY - 20 * scale), 28 * scale, leafPaint);
    canvas.drawCircle(Offset(centerForkX - 18 * scale, centerForkY - 10 * scale), 22 * scale, leafPaint);
    canvas.drawCircle(Offset(centerForkX + 18 * scale, centerForkY - 10 * scale), 22 * scale, leafPaint);

    // Additional glowing aura for golden grove
    if (isGolden) {
      canvas.drawCircle(
        Offset(centerForkX, centerForkY - 10 * scale),
        60 * scale,
        Paint()
          ..color = Colors.amber.withValues(alpha: 0.08)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 12 * scale),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
