import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' show Value;

import 'package:flowos/data/local/database/app_database.dart';
import 'package:flowos/features/attention/repository/attention_data_repository.dart';
import 'package:flowos/features/xp/models/daily_score_calculator.dart';

class FakeDeviceAttentionPlatform extends DeviceAttentionPlatform {
  Map<String, dynamic>? pendingTrigger;
  List<Map<String, dynamic>> nudgeEvents = [];
  Set<String> acknowledgedNudges = {};
  
  PermissionStates permissionStates = const PermissionStates(
    usageAccess: true,
    accessibility: true,
    notificationAccess: true,
    platformSupport: 'android',
  );

  List<Map<String, dynamic>> dailyUsage = [];
  List<Map<String, dynamic>> dailyUnlocks = [];

  @override
  Future<PermissionStates> getPermissionStates() async => permissionStates;

  @override
  Future<List<Map<String, dynamic>>> getDailyUsage(DateTime start, DateTime end) async => dailyUsage;

  @override
  Future<List<Map<String, dynamic>>> getDailyUnlockEvents(DateTime start, DateTime end) async => dailyUnlocks;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('M0 Audit Tests', () {
    test('DailyScoreCalculator reweights properly when attention data is not connected', () {
      // 1. Fully complete coverage
      final resultComplete = DailyScoreCalculator.calculate(
        focusMinutes: 60, // 60 focus score -> 21 pts
        mitsCompleted: 3, // 100 mit score
        scrollMinutes: 0, // 100 attention score -> 25 pts
        scrollBudget: 30,
        intentionCompleted: true, 
        shutdownCompleted: true, 
        energyCheckIns: 3, 
        recoveryActions: 2, // Care score = 100 -> 15 pts
        attentionCoverage: DataCoverage.complete,
      );
      // Expected raw: 21 + 25 + 25 + 15 = 86
      expect(resultComplete.score, 86);

      // 2. Missing coverage (notConnected)
      final resultMissing = DailyScoreCalculator.calculate(
        focusMinutes: 60, // 21 pts
        mitsCompleted: 3, 
        scrollMinutes: 0,
        scrollBudget: 30,
        intentionCompleted: true,
        shutdownCompleted: true,
        energyCheckIns: 3, 
        recoveryActions: 2, // Care score = 100 -> 15 pts
        attentionCoverage: DataCoverage.notConnected,
      );
      // Expected normalized: (21 + 25 + 15) / 0.75 = 61 / 0.75 = 81.33 -> 81
      expect(resultMissing.score, 81);
    });

    test('AttentionDataRepository.syncUsage ignores empty package rows but marks day complete', () async {
      SharedPreferences.setMockInitialValues({});
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final platform = FakeDeviceAttentionPlatform();
      
      // Simulate Usage Access granted
      platform.permissionStates = const PermissionStates(
        usageAccess: true,
        accessibility: true,
        notificationAccess: true,
        platformSupport: 'android',
      );

      // Kotlin returns raw usage containing a real record and a placeholder zero-usage day record
      final nowStr = DateTime.now().toIso8601String().split('T')[0];
      platform.dailyUsage = [
        {
          'date': nowStr,
          'packageName': 'com.instagram.android',
          'label': 'Instagram',
          'minutes': 12,
        },
        {
          'date': nowStr,
          'packageName': '', // dummy placeholder for zero distraction usage day
          'label': '',
          'minutes': 0,
        }
      ];

      final repo = AttentionDataRepository(db, platform);
      await repo.syncUsage(days: 1, forcePlatformCheck: false);

      // Verify com.instagram.android usage is saved
      final records = await db.deviceUsageRecordsDao.getForRange(
        DateTime.now().subtract(const Duration(days: 1)),
        DateTime.now().add(const Duration(days: 1)),
      );
      expect(records.length, 1);
      expect(records.first.packageName, 'com.instagram.android');

      // Verify the day is marked as 'complete' coverageState in device_day_metrics
      final todayDate = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
      final metric = await db.deviceDayMetricsDao.getForDay(todayDate, 'android');
      expect(metric, isNotNull);
      expect(metric!.coverageState, 'complete');

      await db.close();
    });

    test('Drift Schema V6 migration preserves daily reports table integrity', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());

      // Insert some mock reports
      final date = DateTime.now();
      await db.dailyReportsDao.upsertReport(DailyReportsCompanion(
        id: const Value('test-report-1'),
        date: Value(date),
        reportJson: const Value('{"headline":"Super day"}'),
        dailyScore: const Value(92),
        xpEarnedToday: const Value(120),
        attentionCostToday: const Value(0),
        generatedAt: Value(DateTime.now()),
      ));

      final reportBefore = await db.dailyReportsDao.getForDate(date);
      expect(reportBefore, isNotNull);
      expect(reportBefore!.dailyScore, 92);
      expect(reportBefore.coverageState, isNull);

      // Simulate a save with coverageState populated
      await db.dailyReportsDao.upsertReport(DailyReportsCompanion(
        id: const Value('test-report-1'),
        date: Value(date),
        reportJson: const Value('{"headline":"Super day"}'),
        dailyScore: const Value(92),
        xpEarnedToday: const Value(120),
        attentionCostToday: const Value(0),
        generatedAt: Value(DateTime.now()),
        coverageState: const Value('complete'),
      ));

      final reportAfter = await db.dailyReportsDao.getForDate(date);
      expect(reportAfter, isNotNull);
      expect(reportAfter!.dailyScore, 92);
      expect(reportAfter.coverageState, 'complete');

      await db.close();
    });
  });
}
