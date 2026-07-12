import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

/// Immersive visual box breathing guide.
/// 4s Inhale → 4s Hold → 4s Exhale → 4s Hold
class BreathingHelper extends StatefulWidget {
  const BreathingHelper({super.key});

  @override
  State<BreathingHelper> createState() => _BreathingHelperState();
}

class _BreathingHelperState extends State<BreathingHelper>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // 16 seconds for a full box breathing cycle
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 16),
    )..repeat();

    // Trigger soft haptic feedback at the start of each phase
    _controller.addListener(() {
      final progress = _controller.value;
      // 0.0, 0.25, 0.5, 0.75 represent phase boundaries
      if ((progress >= 0.0 && progress < 0.01) ||
          (progress >= 0.25 && progress < 0.26) ||
          (progress >= 0.50 && progress < 0.51) ||
          (progress >= 0.75 && progress < 0.76)) {
        HapticFeedback.mediumImpact();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.background2,
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.04),
          width: 0.5,
        ),
      ),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final val = _controller.value;
          final String phaseText;
          final double scale;
          final double glowOpacity;

          if (val < 0.25) {
            // Inhale (0s to 4s)
            phaseText = 'Inhale... 🌤️';
            final ratio = val / 0.25;
            scale = 0.4 + (0.6 * ratio);
            glowOpacity = 0.1 * ratio;
          } else if (val < 0.50) {
            // Hold (4s to 8s)
            phaseText = 'Hold... ⚡';
            scale = 1.0;
            // Pulsing glow during hold
            final ratio = (val - 0.25) / 0.25;
            glowOpacity = 0.1 + 0.1 * math.sin(ratio * math.pi);
          } else if (val < 0.75) {
            // Exhale (8s to 12s)
            phaseText = 'Exhale... 🍃';
            final ratio = (val - 0.50) / 0.25;
            scale = 1.0 - (0.6 * ratio);
            glowOpacity = 0.2 * (1.0 - ratio);
          } else {
            // Hold (12s to 16s)
            phaseText = 'Hold... 🧘';
            scale = 0.4;
            glowOpacity = 0.0;
          }

          return Column(
            children: [
              Text(
                'Box Breathing',
                style: AppTypography.h3.copyWith(color: AppColors.textPrimary),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Calm your nervous system and restore focus',
                style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),
              // Breathing ring circle
              SizedBox(
                height: 140,
                child: Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Outer glowing circle
                      Container(
                        width: 120 * scale,
                        height: 120 * scale,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.emerald.withValues(alpha: glowOpacity),
                          boxShadow: [
                            if (glowOpacity > 0)
                              BoxShadow(
                                color: AppColors.emerald.withValues(alpha: glowOpacity),
                                blurRadius: 20 * scale,
                                spreadRadius: 5 * scale,
                              ),
                          ],
                        ),
                      ),
                      // Core breathing ring
                      Container(
                        width: 100 * scale,
                        height: 100 * scale,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.emerald,
                            width: 3.5,
                          ),
                          color: AppColors.emerald.withValues(alpha: 0.08),
                        ),
                        child: Center(
                          child: Text(
                            '${((val % 0.25) / 0.25 * 4).floor() + 1}',
                            style: AppTypography.monoSmall.copyWith(
                              color: AppColors.emerald,
                              fontWeight: FontWeight.bold,
                              fontSize: 16 * scale,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                phaseText,
                style: AppTypography.body.copyWith(
                  color: AppColors.emerald,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
