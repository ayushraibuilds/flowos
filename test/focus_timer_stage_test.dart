import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flowos/data/local/database/app_database.dart';
import 'package:flowos/data/local/tables/focus_sessions_table.dart';
import 'package:flowos/features/focus/providers/focus_timer_provider.dart';
import 'package:flowos/features/focus/models/focus_timer_stage.dart';
import 'package:flowos/features/focus/services/focus_session_service.dart';
import 'package:flowos/features/focus/services/policy_writer.dart';
import 'package:flowos/features/focus/models/effective_policy.dart';
import 'package:flowos/features/flow_garden/services/garden_service.dart';
import 'package:flowos/features/flow_garden/models/garden_day.dart';
import 'package:flowos/features/focus/services/ambient_sound_player.dart';

void main() {
  group('Milestone 5 FocusTimerState & Phase Tests', () {
    late AppDatabase db;
    late ProviderContainer container;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      db = AppDatabase.forTesting(drift.DatabaseConnection(NativeDatabase.memory()));
      container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
        ],
      );
    });

    tearDown(() async {
      await db.close();
      container.dispose();
    });

    test('startSession generates seed internally and persists in DB', () async {
      final success = await container.read(focusTimerNotifierProvider.notifier).startSession(
        type: SessionTypeColumn.pomodoro,
        durationMinutes: 25,
      );
      expect(success, isTrue);

      final state = container.read(focusTimerNotifierProvider);
      expect(state, isNotNull);
      expect(state!.gardenSeedKind, isNotEmpty);
      expect(state.gardenSeedEmoji, isNotEmpty);

      // Verify DB row
      final sessionRow = await db.focusSessionsDao.getById(state.sessionId);
      expect(sessionRow, isNotNull);
      expect(sessionRow!.gardenSeedKind, equals(state.gardenSeedKind));
      expect(sessionRow.gardenSeedEmoji, equals(state.gardenSeedEmoji));
      expect(sessionRow.gardenVariant, equals(state.gardenVariant));
    });

    test('Reject start session if a timer is already active', () async {
      // Start first session
      final success1 = await container.read(focusTimerNotifierProvider.notifier).startSession(
        type: SessionTypeColumn.pomodoro,
        durationMinutes: 25,
      );
      expect(success1, isTrue);

      // Start second session without completing/stopping first
      final success2 = await container.read(focusTimerNotifierProvider.notifier).startSession(
        type: SessionTypeColumn.pomodoro,
        durationMinutes: 25,
      );
      expect(success2, isFalse); // rejected
    });

    test('Process death hydration & catch-up for Countdown', () async {
      final now = DateTime.now().toUtc();
      final expectedEnd = now.add(const Duration(minutes: 25));

      // Prep preferences payload
      SharedPreferences.setMockInitialValues({
        'flowos_active_session_id': 'test-session-123',
        'flowos_active_session_type': SessionTypeColumn.pomodoro.name,
        'flowos_active_phase': FocusTimerPhase.running.name,
        'flowos_active_total_seconds': 25 * 60,
        'flowos_active_elapsed_seconds': 100,
        'flowos_active_started_at_utc': now.toIso8601String(),
        'flowos_active_expected_end_time_utc': expectedEnd.toIso8601String(),
        'flowos_active_seed_kind': 'flower',
        'flowos_active_seed_emoji': '🌸',
      });

      // Insert dummy session in DB so it doesn't fail reconciliation
      await db.focusSessionsDao.insertSession(
        FocusSessionsCompanion(
          id: const drift.Value('test-session-123'),
          sessionType: const drift.Value(SessionTypeColumn.pomodoro),
          durationMinutes: const drift.Value(25),
          startedAt: drift.Value(DateTime.now()),
          gardenSeedKind: const drift.Value('flower'),
          gardenSeedEmoji: const drift.Value('🌸'),
          gardenVariant: const drift.Value(0),
        ),
      );

      // Re-create notifier via fresh container to trigger rehydration
      final newContainer = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
        ],
      );
      newContainer.read(focusTimerNotifierProvider);
      
      // Wait for async rehydration query to resolve
      await Future.delayed(const Duration(milliseconds: 100));
      
      final rehydratedState = newContainer.read(focusTimerNotifierProvider);
      expect(rehydratedState, isNotNull);
      expect(rehydratedState!.sessionId, equals('test-session-123'));
      expect(rehydratedState.phase, equals(FocusTimerPhase.running));
      
      newContainer.dispose();
    });

    test('Rehydration clears conflicting preferences when DB disagrees', () async {
      // Preferences has running session, but DB has no matching row
      SharedPreferences.setMockInitialValues({
        'flowos_active_session_id': 'conflicting-session',
        'flowos_active_phase': FocusTimerPhase.running.name,
      });

      final newContainer = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
        ],
      );
      newContainer.read(focusTimerNotifierProvider);
      
      // Wait for async rehydration query to resolve
      await Future.delayed(const Duration(milliseconds: 100));

      final rehydratedState = newContainer.read(focusTimerNotifierProvider);
      // DB check returns null, preferences should be cleared, state is null
      expect(rehydratedState, isNull);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('flowos_active_session_id'), isNull);
      
      newContainer.dispose();
    });

    test('Stale paused session auto-finalizes', () async {
      final oldTime = DateTime.now().toUtc().subtract(const Duration(minutes: 65));
      SharedPreferences.setMockInitialValues({
        'flowos_active_session_id': 'paused-stale-session',
        'flowos_active_session_type': SessionTypeColumn.pomodoro.name,
        'flowos_active_phase': FocusTimerPhase.paused.name,
        'flowos_active_paused_at_utc': oldTime.toIso8601String(),
        'flowos_active_total_seconds': 25 * 60,
        'flowos_active_elapsed_seconds': 10,
        'flowos_active_seed_kind': 'flower',
        'flowos_active_seed_emoji': '🌸',
      });

      await db.focusSessionsDao.insertSession(
        FocusSessionsCompanion(
          id: const drift.Value('paused-stale-session'),
          sessionType: const drift.Value(SessionTypeColumn.pomodoro),
          durationMinutes: const drift.Value(25),
          startedAt: drift.Value(DateTime.now()),
        ),
      );

      final newContainer = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
        ],
      );
      newContainer.read(focusTimerNotifierProvider);
      
      // Wait for async rehydration query and stopSession completion
      await Future.delayed(const Duration(milliseconds: 150));

      final rehydratedState = newContainer.read(focusTimerNotifierProvider);
      // Stale paused session should run stopSession and clean state
      expect(rehydratedState, isNull);

      final session = await db.focusSessionsDao.getById('paused-stale-session');
      expect(session, isNotNull);
      expect(session!.completedAt, isNotNull);
      expect(session.qualityScore, equals('F')); // Stopped with F due to stale/aborted timeout
      
      newContainer.dispose();
    });

    test('Pausing focus session deactivates only focus blocker policy', () async {
      final writer = const SharedPrefsPolicyWriter();
      
      // Setup focus + sleep policies
      final focusPolicy = SourcePolicy(
        sessionId: 'session-123',
        activeUntil: DateTime.now().add(const Duration(minutes: 10)),
        selectedPackages: {'pkg.a'},
        protectionMode: ProtectionMode.guard,
        source: PolicySource.focus,
        scopedBreaks: [],
      );
      final sleepPolicy = SourcePolicy(
        sessionId: 'sleep-123',
        activeUntil: DateTime.now().add(const Duration(hours: 8)),
        selectedPackages: {'pkg.b'},
        protectionMode: ProtectionMode.guard,
        source: PolicySource.sleep,
        scopedBreaks: [],
      );

      await writer.activatePolicy(focusPolicy);
      await writer.activatePolicy(sleepPolicy);

      // Verify both are active
      var active = await writer.getActivePolicies();
      expect(active?.focus, isNotNull);
      expect(active?.sleep, isNotNull);

      // Pause Focus timer (implicitly calls deactivatePolicy on focus)
      await writer.deactivatePolicy(PolicySource.focus);

      active = await writer.getActivePolicies();
      expect(active?.focus, isNull);
      expect(active?.sleep, isNotNull); // Sleep policy remains fully active!
    });

    test('GardenService reads exact persisted seed details', () async {
      final now = DateTime.now();
      final start = DateTime(now.year, now.month, now.day);
      
      // Insert completed focus session with custom persisted seed details
      await db.focusSessionsDao.insertSession(
        FocusSessionsCompanion(
          id: const drift.Value('custom-seed-session'),
          sessionType: const drift.Value(SessionTypeColumn.deepWork),
          durationMinutes: const drift.Value(90),
          actualMinutes: const drift.Value(90),
          completedAt: drift.Value(now),
          startedAt: drift.Value(now.subtract(const Duration(minutes: 90))),
          gardenSeedKind: const drift.Value('tree'),
          gardenVariant: const drift.Value(2),
          gardenSeedEmoji: const drift.Value('🌴'),
        ),
      );

      final service = GardenService(db);
      final day = await service.buildDay(now);
      
      // Verify object grew from persisted seed
      final grown = day.objects.firstWhere((o) => o.id == 'focus-custom-seed-session');
      expect(grown.kind, equals(GardenObjectKind.tree));
      expect(grown.emoji, equals('🌴'));
    });
  });
}
