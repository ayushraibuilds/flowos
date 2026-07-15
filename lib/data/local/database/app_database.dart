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
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// For testing with in-memory database
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 5;

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
        await m.addColumn(deviceUsageRecords, deviceUsageRecords.source);
        await m.addColumn(deviceUsageRecords, deviceUsageRecords.category);
        await m.addColumn(deviceUsageRecords, deviceUsageRecords.isDistracting);
        // Note: Drift will automatically apply default values on columns,
        // but we also perform a manual backfill to populate any existing rows:
        await customStatement("UPDATE device_usage_records SET source = 'android_usage'");
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
