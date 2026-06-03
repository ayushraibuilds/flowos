import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../tables/scroll_logs_table.dart';

part 'scroll_logs_dao.g.dart';

@DriftAccessor(tables: [ScrollLogs])
class ScrollLogsDao extends DatabaseAccessor<AppDatabase>
    with _$ScrollLogsDaoMixin {
  ScrollLogsDao(super.db);

  Future<void> insertLog(ScrollLogsCompanion entry) =>
      into(scrollLogs).insert(entry);

  /// Get today's total scroll minutes
  Future<int> getDailyTotal() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final logs = await (select(scrollLogs)
          ..where((l) => l.timestamp.isBiggerOrEqualValue(start)))
        .get();
    return logs.fold<int>(0, (sum, l) => sum + l.durationMinutes);
  }

  /// Watch today's total
  Stream<int> watchDailyTotal() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    return (select(scrollLogs)
          ..where((l) => l.timestamp.isBiggerOrEqualValue(start)))
        .watch()
        .map((logs) => logs.fold<int>(0, (sum, l) => sum + l.durationMinutes));
  }

  /// Get last 7 days of data (for weekly chart)
  Future<List<ScrollLog>> getWeeklyData() {
    final start = DateTime.now().subtract(const Duration(days: 7));
    return (select(scrollLogs)
          ..where((l) => l.timestamp.isBiggerOrEqualValue(start))
          ..orderBy([(l) => OrderingTerm.asc(l.timestamp)]))
        .get();
  }
}
