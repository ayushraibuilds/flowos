import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flowos/data/local/database/app_database.dart';
import 'package:flowos/data/local/tables/focus_sessions_table.dart';
import 'package:flowos/features/focus/models/focus_timer_stage.dart';
import 'package:flowos/features/focus/providers/focus_timer_provider.dart';
import 'package:flowos/features/focus/services/focus_session_service.dart';
import 'package:flowos/features/xp/models/xp_calculator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late FocusSessionService service;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase.forTesting(NativeDatabase.memory());
    service = FocusSessionService(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('TASK-003: Transactional & Idempotent Focus Completion Tests', () {
    test('FocusSessionService.completeSession is idempotent and creates exactly 1 XP ledger entry', () async {
      final sessionId = await service.startSession(
        type: SessionTypeColumn.pomodoro,
        durationMinutes: 25,
      );

      // Call completeSession 3 times consecutively
      final result1 = await service.completeSession(
        sessionId: sessionId,
        elapsedSeconds: 25 * 60,
        pauseCount: 0,
        backgroundCount: 0,
        type: SessionTypeColumn.pomodoro,
      );

      final result2 = await service.completeSession(
        sessionId: sessionId,
        elapsedSeconds: 25 * 60,
        pauseCount: 0,
        backgroundCount: 0,
        type: SessionTypeColumn.pomodoro,
      );

      final result3 = await service.completeSession(
        sessionId: sessionId,
        elapsedSeconds: 25 * 60,
        pauseCount: 0,
        backgroundCount: 0,
        type: SessionTypeColumn.pomodoro,
      );

      // 1. All results return identical XP
      expect(result1.xpEarned, greaterThan(0));
      expect(result2.xpEarned, equals(result1.xpEarned));
      expect(result3.xpEarned, equals(result1.xpEarned));

      // 2. XP ledger contains EXACTLY ONE row for this sessionId
      final ledgerEntries = await db.xpLedgerDao.select(db.xpLedgerEntries).get();
      final sessionXpRows = ledgerEntries.where((e) => e.sourceEntityId == sessionId).toList();
      expect(sessionXpRows.length, equals(1));
      expect(sessionXpRows.first.pointsDelta, equals(result1.xpEarned));
    });

    test('Calling stopSession on an already completed session does not downgrade or modify completion', () async {
      final sessionId = await service.startSession(
        type: SessionTypeColumn.deepWork,
        durationMinutes: 50,
      );

      final compResult = await service.completeSession(
        sessionId: sessionId,
        elapsedSeconds: 50 * 60,
        pauseCount: 0,
        backgroundCount: 0,
        type: SessionTypeColumn.deepWork,
      );

      // Attempt to stop the already completed session
      final stopResult = await service.stopSession(
        sessionId: sessionId,
        elapsedSeconds: 10 * 60,
        totalSeconds: 50 * 60,
        pauseCount: 0,
        backgroundCount: 0,
        type: SessionTypeColumn.deepWork,
      );

      expect(stopResult.xpEarned, equals(compResult.xpEarned));

      final session = await db.focusSessionsDao.getById(sessionId);
      expect(session, isNotNull);
      expect(session!.completedAt, isNotNull);
      expect(session.qualityScore, isNot(equals('F')));
      expect(session.qualityScore, isNot(equals('D')));
    });

    test('XpCalculator.awardSessionXP is idempotent by sourceEntityId', () async {
      final xpCalc = XpCalculator(db.xpLedgerDao);

      const sessionId = 'test_session_xp_calc';

      final xp1 = await xpCalc.awardSessionXP(
        sessionId: sessionId,
        sessionType: SessionTypeColumn.pomodoro,
        durationMinutes: 25,
        actualMinutes: 25,
        taskId: null,
        streakDays: 3,
        qualityScore: 'A',
      );

      final xp2 = await xpCalc.awardSessionXP(
        sessionId: sessionId,
        sessionType: SessionTypeColumn.pomodoro,
        durationMinutes: 25,
        actualMinutes: 25,
        taskId: null,
        streakDays: 3,
        qualityScore: 'A',
      );

      expect(xp1, greaterThan(0));
      expect(xp2, equals(xp1));

      final ledger = await db.xpLedgerDao.select(db.xpLedgerEntries).get();
      final rows = ledger.where((e) => e.sourceEntityId == sessionId).toList();
      expect(rows.length, equals(1));
    });

    test('FocusTimerNotifier completeSession returns attached completionResult without duplicate calls', () async {
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          focusSessionServiceProvider.overrideWithValue(service),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(focusTimerNotifierProvider.notifier);
      await notifier.startSession(
        type: SessionTypeColumn.pomodoro,
        durationMinutes: 25,
      );

      // Complete session via notifier twice
      final res1 = await notifier.completeSession();
      final res2 = await notifier.completeSession();

      expect(res1.xpEarned, greaterThan(0));
      expect(res2.xpEarned, equals(res1.xpEarned));

      final state = container.read(focusTimerNotifierProvider);
      expect(state, isNotNull);
      expect(state!.phase, equals(FocusTimerPhase.completed));
      expect(state.completionResult, isNotNull);

      // Verify single XP ledger row
      final ledger = await db.xpLedgerDao.select(db.xpLedgerEntries).get();
      final sessionRows = ledger.where((e) => e.sourceEntityId == state.sessionId).toList();
      expect(sessionRows.length, equals(1));
    });

    test('Flowtime manual completion is transactional and idempotent', () async {
      final sessionId = await service.startSession(
        type: SessionTypeColumn.custom,
        durationMinutes: 0,
      );

      final result1 = await service.completeSession(
        sessionId: sessionId,
        elapsedSeconds: 30 * 60,
        pauseCount: 1,
        backgroundCount: 0,
        type: SessionTypeColumn.custom,
        isFlowtime: true,
      );

      final result2 = await service.completeSession(
        sessionId: sessionId,
        elapsedSeconds: 30 * 60,
        pauseCount: 1,
        backgroundCount: 0,
        type: SessionTypeColumn.custom,
        isFlowtime: true,
      );

      expect(result1.xpEarned, greaterThan(0));
      expect(result2.xpEarned, equals(result1.xpEarned));

      final ledger = await db.xpLedgerDao.select(db.xpLedgerEntries).get();
      final rows = ledger.where((e) => e.sourceEntityId == sessionId).toList();
      expect(rows.length, equals(1));
    });
  });
}
