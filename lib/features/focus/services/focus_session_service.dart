import 'dart:convert';
import 'dart:math' as math;
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/xp_constants.dart';
import '../../../data/local/database/app_database.dart';
import '../../../data/local/tables/focus_sessions_table.dart';
import '../../../data/local/tables/xp_ledger_table.dart';
import '../../../features/achievements/models/achievement_checker.dart';
import '../../../features/flow_garden/models/garden_day.dart';
import '../../../features/xp/models/focus_quality_calculator.dart';
import '../../../features/xp/models/streak_service.dart';
import '../../../features/xp/models/xp_calculator.dart';
import '../models/effective_policy.dart';
import 'policy_writer.dart';

const _uuid = Uuid();

/// Model holding result details of a finished/stopped focus session.
class FocusSessionResult {
  final int xpEarned;
  final List<AchievementKey> newlyUnlockedAchievements;
  final GardenObject? gardenGrowth;

  FocusSessionResult({
    required this.xpEarned,
    required this.newlyUnlockedAchievements,
    this.gardenGrowth,
  });
}

/// Unified Focus Session Pipeline.
///
/// Handles beginning, completing (countdown or count-up Flowtime),
/// and premature stop (partial credit constraints) for focus blocks.
class FocusSessionService {
  final AppDatabase _db;
  final PolicyWriter _policyWriter;

  FocusSessionService(this._db, [this._policyWriter = const SharedPrefsPolicyWriter()]);

  /// Start a focus session. Inserts a new session record into the SQLite DB.
  /// Returns the newly generated sessionId (UUID).
  Future<String> startSession({
    required SessionTypeColumn type,
    required int durationMinutes,
    String? taskId,
    ProtectionMode protectionMode = ProtectionMode.guard,
  }) async {
    final sessionId = _uuid.v4();
    
    // Generate seed parameters inside service to avoid UI mismatches
    final isTree = type == SessionTypeColumn.deepWork || durationMinutes >= 50;
    final seedKind = isTree ? 'tree' : 'flower';
    final variants = isTree ? ['🌲', '🌳', '🌴'] : ['🌸', '🌻', '🌷', '🌼'];
    final variant = math.Random().nextInt(variants.length);
    final emoji = variants[variant];

    await _db.focusSessionsDao.insertSession(
      FocusSessionsCompanion(
        id: Value(sessionId),
        taskId: Value(taskId),
        sessionType: Value(type),
        durationMinutes: Value(durationMinutes),
        startedAt: Value(DateTime.now()),
        gardenSeedKind: Value(seedKind),
        gardenVariant: Value(variant),
        gardenSeedEmoji: Value(emoji),
      ),
    );

    // Save active state and distractor packages for Android Accessibility Blocker
    try {
      final protectedApps = await _db.protectedAppsDao.getFocusProtected();
      final packages = protectedApps.map((a) => a.appRef).toSet();

      // Lease duration is short (3 mins) and renewed dynamically by the screens
      final policy = SourcePolicy(
        sessionId: sessionId,
        activeUntil: DateTime.now().add(const Duration(minutes: 3)),
        selectedPackages: packages,
        protectionMode: protectionMode,
        source: PolicySource.focus,
        scopedBreaks: [],
        maxActiveUntil: DateTime.now().add(const Duration(hours: 4)),
      );

      await _policyWriter.activatePolicy(policy);
    } catch (e, st) {
      debugPrint('FocusSessionService: Failed to activate protection policy: $e\n$st');
    }

    return sessionId;
  }

