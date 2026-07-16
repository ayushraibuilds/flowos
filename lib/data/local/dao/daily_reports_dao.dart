import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../database/app_database.dart';
import '../tables/daily_reports_table.dart';

part 'daily_reports_dao.g.dart';

@DriftAccessor(tables: [DailyReports])
class DailyReportsDao extends DatabaseAccessor<AppDatabase>
    with _$DailyReportsDaoMixin {
  DailyReportsDao(super.db);

  final _uuid = const Uuid();

  Future<DailyReport?> getById(String id) =>
      (select(dailyReports)..where((r) => r.id.equals(id))).getSingleOrNull();

  Future<void> _recordOutboxUpsert(String id) async {
    final report = await getById(id);
    if (report != null) {
      await db.into(db.syncOutbox).insert(SyncOutboxCompanion(
        id: Value(_uuid.v4()),
        entityTable: const Value('daily_reports'),
        entityId: Value(id),
        operation: const Value('upsert'),
        serializedData: Value(jsonEncode(report.toJson())),
      ));
    }
  }

  Future<void> insertReport(DailyReportsCompanion entry) async {
    await transaction(() async {
      await into(dailyReports).insert(entry);
      await _recordOutboxUpsert(entry.id.value);
    });
  }

  /// Get report for a specific date
  Future<DailyReport?> getForDate(DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return (select(dailyReports)
          ..where((r) =>
              r.date.isBiggerOrEqualValue(start) &
              r.date.isSmallerThanValue(end) &
              r.deletedAt.isNull()))
        .getSingleOrNull();
  }

  /// Get recent reports for insights
  Future<List<DailyReport>> getRecent({int limit = 30}) =>
      (select(dailyReports)
            ..where((r) => r.deletedAt.isNull())
            ..orderBy([(r) => OrderingTerm.desc(r.date)])
            ..limit(limit))
          .get();

  /// Get reports modified since a given timestamp
  Future<List<DailyReport>> getModifiedSince(DateTime since) =>
      (select(dailyReports)
            ..where((r) => r.updatedAt.isBiggerOrEqualValue(since)))
          .get();

  /// Upsert report (insert or update on conflict)
  Future<void> upsertReport(DailyReportsCompanion entry) async {
    await transaction(() async {
      final updatedEntry = entry.copyWith(
        updatedAt: Value(DateTime.now()),
      );
      await into(dailyReports).insertOnConflictUpdate(updatedEntry);
      await _recordOutboxUpsert(entry.id.value);
    });
  }

  // ─── Sync Bypass ───────────────────────────────────────────────

  Future<void> insertReportFromSync(DailyReportsCompanion entry) => into(dailyReports).insert(entry);
  Future<void> updateReportFromSync(DailyReportsCompanion entry) =>
      (update(dailyReports)..where((r) => r.id.equals(entry.id.value))).write(entry);
}
