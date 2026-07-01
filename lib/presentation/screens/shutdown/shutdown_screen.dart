import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart' show Value;

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/local/database/app_database.dart';
import '../../../features/xp/models/xp_calculator.dart';
import '../../../features/achievements/models/achievement_checker.dart';
import '../../../features/xp/models/streak_service.dart';

/// Shutdown Ritual — end-of-day routine.
/// Move incomplete tasks, close loops, preview tomorrow.
/// Completing earns SHUTDOWN_RITUAL_COMPLETE (+25 XP).
class ShutdownRitualScreen extends ConsumerStatefulWidget {
  const ShutdownRitualScreen({super.key});

  @override
  ConsumerState<ShutdownRitualScreen> createState() => _ShutdownRitualScreenState();
}

class _ShutdownRitualScreenState extends ConsumerState<ShutdownRitualScreen> {
  int _currentStep = 0;

  final _steps = [
    (
      title: 'Review Today',
      emoji: '📋',
      description: "What did you accomplish? What's left unfinished?",
      actionLabel: 'Reviewed →',
    ),
    (
      title: 'Move Incomplete Tasks',
      emoji: '📦',
      description: 'Reschedule or let go. Nothing carries weight overnight.',
      actionLabel: 'Tasks handled →',
    ),
    (
      title: 'Close Open Loops',
      emoji: '🔒',
      description: 'Reply to that message. Jot down that note. Clear your mind.',
      actionLabel: 'Loops closed →',
    ),
    (
      title: 'Tomorrow Preview',
      emoji: '🌅',
      description: 'Glance at tomorrow. One thing to look forward to.',
      actionLabel: "I'm ready for tomorrow →",
    ),
    (
      title: 'Gratitude',
      emoji: '🙏',
      description: 'One thing you\'re grateful for today. You showed up. That counts.',
      actionLabel: 'Complete Ritual 🌙',
    ),
  ];

  void _nextStep() {
    HapticFeedback.selectionClick();
    if (_currentStep < _steps.length - 1) {
      setState(() => _currentStep++);
    } else {
      _complete();
    }
  }

  void _complete() async {
    HapticFeedback.heavyImpact();
    
    final db = ref.read(databaseProvider);
    final xpCalc = XpCalculator(db.xpLedgerDao);
    await xpCalc.awardShutdownRitualXP();
    
    final plan = await db.dailyPlansDao.getToday();
    if (plan != null) {
      await db.dailyPlansDao.completeShutdown(plan.id);
    } else {
      final planId = const Uuid().v4();
      await db.dailyPlansDao.upsertToday(DailyPlansCompanion(
        id: Value(planId),
        date: Value(DateTime.now()),
        shutdownCompleted: const Value(true),
      ));
    }

    // Record streak activity & check achievements
    await StreakService.recordActivity();
    await AchievementChecker.runCheck(db);
    
    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final step = _steps[_currentStep];
    final progress = (_currentStep + 1) / _steps.length;

    return Scaffold(
      backgroundColor: AppColors.background0,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.xxl),
              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 4,
                  backgroundColor: AppColors.background2,
                  valueColor:
                      const AlwaysStoppedAnimation(AppColors.recoveryTeal),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Shutdown Ritual',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                  Text(
                    '${_currentStep + 1} / ${_steps.length}',
                    style: AppTypography.monoSmall.copyWith(
                      color: AppColors.textTertiary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              // Step content
              Text(
                step.emoji,
                style: const TextStyle(fontSize: 64),
              ),
              const SizedBox(height: AppSpacing.xxl),
              Text(
                step.title,
                style: AppTypography.h1.copyWith(
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                step.description,
                style: AppTypography.body.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              // Action button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _nextStep,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _currentStep == _steps.length - 1
                        ? AppColors.recoveryTeal
                        : AppColors.emerald,
                  ),
                  child: Text(step.actionLabel),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  'Skip ritual',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xxxl),
            ],
          ),
        ),
      ),
    );
  }
}
