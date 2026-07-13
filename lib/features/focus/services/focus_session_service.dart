import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/xp_constants.dart';
import '../../../data/local/database/app_database.dart';
import '../../../data/local/tables/focus_sessions_table.dart';
import '../../../data/local/tables/xp_ledger_table.dart';
import '../../../features/achievements/models/achievement_checker.dart';
import '../../../features/flow_garden/models/garden_day.dart';
import '../../../features/xp/models/streak_service.dart';

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

  FocusSessionService(this._db);

  /// Start a focus session. Inserts a new session record into the SQLite DB.
  /// Returns the newly generated sessionId (UUID).
  Future<String> startSession({
    required SessionTypeColumn type,
    required int durationMinutes,
    String? taskId,
  }) async {
    final sessionId = _uuid.v4();
    await _db.focusSessionsDao.insertSession(
      FocusSessionsCompanion(
        id: Value(sessionId),
        taskId: Value(taskId),
        sessionType: Value(type),
        durationMinutes: Value(durationMinutes),
        startedAt: Value(DateTime.now()),
      ),
    );

    // Save active state and distractor packages for Android Accessibility Blocker
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_focus_active', true);

      final rawProfile = prefs.getString('flowos_user_profile');
      if (rawProfile != null) {
        final json = jsonDecode(rawProfile) as Map<String, dynamic>;
        final distractions = List<String>.from(json['distractions'] ?? []);
        final packageNames = distractions
            .map((d) => _mapToPackageName(d))
            .whereType<String>()
            .toList();
        await prefs.setString('blocked_packages', jsonEncode(packageNames));
      }
    } catch (_) {}

    return sessionId;
  }

  String? _mapToPackageName(String label) {
    return switch (label.toLowerCase()) {
      'instagram' => 'com.instagram.android',
      'youtube/shorts' || 'youtube' => 'com.google.android.youtube',
      'tiktok' => 'com.zhiliaoapp.musically',
      'x/twitter' || 'twitter' || 'x' => 'com.twitter.android',
      'reddit' => 'com.reddit.frontpage',
      'browser' => 'com.android.chrome',
      _ => null,
    };
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
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_focus_active', false);
    } catch (_) {}

    final actualMin = (elapsedSeconds / 60).round();
    final interrupts = pauseCount + backgroundCount;
    final quality = interrupts == 0
        ? 'A'
        : interrupts <= 2
        ? 'B'
        : 'C';

    final int xp;
    if (isFlowtime) {
      // Flowtime: 1.6 XP per minute, with quality modifiers
      final double multiplier = quality == 'A'
          ? 1.0
          : quality == 'B'
          ? 0.8
          : 0.6;
      xp = (actualMin * 1.6 * multiplier).round().clamp(1, 150);
    } else {
      // Countdown complete
      final isDeepWork = type == SessionTypeColumn.deepWork;
      final baseXP = isDeepWork
          ? XpConstants.deepWorkComplete
          : XpConstants.pomodoroComplete;
      xp = quality == 'A' ? baseXP : (baseXP * 0.8).round();
    }

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

    // 2. Append XP ledger entry
    await _db.xpLedgerDao.appendEntry(
      XpLedgerEntriesCompanion(
        id: Value(_uuid.v4()),
        actionType: const Value(XpActionTypeColumn.focusComplete),
        pointsDelta: Value(xp),
        sourceEntityId: Value(sessionId),
        explanation: Value(
          'Completed ${actualMin}m ${isFlowtime ? "Flowtime" : type.name} session (Quality: $quality)',
        ),
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
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_focus_active', false);
    } catch (_) {}

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
