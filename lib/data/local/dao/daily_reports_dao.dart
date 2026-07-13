import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../tables/daily_reports_table.dart';

part 'daily_reports_dao.g.dart';

@DriftAccessor(tables: [DailyReports])
class DailyReportsDao extends DatabaseAccessor<AppDatabase>
    with _$DailyReportsDaoMixin {
  DailyReportsDao(super.db);

  Future<void> insertReport(DailyReportsCompanion entry) =>
      into(dailyReports).insert(entry);

  /// Get report for a specific date
  Future<DailyReport?> getForDate(DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return (select(dailyReports)
          ..where((r) =>
              r.date.isBiggerOrEqualValue(start) &
              r.date.isSmallerThanValue(end)))
        .getSingleOrNull();
  }

  /// Get recent reports for insights
  Future<List<DailyReport>> getRecent({int limit = 30}) =>
      (select(dailyReports)
            ..orderBy([(r) => OrderingTerm.desc(r.date)])
            ..limit(limit))
          .get();

  /// Get reports generated since a given timestamp
  Future<List<DailyReport>> getModifiedSince(DateTime since) =>
      (select(dailyReports)
            ..where((r) => r.generatedAt.isBiggerOrEqualValue(since)))
          .get();

  /// Upsert report (insert or update on conflict)
  Future<void> upsertReport(DailyReportsCompanion entry) =>
      into(dailyReports).insertOnConflictUpdate(entry);
}
