import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flowos/data/local/database/app_database.dart';
import 'package:flowos/data/local/tables/focus_sessions_table.dart';
import 'package:flowos/features/focus/models/effective_policy.dart';
import 'package:flowos/features/focus/models/focus_timer_stage.dart';
import 'package:flowos/features/focus/providers/focus_timer_provider.dart';
import 'package:flowos/features/focus/services/focus_session_service.dart';
import 'package:flowos/features/focus/services/policy_writer.dart';

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

  group('TASK-004: Focus Protection Mode Persistence & Lifecycle Tests', () {
    test(
      'Three-mode start: Gentle writes nudge, Guardrail writes guard, Shield writes deep',
      () async {
        final writer = const SharedPrefsPolicyWriter();

        // 1. Gentle mode -> nudge
        final sessionIdNudge = await service.startSession(
          type: SessionTypeColumn.pomodoro,
          durationMinutes: 25,
          protectionMode: ProtectionMode.nudge,
        );
        final policyNudge = await writer.getActivePolicies();
        expect(policyNudge?.focus, isNotNull);
        expect(
          policyNudge!.focus!.protectionMode,
          equals(ProtectionMode.nudge),
        );
        expect(policyNudge.focus!.sessionId, equals(sessionIdNudge));

        // 2. Guardrail mode -> guard
        final sessionIdGuard = await service.startSession(
          type: SessionTypeColumn.pomodoro,
          durationMinutes: 25,
          protectionMode: ProtectionMode.guard,
        );
        final policyGuard = await writer.getActivePolicies();
        expect(policyGuard?.focus, isNotNull);
        expect(
          policyGuard!.focus!.protectionMode,
          equals(ProtectionMode.guard),
        );
        expect(policyGuard.focus!.sessionId, equals(sessionIdGuard));

        // 3. Shield mode -> deep
        final sessionIdDeep = await service.startSession(
          type: SessionTypeColumn.deepWork,
          durationMinutes: 90,
          protectionMode: ProtectionMode.deep,
        );
        final policyDeep = await writer.getActivePolicies();
        expect(policyDeep?.focus, isNotNull);
        expect(policyDeep!.focus!.protectionMode, equals(ProtectionMode.deep));
        expect(policyDeep.focus!.sessionId, equals(sessionIdDeep));
      },
    );

    test(
      'Pause & Resume preserves start-time protectionMode (Shield remains deep)',
      () async {
        final container = ProviderContainer(
          overrides: [
            databaseProvider.overrideWithValue(db),
            focusSessionServiceProvider.overrideWithValue(service),
          ],
        );
        addTearDown(container.dispose);

        final notifier = container.read(focusTimerNotifierProvider.notifier);

        // Start session with Shield (ProtectionMode.deep)
        await notifier.startSession(
          type: SessionTypeColumn.deepWork,
          durationMinutes: 90,
          protectionMode: ProtectionMode.deep,
        );

        final stateRunning = container.read(focusTimerNotifierProvider);
        expect(stateRunning, isNotNull);
        expect(stateRunning!.protectionMode, equals(ProtectionMode.deep));

        // Pause session
        await notifier.pauseSession();
        final statePaused = container.read(focusTimerNotifierProvider);
        expect(statePaused!.phase, equals(FocusTimerPhase.paused));
        expect(statePaused.protectionMode, equals(ProtectionMode.deep));

        // Resume session
        await notifier.resumeSession();
        final stateResumed = container.read(focusTimerNotifierProvider);
        expect(stateResumed!.phase, equals(FocusTimerPhase.running));
        expect(stateResumed.protectionMode, equals(ProtectionMode.deep));

        // Verify reactivated policy writer payload is ProtectionMode.deep
        final writer = const SharedPrefsPolicyWriter();
        final policy = await writer.getActivePolicies();
        expect(policy?.focus, isNotNull);
        expect(policy!.focus!.protectionMode, equals(ProtectionMode.deep));
      },
    );

    test(
      'Rehydration restores persisted protectionMode from SharedPreferences',
      () async {
        const sessionId = 'rehydrate_session_123';
        await db.focusSessionsDao.insertSession(
          FocusSessionsCompanion(
            id: const Value(sessionId),
            sessionType: const Value(SessionTypeColumn.deepWork),
            durationMinutes: const Value(90),
            startedAt: Value(DateTime.now()),
          ),
        );

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('flowos_active_session_id', sessionId);
        await prefs.setString(
          'flowos_active_session_type',
          SessionTypeColumn.deepWork.name,
        );
        await prefs.setString(
          'flowos_active_phase',
          FocusTimerPhase.running.name,
        );
        await prefs.setInt('flowos_active_total_seconds', 90 * 60);
        await prefs.setString(
          'flowos_active_protection_mode',
          ProtectionMode.deep.name,
        );

        final container = ProviderContainer(
          overrides: [
            databaseProvider.overrideWithValue(db),
            focusSessionServiceProvider.overrideWithValue(service),
          ],
        );
        addTearDown(container.dispose);

        // Trigger read to instantiate notifier & rehydrate
        container.read(focusTimerNotifierProvider.notifier);
        await Future.delayed(const Duration(milliseconds: 100));

        final state = container.read(focusTimerNotifierProvider);
        expect(state, isNotNull);
        expect(state!.sessionId, equals(sessionId));
        expect(state.protectionMode, equals(ProtectionMode.deep));
      },
    );

    test(
      'Legacy state without protectionMode defaults safely to ProtectionMode.guard',
      () async {
        const sessionId = 'legacy_session_456';
        await db.focusSessionsDao.insertSession(
          FocusSessionsCompanion(
            id: const Value(sessionId),
            sessionType: const Value(SessionTypeColumn.pomodoro),
            durationMinutes: const Value(25),
            startedAt: Value(DateTime.now()),
          ),
        );

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('flowos_active_session_id', sessionId);
        await prefs.setString(
          'flowos_active_session_type',
          SessionTypeColumn.pomodoro.name,
        );
        await prefs.setString(
          'flowos_active_phase',
          FocusTimerPhase.running.name,
        );
        await prefs.setInt('flowos_active_total_seconds', 25 * 60);
        // Omit flowos_active_protection_mode

        final container = ProviderContainer(
          overrides: [
            databaseProvider.overrideWithValue(db),
            focusSessionServiceProvider.overrideWithValue(service),
          ],
        );
        addTearDown(container.dispose);

        container.read(focusTimerNotifierProvider.notifier);
        await Future.delayed(const Duration(milliseconds: 100));

        final state = container.read(focusTimerNotifierProvider);
        expect(state, isNotNull);
        expect(state!.sessionId, equals(sessionId));
        expect(state.protectionMode, equals(ProtectionMode.guard));
      },
    );

    test(
      'Active scoped breaks survive pause/resume cycle on allowed policy',
      () async {
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
          protectionMode: ProtectionMode.guard,
        );

        final writer = const SharedPrefsPolicyWriter();
        final breakUntil = DateTime.now().add(const Duration(minutes: 5));
        final policyWithBreak = SourcePolicy(
          sessionId: container.read(focusTimerNotifierProvider)!.sessionId,
          activeUntil: DateTime.now().add(const Duration(minutes: 3)),
          selectedPackages: {'com.instagram.android'},
          protectionMode: ProtectionMode.guard,
          source: PolicySource.focus,
          scopedBreaks: [
            ScopedBreak(
              packageName: 'com.instagram.android',
              expiresAt: breakUntil,
              source: PolicySource.focus,
            ),
          ],
        );
        await writer.activatePolicy(policyWithBreak);

        await notifier.pauseSession();
        await notifier.resumeSession();

        final restoredPolicy = await writer.getActivePolicies();
        expect(restoredPolicy?.focus, isNotNull);
        expect(restoredPolicy!.focus!.scopedBreaks.length, equals(1));
        expect(
          restoredPolicy.focus!.scopedBreaks.first.packageName,
          equals('com.instagram.android'),
        );
      },
    );
  });
}
