import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drift/native.dart';
import 'package:flowos/data/local/database/app_database.dart';
import 'package:flowos/data/local/tables/focus_sessions_table.dart';
import 'package:flowos/features/focus/services/focus_session_service.dart';
import 'package:flowos/features/focus/services/policy_writer.dart';
import 'package:flowos/core/constants/xp_constants.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late FocusSessionService service;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase.forTesting(NativeDatabase.memory());
    service = FocusSessionService(db, FakePolicyWriter());
  });

  tearDown(() async {
    await db.close();
  });

  group('FocusSessionService Pipeline Tests', () {
    test('startSession inserts a focus session with status', () async {
      final sessionId = await service.startSession(
        type: SessionTypeColumn.pomodoro,
        durationMinutes: 25,
      );

      expect(sessionId.isNotEmpty, true);

      final session = await db.focusSessionsDao.getById(sessionId);
      expect(session, isNotNull);
      expect(session!.sessionType, SessionTypeColumn.pomodoro);
      expect(session.durationMinutes, 25);
      expect(session.xpEarned, 0);
    });

    test('completeSession countdown awards full XP for quality A', () async {
      final sessionId = await service.startSession(
        type: SessionTypeColumn.pomodoro,
        durationMinutes: 25,
        taskId: 'task-123',
      );

      final result = await service.completeSession(
        sessionId: sessionId,
        elapsedSeconds: 25 * 60,
        pauseCount: 0,
        backgroundCount: 0,
        type: SessionTypeColumn.pomodoro,
      );

      // Pomodoro complete is typically 40 XP
      expect(result.xpEarned, XpConstants.pomodoroComplete);

      final session = await db.focusSessionsDao.getById(sessionId);
      expect(session!.xpEarned, result.xpEarned);
      expect(session.qualityScore, 'A');
      expect(session.actualMinutes, 25);

      final ledgerXP = await db.xpLedgerDao.getLifetimeXP();
      expect(ledgerXP, result.xpEarned);
      expect(result.gardenGrowth?.kind, isNotNull);
    });

    test('completeSession countdown scales down XP for quality B', () async {
      final sessionId = await service.startSession(
        type: SessionTypeColumn.pomodoro,
        durationMinutes: 25,
        taskId: 'task-123',
      );

      final result = await service.completeSession(
        sessionId: sessionId,
        elapsedSeconds: 25 * 60,
        pauseCount: 3, // 3 pauses = quality B
        backgroundCount: 0,
        type: SessionTypeColumn.pomodoro,
      );

      // Unified FocusQualityCalculator B = 0.85x multiplier
      final expectedXP = (XpConstants.pomodoroComplete * 0.85).round();
      expect(result.xpEarned, expectedXP);

      final session = await db.focusSessionsDao.getById(sessionId);
      expect(session!.qualityScore, 'B');
      expect(session.xpEarned, expectedXP);
    });

    test('completeSession Flowtime awards XP proportionally', () async {
      final sessionId = await service.startSession(
        type: SessionTypeColumn.custom,
        durationMinutes: 0,
        taskId: 'task-123',
      );

      final result = await service.completeSession(
        sessionId: sessionId,
        elapsedSeconds: 30 * 60, // 30 minutes
        pauseCount: 0,
        backgroundCount: 0,
        type: SessionTypeColumn.custom,
        isFlowtime: true,
      );

      // 30 min * 1.6 XP/min = 48 XP
      expect(result.xpEarned, 48);

      final session = await db.focusSessionsDao.getById(sessionId);
      expect(session!.qualityScore, 'A');
      expect(session.xpEarned, 48);
    });

    test(
      'stopSession countdown awards partial XP if >= 60% and >= 10m',
      () async {
        final sessionId = await service.startSession(
          type: SessionTypeColumn.pomodoro,
          durationMinutes: 25,
        );

        // 15 mins is 60% of 25 mins
        final result = await service.stopSession(
          sessionId: sessionId,
          elapsedSeconds: 15 * 60,
          totalSeconds: 25 * 60,
          pauseCount: 0,
          backgroundCount: 0,
          type: SessionTypeColumn.pomodoro,
        );

        // 0.6 * baseXP * 0.5 = 0.3 * baseXP. 0.3 * 40 = 12 XP
        final expectedXP = (XpConstants.pomodoroComplete * 0.6 * 0.5).round();
        expect(result.xpEarned, expectedXP);

        final session = await db.focusSessionsDao.getById(sessionId);
        expect(session!.qualityScore, 'D');
        expect(session.xpEarned, expectedXP);
      },
    );

    test('stopSession countdown awards 0 XP if < 60%', () async {
      final sessionId = await service.startSession(
        type: SessionTypeColumn.pomodoro,
        durationMinutes: 25,
      );

      // 10 mins is 40% of 25 mins (less than 60%)
      final result = await service.stopSession(
        sessionId: sessionId,
        elapsedSeconds: 10 * 60,
        totalSeconds: 25 * 60,
        pauseCount: 0,
        backgroundCount: 0,
        type: SessionTypeColumn.pomodoro,
      );

      expect(result.xpEarned, 0);

      final session = await db.focusSessionsDao.getById(sessionId);
      expect(session!.qualityScore, 'F');
      expect(session.xpEarned, 0);
    });
  });
}