  /// Complete a focus session (countdown target hit or Flowtime closed by user).
  /// Calculates quality score, updates session stats, records streak and checks achievements.
  /// Returns the FocusSessionResult containing XP earned and unlocked achievements.
  Future<FocusSessionResult> completeSession({
    required String sessionId,
    required int elapsedSeconds,
    required int pauseCount,
    required int backgroundCount,
    required SessionTypeColumn type,
    bool isFlowtime = false,
  }) async {
    // Deactivate accessibility blocker
    try {
      await _policyWriter.deactivatePolicy(PolicySource.focus);
    } catch (e, st) {
      debugPrint('FocusSessionService: Failed to deactivate policy on completeSession: $e\n$st');
    }

    final actualMin = (elapsedSeconds / 60).round();
    final existingSession = await _db.focusSessionsDao.getById(sessionId);
    final targetMin = existingSession?.durationMinutes ?? (isFlowtime ? actualMin : 25);
    final taskId = existingSession?.taskId;

    final quality = FocusQualityCalculator.calculate(
      durationMinutes: targetMin,
      actualMinutes: actualMin,
      pauseCount: pauseCount,
      backgroundCount: backgroundCount,
    );

    final streak = await StreakService.getStreak();
    final xpCalc = XpCalculator(_db.xpLedgerDao);
    final xp = await xpCalc.awardSessionXP(
      sessionId: sessionId,
      sessionType: isFlowtime ? SessionTypeColumn.custom : type,
      durationMinutes: targetMin,
      actualMinutes: actualMin,
      taskId: taskId,
      streakDays: streak,
      qualityScore: quality,
    );

    // 1. Update session in DB
    await _db.focusSessionsDao.updateSession(
      FocusSessionsCompanion(
        id: Value(sessionId),
        actualMinutes: Value(actualMin),
        pauseCount: Value(pauseCount),
        appBackgroundCount: Value(backgroundCount),
        xpEarned: Value(xp),
        qualityScore: Value(quality),
        completedAt: Value(DateTime.now()),
      ),
    );

    // 3. Record streak activity & check achievements
    await StreakService.recordActivity();
    final newlyUnlocked = await AchievementChecker.runCheck(_db);
    final completedSession = await _db.focusSessionsDao.getById(sessionId);
    final task = completedSession?.taskId == null
        ? null
        : await _db.tasksDao.getById(completedSession!.taskId!);
    final gardenGrowth = completedSession == null
        ? null
        : GardenObject.fromFocusSession(
            sessionId: completedSession.id,
            sessionType: completedSession.sessionType,
            actualMinutes: completedSession.actualMinutes,
            taskTitle: task?.title,
          );

    return FocusSessionResult(
      xpEarned: xp,
      newlyUnlockedAchievements: newlyUnlocked,
      gardenGrowth: gardenGrowth,
    );
  }

  /// Stop session (premature countdown timer cancel).
  /// Grants partial credit (50% XP) if progress >= 60% and actual time >= 10 min.
  /// Otherwise logs F grade with 0 XP.
  /// Returns the FocusSessionResult containing XP earned and unlocked achievements.
  Future<FocusSessionResult> stopSession({
    required String sessionId,
    required int elapsedSeconds,
    required int totalSeconds,
    required int pauseCount,
    required int backgroundCount,
    required SessionTypeColumn type,
  }) async {
    // Deactivate accessibility blocker
    try {
      await _policyWriter.deactivatePolicy(PolicySource.focus);
    } catch (e, st) {
      debugPrint('FocusSessionService: Failed to deactivate policy on stopSession: $e\n$st');
    }

    final actualMin = (elapsedSeconds / 60).round();
    final pct = totalSeconds > 0 ? (elapsedSeconds / totalSeconds) : 0.0;

    int xp = 0;
    List<AchievementKey> newlyUnlocked = [];

    if (pct >= 0.6 && actualMin >= 10) {
      // Partial credit
      final isDeepWork = type == SessionTypeColumn.deepWork;
      final baseXP = isDeepWork
          ? XpConstants.deepWorkComplete
          : XpConstants.pomodoroComplete;
      xp = (baseXP * pct * 0.5).round();

      await _db.focusSessionsDao.updateSession(
        FocusSessionsCompanion(
          id: Value(sessionId),
          actualMinutes: Value(actualMin),
          pauseCount: Value(pauseCount),
          appBackgroundCount: Value(backgroundCount),
          xpEarned: Value(xp),
          qualityScore: const Value('D'),
          completedAt: Value(DateTime.now()),
        ),
      );

      await _db.xpLedgerDao.appendEntry(
        XpLedgerEntriesCompanion(
          id: Value(_uuid.v4()),
          actionType: const Value(XpActionTypeColumn.focusComplete),
          pointsDelta: Value(xp),
          sourceEntityId: Value(sessionId),
          explanation: Value(
            'Partial ${actualMin}m session (${(pct * 100).round()}% complete)',
          ),
        ),
      );

      await StreakService.recordActivity();
      newlyUnlocked = await AchievementChecker.runCheck(_db);
    } else if (sessionId.isNotEmpty) {
      // Discard or record F
      await _db.focusSessionsDao.updateSession(
        FocusSessionsCompanion(
          id: Value(sessionId),
          actualMinutes: Value(actualMin),
          pauseCount: Value(pauseCount),
          appBackgroundCount: Value(backgroundCount),
          qualityScore: const Value('F'),
          completedAt: Value(DateTime.now()),
        ),
      );
    }

    return FocusSessionResult(
      xpEarned: xp,
      newlyUnlockedAchievements: newlyUnlocked,
    );
  }
}

/// Provider for FocusSessionService
final focusSessionServiceProvider = Provider<FocusSessionService>((ref) {
  final db = ref.watch(databaseProvider);
  return FocusSessionService(db);
});
