import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../database/app_database.dart';
import '../tables/daily_plans_table.dart';

part 'daily_plans_dao.g.dart';

@DriftAccessor(tables: [DailyPlans])
class DailyPlansDao extends DatabaseAccessor<AppDatabase>
    with _$DailyPlansDaoMixin {
  DailyPlansDao(super.db);

  final _uuid = const Uuid();

  Future<void> _recordOutboxUpsert(String id) async {
    final plan = await getById(id);
    if (plan != null) {
      await db.into(db.syncOutbox).insert(SyncOutboxCompanion(
        id: Value(_uuid.v4()),
        entityTable: const Value('daily_plans'),
        entityId: Value(id),
        operation: const Value('upsert'),
        serializedData: Value(jsonEncode(plan.toJson())),
      ));
    }
  }

  /// Insert a plan. For daily plans, prefer [upsertToday] to avoid duplicates.
  Future<void> insertPlan(DailyPlansCompanion entry) async {
    await transaction(() async {
      await into(dailyPlans).insert(entry);
      await _recordOutboxUpsert(entry.id.value);
    });
  }

  /// Upsert today's plan — inserts if none exists, updates if one does.
  /// Prevents the duplicate-plan crash when Morning Intention runs twice.
  Future<String> upsertToday(DailyPlansCompanion entry) async {
    return await transaction(() async {
      final existing = await getToday();
      if (existing != null) {
        // Update the existing plan, keeping its ID
        final updatedEntry = entry.copyWith(
          updatedAt: Value(DateTime.now()),
        );
        await (update(dailyPlans)..where((p) => p.id.equals(existing.id)))
            .write(updatedEntry);
        await _recordOutboxUpsert(existing.id);
        return existing.id;
      } else {
        await into(dailyPlans).insert(entry);
        await _recordOutboxUpsert(entry.id.value);
        return entry.id.value;
      }
    });
  }

  Future<void> updatePlan(DailyPlansCompanion entry) async {
    await transaction(() async {
      final updatedEntry = entry.copyWith(
        updatedAt: Value(DateTime.now()),
      );
      await (update(dailyPlans)..where((p) => p.id.equals(entry.id.value)))
          .write(updatedEntry);
      await _recordOutboxUpsert(entry.id.value);
    });
  }

  /// Get today's plan
  Future<DailyPlan?> getToday() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));
    return (select(dailyPlans)
          ..where((p) =>
              p.date.isBiggerOrEqualValue(start) &
              p.date.isSmallerThanValue(end) &
              p.deletedAt.isNull()))
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
              p.date.isSmallerThanValue(end) &
              p.deletedAt.isNull()))
        .watchSingleOrNull();
  }

  /// Mark intention completed
  Future<void> completeIntention(String id) async {
    await transaction(() async {
      await (update(dailyPlans)..where((p) => p.id.equals(id))).write(
        DailyPlansCompanion(
          intentionCompleted: const Value(true),
          updatedAt: Value(DateTime.now()),
        ),
      );
      await _recordOutboxUpsert(id);
    });
  }

  /// Mark shutdown completed
  Future<void> completeShutdown(String id) async {
    await transaction(() async {
      await (update(dailyPlans)..where((p) => p.id.equals(id))).write(
        DailyPlansCompanion(
          shutdownCompleted: const Value(true),
          updatedAt: Value(DateTime.now()),
        ),
      );
      await _recordOutboxUpsert(id);
    });
  }

  /// Get plan for a specific date range (for streak counting).
  Future<DailyPlan?> getByDateRange(DateTime start, DateTime end) {
    return (select(dailyPlans)
          ..where((p) =>
              p.date.isBiggerOrEqualValue(start) &
              p.date.isSmallerThanValue(end) &
              p.deletedAt.isNull()))
        .getSingleOrNull();
  }

  /// Get a plan by ID.
  Future<DailyPlan?> getById(String id) =>
      (select(dailyPlans)..where((p) => p.id.equals(id))).getSingleOrNull();

  /// Get plans created since a given timestamp (for sync push).
  Future<List<DailyPlan>> getModifiedSince(DateTime since) =>
      (select(dailyPlans)
            ..where((p) => p.updatedAt.isBiggerOrEqualValue(since)))
          .get();

  // ─── Sync Bypass ───────────────────────────────────────────────

  Future<void> insertPlanFromSync(DailyPlansCompanion entry) => into(dailyPlans).insert(entry);
  Future<void> updatePlanFromSync(DailyPlansCompanion entry) =>
      (update(dailyPlans)..where((p) => p.id.equals(entry.id.value))).write(entry);
}
