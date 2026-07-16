import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../tables/achievements_table.dart';
import '../tables/attention_costs_table.dart';
import '../tables/daily_plans_table.dart';
import '../tables/daily_reports_table.dart';
import '../tables/energy_checkins_table.dart';
import '../tables/focus_sessions_table.dart';
import '../tables/scroll_logs_table.dart';
import '../tables/tasks_table.dart';
import '../tables/xp_ledger_table.dart';
import '../dao/tasks_dao.dart';
import '../dao/focus_sessions_dao.dart';
import '../dao/xp_ledger_dao.dart';
import '../dao/scroll_logs_dao.dart';
import '../dao/energy_checkins_dao.dart';
import '../dao/daily_plans_dao.dart';
import '../dao/daily_reports_dao.dart';
import '../dao/achievements_dao.dart';
import '../dao/attention_costs_dao.dart';
import '../tables/device_usage_records_table.dart';
import '../dao/device_usage_records_dao.dart';
import '../tables/unlock_attempts_table.dart';
import '../dao/unlock_attempts_dao.dart';
import '../tables/protected_apps_table.dart';
import '../dao/protected_apps_dao.dart';
import '../tables/device_day_metrics_table.dart';
import '../dao/device_day_metrics_dao.dart';
import '../tables/sleep_schedules_table.dart';
import '../dao/sleep_schedules_dao.dart';
import '../tables/notification_daily_counts_table.dart';
import '../tables/processed_notification_batches_table.dart';
import '../dao/notification_daily_counts_dao.dart';
import '../tables/daily_scores_table.dart';
import '../dao/daily_scores_dao.dart';
import '../tables/sync_outbox_table.dart';
import '../dao/sync_outbox_dao.dart';

part 'app_database.g.dart';

