import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../tables/tasks_table.dart';

part 'tasks_dao.g.dart';

@DriftAccessor(tables: [Tasks])
class TasksDao extends DatabaseAccessor<AppDatabase> with _$TasksDaoMixin {
  TasksDao(super.db);

  // ─── Read ──────────────────────────────────────────────────────

  /// All active (not deleted) tasks, ordered by sort order
  Future<List<Task>> getAllActive() => (select(tasks)
        ..where((t) => t.deletedAt.isNull())
        ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
      .get();

  /// Watch all active tasks (reactive stream)
  Stream<List<Task>> watchAllActive() => (select(tasks)
        ..where((t) => t.deletedAt.isNull())
        ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
      .watch();

  /// Get tasks by energy level
  Future<List<Task>> getByEnergyLevel(EnergyLevelColumn level) =>
      (select(tasks)
            ..where((t) => t.deletedAt.isNull() & t.energyLevel.equalsValue(level))
            ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
          .get();

  /// Get today's MITs (max 3)
  Future<List<Task>> getMITs() => (select(tasks)
        ..where((t) => t.deletedAt.isNull() & t.isMIT.equals(true))
        ..limit(3))
      .get();

  /// Watch today's MITs
  Stream<List<Task>> watchMITs() => (select(tasks)
        ..where((t) => t.deletedAt.isNull() & t.isMIT.equals(true))
        ..limit(3))
      .watch();

  /// Get incomplete tasks
  Future<List<Task>> getIncomplete() => (select(tasks)
        ..where((t) => t.deletedAt.isNull() & t.isCompleted.equals(false))
        ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
      .get();

  /// Get a single task by ID
  Future<Task?> getById(String id) =>
      (select(tasks)..where((t) => t.id.equals(id))).getSingleOrNull();

  // ─── Write ─────────────────────────────────────────────────────

  /// Insert a new task
  Future<void> insertTask(TasksCompanion entry) => into(tasks).insert(entry);

  /// Update a task
  Future<void> updateTask(TasksCompanion entry) =>
      (update(tasks)..where((t) => t.id.equals(entry.id.value)))
          .write(entry);

  /// Mark task as completed
  Future<void> completeTask(String id, int xp) =>
      (update(tasks)..where((t) => t.id.equals(id))).write(TasksCompanion(
        isCompleted: const Value(true),
        completedAt: Value(DateTime.now()),
        xpEarned: Value(xp),
        updatedAt: Value(DateTime.now()),
      ));

  /// Toggle MIT status
  Future<void> toggleMIT(String id, bool isMIT) =>
      (update(tasks)..where((t) => t.id.equals(id))).write(TasksCompanion(
        isMIT: Value(isMIT),
        updatedAt: Value(DateTime.now()),
      ));

  /// Soft delete
  Future<void> softDelete(String id) =>
      (update(tasks)..where((t) => t.id.equals(id))).write(TasksCompanion(
        deletedAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ));

  /// Reorder tasks
  Future<void> reorder(List<String> orderedIds) async {
    await transaction(() async {
      for (int i = 0; i < orderedIds.length; i++) {
        await (update(tasks)..where((t) => t.id.equals(orderedIds[i])))
            .write(TasksCompanion(sortOrder: Value(i)));
      }
    });
  }

  /// Count completed tasks for today
  Future<int> countCompletedToday() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final result = await (select(tasks)
          ..where((t) =>
              t.isCompleted.equals(true) &
              t.completedAt.isBiggerOrEqualValue(startOfDay) &
              t.completedAt.isSmallerThanValue(endOfDay)))
        .get();
    return result.length;
  }

  /// Get tasks modified since a given timestamp (for sync push).
  /// Includes soft-deleted tasks so their deletion syncs.
  Future<List<Task>> getModifiedSince(DateTime since) =>
      (select(tasks)
            ..where((t) => t.updatedAt.isBiggerOrEqualValue(since))
            ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
          .get();
}
