import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/constants/xp_constants.dart';

/// Home Dashboard — the "command center."
/// Shows Flow Score, XP bar, MITs, quick actions, and attention budget.
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
              _buildHeader(context),
              const SizedBox(height: AppSpacing.xxl),
              // ─── Flow Score Card ────────────────────────────────
              _buildFlowScoreCard(context),
              const SizedBox(height: AppSpacing.md),
              // ─── XP Progress Bar ───────────────────────────────
              _buildXPBar(context),
              const SizedBox(height: AppSpacing.xxl),
              // ─── MITs Section ──────────────────────────────────
              _buildMITsSection(context),
              const SizedBox(height: AppSpacing.xxl),
              // ─── Quick Actions ─────────────────────────────────
              _buildQuickActions(context),
              const SizedBox(height: AppSpacing.xxl),
              // ─── Attention Budget ──────────────────────────────
              _buildAttentionBudget(context),
              const SizedBox(height: AppSpacing.xxxl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
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
              '1',
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
                'Level 1 · ${XpConstants.tierName(1)}',
                style: AppTypography.h3.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Getting started',
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
                '0',
                style: AppTypography.monoSmall.copyWith(
                  color: AppColors.warningAmber,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFlowScoreCard(BuildContext context) {
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
            'B',
            style: AppTypography.display.copyWith(
              color: AppColors.gradeB,
              fontSize: 64,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '72',
            style: AppTypography.monoSmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Solid start. Keep building momentum.',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildXPBar(BuildContext context) {
    const currentXP = 0;
    final nextLevelXP = XpConstants.xpForLevel(2);
    final progress = currentXP / nextLevelXP;

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
              '$currentXP / $nextLevelXP XP',
              style: AppTypography.monoSmall.copyWith(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
            Text(
              'Level 2',
              style: AppTypography.caption.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMITsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Today's MITs",
          style: AppTypography.h2.copyWith(color: AppColors.textPrimary),
        ),
        const SizedBox(height: AppSpacing.md),
        // Placeholder for empty state
        Container(
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
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      (icon: '🎯', label: 'Focus', onTap: () => context.go('/focus')),
      (icon: '📝', label: 'Add Task', onTap: () => context.go('/tasks')),
      (icon: '📱', label: 'Log Scroll', onTap: () {}),
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

  Widget _buildAttentionBudget(BuildContext context) {
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
              '0 / 30 min',
              style: AppTypography.monoSmall.copyWith(
                color: AppColors.emerald,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: const LinearProgressIndicator(
            value: 0,
            minHeight: 4,
            backgroundColor: AppColors.background2,
            valueColor: AlwaysStoppedAnimation(AppColors.emerald),
          ),
        ),
      ],
    );
  }
}
