import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../database/app_database.dart';
import '../tables/daily_scores_table.dart';

part 'daily_scores_dao.g.dart';

@DriftAccessor(tables: [DailyScores])
class DailyScoresDao extends DatabaseAccessor<AppDatabase>
    with _$DailyScoresDaoMixin {
  DailyScoresDao(super.db);

  final _uuid = const Uuid();

  Future<void> _recordOutboxUpsert(DateTime day) async {
    final score = await getForDay(day);
    if (score != null) {
      final dayStr = day.toIso8601String().substring(0, 10);
      await db.into(db.syncOutbox).insert(SyncOutboxCompanion(
        id: Value(_uuid.v4()),
        entityTable: const Value('daily_scores'),
        entityId: Value(dayStr),
        operation: const Value('upsert'),
        serializedData: Value(jsonEncode(score.toJson())),
      ));
    }
  }

  Future<DailyScore?> getById(String id) {
    try {
      final date = DateTime.parse(id);
      return getForDay(date);
    } catch (_) {
      return Future.value(null);
    }
  }

  Future<void> insertScore(DailyScoresCompanion entry) async {
    await transaction(() async {
      await into(dailyScores).insert(entry);
      if (entry.day.present) {
        await _recordOutboxUpsert(entry.day.value);
      }
    });
  }

  Future<void> upsertScore(DailyScoresCompanion entry) async {
    await transaction(() async {
      await into(dailyScores).insertOnConflictUpdate(entry);
      if (entry.day.present) {
        await _recordOutboxUpsert(entry.day.value);
      }
    });
  }

  // ─── Sync Bypass ───────────────────────────────────────────────

  Future<void> insertScoreFromSync(DailyScoresCompanion entry) =>
      into(dailyScores).insertOnConflictUpdate(entry);

  Future<void> updateScoreFromSync(DailyScoresCompanion entry) =>
      into(dailyScores).insertOnConflictUpdate(entry);

  Future<List<DailyScore>> getModifiedSince(DateTime since) =>
      (select(dailyScores)
            ..where((s) => s.computedAt.isBiggerOrEqualValue(since))
            ..orderBy([(s) => OrderingTerm.desc(s.computedAt)]))
          .get();

  Future<DailyScore?> getForDay(DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    return (select(dailyScores)
          ..where((s) => s.day.equals(startOfDay)))
        .getSingleOrNull();
  }

  Stream<DailyScore?> watchForDay(DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    return (select(dailyScores)
          ..where((s) => s.day.equals(startOfDay)))
        .watchSingleOrNull();
  }

  Future<List<DailyScore>> getScoresInRange(DateTime start, DateTime end) {
    final startOfDay = DateTime(start.year, start.month, start.day);
    final endOfDay = DateTime(end.year, end.month, end.day);
    return (select(dailyScores)
          ..where((s) =>
              s.day.isBiggerOrEqualValue(startOfDay) &
              s.day.isSmallerOrEqualValue(endOfDay))
          ..orderBy([(s) => OrderingTerm.asc(s.day)]))
        .get();
  }

  Stream<List<DailyScore>> watchScoresInRange(DateTime start, DateTime end) {
    final startOfDay = DateTime(start.year, start.month, start.day);
    final endOfDay = DateTime(end.year, end.month, end.day);
    return (select(dailyScores)
          ..where((s) =>
              s.day.isBiggerOrEqualValue(startOfDay) &
              s.day.isSmallerOrEqualValue(endOfDay))
          ..orderBy([(s) => OrderingTerm.asc(s.day)]))
        .watch();
  }

  Future<void> deleteForDay(DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    return (delete(dailyScores)
          ..where((s) => s.day.equals(startOfDay)))
        .go();
  }

  Future<void> clearAll() => delete(dailyScores).go();
}