/// FlowOS main database — local-first, offline-capable.
/// All tables, DAOs, and migrations are defined here.
@DriftDatabase(
  tables: [
    Tasks,
    FocusSessions,
    XpLedgerEntries,
    AttentionCosts,
    ScrollLogs,
    EnergyCheckIns,
    DailyReports,
    Achievements,
    DailyPlans,
    DeviceUsageRecords,
    UnlockAttempts,
    ProtectedApps,
    DeviceDayMetrics,
    SleepSchedules,
    NotificationDailyCounts,
    ProcessedNotificationBatches,
    DailyScores,
    SyncOutbox,
  ],
  daos: [
    TasksDao,
    FocusSessionsDao,
    XpLedgerDao,
    ScrollLogsDao,
    EnergyCheckInsDao,
    DailyPlansDao,
    DailyReportsDao,
    AchievementsDao,
    AttentionCostsDao,
    DeviceUsageRecordsDao,
    UnlockAttemptsDao,
    ProtectedAppsDao,
    DeviceDayMetricsDao,
    SleepSchedulesDao,
    NotificationDailyCountsDao,
    DailyScoresDao,
    SyncOutboxDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// For testing with in-memory database
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 9;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.addColumn(scrollLogs, scrollLogs.intent);
        await m.addColumn(scrollLogs, scrollLogs.wasTimeboxed);
        await m.addColumn(scrollLogs, scrollLogs.plannedMinutes);
        await m.addColumn(dailyPlans, dailyPlans.intentionNote);
      }
      if (from < 3) {
        await m.createTable(deviceUsageRecords);
      }
      if (from < 4) {
        await m.createTable(unlockAttempts);
      }
      if (from < 5) {
        await m.createTable(deviceDayMetrics);
        await m.createTable(protectedApps);
        if (from >= 3) {
          await m.addColumn(deviceUsageRecords, deviceUsageRecords.source);
          await m.addColumn(deviceUsageRecords, deviceUsageRecords.category);
          await m.addColumn(deviceUsageRecords, deviceUsageRecords.isDistracting);
          // Note: Drift will automatically apply default values on columns,
          // but we also perform a manual backfill to populate any existing rows:
          await customStatement("UPDATE device_usage_records SET source = 'android_usage'");
        }
      }
      if (from < 6) {
        await m.addColumn(dailyReports, dailyReports.coverageState);
      }
      if (from < 7) {
        await m.createTable(sleepSchedules);
        await m.createTable(notificationDailyCounts);
        await m.createTable(processedNotificationBatches);
        await m.addColumn(deviceDayMetrics, deviceDayMetrics.notificationObservedFrom);
        await m.addColumn(deviceDayMetrics, deviceDayMetrics.unlockCoverage);
        await m.addColumn(deviceDayMetrics, deviceDayMetrics.notificationCoverage);
      }
      if (from < 8) {
        await m.createTable(dailyScores);
        await m.addColumn(focusSessions, focusSessions.gardenSeedKind);
        await m.addColumn(focusSessions, focusSessions.gardenVariant);
        await m.addColumn(focusSessions, focusSessions.gardenSeedEmoji);

        // Sync-aware V1 backfill of legacy scores
        await customStatement('''
          INSERT OR IGNORE INTO daily_scores (
            day, score, grade, is_incomplete, available_weight, scoring_version,
            focus_points, intent_points, attention_points, care_points, computed_at
          )
          SELECT 
            r1.date,
            r1.daily_score,
            CASE 
              WHEN r1.coverage_state = 'complete' THEN
                CASE 
                  WHEN r1.daily_score >= 90 THEN 'A+'
                  WHEN r1.daily_score >= 80 THEN 'A'
                  WHEN r1.daily_score >= 70 THEN 'B'
                  WHEN r1.daily_score >= 55 THEN 'C'
                  WHEN r1.daily_score >= 40 THEN 'D'
                  ELSE 'F'
                END
              ELSE NULL
            END,
            CASE WHEN r1.coverage_state = 'complete' THEN 0 ELSE 1 END,
            CASE WHEN r1.coverage_state = 'complete' THEN 1.0 ELSE 0.75 END,
            1,
            0.0,
            0.0,
            NULL,
            0.0,
            r1.generated_at
          FROM daily_reports r1
          WHERE r1.generated_at = (
            SELECT MAX(r2.generated_at)
            FROM daily_reports r2
            WHERE r2.date = r1.date
        ''');
      }
      if (from < 9) {
        await m.createTable(syncOutbox);
        await m.addColumn(dailyPlans, dailyPlans.updatedAt);
        await m.addColumn(dailyPlans, dailyPlans.deletedAt);
        await m.addColumn(dailyReports, dailyReports.updatedAt);
        await m.addColumn(dailyReports, dailyReports.deletedAt);
        await m.addColumn(focusSessions, focusSessions.createdAt);
        await m.addColumn(focusSessions, focusSessions.updatedAt);
        await m.addColumn(focusSessions, focusSessions.deletedAt);
        await m.addColumn(scrollLogs, scrollLogs.updatedAt);
        await m.addColumn(scrollLogs, scrollLogs.deletedAt);
        await m.addColumn(energyCheckIns, energyCheckIns.createdAt);
        await m.addColumn(energyCheckIns, energyCheckIns.updatedAt);
        await m.addColumn(energyCheckIns, energyCheckIns.deletedAt);
        await m.addColumn(achievements, achievements.updatedAt);
        await m.addColumn(achievements, achievements.deletedAt);
      }
    },
  );

  /// Delete all data from local database tables
  Future<void> clearAllData() async {
    await transaction(() async {
      await batch((batch) {
        batch.deleteWhere(tasks, (_) => const Constant(true));
        batch.deleteWhere(focusSessions, (_) => const Constant(true));
        batch.deleteWhere(xpLedgerEntries, (_) => const Constant(true));
        batch.deleteWhere(scrollLogs, (_) => const Constant(true));
        batch.deleteWhere(energyCheckIns, (_) => const Constant(true));
        batch.deleteWhere(dailyPlans, (_) => const Constant(true));
        batch.deleteWhere(dailyReports, (_) => const Constant(true));
        batch.deleteWhere(achievements, (_) => const Constant(true));
        batch.deleteWhere(attentionCosts, (_) => const Constant(true));
        batch.deleteWhere(deviceUsageRecords, (_) => const Constant(true));
        batch.deleteWhere(unlockAttempts, (_) => const Constant(true));
        batch.deleteWhere(protectedApps, (_) => const Constant(true));
        batch.deleteWhere(deviceDayMetrics, (_) => const Constant(true));
        batch.deleteWhere(sleepSchedules, (_) => const Constant(true));
        batch.deleteWhere(notificationDailyCounts, (_) => const Constant(true));
        batch.deleteWhere(processedNotificationBatches, (_) => const Constant(true));
        batch.deleteWhere(dailyScores, (_) => const Constant(true));
        batch.deleteWhere(syncOutbox, (_) => const Constant(true));
      });
    });
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'flowos.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}

/// Riverpod provider for the database
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});
