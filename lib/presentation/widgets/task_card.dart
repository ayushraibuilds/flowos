import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/local/database/app_database.dart';
import '../../../data/local/tables/tasks_table.dart';

/// Reusable task card — shows title, energy dot, estimated time,
/// MIT badge, and completion checkbox. Swipe to delete.
class TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback onComplete;
  final VoidCallback onDelete;
  final VoidCallback? onTap;

  const TaskCard({
    super.key,
    required this.task,
    required this.onComplete,
    required this.onDelete,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final energyColor = _energyColor(task.energyLevel);
    final energyEmoji = _energyEmoji(task.energyLevel);

    return Dismissible(
      key: ValueKey(task.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.xl),
        decoration: BoxDecoration(
          color: AppColors.dangerCoral.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        ),
        child: const Icon(Icons.delete_rounded,
            color: AppColors.dangerCoral, size: 24),
      ),
      confirmDismiss: (_) async {
        HapticFeedback.mediumImpact();
        onDelete();
        return false; // We handle deletion ourselves
      },
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
          decoration: BoxDecoration(
            color: task.isCompleted
                ? AppColors.background2.withValues(alpha: 0.5)
                : AppColors.background2,
            borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
            border: Border.all(
              color: task.isMIT
                  ? AppColors.emerald.withValues(alpha: 0.3)
                  : Colors.white.withValues(alpha: 0.04),
              width: task.isMIT ? 1.5 : 0.5,
            ),
          ),
          child: Row(
            children: [
              // Checkbox
              GestureDetector(
                onTap: task.isCompleted ? null : () {
                  HapticFeedback.mediumImpact();
                  onComplete();
                },
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: task.isCompleted
                          ? AppColors.emerald
                          : energyColor.withValues(alpha: 0.5),
                      width: 2,
                    ),
                    color: task.isCompleted
                        ? AppColors.emerald.withValues(alpha: 0.15)
                        : Colors.transparent,
                  ),
                  child: task.isCompleted
                      ? Icon(Icons.check_rounded,
                          size: 16, color: AppColors.emerald)
                      : null,
                ),
              ),
              const SizedBox(width: AppSpacing.md),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // MIT badge
                        if (task.isMIT) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.emerald.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '⭐ MIT',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.emerald,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                        ],
                        // Energy badge
                        Text(
                          energyEmoji,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      task.title,
                      style: AppTypography.body.copyWith(
                        color: task.isCompleted
                            ? AppColors.textTertiary
                            : AppColors.textPrimary,
                        decoration: task.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Estimated time
              Text(
                '${task.estimatedMinutes}m',
                style: AppTypography.monoSmall.copyWith(
                  color: AppColors.textTertiary,
                  fontSize: 11,
                ),
              ),

              // XP earned badge (if completed)
              if (task.isCompleted && task.xpEarned > 0) ...[
                const SizedBox(width: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.emerald.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '+${task.xpEarned}',
                    style: AppTypography.monoSmall.copyWith(
                      color: AppColors.emerald,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _energyColor(EnergyLevelColumn level) => switch (level) {
        EnergyLevelColumn.deep => AppColors.energyDeep,
        EnergyLevelColumn.medium => AppColors.energyMedium,
        EnergyLevelColumn.light => AppColors.energyLight,
      };

  String _energyEmoji(EnergyLevelColumn level) => switch (level) {
        EnergyLevelColumn.deep => '🔥',
        EnergyLevelColumn.medium => '⚡',
        EnergyLevelColumn.light => '🌿',
      };
}
