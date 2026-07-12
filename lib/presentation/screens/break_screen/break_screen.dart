import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:confetti/confetti.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../features/energy/widgets/energy_checkin_sheet.dart';
import '../../../features/wellbeing/widgets/breathing_helper.dart';
import '../../../features/wellbeing/widgets/wellbeing_guide_cards.dart';

/// Break Screen — post-focus XP reveal + break content.
/// Displays breathing visual helper and swipable physical stretch guides.
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
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late ConfettiController _confettiController;
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

    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    if (widget.qualityGrade == 'A' || widget.qualityGrade == 'B' || widget.qualityGrade == 'D') {
      _confettiController.play();
    }

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
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background0,
      body: SafeArea(
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              child: _showBreakContent ? _buildBreakContent() : _buildXPReveal(),
            ),
            ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: [
                AppColors.emerald,
                AppColors.recoveryTeal,
                AppColors.focusBlue,
              ],
            ),
          ],
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
    return SingleChildScrollView(
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
          const SizedBox(height: AppSpacing.md),
          // Soft energy prompt
          GestureDetector(
            onTap: () => EnergyCheckInSheet.show(context),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              decoration: BoxDecoration(
                color: AppColors.emerald.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
                border: Border.all(
                  color: AppColors.emerald.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  const Text('⚡', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'How\'s your energy now?',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Log to keep tracking daily cycles',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: AppColors.textTertiary,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          // Visual Box Breathing widget
          const BreathingHelper(),
          const SizedBox(height: AppSpacing.xl),
          // Swipable Wellbeing Guide Stretches
          const WellbeingGuideCards(),
          const SizedBox(height: AppSpacing.xl),
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
