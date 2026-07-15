import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../tables/daily_scores_table.dart';

part 'daily_scores_dao.g.dart';

@DriftAccessor(tables: [DailyScores])
class DailyScoresDao extends DatabaseAccessor<AppDatabase>
    with _$DailyScoresDaoMixin {
  DailyScoresDao(super.db);

  Future<void> insertScore(DailyScoresCompanion entry) =>
      into(dailyScores).insert(entry);

  Future<void> upsertScore(DailyScoresCompanion entry) =>
      into(dailyScores).insertOnConflictUpdate(entry);

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
