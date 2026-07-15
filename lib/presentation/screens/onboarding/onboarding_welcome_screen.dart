import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

class OnboardingWelcomeScreen extends StatefulWidget {
  final VoidCallback onContinue;
  final VoidCallback onSkip;

  const OnboardingWelcomeScreen({
    super.key,
    required this.onContinue,
    required this.onSkip,
  });

  @override
  State<OnboardingWelcomeScreen> createState() => _OnboardingWelcomeScreenState();
}

class _OnboardingWelcomeScreenState extends State<OnboardingWelcomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.background0,
            AppColors.background1,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
          child: Column(
            children: [
              const Spacer(),
              // Sprout Visual
              AnimatedBuilder(
                animation: _animController,
                builder: (context, child) {
                  return CustomPaint(
                    size: const Size(200, 200),
                    painter: _SproutPainter(progress: _animController.value),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.xxxl),
              Text(
                'Welcome to your Garden',
                style: AppTypography.h1.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Your device activity stays on this device. An account is optional for sync. Your garden grows with your focus.',
                style: AppTypography.body.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              // Buttons
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    widget.onContinue();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.emerald,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
                    ),
                  ),
                  child: Text(
                    'Continue',
                    style: AppTypography.button,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  widget.onSkip();
                },
                child: Text(
                  'Set up later',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}

class _SproutPainter extends CustomPainter {
  final double progress;

  _SproutPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Glow Effect
    final glowPaint = Paint()
      ..color = AppColors.emerald.withValues(alpha: 0.15 + (progress * 0.1))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
    canvas.drawCircle(center + const Offset(0, 10), 40 + (progress * 15), glowPaint);

    // Soil/Seed Base
    final soilPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(center: center + const Offset(0, 50), width: 120, height: 20),
      soilPaint,
    );

    // Stem path
    final stemPaint = Paint()
      ..color = AppColors.emerald
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round;

    final stemPath = Path();
    stemPath.moveTo(center.dx, center.dy + 45);
    stemPath.quadraticBezierTo(
      center.dx - 10 + (progress * 5),
      center.dy + 10,
      center.dx,
      center.dy - 20,
    );
    canvas.drawPath(stemPath, stemPaint);

    // Leaves
    final leafPaint = Paint()
      ..color = AppColors.emerald
      ..style = PaintingStyle.fill;

    // Left Leaf
    final leftLeafPath = Path();
    leftLeafPath.moveTo(center.dx, center.dy - 20);
    leftLeafPath.quadraticBezierTo(
      center.dx - 25,
      center.dy - 35 - (progress * 5),
      center.dx - 30 - (progress * 5),
      center.dy - 20,
    );
    leftLeafPath.quadraticBezierTo(
      center.dx - 15,
      center.dy - 10,
      center.dx,
      center.dy - 20,
    );
    canvas.drawPath(leftLeafPath, leafPaint);

    // Right Leaf
    final rightLeafPath = Path();
    rightLeafPath.moveTo(center.dx, center.dy - 15);
    rightLeafPath.quadraticBezierTo(
      center.dx + 25,
      center.dy - 28 - (progress * 5),
      center.dx + 28 + (progress * 5),
      center.dy - 10,
    );
    rightLeafPath.quadraticBezierTo(
      center.dx + 15,
      center.dy - 5,
      center.dx,
      center.dy - 15,
    );
    canvas.drawPath(rightLeafPath, leafPaint);
  }

  @override
  bool shouldRepaint(covariant _SproutPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
