import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/constants/xp_constants.dart';
import '../../../data/local/database/app_database.dart';
import '../../../features/dashboard/providers/dashboard_providers.dart';
import '../../../features/flow_garden/providers/garden_providers.dart';
import '../../../features/xp/providers/xp_providers.dart';
import '../../../features/achievements/models/achievement_checker.dart';

/// Live Provider for the last 28 days of focus sessions
final last28DaysSessionsProvider = FutureProvider<List<FocusSession>>((ref) async {
  final db = ref.watch(databaseProvider);
  final now = DateTime.now();
  final start = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 27));
  final end = DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
  return db.focusSessionsDao.getByDateRange(start, end);
});

/// Profile screen — your productivity identity.
/// Level badge, stats grid, heatmap calendar, achievements.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

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
              Text(
                'Profile',
                style: AppTypography.h1.copyWith(color: AppColors.textPrimary),
              ),
              const SizedBox(height: AppSpacing.xxl),
              // ─── Level Card ─────────────────────────────────────
              _buildLevelCard(context, ref),
              const SizedBox(height: AppSpacing.xxl),
              // ─── Stats Grid ─────────────────────────────────────
              _buildStatsGrid(ref),
              const SizedBox(height: AppSpacing.xxl),
              // ─── Heatmap Calendar ───────────────────────────────
              _buildHeatmapCalendar(ref),
              const SizedBox(height: AppSpacing.xxl),
              // ─── Achievements ───────────────────────────────────
              _buildAchievements(ref),
              const SizedBox(height: AppSpacing.xxxl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLevelCard(BuildContext context, WidgetRef ref) {
    final level = ref.watch(currentLevelProvider);
    final tierName = ref.watch(currentTierProvider);
    final lifetimeXp = ref.watch(lifetimeXpProvider).valueOrNull ?? 0;

    final levelBaseXp = XpConstants.xpForLevel(level);
    final nextLevelXp = XpConstants.xpForLevel(level + 1);
    final xpInLevel = lifetimeXp - levelBaseXp;
    final xpNeededInLevel = nextLevelXp - levelBaseXp;
    final progress = xpNeededInLevel > 0 ? (xpInLevel / xpNeededInLevel).clamp(0.0, 1.0) : 1.0;

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
          // Level ring
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.emerald, width: 3),
            ),
            child: Center(
              child: Text(
                '$level',
                style: AppTypography.display.copyWith(
                  color: AppColors.emerald,
                  fontSize: 36,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            tierName,
            style: AppTypography.h3.copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: AppSpacing.sm),
          // XP progress
          Text(
            '$xpInLevel / $xpNeededInLevel XP to next level',
            style: AppTypography.monoSmall.copyWith(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: AppColors.background0,
              valueColor: AlwaysStoppedAnimation(AppColors.emerald),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            '$lifetimeXp lifetime XP',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          // Visually distinct CTA button to enter garden
          ElevatedButton.icon(
            onPressed: () => context.push('/garden'),
            icon: const Text('🌸', style: TextStyle(fontSize: 16)),
            label: const Text('Visit Flow Garden'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.emerald.withValues(alpha: 0.1),
              foregroundColor: AppColors.emerald,
              side: BorderSide(
                color: AppColors.emerald.withValues(alpha: 0.3),
                width: 0.5,
              ),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusButton),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(WidgetRef ref) {
    final focusMinutes = ref.watch(lifetimeFocusMinutesProvider).valueOrNull ?? 0;
    final tasksDone = ref.watch(totalCompletedTasksCountProvider).valueOrNull ?? 0;
    final bestStreak = ref.watch(bestStreakProvider).valueOrNull ?? 0;
    final currentStreak = ref.watch(streakProvider).valueOrNull ?? 0;
    final recoveries = ref.watch(lifetimeRecoveriesCountProvider).valueOrNull ?? 0;
    final achievements = ref.watch(achievementsProvider).valueOrNull ?? [];
    final unlockedAchievementsCount = achievements.length;

    final focusHours = focusMinutes ~/ 60;
    final focusHoursStr = focusHours > 0 ? '${focusHours}h' : '${focusMinutes}m';

    final stats = [
      (icon: '⏱️', value: focusHoursStr, label: 'Focus Time'),
      (icon: '✅', value: '$tasksDone', label: 'Tasks Done'),
      (icon: '🔥', value: '$bestStreak', label: 'Best Streak'),
      (icon: '📅', value: '$currentStreak', label: 'Current Streak'),
      (icon: '🔄', value: '$recoveries', label: 'Recoveries'),
      (icon: '🏆', value: '$unlockedAchievementsCount', label: 'Badges'),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: AppSpacing.md,
        mainAxisSpacing: AppSpacing.md,
        childAspectRatio: 0.95,
      ),
      itemCount: stats.length,
      itemBuilder: (context, i) {
        final stat = stats[i];
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.background2,
            borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.04),
              width: 0.5,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(stat.icon, style: const TextStyle(fontSize: 20)),
              const SizedBox(height: AppSpacing.xs),
              Text(
                stat.value,
                style: AppTypography.monoSmall.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Flexible(
                child: Text(
                  stat.label,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textTertiary,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeatmapCalendar(WidgetRef ref) {
    final last28DaysSessions = ref.watch(last28DaysSessionsProvider).valueOrNull ?? [];

    final dailyMinutes = List<int>.filled(28, 0);
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    for (final s in last28DaysSessions) {
      final sessionDay = DateTime(s.startedAt.year, s.startedAt.month, s.startedAt.day);
      final difference = todayStart.difference(sessionDay).inDays;
      if (difference >= 0 && difference < 28) {
        final gridIndex = 27 - difference;
        dailyMinutes[gridIndex] += s.actualMinutes;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Activity (Last 4 Weeks)',
          style: AppTypography.h2.copyWith(color: AppColors.textPrimary),
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.background2,
            borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.04),
              width: 0.5,
            ),
          ),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              crossAxisSpacing: 6,
              mainAxisSpacing: 6,
            ),
            itemCount: 28,
            itemBuilder: (context, i) {
              final mins = dailyMinutes[i];
              final Color cellColor;
              if (mins == 0) {
                cellColor = AppColors.background0;
              } else if (mins < 25) {
                cellColor = AppColors.emerald.withValues(alpha: 0.2);
              } else if (mins < 60) {
                cellColor = AppColors.emerald.withValues(alpha: 0.45);
              } else if (mins < 120) {
                cellColor = AppColors.emerald.withValues(alpha: 0.7);
              } else {
                cellColor = AppColors.emerald;
              }

              return Tooltip(
                message: mins > 0 ? '$mins mins focused' : 'No focus sessions',
                child: Container(
                  decoration: BoxDecoration(
                    color: cellColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAchievements(WidgetRef ref) {
    final achievementsAsync = ref.watch(achievementsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Achievements',
          style: AppTypography.h2.copyWith(color: AppColors.textPrimary),
        ),
        const SizedBox(height: AppSpacing.md),
        achievementsAsync.when(
          data: (dbList) {
            // Map static metadata configurations with database unlock statuses
            final list = allAchievements.map((info) {
              final isUnlocked = dbList.any((a) => a.achievementKey == info.key.name);
              return (info: info, isUnlocked: isUnlocked);
            }).toList();

            return SizedBox(
              height: 100,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: list.length,
                separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
                itemBuilder: (context, i) {
                  final badge = list[i];
                  return Container(
                    width: 90,
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.background2,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
                      border: Border.all(
                        color: badge.isUnlocked
                            ? AppColors.emerald.withValues(alpha: 0.3)
                            : Colors.white.withValues(alpha: 0.04),
                        width: 0.5,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          badge.isUnlocked ? badge.info.emoji : '🔒',
                          style: TextStyle(
                            fontSize: 28,
                            color: !badge.isUnlocked ? AppColors.textTertiary : null,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          badge.info.name,
                          style: AppTypography.caption.copyWith(
                            color: badge.isUnlocked
                                ? AppColors.textSecondary
                                : AppColors.textTertiary,
                            fontSize: 10,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, s) => Text('Error loading achievements: $e'),
        ),
      ],
    );
  }
}
