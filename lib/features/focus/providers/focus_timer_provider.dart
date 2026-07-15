import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../data/local/database/app_database.dart';
import '../../../../data/local/tables/focus_sessions_table.dart';
import '../models/focus_timer_stage.dart';
import '../services/focus_session_service.dart';
import '../services/policy_writer.dart';
import '../models/effective_policy.dart';

/// Notifier managing unified Focus and Deep Work timer state machine.
class FocusTimerNotifier extends StateNotifier<FocusTimerState?> {
  final Ref _ref;
  Timer? _ticker;
  Timer? _leaseTicker;

  static const _prefSessionId = 'flowos_active_session_id';
  static const _prefTaskTitle = 'flowos_active_task_title';
  static const _prefTaskId = 'flowos_active_task_id';
  static const _prefSessionType = 'flowos_active_session_type';
  static const _prefPhase = 'flowos_active_phase';
  static const _prefTotalSeconds = 'flowos_active_total_seconds';
  static const _prefElapsedSeconds = 'flowos_active_elapsed_seconds';
  static const _prefPauseCount = 'flowos_active_pause_count';
  static const _prefBackgroundCount = 'flowos_active_background_count';
  static const _prefStartedAtUtc = 'flowos_active_started_at_utc';
  static const _prefPausedAtUtc = 'flowos_active_paused_at_utc';
  static const _prefExpectedEndTimeUtc = 'flowos_active_expected_end_time_utc';
  static const _prefAccumulatedRunningSeconds = 'flowos_active_accumulated_running_seconds';
  static const _prefLastResumedAtUtc = 'flowos_active_last_resumed_at_utc';
  static const _prefSelectedSound = 'flowos_active_selected_sound';
  static const _prefSeedKind = 'flowos_active_seed_kind';
  static const _prefSeedVariant = 'flowos_active_seed_variant';
  static const _prefSeedEmoji = 'flowos_active_seed_emoji';

  FocusTimerNotifier(this._ref) : super(null) {
    _rehydrate();
  }

