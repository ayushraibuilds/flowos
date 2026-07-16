import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../database/app_database.dart';
import '../tables/focus_sessions_table.dart';

part 'focus_sessions_dao.g.dart';

@DriftAccessor(tables: [FocusSessions])
class FocusSessionsDao extends DatabaseAccessor<AppDatabase>
    with _$FocusSessionsDaoMixin {
  FocusSessionsDao(super.db);

  final _uuid = const Uuid();

  Future<void> _recordOutboxUpsert(String id) async {
    final session = await getById(id);
    if (session != null) {
      await db.into(db.syncOutbox).insert(SyncOutboxCompanion(
        id: Value(_uuid.v4()),
        entityTable: const Value('focus_sessions'),
        entityId: Value(id),
        operation: const Value('upsert'),
        serializedData: Value(jsonEncode(session.toJson())),
      ));
    }
  }

  /// Insert a new session
  Future<void> insertSession(FocusSessionsCompanion entry) async {
    await transaction(() async {
      await into(focusSessions).insert(entry);
      await _recordOutboxUpsert(entry.id.value);
    });
  }

  /// Update a session (e.g., when completed)
  Future<void> updateSession(FocusSessionsCompanion entry) async {
    await transaction(() async {
      await (update(focusSessions)..where((s) => s.id.equals(entry.id.value))).write(entry);
      await _recordOutboxUpsert(entry.id.value);
    });
  }

  // ─── Sync Bypass ───────────────────────────────────────────────

  Future<void> insertSessionFromSync(FocusSessionsCompanion entry) => into(focusSessions).insert(entry);
  Future<void> updateSessionFromSync(FocusSessionsCompanion entry) =>
      (update(focusSessions)..where((s) => s.id.equals(entry.id.value))).write(entry);

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

  /// Get sessions modified since a given timestamp (for sync push).
  Future<List<FocusSession>> getModifiedSince(DateTime since) =>
      (select(focusSessions)
            ..where((s) => s.updatedAt.isBiggerOrEqualValue(since))
            ..orderBy([(s) => OrderingTerm.desc(s.updatedAt)]))
          .get();
}
