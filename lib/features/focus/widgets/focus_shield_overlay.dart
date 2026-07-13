import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../models/focus_protection.dart';

/// Full-screen, premium focus protection shield overlay.
/// Displayed when a blocked app is intercepted.
class FocusShieldOverlay extends StatefulWidget {
  final String packageName;
  final FocusProtectionLevel protectionLevel;
  final VoidCallback onKeepFocus;
  final VoidCallback onCancelSession;
  final Function(int minutes)? onGrantBreak;

  const FocusShieldOverlay({
    super.key,
    required this.packageName,
    required this.protectionLevel,
    required this.onKeepFocus,
    required this.onCancelSession,
    this.onGrantBreak,
  });

  static Future<void> show(
    BuildContext context, {
    required String packageName,
    required FocusProtectionLevel protectionLevel,
    required VoidCallback onKeepFocus,
    required VoidCallback onCancelSession,
    Function(int minutes)? onGrantBreak,
  }) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: AppColors.background0.withValues(alpha: 0.96),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (ctx, anim1, anim2) => FocusShieldOverlay(
        packageName: packageName,
        protectionLevel: protectionLevel,
        onKeepFocus: () {
          Navigator.pop(ctx);
          onKeepFocus();
        },
        onCancelSession: () {
          Navigator.pop(ctx);
          onCancelSession();
        },
        onGrantBreak: onGrantBreak != null
            ? (min) {
                Navigator.pop(ctx);
                onGrantBreak(min);
              }
            : null,
      ),
    );
  }

  @override
  State<FocusShieldOverlay> createState() => _FocusShieldOverlayState();
}

class _FocusShieldOverlayState extends State<FocusShieldOverlay>
    with SingleTickerProviderStateMixin {
  late int _secondsRemaining;
  Timer? _timer;
  bool _canAction = false;
  int _selectedBreakMinutes = 5;

  // Pulse/Breathing Animation
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _secondsRemaining = switch (widget.protectionLevel) {
      FocusProtectionLevel.softReturn => 10,
      FocusProtectionLevel.pauseAndProtect => 30,
      FocusProtectionLevel.intentionalExit => 30,
    };

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining <= 1) {
        timer.cancel();
        if (mounted) {
          setState(() {
            _secondsRemaining = 0;
            _canAction = true;
          });
          HapticFeedback.heavyImpact();
        }
      } else {
        if (mounted) {
          setState(() {
            _secondsRemaining--;
          });
          if (_secondsRemaining <= 5) {
            HapticFeedback.lightImpact();
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final modeLabel = widget.protectionLevel.shortLabel;
    final appLabel = _cleanAppName(widget.packageName);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xxl,
            vertical: AppSpacing.xl,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              // Shield Icon & Mode
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.dangerCoral.withValues(alpha: 0.1),
                ),
                child: Icon(
                  Icons.shield_outlined,
                  size: 48,
                  color: AppColors.dangerCoral,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Focus Active · $modeLabel Mode',
                style: AppTypography.monoSmall.copyWith(
                  color: AppColors.dangerCoral,
                  letterSpacing: 2,
                ),
              ),

              const SizedBox(height: AppSpacing.xxl),

              // Dynamic prompt
              Text(
                '$appLabel is shielded',
                style: AppTypography.h2.copyWith(color: AppColors.textPrimary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                _getInstructionText(),
                style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),

              const Spacer(),

              // Animated Breathing Ring
              ScaleTransition(
                scale: _pulseAnimation,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.dangerCoral.withValues(alpha: 0.3),
                      width: 4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.dangerCoral.withValues(alpha: 0.1),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (!_canAction) ...[
                          Text(
                            '$_secondsRemaining',
                            style: AppTypography.display.copyWith(
                              fontSize: 36,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            'Breathe',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ] else ...[
                          Icon(
                            Icons.check_circle_outline_rounded,
                            size: 40,
                            color: AppColors.emerald,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Ready',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.emerald,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),

              const Spacer(flex: 2),

              // Actions Block
              if (_canAction) ...[
                if (widget.protectionLevel == FocusProtectionLevel.softReturn) ...[
                  // Reflect Mode Actions
                  ElevatedButton(
                    onPressed: widget.onKeepFocus,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.emerald,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(50),
                    ),
                    child: const Text('Resume Focus'),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  OutlinedButton(
                    onPressed: () => widget.onGrantBreak?.call(5),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                    ),
                    child: const Text('Continue to app (5m break)'),
                  ),
                ] else if (widget.protectionLevel == FocusProtectionLevel.pauseAndProtect) ...[
                  // Guard Mode Actions
                  ElevatedButton(
                    onPressed: widget.onKeepFocus,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.emerald,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(50),
                    ),
                    child: const Text('Resume Focus'),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildBreakPicker(),
                  const SizedBox(height: AppSpacing.md),
                  OutlinedButton(
                    onPressed: () => widget.onGrantBreak?.call(_selectedBreakMinutes),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                    ),
                    child: Text('Take a $_selectedBreakMinutes min break'),
                  ),
                ] else ...[
                  // Deep Mode Actions
                  ElevatedButton(
                    onPressed: widget.onKeepFocus,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.emerald,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(50),
                    ),
                    child: const Text('Resume Focus'),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextButton(
                    onPressed: widget.onCancelSession,
                    child: const Text(
                      'Give up & End Focus Session',
                      style: TextStyle(color: AppColors.dangerCoral),
                    ),
                  ),
                ],
              ] else ...[
                // Disabled placeholder during countdown
                ElevatedButton(
                  onPressed: null,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                  ),
                  child: Text('Pause to reflect ($_secondsRemaining s)'),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBreakPicker() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [5, 10, 15].map((m) {
        final isSel = _selectedBreakMinutes == m;
        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _selectedBreakMinutes = m);
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: isSel ? AppColors.dangerCoral.withValues(alpha: 0.15) : AppColors.background2,
              borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
              border: Border.all(
                color: isSel ? AppColors.dangerCoral : Colors.transparent,
              ),
            ),
            child: Text(
              '$m min',
              style: AppTypography.bodySmall.copyWith(
                color: isSel ? AppColors.dangerCoral : AppColors.textSecondary,
                fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  String _getInstructionText() {
    return switch (widget.protectionLevel) {
      FocusProtectionLevel.softReturn =>
        'Take a 10-second breath. You can choose to skip past this reminder if you must.',
      FocusProtectionLevel.pauseAndProtect =>
        'Take a 30-second pause to reflect. You can request a short timed break once the count ends.',
      FocusProtectionLevel.intentionalExit =>
        'This is Deep Focus. You cannot bypass this shield without terminating your entire focus session.',
    };
  }

  String _cleanAppName(String pkg) {
    if (pkg.contains('instagram')) return 'Instagram';
    if (pkg.contains('youtube')) return 'YouTube';
    if (pkg.contains('tiktok') || pkg.contains('musically')) return 'TikTok';
    if (pkg.contains('twitter') || pkg.contains('x')) return 'X/Twitter';
    if (pkg.contains('reddit')) return 'Reddit';
    if (pkg.contains('chrome') || pkg.contains('browser')) return 'Browser';
    return 'Distractor App';
  }
}
