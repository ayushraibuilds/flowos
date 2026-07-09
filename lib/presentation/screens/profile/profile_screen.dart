import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/constants/xp_constants.dart';

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
              _buildLevelCard(),
              const SizedBox(height: AppSpacing.xxl),
              // ─── Stats Grid ─────────────────────────────────────
              _buildStatsGrid(),
              const SizedBox(height: AppSpacing.xxl),
              // ─── Heatmap Calendar ───────────────────────────────
              _buildHeatmapCalendar(),
              const SizedBox(height: AppSpacing.xxl),
              // ─── Achievements ───────────────────────────────────
              _buildAchievements(),
              const SizedBox(height: AppSpacing.xxxl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLevelCard() {
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
                '1',
                style: AppTypography.display.copyWith(
                  color: AppColors.emerald,
                  fontSize: 36,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            XpConstants.tierName(1),
            style: AppTypography.h3.copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: AppSpacing.sm),
          // XP progress
          Text(
            '0 / ${XpConstants.xpForLevel(2)} XP to next level',
            style: AppTypography.monoSmall.copyWith(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: 0,
              minHeight: 6,
              backgroundColor: AppColors.background0,
              valueColor: AlwaysStoppedAnimation(AppColors.emerald),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            '0 lifetime XP',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    final stats = [
      (icon: '⏱️', value: '0h', label: 'Focus Time'),
      (icon: '✅', value: '0', label: 'Tasks Done'),
      (icon: '🔥', value: '0', label: 'Best Streak'),
      (icon: '📅', value: '0', label: 'Current Streak'),
      (icon: '🔄', value: '0', label: 'Recoveries'),
      (icon: '🏆', value: '0', label: 'Badges'),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: AppSpacing.md,
        mainAxisSpacing: AppSpacing.md,
        childAspectRatio: 1.1,
      ),
      itemCount: stats.length,
      itemBuilder: (context, i) {
        final stat = stats[i];
        return Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.background2,
            borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
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
                ),
              ),
              const SizedBox(height: 2),
              Text(
                stat.label,
                style: AppTypography.caption.copyWith(
                  color: AppColors.textTertiary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeatmapCalendar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Activity',
          style: AppTypography.h2.copyWith(color: AppColors.textPrimary),
        ),
        const SizedBox(height: AppSpacing.md),
        // Simplified heatmap — 7 columns (days) × 4 rows (weeks)
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.background2,
            borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
          ),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
            ),
            itemCount: 28,
            itemBuilder: (context, i) {
              return Container(
                decoration: BoxDecoration(
                  color: AppColors.background0,
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAchievements() {
    final badges = [
      (emoji: '🌅', name: 'Early Bird', locked: true),
      (emoji: '🔥', name: 'Flow Master', locked: true),
      (emoji: '📵', name: 'Digital Detox', locked: true),
      (emoji: '🎯', name: 'Triple Threat', locked: true),
      (emoji: '⚡', name: '1000 XP Day', locked: true),
      (emoji: '👑', name: 'Consistency', locked: true),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Achievements',
          style: AppTypography.h2.copyWith(color: AppColors.textPrimary),
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: badges.length,
            separatorBuilder: (_, __) =>
                const SizedBox(width: AppSpacing.md),
            itemBuilder: (context, i) {
              final badge = badges[i];
              return Container(
                width: 80,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.background2,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      badge.locked ? '🔒' : badge.emoji,
                      style: TextStyle(
                        fontSize: 28,
                        color: badge.locked
                            ? AppColors.textTertiary
                            : null,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      badge.name,
                      style: AppTypography.caption.copyWith(
                        color: badge.locked
                            ? AppColors.textTertiary
                            : AppColors.textSecondary,
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
        ),
      ],
    );
  }
}
