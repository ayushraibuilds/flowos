import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../tables/focus_sessions_table.dart';

part 'focus_sessions_dao.g.dart';

@DriftAccessor(tables: [FocusSessions])
class FocusSessionsDao extends DatabaseAccessor<AppDatabase>
    with _$FocusSessionsDaoMixin {
  FocusSessionsDao(super.db);

  /// Insert a new session
  Future<void> insertSession(FocusSessionsCompanion entry) =>
      into(focusSessions).insert(entry);

  /// Update a session (e.g., when completed)
  Future<void> updateSession(FocusSessionsCompanion entry) =>
      (update(focusSessions)..where((s) => s.id.equals(entry.id.value)))
          .write(entry);

  /// Get all sessions for a date range
  Future<List<FocusSession>> getByDateRange(
      DateTime start, DateTime end) =>
      (select(focusSessions)
            ..where((s) =>
                s.startedAt.isBiggerOrEqualValue(start) &
                s.startedAt.isSmallerThanValue(end))
            ..orderBy([(s) => OrderingTerm.desc(s.startedAt)]))
          .get();

  /// Get today's sessions
  Future<List<FocusSession>> getToday() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));
    return getByDateRange(start, end);
  }

  /// Watch today's sessions
  Stream<List<FocusSession>> watchToday() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));
    return (select(focusSessions)
          ..where((s) =>
              s.startedAt.isBiggerOrEqualValue(start) &
              s.startedAt.isSmallerThanValue(end))
          ..orderBy([(s) => OrderingTerm.desc(s.startedAt)]))
        .watch();
  }

  /// Get sessions for a specific task
  Future<List<FocusSession>> getByTask(String taskId) =>
      (select(focusSessions)
            ..where((s) => s.taskId.equals(taskId))
            ..orderBy([(s) => OrderingTerm.desc(s.startedAt)]))
          .get();

  /// Get a single session by its ID
  Future<FocusSession?> getById(String id) =>
      (select(focusSessions)..where((s) => s.id.equals(id))).getSingleOrNull();

  /// Total focus minutes today
  Future<int> totalFocusMinutesToday() async {
    final sessions = await getToday();
    return sessions.fold<int>(0, (sum, s) => sum + s.actualMinutes);
  }

  /// Watch total lifetime focus minutes
  Stream<int> watchLifetimeFocusMinutes() {
    return select(focusSessions).watch().map((sessions) =>
        sessions.fold<int>(0, (sum, s) => sum + s.actualMinutes));
  }

  /// Get sessions started since a given timestamp (for sync push).
  Future<List<FocusSession>> getModifiedSince(DateTime since) =>
      (select(focusSessions)
            ..where((s) => s.startedAt.isBiggerOrEqualValue(since))
            ..orderBy([(s) => OrderingTerm.desc(s.startedAt)]))
          .get();
}
