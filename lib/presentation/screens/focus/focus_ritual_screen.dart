import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/local/database/app_database.dart';
import '../../../features/xp/models/xp_calculator.dart';
import '../../../features/achievements/models/achievement_checker.dart';
import '../../../features/xp/models/streak_service.dart';

/// Focus Ritual — pre-focus checklist + optional breathing.
/// Completing the ritual earns FOCUS_RITUAL_COMPLETE (+10 XP).
class FocusRitualScreen extends ConsumerStatefulWidget {
  final VoidCallback onComplete;

  const FocusRitualScreen({super.key, required this.onComplete});

  @override
  ConsumerState<FocusRitualScreen> createState() => _FocusRitualScreenState();
}

class _FocusRitualScreenState extends ConsumerState<FocusRitualScreen>
    with SingleTickerProviderStateMixin {
  final _checklist = [
    (emoji: '💧', label: 'Water ready?', checked: false),
    (emoji: '🖥️', label: 'Tabs closed?', checked: false),
    (emoji: '📱', label: 'Phone on DND?', checked: false),
    (emoji: '🎯', label: 'Intention set?', checked: false),
  ];

  bool _showBreathing = false;
  int _breathPhase = 0; // 0=inhale, 1=hold, 2=exhale
  int _breathCycle = 0;
  Timer? _breathTimer;
  late AnimationController _breathController;

  @override
  void initState() {
    super.initState();
    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
  }

  @override
  void dispose() {
    _breathTimer?.cancel();
    _breathController.dispose();
    super.dispose();
  }

  bool get _allChecked => _checklist.every((item) => item.checked);

  void _toggleItem(int index) {
    HapticFeedback.selectionClick();
    setState(() {
      _checklist[index] = (
        emoji: _checklist[index].emoji,
        label: _checklist[index].label,
        checked: !_checklist[index].checked,
      );
    });
  }

  void _startBreathing() {
    setState(() => _showBreathing = true);
    _runBreathCycle();
  }

  void _runBreathCycle() {
    // 4-7-8 pattern: inhale 4s, hold 7s, exhale 8s
    final durations = [4, 7, 8];

    _breathTimer = Timer(Duration(seconds: durations[_breathPhase]), () {
      setState(() {
        _breathPhase = (_breathPhase + 1) % 3;
        if (_breathPhase == 0) _breathCycle++;
      });

      if (_breathCycle >= 3) {
        // Done — 3 cycles
        _breathTimer?.cancel();
        _complete();
      } else {
        _runBreathCycle();
      }
    });

    // Animate the circle
    if (_breathPhase == 0) {
      _breathController.duration = Duration(seconds: durations[0]);
      _breathController.forward(from: 0);
    } else if (_breathPhase == 2) {
      _breathController.duration = Duration(seconds: durations[2]);
      _breathController.reverse(from: 1);
    }
  }

  void _complete() async {
    HapticFeedback.heavyImpact();
    final db = ref.read(databaseProvider);
    final xpCalc = XpCalculator(db.xpLedgerDao);
    await xpCalc.awardFocusRitualXP();
    
    // Record streak activity & check achievements
    await StreakService.recordActivity();
    await AchievementChecker.runCheck(db);

    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background0,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: _showBreathing ? _buildBreathing() : _buildChecklist(),
        ),
      ),
    );
  }

  Widget _buildChecklist() {
    return Column(
      children: [
        const Spacer(),
        Text(
          'Focus Ritual',
          style: AppTypography.h1.copyWith(color: AppColors.textPrimary),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Prepare your environment',
          style: AppTypography.body.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.xxxl),
        // Checklist
        ...List.generate(_checklist.length, (i) {
          final item = _checklist[i];
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: GestureDetector(
              onTap: () => _toggleItem(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: item.checked
                      ? AppColors.emerald.withValues(alpha: 0.08)
                      : AppColors.background2,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
                  border: Border.all(
                    color: item.checked
                        ? AppColors.emerald.withValues(alpha: 0.3)
                        : Colors.transparent,
                  ),
                ),
                child: Row(
                  children: [
                    Text(item.emoji, style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        item.label,
                        style: AppTypography.body.copyWith(
                          color: item.checked
                              ? AppColors.emerald
                              : AppColors.textPrimary,
                          decoration: item.checked
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: item.checked
                            ? AppColors.emerald
                            : Colors.transparent,
                        border: Border.all(
                          color: item.checked
                              ? AppColors.emerald
                              : AppColors.textTertiary,
                          width: 2,
                        ),
                      ),
                      child: item.checked
                          ? const Icon(Icons.check, size: 16,
                              color: AppColors.textInverse)
                          : null,
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
        const Spacer(),
        // Actions
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _startBreathing,
                child: const Text('🧘 Breathe First'),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: ElevatedButton(
                onPressed: _complete,
                child: Text(_allChecked ? 'Enter Flow →' : 'Skip →'),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xxxl),
      ],
    );
  }

  Widget _buildBreathing() {
    final labels = ['Inhale...', 'Hold...', 'Exhale...'];

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          labels[_breathPhase],
          style: AppTypography.h2.copyWith(
            color: AppColors.recoveryTeal,
          ),
        ),
        const SizedBox(height: AppSpacing.xxxl),
        AnimatedBuilder(
          animation: _breathController,
          builder: (context, child) {
            final scale = 0.5 + (_breathController.value * 0.5);
            return Transform.scale(
              scale: scale,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.recoveryTeal.withValues(alpha: 0.15),
                  border: Border.all(
                    color: AppColors.recoveryTeal.withValues(alpha: 0.4),
                    width: 2,
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: AppSpacing.xxxl),
        Text(
          'Cycle ${_breathCycle + 1} / 3',
          style: AppTypography.monoSmall.copyWith(
            color: AppColors.textTertiary,
          ),
        ),
        const SizedBox(height: AppSpacing.xxxl),
        TextButton(
          onPressed: () {
            _breathTimer?.cancel();
            _complete();
          },
          child: Text(
            'Skip',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
        ),
      ],
    );
  }
}
