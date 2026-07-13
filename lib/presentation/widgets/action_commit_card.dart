import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:uuid/uuid.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../data/local/database/app_database.dart';
import '../../data/local/tables/tasks_table.dart';
import '../../features/onboarding/models/user_profile.dart';
import '../../features/onboarding/providers/onboarding_providers.dart';
import '../../features/reports/models/weekly_action.dart';
import 'flow_surface.dart';

class ActionCommitCard extends ConsumerWidget {
  final WeeklyAction action;
  final VoidCallback? onAccept;
  final VoidCallback? onChooseDifferent;
  final VoidCallback? onSkip;

  const ActionCommitCard({
    super.key,
    required this.action,
    this.onAccept,
    this.onChooseDifferent,
    this.onSkip,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final title = switch (action.type) {
      WeeklyActionType.scheduleFocusWindow => 'Schedule Focus Time 📅',
      WeeklyActionType.reduceOneTrigger => 'Mindful Distraction Limit 📱',
      WeeklyActionType.moveTaskToEnergy => 'Deep Work Shift 🧠',
    };

    final accentColor = switch (action.type) {
      WeeklyActionType.scheduleFocusWindow => AppColors.focusBlue,
      WeeklyActionType.reduceOneTrigger => AppColors.dangerCoral,
      WeeklyActionType.moveTaskToEnergy => AppColors.emerald,
    };

    return FlowSurface(
      variant: FlowSurfaceVariant.standard,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('✨', style: const TextStyle(fontSize: 16)),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'COMMIT TO CHANGE',
                style: AppTypography.monoSmall.copyWith(
                  color: accentColor,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            title,
            style: AppTypography.h3.copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            action.description,
            style: AppTypography.body.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              if (onChooseDifferent != null) ...[
                OutlinedButton(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    onChooseDifferent!();
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
                    ),
                  ),
                  child: const Text('Different Change'),
                ),
                const SizedBox(width: AppSpacing.md),
              ],
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    HapticFeedback.mediumImpact();
                    await _executeAction(ref);
                    if (onAccept != null) onAccept!();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor.withValues(alpha: 0.15),
                    foregroundColor: accentColor,
                    elevation: 0,
                    side: BorderSide(color: accentColor.withValues(alpha: 0.3)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
                    ),
                  ),
                  child: const Text('Accept Change'),
                ),
              ),
            ],
          ),
          if (onSkip != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Center(
              child: TextButton(
                onPressed: () {
                  HapticFeedback.selectionClick();
                  onSkip!();
                },
                child: Text(
                  'Skip for now',
                  style: AppTypography.caption.copyWith(color: AppColors.textTertiary),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _executeAction(WidgetRef ref) async {
    final db = ref.read(databaseProvider);
    final prefs = await SharedPreferences.getInstance();

    switch (action.type) {
      case WeeklyActionType.scheduleFocusWindow:
        // Schedule Focus window for tomorrow
        DateTime targetDate = DateTime.now().add(const Duration(days: 1));
        if (action.weekday != null) {
          while (targetDate.weekday != action.weekday) {
            targetDate = targetDate.add(const Duration(days: 1));
          }
        }
        final dateOnly = DateTime(targetDate.year, targetDate.month, targetDate.day);
        
        final plan = await db.dailyPlansDao.getByDateRange(dateOnly, dateOnly.add(const Duration(days: 1)));
        if (plan == null) {
          await db.dailyPlansDao.insertPlan(DailyPlansCompanion(
            id: Value(const Uuid().v4()),
            date: Value(dateOnly),
            intentionNote: Value('Commitment Focus: ${action.startHour ?? 9}:00 - ${action.endHour ?? 10}:00'),
          ));
        } else {
          await db.dailyPlansDao.updatePlan(DailyPlansCompanion(
            id: Value(plan.id),
            date: Value(plan.date),
            intentionNote: Value('${plan.intentionNote ?? ""}\nCommitment Focus: ${action.startHour ?? 9}:00 - ${action.endHour ?? 10}:00'.trim()),
          ));
        }
        
        if (action.startHour != null) {
          await prefs.setInt('flowos_suggested_focus_start', action.startHour!);
        }
        if (action.endHour != null) {
          await prefs.setInt('flowos_suggested_focus_end', action.endHour!);
        }
        break;

      case WeeklyActionType.reduceOneTrigger:
        // Upgrade user profile protectionMode to firm
        final currentProfile = ref.read(userProfileProvider);
        final updated = UserProfile(
          goals: currentProfile.goals,
          distractions: currentProfile.distractions,
          protectedStartHour: currentProfile.protectedStartHour,
          protectedEndHour: currentProfile.protectedEndHour,
          protectedWeekdaysOnly: currentProfile.protectedWeekdaysOnly,
          protectionMode: 'firm',
        );
        await ref.read(userProfileProvider.notifier).updateProfile(updated);
        break;

      case WeeklyActionType.moveTaskToEnergy:
        // Mark task energy as deep
        if (action.taskId != null) {
          await (db.update(db.tasks)..where((t) => t.id.equals(action.taskId!)))
              .write(const TasksCompanion(
            energyLevel: Value(EnergyLevelColumn.deep),
          ));
        }
        break;
    }
  }
}