  /// Initialize and load session from preferences, verifying with the database.
  Future<void> _rehydrate() async {
    final prefs = await SharedPreferences.getInstance();
    final sessionId = prefs.getString(_prefSessionId);
    if (sessionId == null || sessionId.isEmpty) {
      state = null;
      return;
    }

    // Verify session existence and active status in DB (source of truth reconciliation)
    final db = _ref.read(databaseProvider);
    final dbSession = await db.focusSessionsDao.getById(sessionId);
    if (dbSession == null || dbSession.completedAt != null) {
      // Conflicting/stale pref payload -> clear
      await _clearPrefs();
      state = null;
      return;
    }

    // Rehydrate properties
    final taskTitle = prefs.getString(_prefTaskTitle);
    final taskId = prefs.getString(_prefTaskId);
    final sessionTypeStr = prefs.getString(_prefSessionType) ?? SessionTypeColumn.pomodoro.name;
    final sessionType = SessionTypeColumn.values.firstWhere(
      (e) => e.name == sessionTypeStr,
      orElse: () => SessionTypeColumn.pomodoro,
    );
    final phaseStr = prefs.getString(_prefPhase) ?? FocusTimerPhase.idle.name;
    final phase = FocusTimerPhase.values.firstWhere(
      (e) => e.name == phaseStr,
      orElse: () => FocusTimerPhase.idle,
    );
    final totalSeconds = prefs.getInt(_prefTotalSeconds) ?? 25 * 60;
    final elapsedSeconds = prefs.getInt(_prefElapsedSeconds) ?? 0;
    final pauseCount = prefs.getInt(_prefPauseCount) ?? 0;
    final backgroundCount = prefs.getInt(_prefBackgroundCount) ?? 0;
    
    final startedAtStr = prefs.getString(_prefStartedAtUtc);
    final startedAtUtc = startedAtStr != null ? DateTime.parse(startedAtStr).toUtc() : DateTime.now().toUtc();
    
    final pausedAtStr = prefs.getString(_prefPausedAtUtc);
    final pausedAtUtc = pausedAtStr != null ? DateTime.parse(pausedAtStr).toUtc() : null;

    final expectedEndTimeStr = prefs.getString(_prefExpectedEndTimeUtc);
    final expectedEndTimeUtc = expectedEndTimeStr != null ? DateTime.parse(expectedEndTimeStr).toUtc() : null;

    final accumulatedRunningSeconds = prefs.getInt(_prefAccumulatedRunningSeconds) ?? 0;
    
    final lastResumedAtStr = prefs.getString(_prefLastResumedAtUtc);
    final lastResumedAtUtc = lastResumedAtStr != null ? DateTime.parse(lastResumedAtStr).toUtc() : null;

    final selectedSound = prefs.getString(_prefSelectedSound) ?? 'none';
    final seedKind = prefs.getString(_prefSeedKind) ?? 'flower';
    final seedVariant = prefs.getInt(_prefSeedVariant) ?? 0;
    final seedEmoji = prefs.getString(_prefSeedEmoji) ?? '🌸';

    var restored = FocusTimerState(
      sessionId: sessionId,
      taskId: taskId,
      taskTitle: taskTitle,
      sessionType: sessionType,
      phase: phase,
      totalSeconds: totalSeconds,
      elapsedSeconds: elapsedSeconds,
      pauseCount: pauseCount,
      backgroundCount: backgroundCount,
      startedAtUtc: startedAtUtc,
      pausedAtUtc: pausedAtUtc,
      expectedEndTimeUtc: expectedEndTimeUtc,
      accumulatedRunningSeconds: accumulatedRunningSeconds,
      lastResumedAtUtc: lastResumedAtUtc,
      selectedSound: selectedSound,
      gardenSeedKind: seedKind,
      gardenVariant: seedVariant,
      gardenSeedEmoji: seedEmoji,
    );

    final now = DateTime.now().toUtc();
    final isCountdown = sessionType != SessionTypeColumn.custom; // Custom = Flowtime

    if (isCountdown && expectedEndTimeUtc != null) {
      // 1. Check stale countdown session (startedAt + duration + 5 mins limit)
      final staleLimit = expectedEndTimeUtc.add(const Duration(minutes: 5));
      if (now.isAfter(staleLimit)) {
        debugPrint('⏳ FocusTimer: Stale countdown session detected. Auto-finalizing via stopSession().');
        final service = _ref.read(focusSessionServiceProvider);
        await service.stopSession(
          sessionId: sessionId,
          elapsedSeconds: elapsedSeconds,
          totalSeconds: totalSeconds,
          pauseCount: pauseCount,
          backgroundCount: backgroundCount,
          type: sessionType,
        );
        await _clearPrefs();
        state = null;
        return;
      }

      // 2. Check if naturally completed while backgrounded/closed
      if (now.isAfter(expectedEndTimeUtc)) {
        debugPrint('⏳ FocusTimer: Countdown completed naturally while closed. Finalizing.');
        final service = _ref.read(focusSessionServiceProvider);
        await service.completeSession(
          sessionId: sessionId,
          elapsedSeconds: totalSeconds,
          pauseCount: pauseCount,
          backgroundCount: backgroundCount,
          type: sessionType,
        );
        await _clearPrefs();
        state = null;
        return;
      }

      // 3. Catch up elapsed timer
      if (phase == FocusTimerPhase.running) {
        final elapsed = totalSeconds - expectedEndTimeUtc.difference(now).inSeconds;
        restored = restored.copyWith(elapsedSeconds: elapsed.clamp(0, totalSeconds));
      }
    } else if (!isCountdown) {
      // Flowtime stale/resume checks
      if (phase == FocusTimerPhase.running && lastResumedAtUtc != null) {
        // Catch up Flowtime elapsed seconds
        final running = accumulatedRunningSeconds + now.difference(lastResumedAtUtc).inSeconds;
        restored = restored.copyWith(elapsedSeconds: running);
        
        // Auto-finalize flowtime if lease expired / closed for too long (> 15 minutes)
        final lastActive = lastResumedAtUtc;
        if (now.difference(lastActive).inMinutes > 15) {
          debugPrint('⏳ FocusTimer: Flowtime closed for >15m without updates. Finalizing.');
          final service = _ref.read(focusSessionServiceProvider);
          await service.completeSession(
            sessionId: sessionId,
            elapsedSeconds: running,
            pauseCount: pauseCount,
            backgroundCount: backgroundCount,
            type: sessionType,
            isFlowtime: true,
          );
          await _clearPrefs();
          state = null;
          return;
        }
      }
    }

    // Check stale paused sessions (> 60 minutes or next local day)
    if (phase == FocusTimerPhase.paused && pausedAtUtc != null) {
      final pausedDuration = now.difference(pausedAtUtc);
      final isNextDay = now.toLocal().day != pausedAtUtc.toLocal().day;
      if (pausedDuration.inMinutes > 60 || isNextDay) {
        debugPrint('⏳ FocusTimer: Session paused for too long, auto-finalizing.');
        final service = _ref.read(focusSessionServiceProvider);
        await service.stopSession(
          sessionId: sessionId,
          elapsedSeconds: elapsedSeconds,
          totalSeconds: totalSeconds,
          pauseCount: pauseCount,
          backgroundCount: backgroundCount,
          type: sessionType,
        );
        await _clearPrefs();
        state = null;
        return;
      }
    }

    state = restored;

    if (state!.phase == FocusTimerPhase.running) {
      _startTickers();
    }
  }

