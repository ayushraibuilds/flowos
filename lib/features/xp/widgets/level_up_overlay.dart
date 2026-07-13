import 'dart:async';
import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/constants/xp_constants.dart';

/// Full-screen level-up celebration overlay.
/// Shows when XP crosses a level threshold.
/// Level never goes down — this is always a celebration.
///
/// Uses code-native confetti particles (no Lottie dependency).
class LevelUpOverlay extends StatefulWidget {
  final int newLevel;
  final String tierName;
  final VoidCallback onDismiss;

  const LevelUpOverlay({
    super.key,
    required this.newLevel,
    required this.tierName,
    required this.onDismiss,
  });

  /// Show the overlay as a dialog
  static Future<void> show(
    BuildContext context, {
    required int newLevel,
    required String tierName,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: AppColors.background0.withValues(alpha: 0.92),
      builder: (ctx) => LevelUpOverlay(
        newLevel: newLevel,
        tierName: tierName,
        onDismiss: () => Navigator.pop(ctx),
      ),
    );
  }

  @override
  State<LevelUpOverlay> createState() => _LevelUpOverlayState();
}

class _LevelUpOverlayState extends State<LevelUpOverlay>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _fadeController;
  late AnimationController _shimmerController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _shimmerAnimation;
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();

    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOutCubic),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: Curves.easeOut,
      ),
    );

    _shimmerAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );

    _confettiController = ConfettiController(
      duration: const Duration(seconds: 4),
    );

    HapticFeedback.heavyImpact();

    // Sequence: confetti burst → glow → level number → details → shimmer loop
    _confettiController.play();
    _scaleController.forward();
    Future.delayed(const Duration(milliseconds: 600), () {
      _fadeController.forward();
    });
    Future.delayed(const Duration(milliseconds: 1200), () {
      _shimmerController.repeat();
    });
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _fadeController.dispose();
    _shimmerController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // ── Confetti emitter (center-top burst) ──
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: pi / 2, // downward
              blastDirectionality: BlastDirectionality.explosive,
              emissionFrequency: 0.04,
              numberOfParticles: 25,
              maxBlastForce: 30,
              minBlastForce: 10,
              gravity: 0.15,
              colors: [
                AppColors.emerald,
                AppColors.focusBlue,
                const Color(0xFFFFD700), // gold
                const Color(0xFFFF6B6B), // coral
                const Color(0xFFAB47BC), // purple
                const Color(0xFF4DD0E1), // cyan
              ],
            ),
          ),
          // ── Main content ──
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Level ring with glow + shimmer
                AnimatedBuilder(
                  animation: _scaleController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _scaleAnimation.value,
                      child: AnimatedBuilder(
                        animation: _shimmerController,
                        builder: (context, _) {
                          return Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.emerald,
                                width: 4,
                              ),
                              gradient: SweepGradient(
                                center: Alignment.center,
                                colors: [
                                  AppColors.background0.withValues(alpha: 0.0),
                                  AppColors.emerald.withValues(alpha: 0.05),
                                  AppColors.background0.withValues(alpha: 0.0),
                                ],
                                stops: [
                                  (_shimmerAnimation.value - 0.2).clamp(0.0, 1.0),
                                  _shimmerAnimation.value.clamp(0.0, 1.0),
                                  (_shimmerAnimation.value + 0.2).clamp(0.0, 1.0),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.emerald
                                      .withValues(alpha: 0.3 * _glowAnimation.value),
                                  blurRadius: 40 * _glowAnimation.value,
                                  spreadRadius: 10 * _glowAnimation.value,
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                '${widget.newLevel}',
                                style: AppTypography.display.copyWith(
                                  color: AppColors.emerald,
                                  fontSize: 56,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.xxl),
                // "LEVEL UP" text
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    children: [
                      Text(
                        'LEVEL UP',
                        style: AppTypography.h2.copyWith(
                          color: AppColors.emerald,
                          letterSpacing: 4,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      // Tier name
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xl,
                          vertical: AppSpacing.md,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.emerald.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                          border: Border.all(
                            color: AppColors.emerald.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          widget.tierName,
                          style: AppTypography.h3.copyWith(
                            color: AppColors.emerald,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        'Next: ${XpConstants.xpForLevel(widget.newLevel + 1)} XP',
                        style: AppTypography.monoSmall.copyWith(
                          color: AppColors.textTertiary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxxl * 2),
                      // Continue button
                      ElevatedButton(
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          widget.onDismiss();
                        },
                        child: const Text('Continue'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
