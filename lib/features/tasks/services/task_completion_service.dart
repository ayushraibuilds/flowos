import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/xp_constants.dart';
import '../../../data/local/database/app_database.dart';
import '../../../data/local/tables/xp_ledger_table.dart';

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

    // 3. Check if all MITs are now complete → award bonus
    await _checkAllMITsBonus();

    return xp;
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
