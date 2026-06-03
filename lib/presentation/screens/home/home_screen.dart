import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/constants/xp_constants.dart';
import '../../../features/dashboard/providers/dashboard_providers.dart';
import '../../../features/tasks/providers/task_providers.dart';
import '../../widgets/task_card.dart';
import '../../../data/local/database/app_database.dart';

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
              const Text('🔥', style: TextStyle(fontSize: 16)),
              const SizedBox(width: AppSpacing.xs),
              Text(
                '$streak',
                style: AppTypography.monoSmall.copyWith(
                  color: streak > 0
                      ? AppColors.warningAmber
                      : AppColors.textTertiary,
                ),
              ),
            ],
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
            valueColor: const AlwaysStoppedAnimation(AppColors.emerald),
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
                  await db.tasksDao.completeTask(task.id, XpConstants.mitComplete);
                },
                onDelete: () async {
                  final db = ref.read(databaseProvider);
                  await db.tasksDao.toggleMIT(task.id, false);
                },
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
}
