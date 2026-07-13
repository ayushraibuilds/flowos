import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' hide Column;

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../features/ai/services/ai_service.dart';
import '../../../features/xp/models/daily_score_calculator.dart';
import '../../../data/local/database/app_database.dart';
import '../../../features/onboarding/providers/onboarding_providers.dart';
import '../../../features/reports/models/weekly_action.dart';
import '../../../features/reports/services/weekly_action_engine.dart';
import '../../widgets/action_commit_card.dart';

/// Weekly Review Screen — Sunday guided 5-min flow.
/// AI-generated reflection questions + week summary infographic.
class WeeklyReviewScreen extends ConsumerStatefulWidget {
  const WeeklyReviewScreen({super.key});

  @override
  ConsumerState<WeeklyReviewScreen> createState() => _WeeklyReviewScreenState();
}

class _WeeklyReviewScreenState extends ConsumerState<WeeklyReviewScreen> {
  WeeklyReview? _review;
  WeeklyAction? _weeklyAction;
  bool _loading = true;
  int _currentStep = 0;
  Map<String, dynamic> _weekData = {};

  @override
  void initState() {
    super.initState();
    _loadReview();
  }

  Future<void> _loadReview() async {
    final db = ref.read(databaseProvider);

    // Calculate past 7 days range (up to end of today)
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final weekStart = todayStart.subtract(const Duration(days: 6));
    final weekEnd = todayStart.add(const Duration(days: 1));

    // Fetch completed tasks in range
    final completedTasksLast7Days = await (db.select(db.tasks)
          ..where((t) =>
              t.isCompleted.equals(true) &
              t.completedAt.isBiggerOrEqualValue(weekStart) &
              t.completedAt.isSmallerThanValue(weekEnd)))
        .get();
    final totalTasksCompleted = completedTasksLast7Days.length;

    // Fetch focus sessions in range
    final sessions = await db.focusSessionsDao.getByDateRange(weekStart, weekEnd);
    final totalFocusMinutes = sessions.fold<int>(0, (sum, s) => sum + s.durationMinutes);
    final totalFocusHours = double.parse((totalFocusMinutes / 60.0).toStringAsFixed(1));

    // Fetch scroll minutes in range
    final scrollLogs = await (db.select(db.scrollLogs)
          ..where((l) =>
              l.timestamp.isBiggerOrEqualValue(weekStart) &
              l.timestamp.isSmallerThanValue(weekEnd)))
        .get();
    final scrollTotalMinutes = scrollLogs.fold<int>(0, (sum, l) => sum + l.durationMinutes);
    final recoveryActions = scrollLogs.where((l) => l.recoveryActionTaken).length;

    // Fetch XP earned in range
    final xpEntries = await (db.select(db.xpLedgerEntries)
          ..where((x) =>
              x.timestamp.isBiggerOrEqualValue(weekStart) &
              x.timestamp.isSmallerThanValue(weekEnd)))
        .get();
    final totalXp = xpEntries.fold<int>(0, (sum, x) => sum + x.pointsDelta);

    // Fetch energy check-ins in range
    final energyCheckins = await db.energyCheckInsDao.getCheckInsInRange(weekStart, weekEnd);

    // Calculate daily scores and MIT metrics per day
    final dailyScores = <int>[];
    int mitsCompleted = 0;
    int mitsTotal = 0;
    int streakDays = 0;

    for (int i = 6; i >= 0; i--) {
      final day = todayStart.subtract(Duration(days: i));
      final dayEnd = day.add(const Duration(days: 1));

      final plan = await db.dailyPlansDao.getByDateRange(day, dayEnd);
      final hasIntention = plan?.intentionCompleted ?? false;
      final hasShutdown = plan?.shutdownCompleted ?? false;
      final scrollBudget = plan?.scrollBudgetMinutes ?? 30;

      final daySessions = sessions.where((s) =>
          s.startedAt.isAfter(day.subtract(const Duration(seconds: 1))) &&
          s.startedAt.isBefore(dayEnd));
      final dayFocusMinutes = daySessions.fold<int>(0, (sum, s) => sum + s.durationMinutes);

      final dayCompletedTasks = completedTasksLast7Days.where((t) =>
          t.completedAt != null &&
          t.completedAt!.isAfter(day.subtract(const Duration(seconds: 1))) &&
          t.completedAt!.isBefore(dayEnd));

      final dayMits = dayCompletedTasks.where((t) => t.isMIT).length;
      mitsCompleted += dayMits;
      mitsTotal += 3;

      final dayScrollLogs = scrollLogs.where((l) =>
          l.timestamp.isAfter(day.subtract(const Duration(seconds: 1))) &&
          l.timestamp.isBefore(dayEnd));
      final dayScrollMinutes = dayScrollLogs.fold<int>(0, (sum, l) => sum + l.durationMinutes);

      final dayEnergyCheckins = energyCheckins.where((e) =>
          e.date.isAfter(day.subtract(const Duration(seconds: 1))) &&
          e.date.isBefore(dayEnd));
      final dayEnergyCount = dayEnergyCheckins.length;

      final score = DailyScoreCalculator.calculate(
        focusMinutes: dayFocusMinutes,
        mitsCompleted: dayMits,
        scrollMinutes: dayScrollMinutes,
        scrollBudget: scrollBudget,
        intentionCompleted: hasIntention,
        shutdownCompleted: hasShutdown,
        energyCheckIns: dayEnergyCount,
      );
      dailyScores.add(score);
    }

    // Calculate current streak
    final currentPlan = await db.dailyPlansDao.getToday();
    if (currentPlan != null && currentPlan.intentionCompleted) streakDays = 1;
    for (int i = 1; i <= 365; i++) {
      final d = todayStart.subtract(Duration(days: i));
      final start = DateTime(d.year, d.month, d.day);
      final end = start.add(const Duration(days: 1));
      final p = await db.dailyPlansDao.getByDateRange(start, end);
      if (p != null && p.intentionCompleted) {
        streakDays++;
      } else {
        break;
      }
    }

    final bestDayScore = dailyScores.isEmpty ? 0 : dailyScores.reduce((a, b) => a > b ? a : b);
    final worstDayScore = dailyScores.isEmpty ? 0 : dailyScores.reduce((a, b) => a < b ? a : b);

    _weekData = {
      'week_start': weekStart.toIso8601String().split('T')[0],
      'week_end': todayStart.toIso8601String().split('T')[0],
      'daily_scores': dailyScores,
      'total_focus_hours': totalFocusHours,
      'total_tasks_completed': totalTasksCompleted,
      'total_xp': totalXp,
      'scroll_total_minutes': scrollTotalMinutes,
      'recovery_actions': recoveryActions,
      'streak_days': streakDays,
      'best_day_score': bestDayScore,
      'worst_day_score': worstDayScore,
      'mits_completed': mitsCompleted,
      'mits_total': mitsTotal,
      'private_mode': false,
      'prompt_version': 1,
    };

    final aiService = AiService();
    final review = await aiService.generateWeeklyReview(weekData: _weekData);
    final incompleteTasks = await db.tasksDao.getIncomplete();
    final profile = ref.read(userProfileProvider);
    final weeklyAction = WeeklyActionEngine.generateWeeklyAction(
      sessions: sessions,
      scrollLogs: scrollLogs,
      incompleteTasks: incompleteTasks,
      profile: profile,
    );

    if (mounted) {
      setState(() {
        _review = review ?? WeeklyReview(
          summary: 'A solid week of building habits. Check the numbers below.',
          wins: [
            'Maintained a $streakDays-day streak',
            '$totalTasksCompleted tasks completed',
            'Earned $totalXp XP this week'
          ],
          growthAreas: ['Try protecting morning hours for deep work'],
          reflectionQuestions: [
            'What was your focus highlight this week?',
            'What drained your attention most?',
            'If you could only do 3 things next week, what would they be?',
          ],
          nextWeekFocus: 'Start each day with one deep work session.',
        );
        _weeklyAction = weeklyAction;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: AppColors.background0,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.emerald),
        ),
      );
    }

