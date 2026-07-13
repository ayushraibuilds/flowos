import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../xp/widgets/streak_fire_widget.dart';

/// Celebration Service — Coordinates tactile haptics, success/xp floats,
/// level-up alerts, and brand-styled achievements overlays.
///
/// All celebration effects are code-native (confetti package + CustomPainter).
/// No Lottie JSON files required.
class CelebrationService {
  CelebrationService._();

  /// Play a successive pulse haptic pattern for focus completion.
  static Future<void> playSuccessPattern() async {
    await HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    await HapticFeedback.mediumImpact();
  }

  /// Play a quick successive double pulse for achievements.
  static Future<void> playAchievementPattern() async {
    await HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 80));
    await HapticFeedback.mediumImpact();
  }

  /// Show a premium, brand-styled floating overlay toast for achievements
  static void showAchievementToast(
    BuildContext context, {
    required String name,
    required String emoji,
  }) {
    playAchievementPattern();

    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        duration: const Duration(seconds: 4),
        content: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: AppColors.background2.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
            border: Border.all(
              color: AppColors.emerald.withValues(alpha: 0.4),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.emerald.withValues(alpha: 0.15),
                blurRadius: 16,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Row(
            children: [
              Text(
                emoji,
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Achievement Unlocked!',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.emerald,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      name,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Show a streak fire celebration overlay.
  /// Displays rising flame particles for streak milestones (e.g., 7-day, 30-day).
  static void showStreakCelebration(
    BuildContext context, {
    required int streakDays,
  }) {
    playSuccessPattern();

    final overlay = OverlayEntry(
      builder: (ctx) => _StreakOverlay(
        streakDays: streakDays,
        onDismiss: () {},
      ),
    );

    Overlay.of(context).insert(overlay);

    // Auto-dismiss after animation + display time
    Future.delayed(const Duration(seconds: 4), () {
      overlay.remove();
    });
  }

  /// Show a quick XP float indicator above a widget position.
  /// Useful for inline "+25 XP" fly-up animations.
  static void showXpFloat(
    BuildContext context, {
    required int xp,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        duration: const Duration(seconds: 2),
        content: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: AppColors.emerald.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
              border: Border.all(
                color: AppColors.emerald.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              '+$xp XP',
              style: AppTypography.monoSmall.copyWith(
                color: AppColors.emerald,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Internal widget for streak fire overlay
class _StreakOverlay extends StatefulWidget {
  final int streakDays;
  final VoidCallback onDismiss;

  const _StreakOverlay({
    required this.streakDays,
    required this.onDismiss,
  });

  @override
  State<_StreakOverlay> createState() => _StreakOverlayState();
}

class _StreakOverlayState extends State<_StreakOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeController,
      child: Material(
        color: AppColors.background0.withValues(alpha: 0.6),
        child: Stack(
          children: [
            // Fire particles
            const Positioned.fill(
              child: StreakFireWidget(
                particleCount: 50,
                duration: Duration(seconds: 3),
              ),
            ),
            // Streak text
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '🔥',
                    style: TextStyle(fontSize: 48),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    '${widget.streakDays}-Day Streak!',
                    style: AppTypography.h2.copyWith(
                      color: const Color(0xFFFFD700),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Keep the fire alive',
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
    );
  }
}
