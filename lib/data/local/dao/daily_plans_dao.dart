import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../tables/daily_plans_table.dart';

part 'daily_plans_dao.g.dart';

@DriftAccessor(tables: [DailyPlans])
class DailyPlansDao extends DatabaseAccessor<AppDatabase>
    with _$DailyPlansDaoMixin {
  DailyPlansDao(super.db);

  /// Insert a plan. For daily plans, prefer [upsertToday] to avoid duplicates.
  Future<void> insertPlan(DailyPlansCompanion entry) =>
      into(dailyPlans).insert(entry);

  /// Upsert today's plan — inserts if none exists, updates if one does.
  /// Prevents the duplicate-plan crash when Morning Intention runs twice.
  Future<String> upsertToday(DailyPlansCompanion entry) async {
    final existing = await getToday();
    if (existing != null) {
      // Update the existing plan, keeping its ID
      await (update(dailyPlans)..where((p) => p.id.equals(existing.id)))
          .write(entry);
      return existing.id;
    } else {
      await into(dailyPlans).insert(entry);
      return entry.id.value;
    }
  }

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

  /// Get plan for a specific date range (for streak counting).
  Future<DailyPlan?> getByDateRange(DateTime start, DateTime end) {
    return (select(dailyPlans)
          ..where((p) =>
              p.date.isBiggerOrEqualValue(start) &
              p.date.isSmallerThanValue(end)))
        .getSingleOrNull();
  }

  /// Get a plan by ID.
  Future<DailyPlan?> getById(String id) =>
      (select(dailyPlans)..where((p) => p.id.equals(id))).getSingleOrNull();

  /// Get plans created since a given timestamp (for sync push).
  Future<List<DailyPlan>> getModifiedSince(DateTime since) =>
      (select(dailyPlans)
            ..where((p) => p.createdAt.isBiggerOrEqualValue(since)))
          .get();
}
