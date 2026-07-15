import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drift/native.dart';
import 'package:flowos/data/local/database/app_database.dart';
import 'package:flowos/features/attention/repository/attention_data_repository.dart';

class FakeDeviceAttentionPlatform extends DeviceAttentionPlatform {
  bool hasUsage = false;
  
  @override
  Future<PermissionStates> getPermissionStates() async {
    return PermissionStates(
      usageAccess: hasUsage,
      accessibility: false,
      notificationAccess: false,
      platformSupport: 'android',
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late AttentionDataRepository repository;
  late FakeDeviceAttentionPlatform platform;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase.forTesting(NativeDatabase.memory());
    platform = FakeDeviceAttentionPlatform();
    repository = AttentionDataRepository(db, platform);
  });

  tearDown(() async {
    await db.close();
  });

  group('AttentionDataRepository Tests', () {
    test('syncUsage does not sync when permission is denied', () async {
      platform.hasUsage = false;
      await repository.syncUsage(days: 1);
      
      final today = DateTime.now();
      final dayData = await repository.getAttentionDay(today);
      expect(dayData.coverage, DataCoverage.notConnected);
    });

    test('manual scroll logs exclude auto logs', () async {
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

      final today = DateTime.now();
      final dayData = await repository.getAttentionDay(today);
      expect(dayData.manualScrollMinutes, 10);
      expect(dayData.effectiveDistractingMinutes, 10);
    });
  });
}
