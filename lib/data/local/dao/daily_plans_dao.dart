import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../tables/daily_plans_table.dart';

part 'daily_plans_dao.g.dart';

@DriftAccessor(tables: [DailyPlans])
class DailyPlansDao extends DatabaseAccessor<AppDatabase>
    with _$DailyPlansDaoMixin {
  DailyPlansDao(super.db);

  Future<void> insertPlan(DailyPlansCompanion entry) =>
      into(dailyPlans).insert(entry);

  Future<void> updatePlan(DailyPlansCompanion entry) =>
      (update(dailyPlans)..where((p) => p.id.equals(entry.id.value)))
          .write(entry);

  /// Get today's plan
  Future<DailyPlan?> getToday() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));
    return (select(dailyPlans)
          ..where((p) =>
              p.date.isBiggerOrEqualValue(start) &
              p.date.isSmallerThanValue(end)))
        .getSingleOrNull();
  }

  /// Watch today's plan
  Stream<DailyPlan?> watchToday() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));
    return (select(dailyPlans)
          ..where((p) =>
              p.date.isBiggerOrEqualValue(start) &
              p.date.isSmallerThanValue(end)))
        .watchSingleOrNull();
  }

  /// Mark intention completed
  Future<void> completeIntention(String id) =>
      (update(dailyPlans)..where((p) => p.id.equals(id))).write(
        const DailyPlansCompanion(
          intentionCompleted: Value(true),
        ),
      );

  /// Mark shutdown completed
  Future<void> completeShutdown(String id) =>
      (update(dailyPlans)..where((p) => p.id.equals(id))).write(
        const DailyPlansCompanion(
          shutdownCompleted: Value(true),
        ),
      );
}
