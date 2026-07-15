import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

class FocusNudgeBanner extends StatefulWidget {
  final String appLabel;
  final VoidCallback onReturn;
  final VoidCallback onDismiss;

  const FocusNudgeBanner({
    super.key,
    required this.appLabel,
    required this.onReturn,
    required this.onDismiss,
  });

  @override
  State<FocusNudgeBanner> createState() => _FocusNudgeBannerState();
}

class _FocusNudgeBannerState extends State<FocusNudgeBanner> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  Timer? _autoDismissTimer;

  bool get _reducedMotion {
    if (!mounted) return false;
    final media = MediaQuery.of(context);
    return media.accessibleNavigation || media.disableAnimations;
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_reducedMotion) {
        _controller.value = 1.0;
      } else {
        _controller.forward();
      }
    });

    // Auto dismiss after 12 seconds
    _autoDismissTimer = Timer(const Duration(seconds: 12), () {
      if (mounted) {
        _dismiss();
      }
    });
  }

  @override
  void dispose() {
    _autoDismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _dismiss() {
    if (_reducedMotion) {
      widget.onDismiss();
    } else {
      _controller.reverse().then((_) {
        if (mounted) {
          widget.onDismiss();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final capsuleBody = ClipRRect(
      borderRadius: BorderRadius.circular(100),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.background2.withValues(alpha: 0.75),
            borderRadius: BorderRadius.circular(100),
            border: Border.all(color: AppColors.warningAmber.withValues(alpha: 0.25)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.warningAmber.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.spa_rounded, // Seed/leaf icon
                  color: AppColors.warningAmber,
                  size: 16,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Flexible(
                child: Text(
                  'Opened ${widget.appLabel} during focus. Return?',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              TextButton(
                onPressed: _dismiss,
                style: TextButton.styleFrom(
                  minimumSize: Size.zero,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Dismiss',
                  style: AppTypography.monoSmall.copyWith(
                    color: AppColors.textTertiary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              ElevatedButton(
                onPressed: () {
                  widget.onReturn();
                  _dismiss();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.warningAmber,
                  foregroundColor: Colors.black,
                  elevation: 0,
                  minimumSize: Size.zero,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(100),
                  ),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Return',
                  style: AppTypography.monoSmall.copyWith(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: _reducedMotion
            ? capsuleBody
            : SlideTransition(
                position: _slideAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: capsuleBody,
                ),
              ),
      ),
    );
  }
}
