import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:sqlite3/sqlite3.dart';

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
  int get schemaVersion => 10;

  String _activeOwnerId = 'local';
  String get activeOwnerId => _activeOwnerId;
  void setActiveOwnerId(String? ownerId) {
    _activeOwnerId = (ownerId != null && ownerId.isNotEmpty)
        ? ownerId
        : 'local';
  }

  /// Checks if a physical table exists in SQLite.
  Future<bool> _hasTable(String tableName) async {
    final result = await customSelect(
      "SELECT count(*) as cnt FROM sqlite_master WHERE type='table' AND name=?",
      variables: [Variable.withString(tableName)],
    ).getSingle();
    return (result.read<int>('cnt')) > 0;
  }

  /// Checks if a physical column exists in a table via PRAGMA table_info.
  Future<bool> _hasColumn(String tableName, String columnName) async {
    if (!await _hasTable(tableName)) return false;
    final columns = await customSelect("PRAGMA table_info('$tableName')").get();
    return columns.any((row) => row.read<String>('name') == columnName);
  }

  /// Safely adds a column only if the table exists and column does not exist physically.
  Future<void> _safeAddColumn(
    Migrator m,
    TableInfo table,
    GeneratedColumn column,
  ) async {
    if (await _hasTable(table.actualTableName) &&
        !await _hasColumn(table.actualTableName, column.name)) {
      try {
        await m.addColumn(table, column);
      } catch (_) {
        try {
          final sql =
              'ALTER TABLE "${table.actualTableName}" ADD COLUMN "${column.name}"';
          await customStatement(sql);
        } catch (_) {}
      }
    }
  }

  /// Safely creates a table only if it does not already exist physically.
  Future<void> _safeCreateTable(Migrator m, TableInfo table) async {
    if (!await _hasTable(table.actualTableName)) {
      await m.createTable(table);
    }
  }

  /// Inspects physical SQLite schema and repairs any missing tables or columns idempotently.
  Future<void> _verifyAndRepairPhysicalSchema(Migrator m) async {
    for (final table in allTables) {
      if (!await _hasTable(table.actualTableName)) {
        await m.createTable(table);
      } else {
        for (final col in table.$columns) {
          await _safeAddColumn(m, table, col);
        }
      }
    }

    // Defensive backfill for legacy rows where newly added non-nullable columns might be NULL
    if (await _hasTable('tasks')) {
      await customStatement(
        "UPDATE tasks SET description = '' WHERE description IS NULL;",
      );
      await customStatement(
        "UPDATE tasks SET energy_level = 0 WHERE energy_level IS NULL;",
      );
      await customStatement(
        "UPDATE tasks SET estimated_minutes = 15 WHERE estimated_minutes IS NULL;",
      );
      await customStatement(
        "UPDATE tasks SET friction_score = 0 WHERE friction_score IS NULL;",
      );
      await customStatement(
        "UPDATE tasks SET category = 'work' WHERE category IS NULL;",
      );
      await customStatement(
        "UPDATE tasks SET sort_order = 0 WHERE sort_order IS NULL;",
      );
      await customStatement(
        "UPDATE tasks SET updated_at = 1600000000 WHERE updated_at IS NULL;",
      );
    }
    if (await _hasTable('daily_plans')) {
      await customStatement(
        "UPDATE daily_plans SET updated_at = 1600000000 WHERE updated_at IS NULL;",
      );
    }
    if (await _hasTable('daily_reports')) {
      await customStatement(
        "UPDATE daily_reports SET updated_at = 1600000000 WHERE updated_at IS NULL;",
      );
    }
    if (await _hasTable('focus_sessions')) {
      await customStatement(
        "UPDATE focus_sessions SET created_at = 1600000000 WHERE created_at IS NULL;",
      );
      await customStatement(
        "UPDATE focus_sessions SET updated_at = 1600000000 WHERE updated_at IS NULL;",
      );
    }
    if (await _hasTable('scroll_logs')) {
      await customStatement(
        "UPDATE scroll_logs SET updated_at = 1600000000 WHERE updated_at IS NULL;",
      );
    }
    if (await _hasTable('energy_check_ins')) {
      await customStatement(
        "UPDATE energy_check_ins SET created_at = 1600000000 WHERE created_at IS NULL;",
      );
      await customStatement(
        "UPDATE energy_check_ins SET updated_at = 1600000000 WHERE updated_at IS NULL;",
      );
    }
    if (await _hasTable('achievements')) {
      await customStatement(
        "UPDATE achievements SET updated_at = 1600000000 WHERE updated_at IS NULL;",
      );
    }
    if (await _hasTable('device_usage_records')) {
      await customStatement(
        "UPDATE device_usage_records SET is_distracting = 0 WHERE is_distracting IS NULL;",
      );
      await customStatement(
        "UPDATE device_usage_records SET platform = 'android' WHERE platform IS NULL;",
      );
      await customStatement(
        "UPDATE device_usage_records SET date = 1600000000 WHERE date IS NULL;",
      );
      await customStatement(
        "UPDATE device_usage_records SET sync_time = 1600000000 WHERE sync_time IS NULL;",
      );
      await customStatement(
        "UPDATE device_usage_records SET minutes = 0 WHERE minutes IS NULL;",
      );
    }
  }

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await _safeAddColumn(m, scrollLogs, scrollLogs.intent);
        await _safeAddColumn(m, scrollLogs, scrollLogs.wasTimeboxed);
        await _safeAddColumn(m, scrollLogs, scrollLogs.plannedMinutes);
        await _safeAddColumn(m, dailyPlans, dailyPlans.intentionNote);
      }
      if (from < 3) {
        await _safeCreateTable(m, deviceUsageRecords);
      }
      if (from < 4) {
        await _safeCreateTable(m, unlockAttempts);
      }
      if (from < 5) {
        await _safeCreateTable(m, deviceDayMetrics);
        await _safeCreateTable(m, protectedApps);
        if (from >= 3) {
          await _safeAddColumn(
            m,
            deviceUsageRecords,
            deviceUsageRecords.source,
          );
          await _safeAddColumn(
            m,
            deviceUsageRecords,
            deviceUsageRecords.category,
          );
          await _safeAddColumn(
            m,
            deviceUsageRecords,
            deviceUsageRecords.isDistracting,
          );
          await customStatement(
            "UPDATE device_usage_records SET source = 'android_usage' WHERE source IS NULL",
          );
        }
      }
      if (from < 6) {
        await _safeAddColumn(m, dailyReports, dailyReports.coverageState);
      }
      if (from < 7) {
        await _safeCreateTable(m, sleepSchedules);
        await _safeCreateTable(m, notificationDailyCounts);
        await _safeCreateTable(m, processedNotificationBatches);
        await _safeAddColumn(
          m,
          deviceDayMetrics,
          deviceDayMetrics.notificationObservedFrom,
        );
        await _safeAddColumn(
          m,
          deviceDayMetrics,
          deviceDayMetrics.unlockCoverage,
        );
        await _safeAddColumn(
          m,
          deviceDayMetrics,
          deviceDayMetrics.notificationCoverage,
        );
      }
      if (from < 8) {
        await _safeCreateTable(m, dailyScores);
        await _safeAddColumn(m, focusSessions, focusSessions.gardenSeedKind);
        await _safeAddColumn(m, focusSessions, focusSessions.gardenVariant);
        await _safeAddColumn(m, focusSessions, focusSessions.gardenSeedEmoji);

        // Sync-aware V1 backfill of legacy scores
        if (await _hasTable('daily_reports')) {
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
            )
          ''');
        }
      }
      if (from < 9) {
        await _safeCreateTable(m, syncOutbox);
        await _safeAddColumn(m, dailyPlans, dailyPlans.updatedAt);
        await _safeAddColumn(m, dailyPlans, dailyPlans.deletedAt);
        await _safeAddColumn(m, dailyReports, dailyReports.updatedAt);
        await _safeAddColumn(m, dailyReports, dailyReports.deletedAt);
        await _safeAddColumn(m, focusSessions, focusSessions.createdAt);
        await _safeAddColumn(m, focusSessions, focusSessions.updatedAt);
        await _safeAddColumn(m, focusSessions, focusSessions.deletedAt);
        await _safeAddColumn(m, scrollLogs, scrollLogs.updatedAt);
        await _safeAddColumn(m, scrollLogs, scrollLogs.deletedAt);
        await _safeAddColumn(m, energyCheckIns, energyCheckIns.createdAt);
        await _safeAddColumn(m, energyCheckIns, energyCheckIns.updatedAt);
        await _safeAddColumn(m, energyCheckIns, energyCheckIns.deletedAt);
        await _safeAddColumn(m, achievements, achievements.updatedAt);
        await _safeAddColumn(m, achievements, achievements.deletedAt);
      }
      if (from < 10) {
        await _safeAddColumn(m, syncOutbox, syncOutbox.ownerId);
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON;');
      await _verifyAndRepairPhysicalSchema(Migrator(this));
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
        batch.deleteWhere(
          processedNotificationBatches,
          (_) => const Constant(true),
        );
        batch.deleteWhere(dailyScores, (_) => const Constant(true));
        batch.deleteWhere(syncOutbox, (_) => const Constant(true));
      });
    });
  }
}

void quarantineCorruptDatabase(File file, String reason) {
  try {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final quarantinePath = '${file.path}.corrupt_$timestamp';
    file.copySync(quarantinePath);
    file.deleteSync();
    debugPrint(
      '⚠️ Database corruption detected ($reason). Original database quarantined to: $quarantinePath',
    );
  } catch (e) {
    debugPrint('⚠️ Quarantine attempt failed: $e');
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'flowos.sqlite'));
    if (file.existsSync()) {
      try {
        final testDb = sqlite3.open(file.path);
        final result = testDb.select('PRAGMA quick_check;');
        testDb.close();
        if (result.isNotEmpty && result.first.values.isNotEmpty) {
          final status = result.first.values.first.toString();
          if (status != 'ok') {
            quarantineCorruptDatabase(file, status);
          }
        }
      } catch (e) {
        quarantineCorruptDatabase(file, e.toString());
      }
    }
    return NativeDatabase.createInBackground(file);
  });
}

/// Riverpod provider for the database
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});
