import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/constants/xp_constants.dart';
import '../../../features/dashboard/providers/dashboard_providers.dart';
import '../../../features/xp/providers/xp_providers.dart' show streakProvider, streakPausedProvider, todayPlanProvider;
import '../../../features/energy/providers/energy_providers.dart';
import '../../../features/energy/widgets/energy_checkin_sheet.dart';
import '../../../features/tasks/providers/task_providers.dart';
import '../../widgets/task_card.dart';
import '../../../data/local/database/app_database.dart';
import '../../../features/tasks/services/task_completion_service.dart';

final intentionBannerDismissedProvider = StateNotifierProvider<IntentionBannerDismissedNotifier, bool>((ref) {
  return IntentionBannerDismissedNotifier();
});

class IntentionBannerDismissedNotifier extends StateNotifier<bool> {
  IntentionBannerDismissedNotifier() : super(false) {
    _load();
  }

  String get _dateKey {
    final now = DateTime.now();
    return 'flowos_intention_dismissed_${now.year}-${now.month}-${now.day}';
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_dateKey) ?? false;
  }

  Future<void> dismiss() async {
    state = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_dateKey, true);
  }
}

/// Home Dashboard — the "command center."
/// Shows Flow Score, XP bar, MITs, quick actions, and attention budget.
/// All data is now reactive from Drift DAOs via Riverpod providers.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.lg),
              // ─── Header: Level + Streak ────────────────────────
              _buildHeader(context, ref),
              const SizedBox(height: AppSpacing.xxl),
              // ─── Intention Banner (Soft Daily Gate) ─────────────
              _buildIntentionBanner(context, ref),
              const SizedBox(height: AppSpacing.lg),
              // ─── Flow Score Card ────────────────────────────────
              _buildFlowScoreCard(context, ref),
              const SizedBox(height: AppSpacing.md),
              // ─── XP Progress Bar ───────────────────────────────
              _buildXPBar(context, ref),
              const SizedBox(height: AppSpacing.xxl),
              // ─── MITs Section ──────────────────────────────────
              _buildMITsSection(context, ref),
              const SizedBox(height: AppSpacing.xxl),
              // ─── Quick Actions ─────────────────────────────────
              _buildQuickActions(context),
              const SizedBox(height: AppSpacing.xxl),
              // ─── Attention Budget ──────────────────────────────
              _buildAttentionBudget(context, ref),
              const SizedBox(height: AppSpacing.xxxl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    final level = ref.watch(currentLevelProvider);
    final tier = ref.watch(currentTierProvider);
    final streakAsync = ref.watch(streakProvider);
    final streak = streakAsync.valueOrNull ?? 0;
    final paused = ref.watch(streakPausedProvider).valueOrNull ?? false;

    final energyCheckIn = ref.watch(latestEnergyCheckInProvider);
    final energyValue = energyCheckIn?.value;

    return Row(
      children: [
        // Level badge
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.emerald, width: 2),
          ),
          child: Center(
            child: Text(
              '$level',
              style: AppTypography.monoSmall.copyWith(
                color: AppColors.emerald,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Level $level · $tier',
                style: AppTypography.h3.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                level == 0 ? 'Getting started' : 'Keep building momentum',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        // Streak counter
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: AppColors.background2,
            borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(paused ? '⏸️' : '🔥', style: const TextStyle(fontSize: 16)),
              const SizedBox(width: AppSpacing.xs),
              Text(
                '$streak',
                style: AppTypography.monoSmall.copyWith(
                  color: streak > 0
                      ? AppColors.warningAmber
                      : AppColors.textTertiary,
                ),
              ),
              if (paused) ...[
                const SizedBox(width: AppSpacing.xs),
                Text(
                  '(paused)',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textTertiary,
                    fontSize: 10,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        // Energy check-in chip
        GestureDetector(
          onTap: () => EnergyCheckInSheet.show(context),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: AppColors.background2,
              borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
              border: Border.all(
                color: AppColors.emerald.withAlpha(50),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('⚡', style: TextStyle(fontSize: 14)),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  energyValue != null ? '$energyValue/5' : 'Log',
                  style: AppTypography.monoSmall.copyWith(
                    color: energyValue != null ? AppColors.emerald : AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFlowScoreCard(BuildContext context, WidgetRef ref) {
    final scoreAsync = ref.watch(dailyScoreProvider);
    final score = scoreAsync.valueOrNull;
    final grade = score?.grade ?? '—';
    final value = score?.score ?? 0;
    final message = score?.message ?? 'Loading...';

    final gradeColor = switch (grade) {
      'A+' || 'A' => AppColors.gradeA,
      'B' => AppColors.gradeB,
      'C' => AppColors.gradeC,
      'D' => AppColors.gradeD,
      _ => AppColors.textTertiary,
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xxl),
      decoration: BoxDecoration(
        color: AppColors.background2,
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.06),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.emeraldGlow,
            blurRadius: 30,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            grade,
            style: AppTypography.display.copyWith(
              color: gradeColor,
              fontSize: 64,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '$value',
            style: AppTypography.monoSmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            message,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildXPBar(BuildContext context, WidgetRef ref) {
    final lifetimeXP = ref.watch(lifetimeXpProvider).valueOrNull ?? 0;
    final level = ref.watch(currentLevelProvider);
    final currentLevelXP = XpConstants.xpForLevel(level);
    final nextLevelXP = XpConstants.xpForLevel(level + 1);
    final xpInLevel = lifetimeXP - currentLevelXP;
    final xpNeeded = nextLevelXP - currentLevelXP;
    final progress = xpNeeded > 0 ? xpInLevel / xpNeeded : 0.0;

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            minHeight: 8,
            backgroundColor: AppColors.background2,
            valueColor: AlwaysStoppedAnimation(AppColors.emerald),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$lifetimeXP / $nextLevelXP XP',
              style: AppTypography.monoSmall.copyWith(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
            Text(
              'Level ${level + 1}',
              style: AppTypography.caption.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMITsSection(BuildContext context, WidgetRef ref) {
    final mitsAsync = ref.watch(mitsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Today's MITs",
          style: AppTypography.h2.copyWith(color: AppColors.textPrimary),
        ),
        const SizedBox(height: AppSpacing.md),
        mitsAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
          data: (mits) {
            if (mits.isEmpty) {
              return _buildEmptyMITs(context);
            }
            return Column(
              children: mits.map((task) => TaskCard(
                task: task,
                onComplete: () async {
                  final db = ref.read(databaseProvider);
                  final service = TaskCompletionService(db);
                  await service.completeTask(task);
                },
                onDelete: () async {
                  final db = ref.read(databaseProvider);
                  await db.tasksDao.toggleMIT(task.id, false);
                },
                onTap: () => _startDeepWork(context, task),
              )).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildEmptyMITs(BuildContext context) {
    return Container(
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
          const Text('🎯', style: TextStyle(fontSize: 32)),
          const SizedBox(height: AppSpacing.md),
          Text(
            'No MITs set yet',
            style: AppTypography.body.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Start your morning intention to pick 3 MITs',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => context.push('/morning-intention'),
              child: const Text('Set Morning Intention'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      (icon: '🎯', label: 'Focus', onTap: () => context.go('/focus')),
      (icon: '📝', label: 'Add Task', onTap: () => context.go('/tasks')),
      (icon: '📱', label: 'Log Scroll', onTap: () => context.push('/scroll-tracker')),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: actions.map((action) {
          return Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: OutlinedButton.icon(
              onPressed: action.onTap,
              icon: Text(action.icon, style: const TextStyle(fontSize: 16)),
              label: Text(action.label),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAttentionBudget(BuildContext context, WidgetRef ref) {
    final scrollAsync = ref.watch(dailyScrollProvider);
    final scrollUsed = scrollAsync.valueOrNull ?? 0;
    final scoreAsync = ref.watch(dailyScoreProvider);
    final budget = scoreAsync.valueOrNull?.scrollBudget ?? 30;
    final progress = budget > 0 ? scrollUsed / budget : 0.0;
    final isOver = scrollUsed > budget;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Attention Budget',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              '$scrollUsed / $budget min',
              style: AppTypography.monoSmall.copyWith(
                color: isOver ? AppColors.dangerCoral : AppColors.emerald,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            minHeight: 4,
            backgroundColor: AppColors.background2,
            valueColor: AlwaysStoppedAnimation(
              isOver ? AppColors.dangerCoral : AppColors.emerald,
            ),
          ),
        ),
      ],
    );
  }

  void _startDeepWork(BuildContext context, Task task) {
    context.push('/deep-work', extra: {
      'taskId': task.id,
      'taskTitle': task.title,
    });
  }

  Widget _buildIntentionBanner(BuildContext context, WidgetRef ref) {
    final todayPlanAsync = ref.watch(todayPlanProvider);
    final isDismissed = ref.watch(intentionBannerDismissedProvider);

    return todayPlanAsync.maybeWhen(
      data: (plan) {
        if (plan != null) return const SizedBox.shrink();

        final now = DateTime.now();
        if (now.hour >= 12 || isDismissed) return const SizedBox.shrink();

        return Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.lg),
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.background1, AppColors.background2],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
            border: Border.all(
              color: AppColors.emerald.withAlpha(76),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Text('🌅', style: TextStyle(fontSize: 20)),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        "Set Today's Intention",
                        style: AppTypography.h3.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () {
                      ref.read(intentionBannerDismissedProvider.notifier).dismiss();
                    },
                    icon: const Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: AppColors.textTertiary,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                "Align your attention before starting work. Tap below to set today's 3 MITs.",
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.push('/morning-intention'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.emerald,
                    foregroundColor: AppColors.textInverse,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusButton),
                    ),
                    elevation: 0,
                  ),
                  child: const Text('Set Intention'),
                ),
              ),
            ],
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}