    final steps = [
      _buildSummaryStep(),
      _buildWinsStep(),
      _buildGrowthStep(),
      _buildReflectionStep(),
      _buildNextWeekStep(),
      _buildActionStep(),
    ];

    return Scaffold(
      backgroundColor: AppColors.background0,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.xxl),
              // Progress
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (_currentStep + 1) / steps.length,
                  minHeight: 4,
                  backgroundColor: AppColors.background2,
                  valueColor: AlwaysStoppedAnimation(AppColors.emerald),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Weekly Review',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                  Text(
                    '${_currentStep + 1}/${steps.length}',
                    style: AppTypography.monoSmall.copyWith(
                      color: AppColors.textTertiary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              // Content
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: steps[_currentStep],
              ),
              const Spacer(),
              // Navigation
              Row(
                children: [
                  if (_currentStep > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          setState(() => _currentStep--);
                        },
                        child: const Text('← Back'),
                      ),
                    ),
                  if (_currentStep > 0) const SizedBox(width: AppSpacing.md),
                  if (_currentStep < steps.length - 1)
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          setState(() => _currentStep++);
                        },
                        child: const Text('Continue →'),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Skip review',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryStep() {
    final scores = _weekData['daily_scores'] as List;
    return Column(
      key: const ValueKey('summary'),
      children: [
        Text('📊', style: const TextStyle(fontSize: 48)),
        const SizedBox(height: AppSpacing.xxl),
        Text(
          'Your Week',
          style: AppTypography.h1.copyWith(color: AppColors.textPrimary),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          _review!.summary,
          style: AppTypography.body.copyWith(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xxl),
        // Mini score chart
        SizedBox(
          height: 80,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(scores.length, (i) {
              final score = scores[i] as int;
              final height = score / 100 * 60;
              final isToday = i == scores.length - 1;
              return Container(
                width: 28,
                height: height.toDouble(),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: isToday
                      ? AppColors.emerald
                      : AppColors.emerald.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: ['M', 'T', 'W', 'T', 'F', 'S', 'S'].map((d) {
            return SizedBox(
              width: 34,
              child: Text(
                d,
                style: AppTypography.caption.copyWith(
                  color: AppColors.textTertiary,
                ),
                textAlign: TextAlign.center,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildWinsStep() {
    return Column(
      key: const ValueKey('wins'),
      children: [
        Text('🏆', style: const TextStyle(fontSize: 48)),
        const SizedBox(height: AppSpacing.xxl),
        Text(
          'Wins',
          style: AppTypography.h1.copyWith(color: AppColors.emerald),
        ),
        const SizedBox(height: AppSpacing.xxl),
        ...(_review!.wins.map((win) => Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.emerald.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
              border: Border.all(
                color: AppColors.emerald.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Text('✓ ', style: TextStyle(color: AppColors.emerald)),
                Expanded(
                  child: Text(
                    win,
                    style: AppTypography.body.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ))),
      ],
    );
  }

  Widget _buildGrowthStep() {
    return Column(
      key: const ValueKey('growth'),
      children: [
        Text('🌱', style: const TextStyle(fontSize: 48)),
        const SizedBox(height: AppSpacing.xxl),
        Text(
          'Growth Areas',
          style: AppTypography.h1.copyWith(color: AppColors.textPrimary),
        ),
        const SizedBox(height: AppSpacing.xxl),
        ...(_review!.growthAreas.map((area) => Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.background2,
              borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
            ),
            child: Text(
              area,
              style: AppTypography.body.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ))),
      ],
    );
  }

  Widget _buildReflectionStep() {
    return Column(
      key: const ValueKey('reflection'),
      children: [
        Text('🪞', style: const TextStyle(fontSize: 48)),
        const SizedBox(height: AppSpacing.xxl),
        Text(
          'Reflect',
          style: AppTypography.h1.copyWith(color: AppColors.textPrimary),
        ),
        const SizedBox(height: AppSpacing.xxl),
        ...List.generate(_review!.reflectionQuestions.length, (i) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.lg),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.background2,
                borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
                border: Border(
                  left: BorderSide(
                    color: AppColors.focusBlue.withValues(alpha: 0.5),
                    width: 2,
                  ),
                ),
              ),
              child: Text(
                _review!.reflectionQuestions[i],
                style: AppTypography.body.copyWith(
                  color: AppColors.textPrimary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildNextWeekStep() {
    return Column(
      key: const ValueKey('next'),
      children: [
        Text('🚀', style: const TextStyle(fontSize: 48)),
        const SizedBox(height: AppSpacing.xxl),
        Text(
          'Next Week',
          style: AppTypography.h1.copyWith(color: AppColors.textPrimary),
        ),
        const SizedBox(height: AppSpacing.xxl),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.xxl),
          decoration: BoxDecoration(
            color: AppColors.emerald.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
            border: Border.all(
              color: AppColors.emerald.withValues(alpha: 0.2),
            ),
          ),
          child: Text(
            _review!.nextWeekFocus,
            style: AppTypography.h3.copyWith(
              color: AppColors.emerald,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
        Text(
          'Week reviewed. Ready for the next one. 💪',
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildActionStep() {
    if (_weeklyAction == null) {
      return Column(
        key: const ValueKey('action_empty'),
        children: [
          const Text('🏁', style: TextStyle(fontSize: 48)),
          const SizedBox(height: AppSpacing.xxl),
          Text(
            'Ready to start!',
            style: AppTypography.h1.copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: AppSpacing.xxl),
          Text(
            'You are all set for next week. Keep up the great work!',
            style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xxl),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Complete Review'),
          ),
        ],
      );
    }

    return Column(
      key: const ValueKey('action_card'),
      children: [
        Text(
          'Commit to Next Week',
          style: AppTypography.h2.copyWith(color: AppColors.textPrimary),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Choose one change to apply to your plan.',
          style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary),
        ),
        const SizedBox(height: AppSpacing.xxl),
        ActionCommitCard(
          action: _weeklyAction!,
          onAccept: () => Navigator.pop(context),
          onSkip: () => Navigator.pop(context),
          onChooseDifferent: () {
            setState(() {
              if (_weeklyAction!.type != WeeklyActionType.scheduleFocusWindow) {
                _weeklyAction = const WeeklyAction(
                  id: 'alternate_focus_window',
                  type: WeeklyActionType.scheduleFocusWindow,
                  description: 'Schedule one 25-minute focus window tomorrow at 9:00 AM.',
                  startHour: 9,
                  endHour: 10,
                );
              } else {
                _weeklyAction = const WeeklyAction(
                  id: 'alternate_firm_protection',
                  type: WeeklyActionType.reduceOneTrigger,
                  description: 'Enable Firm protection mode for all distracting apps.',
                );
              }
            });
          },
        ),
      ],
    );
  }
}
