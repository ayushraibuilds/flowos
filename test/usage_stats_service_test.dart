import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drift/native.dart';
import 'package:flowos/data/local/database/app_database.dart';
import 'package:flowos/features/attention/services/usage_stats_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late UsageStatsService service;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase.forTesting(NativeDatabase.memory());
    service = UsageStatsService(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('UsageStatsService Tests', () {
    test('syncUsageStats never fabricates device usage off Android', () async {
      final result = await service.syncUsageStats();

      expect(result.status, UsageSyncStatus.unsupported);
      expect(await db.scrollLogsDao.getTodayLogs(), isEmpty);
    });

    test('deleteAllAutoLogsForToday preserves manual logs', () async {
      await db.scrollLogsDao.insertLog(
        ScrollLogsCompanion.insert(
          id: 'manual',
          appName: 'Quick Log',
          durationMinutes: 10,
          dailyScoreImpact: -10,
        ),
      );
      await db.scrollLogsDao.insertLog(
        ScrollLogsCompanion.insert(
          id: 'auto',
          appName: 'Instagram [Auto]',
          durationMinutes: 15,
          dailyScoreImpact: -10,
        ),
      );

      final start = DateTime(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day,
      );
      await db.scrollLogsDao.deleteAllAutoLogsForToday(start);

      final logs = await db.scrollLogsDao.getTodayLogs();
      expect(logs, hasLength(1));
      expect(logs.single.appName, 'Quick Log');
    });
  });
}
