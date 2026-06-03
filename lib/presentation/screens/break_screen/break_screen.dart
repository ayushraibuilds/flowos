import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

/// Break Screen — post-focus XP reveal + break content.
/// Phase 1: XP reveal animation, static break content (riddle/fact/breathing).
class BreakScreen extends StatefulWidget {
  final int xpEarned;
  final String qualityGrade;
  final int focusMinutes;

  const BreakScreen({
    super.key,
    required this.xpEarned,
    required this.qualityGrade,
    required this.focusMinutes,
  });

  @override
  State<BreakScreen> createState() => _BreakScreenState();
}

class _BreakScreenState extends State<BreakScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  bool _showBreakContent = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _scaleAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );

    _controller.forward();
    HapticFeedback.heavyImpact();

    // Show break content after reveal animation
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showBreakContent = true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background0,
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          child: _showBreakContent ? _buildBreakContent() : _buildXPReveal(),
        ),
      ),
    );
  }

  Widget _buildXPReveal() {
    return Center(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Transform.scale(
                scale: _scaleAnimation.value,
                child: Text(
                  '+${widget.xpEarned}',
                  style: AppTypography.display.copyWith(
                    color: AppColors.emerald,
                    fontSize: 72,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Opacity(
                opacity: _fadeAnimation.value,
                child: Text(
                  'XP',
                  style: AppTypography.h2.copyWith(
                    color: AppColors.emerald.withValues(alpha: 0.7),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              Opacity(
                opacity: _fadeAnimation.value,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.gradeColor(widget.qualityGrade)
                        .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                    border: Border.all(
                      color: AppColors.gradeColor(widget.qualityGrade),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    'Grade: ${widget.qualityGrade}',
                    style: AppTypography.body.copyWith(
                      color: AppColors.gradeColor(widget.qualityGrade),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBreakContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.lg),
          // Earned summary card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.background2,
              borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.06),
                width: 0.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _miniStat('+${widget.xpEarned} XP', AppColors.emerald),
                _miniStat('Grade ${widget.qualityGrade}',
                    AppColors.gradeColor(widget.qualityGrade)),
                _miniStat('${widget.focusMinutes} min', AppColors.focusBlue),
              ],
            ),
          ),
          const Spacer(flex: 1),
          // Break content (static for Phase 1)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.xxl),
            decoration: BoxDecoration(
              color: AppColors.background2,
              borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.06),
                width: 0.5,
              ),
            ),
            child: Column(
              children: [
                const Text('🧩', style: TextStyle(fontSize: 32)),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'The more you take, the more you leave behind. What am I?',
                  style: AppTypography.body.copyWith(
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.lg),
                TextButton(
                  onPressed: () {
                    // Reveal answer
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: AppColors.background3,
                        title: Text(
                          'Answer',
                          style: AppTypography.h3
                              .copyWith(color: AppColors.textPrimary),
                        ),
                        content: Text(
                          'Footsteps',
                          style: AppTypography.body
                              .copyWith(color: AppColors.emerald),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Nice!'),
                          ),
                        ],
                      ),
                    );
                  },
                  child: const Text('Tap to reveal answer'),
                ),
              ],
            ),
          ),
          const Spacer(flex: 2),
          // Next session CTA
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Start Next Session →'),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Skip break',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }

  Widget _miniStat(String label, Color color) {
    return Text(
      label,
      style: AppTypography.monoSmall.copyWith(color: color, fontSize: 13),
    );
  }
}
