import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/xp_constants.dart';
import '../../../data/local/database/app_database.dart';
import '../../../data/local/tables/xp_ledger_table.dart';
import '../../../data/local/tables/tasks_table.dart';
import '../../achievements/models/achievement_checker.dart';
import '../../xp/models/streak_service.dart';

const _uuid = Uuid();

/// Centralized task completion service.
///
/// All task completions MUST go through this service to ensure:
/// 1. Task is marked complete in the tasks table
/// 2. XP ledger entry is appended (so lifetime XP stays accurate)
/// 3. All-MITs bonus is checked
///
/// This prevents the bug where Home completion skipped the XP ledger
/// while Tasks screen included it.
class TaskCompletionService {
  final AppDatabase _db;

  TaskCompletionService(this._db);

  /// Complete a task and award XP. Returns the XP earned.
  Future<int> completeTask(Task task) async {
    // Calculate XP: MIT gets mitComplete, normal gets taskComplete
    final xp = task.isMIT ? XpConstants.mitComplete : XpConstants.taskComplete;

    // 1. Mark task complete in DB
    await _db.tasksDao.completeTask(task.id, xp);

    // 2. Append XP ledger entry (the critical step Home was missing)
    await _db.xpLedgerDao.appendEntry(XpLedgerEntriesCompanion(
      id: Value(_uuid.v4()),
      actionType: Value(task.isMIT
          ? XpActionTypeColumn.mitComplete
          : XpActionTypeColumn.taskComplete),
      pointsDelta: Value(xp),
      sourceEntityId: Value(task.id),
      explanation: Value(
          'Completed ${task.isMIT ? "MIT" : "task"}: ${task.title}'),
    ));

    // 2.5. Clone task if recurrence is configured
    if (task.recurrenceRule != null) {
      final baseDate = task.dueDate ?? DateTime.now();
      final nextDueDate = _calculateNextDueDate(baseDate, task.recurrenceRule!);

      await _db.tasksDao.insertTask(TasksCompanion(
        id: Value(_uuid.v4()),
        title: Value(task.title),
        description: Value(task.description),
        energyLevel: Value(task.energyLevel),
        estimatedMinutes: Value(task.estimatedMinutes),
        frictionScore: Value(task.frictionScore),
        category: Value(task.category),
        dueDate: Value(nextDueDate),
        recurrenceRule: Value(task.recurrenceRule),
        sortOrder: Value(task.sortOrder),
      ));
    }

    // 3. Check if all MITs are now complete → award bonus
    await _checkAllMITsBonus();

    // 4. Record activity and run achievement check
    await StreakService.recordActivity();
    await AchievementChecker.runCheck(_db);

    return xp;
  }

  /// Calculates the next due date based on the base date and recurrence rule.
  DateTime _calculateNextDueDate(DateTime baseDate, RecurrenceRuleColumn rule) {
    switch (rule) {
      case RecurrenceRuleColumn.daily:
        return baseDate.add(const Duration(days: 1));
      case RecurrenceRuleColumn.weekdays:
        var next = baseDate.add(const Duration(days: 1));
        while (next.weekday == DateTime.saturday || next.weekday == DateTime.sunday) {
          next = next.add(const Duration(days: 1));
        }
        return next;
      case RecurrenceRuleColumn.weekly:
        return baseDate.add(const Duration(days: 7));
      case RecurrenceRuleColumn.monthly:
        int newMonth = baseDate.month + 1;
        int newYear = baseDate.year;
        if (newMonth > 12) {
          newMonth = 1;
          newYear += 1;
        }
        int newDay = baseDate.day;
        // Check days count of the target month to clamp if day overflows (e.g. 31 -> 28/29)
        final lastDayOfNextMonth = DateTime(newYear, newMonth + 1, 0).day;
        if (newDay > lastDayOfNextMonth) {
          newDay = lastDayOfNextMonth;
        }
        return DateTime(
          newYear,
          newMonth,
          newDay,
          baseDate.hour,
          baseDate.minute,
          baseDate.second,
        );
    }
  }

  /// Check if all 3 MITs are completed and award the bonus if so.
  Future<void> _checkAllMITsBonus() async {
    final mits = await _db.tasksDao.getMITs();
    if (mits.length == 3 && mits.every((t) => t.isCompleted)) {
      // Check we haven't already awarded this today
      final existing = await _db.xpLedgerDao
          .sumTodayByType(XpActionTypeColumn.allMitsDaily);
      if (existing == 0) {
        await _db.xpLedgerDao.appendEntry(XpLedgerEntriesCompanion(
          id: Value(_uuid.v4()),
          actionType: const Value(XpActionTypeColumn.allMitsDaily),
          pointsDelta: const Value(XpConstants.allMitsDaily),
          explanation: const Value('All 3 MITs completed today! 🎯'),
        ));
      }
    }
  }
}
