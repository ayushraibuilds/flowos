import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

// ═══════════════════════════════════════════════════════════════════
// Reusable state widgets for every screen in FlowOS.
// Every screen should use these instead of ad-hoc implementations.
// ═══════════════════════════════════════════════════════════════════

/// Empty state — shown when there's no data yet.
/// Includes emoji, title, subtitle, and optional CTA button.
class FlowEmptyState extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const FlowEmptyState({
    super.key,
    required this.emoji,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 56)),
            const SizedBox(height: AppSpacing.xxl),
            Text(
              title,
              style: AppTypography.h2.copyWith(color: AppColors.textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              subtitle,
              style: AppTypography.body.copyWith(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.xxl),
              ElevatedButton(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ─── Preset empty states ─────────────────────────────────

  /// No tasks yet
  static FlowEmptyState tasks({VoidCallback? onAdd}) => FlowEmptyState(
        emoji: '📝',
        title: 'No tasks yet',
        subtitle: 'Add your first task or use Brain Dump\nto get AI-sorted tasks.',
        actionLabel: 'Add Task',
        onAction: onAdd,
      );

  /// No focus sessions today
  static const focusSessions = FlowEmptyState(
    emoji: '⏱️',
    title: 'No focus sessions today',
    subtitle: 'Start a focus session to earn XP\nand build your streak.',
  );

  /// No insights available
  static const insights = FlowEmptyState(
    emoji: '📊',
    title: 'Not enough data yet',
    subtitle: 'Use FlowOS for a few days\nto unlock personalized insights.',
  );

  /// No achievements
  static const achievements = FlowEmptyState(
    emoji: '🏆',
    title: 'No achievements unlocked',
    subtitle: 'Complete tasks, focus sessions, and\nbuild streaks to earn badges.',
  );

  /// No scroll logs
  static const scrollLogs = FlowEmptyState(
    emoji: '📱',
    title: 'No scroll data',
    subtitle: 'Log your scrolling time to track\nattention costs.',
  );
}

/// Loading state — centered spinner with optional message.
class FlowLoadingState extends StatelessWidget {
  final String? message;

  const FlowLoadingState({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: AppColors.emerald,
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: AppSpacing.lg),
            Text(
              message!,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Error state — shown when something fails.
/// Includes emoji, error message, and retry button.
class FlowErrorState extends StatelessWidget {
  final String? message;
  final VoidCallback? onRetry;

  const FlowErrorState({
    super.key,
    this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('😔', style: TextStyle(fontSize: 48)),
            const SizedBox(height: AppSpacing.xxl),
            Text(
              'Something went wrong',
              style: AppTypography.h3.copyWith(color: AppColors.textPrimary),
            ),
            if (message != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                message!,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.xxl),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Try Again'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Network-aware wrapper — shows offline banner when disconnected.
class FlowNetworkBanner extends StatelessWidget {
  final bool isOffline;
  final Widget child;

  const FlowNetworkBanner({
    super.key,
    required this.isOffline,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (isOffline)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.xs,
              horizontal: AppSpacing.lg,
            ),
            color: AppColors.warningAmber.withValues(alpha: 0.15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.wifi_off_rounded,
                  size: 14,
                  color: AppColors.warningAmber,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Offline — changes will sync when connected',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.warningAmber,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        Expanded(child: child),
      ],
    );
  }
}

/// Sync status indicator — shows in app bar or home screen.
class FlowSyncIndicator extends StatelessWidget {
  final String status; // 'idle', 'syncing', 'synced', 'error'

  const FlowSyncIndicator({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final (icon, color, label) = switch (status) {
      'syncing' => (Icons.sync_rounded, AppColors.focusBlue, 'Syncing...'),
      'synced' => (Icons.cloud_done_rounded, AppColors.emerald, 'Synced'),
      'error' => (Icons.sync_problem_rounded, AppColors.dangerCoral, 'Sync error'),
      _ => (Icons.cloud_off_rounded, AppColors.textTertiary, 'Offline'),
    };

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTypography.caption.copyWith(
            color: color,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}