  /// Start a focus session. Rejects if one is already active.
  Future<bool> startSession({
    required SessionTypeColumn type,
    required int durationMinutes,
    String? taskId,
    String? taskTitle,
    String selectedSound = 'none',
  }) async {
    if (state != null && state!.phase != FocusTimerPhase.idle && state!.phase != FocusTimerPhase.stopped && state!.phase != FocusTimerPhase.completed) {
      debugPrint('⚠️ FocusTimer: Rejecting start request. A session is already active.');
      return false;
    }

    final service = _ref.read(focusSessionServiceProvider);
    final sessionId = await service.startSession(
      type: type,
      durationMinutes: durationMinutes,
      taskId: taskId,
    );

    // Re-load the database record to get the exact generated seed Kind and Variant
    final db = _ref.read(databaseProvider);
    final dbSession = await db.focusSessionsDao.getById(sessionId);
    
    final seedKind = dbSession?.gardenSeedKind ?? 'flower';
    final seedVariant = dbSession?.gardenVariant ?? 0;
    final seedEmoji = dbSession?.gardenSeedEmoji ?? '🌸';

    final totalSeconds = durationMinutes * 60;
    final now = DateTime.now().toUtc();
    final expectedEndTimeUtc = type != SessionTypeColumn.custom ? now.add(Duration(seconds: totalSeconds)) : null;

    final newState = FocusTimerState(
      sessionId: sessionId,
      taskId: taskId,
      taskTitle: taskTitle,
      sessionType: type,
      phase: FocusTimerPhase.running,
      totalSeconds: totalSeconds,
      elapsedSeconds: 0,
      pauseCount: 0,
      backgroundCount: 0,
      startedAtUtc: now,
      expectedEndTimeUtc: expectedEndTimeUtc,
      accumulatedRunningSeconds: 0,
      lastResumedAtUtc: now,
      selectedSound: selectedSound,
      gardenSeedKind: seedKind,
      gardenVariant: seedVariant,
      gardenSeedEmoji: seedEmoji,
    );

    state = newState;
    await _saveToPrefs(newState);
    _startTickers();
    return true;
  }

  /// Pause current timer session. Bypasses only Focus blocker policy.
  Future<void> pauseSession() async {
    final current = state;
    if (current == null || current.phase != FocusTimerPhase.running) return;

    _stopTickers();

    final now = DateTime.now().toUtc();
    final accumulated = current.sessionType == SessionTypeColumn.custom && current.lastResumedAtUtc != null
        ? current.accumulatedRunningSeconds + now.difference(current.lastResumedAtUtc!).inSeconds
        : current.accumulatedRunningSeconds;

    final updated = current.copyWith(
      phase: FocusTimerPhase.paused,
      pausedAtUtc: now,
      pauseCount: current.pauseCount + 1,
      accumulatedRunningSeconds: accumulated,
      lastResumedAtUtc: null,
    );

    state = updated;
    await _saveToPrefs(updated);

    // Call deactivatePolicy on focus only. Sleep deep/guard remains untouched.
    try {
      final writer = const SharedPrefsPolicyWriter();
      await writer.deactivatePolicy(PolicySource.focus);
    } catch (_) {}
  }

