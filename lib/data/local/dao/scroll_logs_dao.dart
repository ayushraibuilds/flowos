import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../database/app_database.dart';
import '../tables/scroll_logs_table.dart';

part 'scroll_logs_dao.g.dart';

@DriftAccessor(tables: [ScrollLogs])
class ScrollLogsDao extends DatabaseAccessor<AppDatabase>
    with _$ScrollLogsDaoMixin {
  ScrollLogsDao(super.db);

  final _uuid = const Uuid();

  Future<ScrollLog?> getById(String id) =>
      (select(scrollLogs)..where((l) => l.id.equals(id))).getSingleOrNull();

  Future<void> _recordOutboxUpsert(String id) async {
    final log = await getById(id);
    if (log != null) {
      await db.into(db.syncOutbox).insert(SyncOutboxCompanion(
        id: Value(_uuid.v4()),
        entityTable: const Value('scroll_logs'),
        entityId: Value(id),
        operation: const Value('upsert'),
        serializedData: Value(jsonEncode(log.toJson())),
      ));
    }
  }

  Future<void> insertLog(ScrollLogsCompanion entry) async {
    await transaction(() async {
      await into(scrollLogs).insert(entry);
      await _recordOutboxUpsert(entry.id.value);
    });
  }

  /// Get today's total scroll minutes
  Future<int> getDailyTotal({DateTime? clock}) async {
    final now = clock ?? DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final logs = await (select(
      scrollLogs,
    )..where((l) => l.timestamp.isBiggerOrEqualValue(start) & l.deletedAt.isNull())).get();
    return logs.fold<int>(0, (sum, l) => sum + l.durationMinutes);
  }

  /// Watch today's total
  Stream<int> watchDailyTotal({DateTime? clock}) {
    final now = clock ?? DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    return (select(scrollLogs)
          ..where((l) => l.timestamp.isBiggerOrEqualValue(start) & l.deletedAt.isNull()))
        .watch()
        .map((logs) => logs.fold<int>(0, (sum, l) => sum + l.durationMinutes));
  }

  /// Get last 7 days of data (for weekly chart)
  Future<List<ScrollLog>> getWeeklyData({DateTime? clock}) {
    final now = clock ?? DateTime.now();
    final start = now.subtract(const Duration(days: 7));
    return (select(scrollLogs)
          ..where((l) => l.timestamp.isBiggerOrEqualValue(start) & l.deletedAt.isNull())
          ..orderBy([(l) => OrderingTerm.asc(l.timestamp)]))
        .get();
  }

  /// Get logs modified since a given timestamp (for sync push).
  Future<List<ScrollLog>> getModifiedSince(DateTime since) => (select(
    scrollLogs,
  )..where((l) => l.updatedAt.isBiggerOrEqualValue(since))).get();

  // ─── Sync Bypass ───────────────────────────────────────────────

  Future<void> insertLogFromSync(ScrollLogsCompanion entry) => into(scrollLogs).insert(entry);
  Future<void> updateLogFromSync(ScrollLogsCompanion entry) =>
      (update(scrollLogs)..where((l) => l.id.equals(entry.id.value))).write(entry);

  /// Delete auto scroll logs for a specific app today
  Future<void> deleteAutoLogsForToday(String appName, DateTime start) {
    return (delete(scrollLogs)..where(
          (l) =>
              l.appName.equals(appName) &
              l.timestamp.isBiggerOrEqualValue(start),
        ))
        .go();
  }

  /// Replace the complete auto-imported snapshot for today without touching
  /// the user's manual logs.
  Future<void> deleteAllAutoLogsForToday(DateTime start) {
    return (delete(scrollLogs)..where(
          (l) =>
              l.appName.like('% [Auto]') &
              l.timestamp.isBiggerOrEqualValue(start),
        ))
        .go();
  }

  /// Get all scroll logs logged today
  Future<List<ScrollLog>> getTodayLogs({DateTime? clock}) {
    final now = clock ?? DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    return (select(
      scrollLogs,
    )..where((l) => l.timestamp.isBiggerOrEqualValue(start))).get();
  }
}
