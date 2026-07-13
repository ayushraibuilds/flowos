import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../tables/attention_costs_table.dart';

part 'attention_costs_dao.g.dart';

@DriftAccessor(tables: [AttentionCosts])
class AttentionCostsDao extends DatabaseAccessor<AppDatabase>
    with _$AttentionCostsDaoMixin {
  AttentionCostsDao(super.db);

  /// Insert a new attention cost entry
  Future<void> insertCost(AttentionCostsCompanion entry) =>
      into(attentionCosts).insert(entry);

  /// Get all costs logged today
  Future<List<AttentionCost>> getToday() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));
    return (select(attentionCosts)
          ..where((c) =>
              c.timestamp.isBiggerOrEqualValue(start) &
              c.timestamp.isSmallerThanValue(end)))
        .get();
  }

  /// Get total impact score today (returns sum of dailyScoreImpact)
  Future<int> getTodayTotalImpact() async {
    final todayCosts = await getToday();
    return todayCosts.fold<int>(0, (sum, c) => sum + c.dailyScoreImpact);
  }

  /// Watch total impact score today
  Stream<int> watchTodayTotalImpact() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));
    return (select(attentionCosts)
          ..where((c) =>
              c.timestamp.isBiggerOrEqualValue(start) &
              c.timestamp.isSmallerThanValue(end)))
        .watch()
        .map((list) => list.fold<int>(0, (sum, c) => sum + c.dailyScoreImpact));
  }

  /// Get modified since (for sync purposes)
  Future<List<AttentionCost>> getModifiedSince(DateTime since) =>
      (select(attentionCosts)
            ..where((c) => c.timestamp.isBiggerOrEqualValue(since)))
          .get();
}