  /// Resume current paused timer session.
  Future<void> resumeSession() async {
    final current = state;
    if (current == null || current.phase != FocusTimerPhase.paused || current.pausedAtUtc == null) return;

    final now = DateTime.now().toUtc();
    final pausedSeconds = now.difference(current.pausedAtUtc!).inSeconds;

    final DateTime? expectedEnd;
    if (current.expectedEndTimeUtc != null) {
      expectedEnd = current.expectedEndTimeUtc!.add(Duration(seconds: pausedSeconds));
    } else {
      expectedEnd = null;
    }

    final updated = current.copyWith(
      phase: FocusTimerPhase.running,
      pausedAtUtc: null,
      expectedEndTimeUtc: expectedEnd,
      lastResumedAtUtc: now,
    );

    state = updated;
    await _saveToPrefs(updated);
    _startTickers();

    // Re-activate Focus blocker policy
    try {
      final db = _ref.read(databaseProvider);
      final protectedApps = await db.protectedAppsDao.getFocusProtected();
      final packages = protectedApps.map((a) => a.appRef).toSet();
      
      final policy = SourcePolicy(
        sessionId: current.sessionId,
        activeUntil: DateTime.now().add(const Duration(minutes: 3)),
        selectedPackages: packages,
        protectionMode: ProtectionMode.guard,
        source: PolicySource.focus,
        scopedBreaks: [],
      );

      final writer = const SharedPrefsPolicyWriter();
      await writer.activatePolicy(policy);
    } catch (_) {}
  }

  /// Stop session prematurely (cancellation/stop pipeline).
  Future<FocusSessionResult> stopSession() async {
    final current = state;
    if (current == null) {
      return FocusSessionResult(xpEarned: 0, newlyUnlockedAchievements: []);
    }

    _stopTickers();

    final service = _ref.read(focusSessionServiceProvider);
    final result = await service.stopSession(
      sessionId: current.sessionId,
      elapsedSeconds: current.elapsedSeconds,
      totalSeconds: current.totalSeconds,
      pauseCount: current.pauseCount,
      backgroundCount: current.backgroundCount,
      type: current.sessionType,
    );

    state = current.copyWith(phase: FocusTimerPhase.stopped);
    await _clearPrefs();
    state = null;
    return result;
  }

  /// Complete session (countdown hit or user completed Flowtime).
  Future<FocusSessionResult> completeSession() async {
    final current = state;
    if (current == null) {
      return FocusSessionResult(xpEarned: 0, newlyUnlockedAchievements: []);
    }

    _stopTickers();

    final service = _ref.read(focusSessionServiceProvider);
    final isFlow = current.sessionType == SessionTypeColumn.custom;
    final result = await service.completeSession(
      sessionId: current.sessionId,
      elapsedSeconds: isFlow ? current.elapsedSeconds : current.totalSeconds,
      pauseCount: current.pauseCount,
      backgroundCount: current.backgroundCount,
      type: current.sessionType,
      isFlowtime: isFlow,
    );

    state = current.copyWith(phase: FocusTimerPhase.completed);
    await _clearPrefs();
    state = null;
    return result;
  }

  /// Record a background switch. Increments background counter.
  Future<void> recordBackground() async {
    final current = state;
    if (current == null || current.phase != FocusTimerPhase.running) return;

    final updated = current.copyWith(
      backgroundCount: current.backgroundCount + 1,
    );
    state = updated;
    await _saveToPrefs(updated);
  }

  /// Change active ambient sound key in state & player loop.
  void selectSound(String soundKey) {
    if (state != null) {
      final updated = state!.copyWith(selectedSound: soundKey);
      state = updated;
      _saveToPrefs(updated);
    }
  }

  void _startTickers() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      final current = state;
      if (current == null || current.phase != FocusTimerPhase.running) {
        timer.cancel();
        return;
      }

