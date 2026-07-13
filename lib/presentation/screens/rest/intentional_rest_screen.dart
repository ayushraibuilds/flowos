import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../widgets/flow_surface.dart';

class IntentionalRestScreen extends StatefulWidget {
  const IntentionalRestScreen({super.key});

  @override
  State<IntentionalRestScreen> createState() => _IntentionalRestScreenState();
}

class _IntentionalRestScreenState extends State<IntentionalRestScreen>
    with SingleTickerProviderStateMixin {
  int _selectedMinutes = 5;
  bool _isActive = false;
  int _secondsRemaining = 5 * 60;
  Timer? _timer;

  // Box Breathing Animation
  late AnimationController _animController;
  late Animation<double> _pulseAnimation;
  String _breathPhase = 'Ready';
  int _breathTimer = 0;
  Timer? _breathCycleTimer;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.6).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _breathCycleTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  void _startRest() {
    HapticFeedback.mediumImpact();
    setState(() {
      _isActive = true;
      _secondsRemaining = _selectedMinutes * 60;
      _breathPhase = 'Inhale';
      _breathTimer = 4;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining <= 0) {
        _onComplete();
      } else {
        setState(() => _secondsRemaining--);
      }
    });

    _startBreathCycle();
  }

  void _startBreathCycle() {
    _animController.forward();
    _breathCycleTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        _breathTimer--;
        if (_breathTimer <= 0) {
          _advanceBreathPhase();
        }
      });
    });
  }

  void _advanceBreathPhase() {
    switch (_breathPhase) {
      case 'Inhale':
        _breathPhase = 'Hold';
        _breathTimer = 4;
        _animController.stop(); // Hold at expanded size
        HapticFeedback.selectionClick();
        break;
      case 'Hold':
        _breathPhase = 'Exhale';
        _breathTimer = 4;
        _animController.reverse(); // Contract
        HapticFeedback.selectionClick();
        break;
      case 'Exhale':
        _breathPhase = 'Hold Out';
        _breathTimer = 4;
        _animController.stop(); // Hold at small size
        HapticFeedback.selectionClick();
        break;
      case 'Hold Out':
        _breathPhase = 'Inhale';
        _breathTimer = 4;
        _animController.forward(); // Inhale again
        HapticFeedback.selectionClick();
        break;
    }
  }

  void _onComplete() {
    _timer?.cancel();
    _breathCycleTimer?.cancel();
    _animController.stop();
    HapticFeedback.mediumImpact();

    // Show completion alert
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.background2,
        title: Text('Rest Completed 🔋', style: AppTypography.h3.copyWith(color: AppColors.emerald)),
        content: Text(
          'How do you feel? You successfully stepped away to recharge your batteries without scrolling.',
          style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.pop(); // Go back to scroll tracker
            },
            child: Text('Peaceful', style: TextStyle(color: AppColors.emerald)),
          ),
        ],
      ),
    );
  }

  void _cancelRest() {
    HapticFeedback.selectionClick();
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final formatMin = (_secondsRemaining ~/ 60).toString().padLeft(2, '0');
    final formatSec = (_secondsRemaining % 60).toString().padLeft(2, '0');

    return Scaffold(
      backgroundColor: AppColors.background0,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            children: [
              // Top Exit button (only visible before starting)
              Align(
                alignment: Alignment.topLeft,
                child: IconButton(
                  icon: Icon(Icons.close_rounded, color: AppColors.textTertiary),
                  onPressed: _cancelRest,
                ),
              ),

              const Spacer(),

              if (!_isActive) ...[
                // Setup View
                const Text('🔋', style: TextStyle(fontSize: 64)),
                const SizedBox(height: AppSpacing.lg),
                Text('Intentional Rest', style: AppTypography.h1),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Step away from feed scroll. Rest your eyes and reset your focus.',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xxl),

                // Duration Selector Chips
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [5, 10, 15].map((m) {
                    final isSel = _selectedMinutes == m;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                      child: ChoiceChip(
                        label: Text('$m Min', style: AppTypography.bodySmall),
                        selected: isSel,
                        onSelected: (val) {
                          if (val) {
                            HapticFeedback.selectionClick();
                            setState(() => _selectedMinutes = m);
                          }
                        },
                        selectedColor: AppColors.emerald.withValues(alpha: 0.12),
                        disabledColor: AppColors.background2,
                        backgroundColor: AppColors.background2,
                        labelStyle: TextStyle(
                          color: isSel ? AppColors.emerald : AppColors.textSecondary,
                        ),
                        side: BorderSide(
                          color: isSel ? AppColors.emerald : Colors.white.withValues(alpha: 0.05),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const Spacer(),

                // Start button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _startRest,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.emerald,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
                      ),
                    ),
                    child: Text('Start Rest Break', style: AppTypography.button),
                  ),
                ),
              ] else ...[
                // Running View with Box Breathing Animation
                Text(
                  '$formatMin:$formatSec',
                  style: AppTypography.display.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: 64,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Rest Timer Active',
                  style: AppTypography.monoSmall.copyWith(color: AppColors.textTertiary),
                ),

                const Spacer(),

                // Breathing pulsing visual circle
                Center(
                  child: AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _pulseAnimation.value,
                        child: Container(
                          width: 130,
                          height: 130,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.emerald.withValues(alpha: 0.08),
                            border: Border.all(
                              color: AppColors.emerald.withValues(alpha: 0.3),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.emerald.withValues(alpha: 0.12),
                                blurRadius: 40,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _breathPhase,
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.emerald,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '$_breathTimer',
                                  style: AppTypography.monoSmall.copyWith(
                                    color: AppColors.textTertiary,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const Spacer(),

                // Box breathing info
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.background2,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
                  ),
                  child: Text(
                    'Box Breathing Cycle: Inhale 4s ➔ Hold 4s ➔ Exhale 4s ➔ Hold 4s',
                    style: AppTypography.caption.copyWith(color: AppColors.textTertiary),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
