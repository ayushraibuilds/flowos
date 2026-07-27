import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../models/focus_timer_stage.dart';

class FocusTimerDisplay extends StatelessWidget {
  final FocusTimerPhase phase;
  final int remainingSeconds;
  final int totalSeconds;
  final String formattedTime;
  final Animation<double> breatheAnimation;
  final VoidCallback? onStart;
  final VoidCallback? onPause;
  final VoidCallback? onResume;
  final VoidCallback? onStop;

  const FocusTimerDisplay({
    super.key,
    required this.phase,
    required this.remainingSeconds,
    required this.totalSeconds,
    required this.formattedTime,
    required this.breatheAnimation,
    this.onStart,
    this.onPause,
    this.onResume,
    this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    final progress = totalSeconds > 0
        ? (remainingSeconds / totalSeconds).clamp(0.0, 1.0)
        : 0.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: breatheAnimation,
          builder: (context, child) {
            final scale = phase == FocusTimerPhase.running
                ? breatheAnimation.value
                : 1.0;
            return Transform.scale(scale: scale, child: child);
          },
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 240,
                height: 240,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 8,
                  backgroundColor: AppColors.background2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    phase == FocusTimerPhase.completing ||
                            phase == FocusTimerPhase.completed
                        ? Colors.blueAccent
                        : AppColors.emerald,
                  ),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    formattedTime,
                    style: AppTypography.h1.copyWith(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    _phaseLabel(phase),
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (phase == FocusTimerPhase.idle && onStart != null)
              ElevatedButton.icon(
                onPressed: onStart,
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Start Focus'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.emerald,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                ),
              ),
            if (phase == FocusTimerPhase.running && onPause != null) ...[
              IconButton(
                onPressed: onPause,
                iconSize: 48,
                icon: const Icon(Icons.pause_circle_filled_rounded),
                color: AppColors.emerald,
              ),
              const SizedBox(width: AppSpacing.md),
              IconButton(
                onPressed: onStop,
                iconSize: 48,
                icon: const Icon(Icons.stop_circle_rounded),
                color: AppColors.textTertiary,
              ),
            ],
            if (phase == FocusTimerPhase.paused && onResume != null) ...[
              IconButton(
                onPressed: onResume,
                iconSize: 48,
                icon: const Icon(Icons.play_circle_fill_rounded),
                color: AppColors.emerald,
              ),
              const SizedBox(width: AppSpacing.md),
              IconButton(
                onPressed: onStop,
                iconSize: 48,
                icon: const Icon(Icons.stop_circle_rounded),
                color: AppColors.textTertiary,
              ),
            ],
          ],
        ),
      ],
    );
  }

  String _phaseLabel(FocusTimerPhase p) {
    switch (p) {
      case FocusTimerPhase.idle:
        return 'Ready';
      case FocusTimerPhase.running:
        return 'Focusing';
      case FocusTimerPhase.paused:
        return 'Paused';
      case FocusTimerPhase.completing:
        return 'Completing';
      case FocusTimerPhase.completed:
        return 'Completed';
      case FocusTimerPhase.stopped:
        return 'Stopped';
    }
  }
}