      final now = DateTime.now().toUtc();
      final int elapsed;
      if (current.sessionType == SessionTypeColumn.custom) {
        // Flowtime increment
        elapsed = current.lastResumedAtUtc != null
            ? current.accumulatedRunningSeconds + now.difference(current.lastResumedAtUtc!).inSeconds
            : current.elapsedSeconds;
      } else {
        // Countdown increment
        if (current.expectedEndTimeUtc != null) {
          final diff = current.expectedEndTimeUtc!.difference(now).inSeconds;
          elapsed = (current.totalSeconds - diff).clamp(0, current.totalSeconds);
          if (elapsed >= current.totalSeconds) {
            completeSession();
            return;
          }
        } else {
          elapsed = current.elapsedSeconds + 1;
        }
      }

      state = current.copyWith(elapsedSeconds: elapsed);
    });

    // Blocker accessibility lease renewer
    _leaseTicker?.cancel();
    _leaseTicker = Timer.periodic(const Duration(seconds: 20), (timer) async {
      final current = state;
      if (current == null || current.phase != FocusTimerPhase.running) {
        timer.cancel();
        return;
      }
      try {
        final writer = const SharedPrefsPolicyWriter();
        await writer.renewLease(PolicySource.focus, DateTime.now().add(const Duration(minutes: 2)));
      } catch (_) {}
    });
  }

  void _stopTickers() {
    _ticker?.cancel();
    _ticker = null;
    _leaseTicker?.cancel();
    _leaseTicker = null;
  }

  Future<void> _saveToPrefs(FocusTimerState s) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefSessionId, s.sessionId);
    if (s.taskId != null) await prefs.setString(_prefTaskId, s.taskId!);
    if (s.taskTitle != null) await prefs.setString(_prefTaskTitle, s.taskTitle!);
    await prefs.setString(_prefSessionType, s.sessionType.name);
    await prefs.setString(_prefPhase, s.phase.name);
    await prefs.setInt(_prefTotalSeconds, s.totalSeconds);
    await prefs.setInt(_prefElapsedSeconds, s.elapsedSeconds);
    await prefs.setInt(_prefPauseCount, s.pauseCount);
    await prefs.setInt(_prefBackgroundCount, s.backgroundCount);
    await prefs.setString(_prefStartedAtUtc, s.startedAtUtc.toIso8601String());
    if (s.pausedAtUtc != null) await prefs.setString(_prefPausedAtUtc, s.pausedAtUtc!.toIso8601String());
    if (s.expectedEndTimeUtc != null) await prefs.setString(_prefExpectedEndTimeUtc, s.expectedEndTimeUtc!.toIso8601String());
    await prefs.setInt(_prefAccumulatedRunningSeconds, s.accumulatedRunningSeconds);
    if (s.lastResumedAtUtc != null) await prefs.setString(_prefLastResumedAtUtc, s.lastResumedAtUtc!.toIso8601String());
    await prefs.setString(_prefSelectedSound, s.selectedSound);
    await prefs.setString(_prefSeedKind, s.gardenSeedKind);
    await prefs.setInt(_prefSeedVariant, s.gardenVariant);
    await prefs.setString(_prefSeedEmoji, s.gardenSeedEmoji);
  }

  Future<void> _clearPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefSessionId);
    await prefs.remove(_prefTaskId);
    await prefs.remove(_prefTaskTitle);
    await prefs.remove(_prefSessionType);
    await prefs.remove(_prefPhase);
    await prefs.remove(_prefTotalSeconds);
    await prefs.remove(_prefElapsedSeconds);
    await prefs.remove(_prefPauseCount);
    await prefs.remove(_prefBackgroundCount);
    await prefs.remove(_prefStartedAtUtc);
    await prefs.remove(_prefPausedAtUtc);
    await prefs.remove(_prefExpectedEndTimeUtc);
    await prefs.remove(_prefAccumulatedRunningSeconds);
    await prefs.remove(_prefLastResumedAtUtc);
    await prefs.remove(_prefSelectedSound);
    await prefs.remove(_prefSeedKind);
    await prefs.remove(_prefSeedVariant);
    await prefs.remove(_prefSeedEmoji);
  }

  @override
  void dispose() {
    _stopTickers();
    super.dispose();
  }
}

/// Global provider for unified focus timer.
final focusTimerNotifierProvider = StateNotifierProvider<FocusTimerNotifier, FocusTimerState?>((ref) {
  return FocusTimerNotifier(ref);
});

/// Global provider for tracking whether rest/recovery is active.
final isRecoveryActiveProvider = StateProvider<bool>((ref) => false);
