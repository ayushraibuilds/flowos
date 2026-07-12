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
    test('syncUsageStats in simulator injects mock data only once', () async {
      // First sync -> should inject mock data
      await service.syncUsageStats();

      var logs = await db.scrollLogsDao.getTodayLogs();
      expect(logs.length, 3);
      expect(logs.any((l) => l.appName == 'Instagram [Auto]'), true);
      expect(logs.any((l) => l.appName == 'YouTube [Auto]'), true);
      expect(logs.any((l) => l.appName == 'TikTok [Auto]'), true);

      // Second sync -> should NOT inject duplicate logs because auto exists
      await service.syncUsageStats();
      logs = await db.scrollLogsDao.getTodayLogs();
      expect(logs.length, 3); // still 3
    });

    test('deleteAutoLogsForToday removes only logs for specified app today', () async {
      await service.syncUsageStats();
      
      final start = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
      await db.scrollLogsDao.deleteAutoLogsForToday('Instagram [Auto]', start);

      final logs = await db.scrollLogsDao.getTodayLogs();
      expect(logs.length, 2);
      expect(logs.any((l) => l.appName == 'Instagram [Auto]'), false);
      expect(logs.any((l) => l.appName == 'YouTube [Auto]'), true);
    });
  });
}
