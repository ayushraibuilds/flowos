import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';

import 'package:flowos/data/local/database/app_database.dart';
import 'package:flowos/features/insights/services/history_aggregator.dart';
import 'package:flowos/features/attention/repository/attention_data_repository.dart';
import 'package:flowos/features/xp/models/daily_score_calculator.dart';

void main() {
  group('HistoryAggregator V2 Tests', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase.forTesting(DatabaseConnection(NativeDatabase.memory()));
    });

    tearDown(() async {
      await db.close();
    });

    test('getWeeklyAggregate averages only complete V2 days and excludes V1 days', () async {
      final now = DateTime.now();
      final monday = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));

      // Day 1: Complete V2 score = 80
      await db.dailyScoresDao.upsertScore(DailyScoresCompanion.insert(
        day: monday,
        score: 80,
        grade: const Value('A'),
        isIncomplete: false,
        availableWeight: 1.0,
        scoringVersion: 2,
        focusPoints: 35.0,
        intentPoints: 20.0,
        attentionPoints: const Value(15.0),
        carePoints: 10.0,
      ));

      // Day 2: Incomplete V2 score = 90 (Attention omitted, should be excluded from average)
      await db.dailyScoresDao.upsertScore(DailyScoresCompanion.insert(
        day: monday.add(const Duration(days: 1)),
        score: 90,
        grade: const Value(null),
        isIncomplete: true,
        availableWeight: 0.75,
        scoringVersion: 2,
        focusPoints: 35.0,
        intentPoints: 20.0,
        attentionPoints: const Value(null),
        carePoints: 12.0,
      ));

      // Day 3: Complete V1 score = 95 (Legacy V1 score, should be excluded from V2 average)
      await db.dailyScoresDao.upsertScore(DailyScoresCompanion.insert(
        day: monday.add(const Duration(days: 2)),
        score: 95,
        grade: const Value('A+'),
        isIncomplete: false,
        availableWeight: 1.0,
        scoringVersion: 1,
        focusPoints: 0.0,
        intentPoints: 0.0,
        attentionPoints: const Value(null),
        carePoints: 0.0,
      ));

      // Day 4: Complete V2 score = 60
      await db.dailyScoresDao.upsertScore(DailyScoresCompanion.insert(
        day: monday.add(const Duration(days: 3)),
        score: 60,
        grade: const Value('C'),
        isIncomplete: false,
        availableWeight: 1.0,
        scoringVersion: 2,
        focusPoints: 20.0,
        intentPoints: 15.0,
        attentionPoints: const Value(15.0),
        carePoints: 10.0,
      ));

      final aggregate = await HistoryAggregator.getWeeklyAggregate(db, monday);

      // We expect average of complete V2 days: (80 + 60) / 2 = 70.
      expect(aggregate.averageScore, 70);
      expect(aggregate.scoredDaysCount, 2);
    });

    test('reclaimable time calculates delta strictly based on historic budget limits and distracting app flags', () async {
      final now = DateTime.now();
      final monday = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));

      // 1. Mark day complete in metrics
      await db.into(db.deviceDayMetrics).insert(DeviceDayMetricsCompanion.insert(
        id: 'metric-mon-android',
        day: monday,
        platform: 'android',
        coverageState: 'complete',
      ));

      // 2. Setup distracting app watchlist
      await db.into(db.protectedApps).insert(ProtectedAppsCompanion.insert(
        id: 'app-ig',
        platform: 'android',
        appRef: 'com.instagram.android',
        displayName: 'Instagram',
        protectsFocus: const Value(true),
        isEssential: const Value(false),
      ));

      // 3. Configure daily plan budget for that day
      await db.into(db.dailyPlans).insert(DailyPlansCompanion.insert(
        id: 'plan-mon',
        date: monday,
        scrollBudgetMinutes: const Value(30),
      ));

      // 4. Create historic distracting usage records
      await db.into(db.deviceUsageRecords).insert(DeviceUsageRecordsCompanion.insert(
        id: 'record-mon-ig',
        date: monday.add(const Duration(hours: 10)),
        packageName: 'com.instagram.android',
        label: const Value('Instagram'),
        minutes: 45, // 15 min over budget of 30
        source: const Value('android_usage'),
        isDistracting: const Value(true),
        platform: 'android',
      ));

      // Day 2 (Tuesday): complete day but daily plan scrollBudget is unconfigured/0.
      // Reclaimable should ignore this day (should NOT invent budget).
      await db.into(db.deviceDayMetrics).insert(DeviceDayMetricsCompanion.insert(
        id: 'metric-tue-android',
        day: monday.add(const Duration(days: 1)),
        platform: 'android',
        coverageState: 'complete',
      ));
      await db.into(db.deviceUsageRecords).insert(DeviceUsageRecordsCompanion.insert(
        id: 'record-tue-ig',
        date: monday.add(const Duration(days: 1, hours: 10)),
        packageName: 'com.instagram.android',
        label: const Value('Instagram'),
        minutes: 45,
        source: const Value('android_usage'),
        isDistracting: const Value(true),
        platform: 'android',
      ));

      final aggregate = await HistoryAggregator.getWeeklyAggregate(db, monday);

      // Reclaimable minutes should be 15, ignoring Tuesday since its budget was unconfigured/0
      expect(aggregate.reclaimableMinutes, 15);
      expect(aggregate.hasReclaimableData, true);
    });
  });
}
