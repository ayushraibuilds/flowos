import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../models/garden_day.dart';
import 'garden_object_painter.dart';

/// Shared, lightweight garden canvas used both on Home and in the full garden.
class GardenPlot extends StatelessWidget {
  final GardenDay day;
  final double height;
  final String? animateObjectId;
  final bool showCopy;

  const GardenPlot({
    super.key,
    required this.day,
    this.height = 240,
    this.animateObjectId,
    this.showCopy = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        gradient: const LinearGradient(
          colors: [Color(0xFF102A34), Color(0xFF102118), Color(0xFF171A17)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        border: Border.all(color: AppColors.emerald.withValues(alpha: 0.22)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              Positioned(
                top: -height * 0.34,
                right: -height * 0.20,
                child: Container(
                  width: height * 0.65,
                  height: height * 0.65,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.recoveryTeal.withValues(alpha: 0.10),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: -height * 0.32,
                child: Container(
                  height: height * 0.62,
                  decoration: BoxDecoration(
                    color: const Color(0xFF263321),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.elliptical(
                        constraints.maxWidth,
                        height * 0.22,
                      ),
                    ),
                  ),
                ),
              ),
              if (day.isResting)
                const Align(
                  alignment: Alignment(0, 0.22),
                  child: Text('🌙', style: TextStyle(fontSize: 38)),
                ),
              ...day.objects.map((object) {
                final isGrowing = animateObjectId == object.id;
                return Positioned(
                  left: constraints.maxWidth * object.x - 20,
                  top: height * object.y - 20,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      if (object.kind == GardenObjectKind.wildlife) {
                        context.push(
                          '/rest',
                          extra: {
                            'defaultMinutes': 2,
                            'autoStart': true,
                          },
                        );
                      } else if (object.kind == GardenObjectKind.tree ||
                          object.kind == GardenObjectKind.flower) {
                        context.push('/focus');
                      }
                    },
                    child: AnimatedScale(
                      duration: const Duration(milliseconds: 850),
                      curve: Curves.elasticOut,
                      scale: isGrowing ? 1.24 : 1,
                      child: SizedBox(
                        width: object.kind == GardenObjectKind.tree ? 48 : 36,
                        height: object.kind == GardenObjectKind.tree ? 48 : 36,
                        child: CustomPaint(
                          painter: GardenObjectPainter(
                            kind: object.kind,
                            emoji: object.emoji,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
              if (showCopy)
                Positioned(
                  left: AppSpacing.lg,
                  right: AppSpacing.lg,
                  top: AppSpacing.lg,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        day.headline,
                        style: AppTypography.h3.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        day.supportingText,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
