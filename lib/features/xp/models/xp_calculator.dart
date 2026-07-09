import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/xp_constants.dart';
import '../../../data/local/dao/xp_ledger_dao.dart';
import '../../../data/local/database/app_database.dart';
import '../../../data/local/tables/xp_ledger_table.dart';
import '../../../data/local/tables/tasks_table.dart';
import '../../../data/local/tables/focus_sessions_table.dart';
import 'streak_service.dart';

const _uuid = Uuid();

/// Pure XP calculation logic + ledger writing.
/// All XP changes flow through here — never write to the ledger directly.
class XpCalculator {
  final XpLedgerDao _ledgerDao;

  XpCalculator(this._ledgerDao);

  // ─── Focus Session XP ─────────────────────────────────────────

  /// Calculate and record XP for a completed focus session.
  /// Returns the XP earned.
  Future<int> awardSessionXP({
    required String sessionId,
    required SessionTypeColumn sessionType,
    required int durationMinutes,
    required int actualMinutes,
    required String? taskId,
    required int streakDays,
  }) async {
    // Base XP by session type
    int baseXP = switch (sessionType) {
      SessionTypeColumn.pomodoro => XpConstants.pomodoroComplete,
      SessionTypeColumn.deepWork => XpConstants.deepWorkComplete,
      SessionTypeColumn.custom => (actualMinutes * 1.6).round(), // ~40 XP per 25m
    };

    // Partial credit: if completed < 100% but >= 60%, proportional XP
    final completionRatio = durationMinutes > 0
        ? actualMinutes / durationMinutes
        : 0.0;

    if (completionRatio < 0.6) {
      // Below 60% — no XP (attention cost recorded separately)
      return 0;
    } else if (completionRatio < 1.0) {
      // 60-99% — proportional
      baseXP = (baseXP * completionRatio).round();
    }

    // Standalone session multiplier (no task attached = 60% XP)
    if (taskId == null) {
      baseXP = (baseXP * XpConstants.standaloneSessionMultiplier).round();
    }

    // Streak multiplier
    final streakMultiplier = XpConstants.streakMultiplier(streakDays);
    baseXP = (baseXP * streakMultiplier).round();

    // Daily cap check
    final todayTotal = await _ledgerDao.getDailyXP();
    if (todayTotal + baseXP > XpConstants.dailyCapTotal) {
      baseXP = (XpConstants.dailyCapTotal - todayTotal).clamp(0, baseXP);
    }

    if (baseXP <= 0) return 0;

    // Record to ledger
    await _appendEntry(XpLedgerEntriesCompanion(
      id: Value(_uuid.v4()),
      actionType: const Value(XpActionTypeColumn.focusComplete),
      pointsDelta: Value(baseXP),
      sourceEntityId: Value(sessionId),
      explanation: Value(
        'Completed ${actualMinutes}m ${sessionType.name} session'
        '${taskId == null ? " (standalone)" : ""}'
        '${streakDays >= 7 ? " · ${streakMultiplier}x streak" : ""}',
      ),
      timestamp: Value(DateTime.now()),
    ));

    return baseXP;
  }

  // ─── Task Completion XP ────────────────────────────────────────

  /// Award XP for completing a task.
  Future<int> awardTaskXP({
    required String taskId,
    required String taskTitle,
    required bool isMIT,
    required EnergyLevelColumn energyLevel,
    required int streakDays,
  }) async {
    int baseXP = XpConstants.taskComplete;

    // MIT bonus (only if added before cutoff hour)
    if (isMIT) {
      baseXP += XpConstants.mitComplete;
    }

    // Light task daily cap
    if (energyLevel == EnergyLevelColumn.light) {
      final lightXPToday = await _ledgerDao
          .sumTodayByType(XpActionTypeColumn.taskComplete);
      if (lightXPToday >= XpConstants.dailyCapLightTasks) {
        baseXP = 0; // Cap reached
      }
    }

    // Streak multiplier
    baseXP = (baseXP * XpConstants.streakMultiplier(streakDays)).round();

    // Daily cap
    final todayTotal = await _ledgerDao.getDailyXP();
    if (todayTotal + baseXP > XpConstants.dailyCapTotal) {
      baseXP = (XpConstants.dailyCapTotal - todayTotal).clamp(0, baseXP);
    }

    if (baseXP <= 0) return 0;

    await _appendEntry(XpLedgerEntriesCompanion(
      id: Value(_uuid.v4()),
      actionType: const Value(XpActionTypeColumn.taskComplete),
      pointsDelta: Value(baseXP),
      sourceEntityId: Value(taskId),
      explanation: Value(
        'Completed: "$taskTitle"${isMIT ? " (MIT)" : ""}',
      ),
      timestamp: Value(DateTime.now()),
    ));

    return baseXP;
  }

  // ─── MIT Completion Bonus ──────────────────────────────────────

  /// Award all-MITs-completed daily bonus.
  Future<int> awardAllMITsBonus() async {
    const xp = XpConstants.allMitsDaily;

    await _appendEntry(XpLedgerEntriesCompanion(
      id: Value(_uuid.v4()),
      actionType: const Value(XpActionTypeColumn.allMitsDaily),
      pointsDelta: const Value(xp),
      explanation: const Value('All 3 MITs completed today! 🎯'),
      timestamp: Value(DateTime.now()),
    ));

    return xp;
  }

  // ─── Ritual XP ────────────────────────────────────────────────

  Future<int> awardFocusRitualXP() async {
    const xp = XpConstants.focusRitualComplete;

    await _appendEntry(XpLedgerEntriesCompanion(
      id: Value(_uuid.v4()),
      actionType: const Value(XpActionTypeColumn.focusRitualComplete),
      pointsDelta: const Value(xp),
      explanation: const Value('Focus ritual completed 🧘'),
      timestamp: Value(DateTime.now()),
    ));

    return xp;
  }

  Future<int> awardShutdownRitualXP() async {
    const xp = XpConstants.shutdownRitualComplete;

    await _appendEntry(XpLedgerEntriesCompanion(
      id: Value(_uuid.v4()),
      actionType: const Value(XpActionTypeColumn.shutdownRitualComplete),
      pointsDelta: const Value(xp),
      explanation: const Value('Shutdown ritual completed 🌙'),
      timestamp: Value(DateTime.now()),
    ));

    return xp;
  }

  // ─── Bounce-Back Bonus ─────────────────────────────────────────

  Future<int> awardBounceBackBonus(String recoveryType) async {
    const xp = XpConstants.bounceBackBonus;

    await _appendEntry(XpLedgerEntriesCompanion(
      id: Value(_uuid.v4()),
      actionType: const Value(XpActionTypeColumn.bounceBackBonus),
      pointsDelta: const Value(xp),
      explanation: Value('Recovery after scrolling: $recoveryType 🔄'),
      timestamp: Value(DateTime.now()),
    ));

    return xp;
  }

  // ─── Break Content Bonus ───────────────────────────────────────

  Future<int> awardBreakContentXP() async {
    const xp = XpConstants.breakContentUsed;

    await _appendEntry(XpLedgerEntriesCompanion(
      id: Value(_uuid.v4()),
      actionType: const Value(XpActionTypeColumn.breakContentUsed),
      pointsDelta: const Value(xp),
      explanation: const Value('Engaged with break content 🧩'),
      timestamp: Value(DateTime.now()),
    ));

    return xp;
  }

  // ─── Energy Check-in Bonus ─────────────────────────────────────

  Future<int> awardEnergyCheckin3xBonus() async {
    const xp = XpConstants.energyCheckin3x;

    await _appendEntry(XpLedgerEntriesCompanion(
      id: Value(_uuid.v4()),
      actionType: const Value(XpActionTypeColumn.energyCheckin3x),
      pointsDelta: const Value(xp),
      explanation: const Value('All 3 energy check-ins completed ⚡'),
      timestamp: Value(DateTime.now()),
    ));

    return xp;
  }

  // ─── Streak Bonus ─────────────────────────────────────────────

  Future<int> awardStreakBonus(int streakDays) async {
    const xp = XpConstants.sevenDayStreak;

    await _appendEntry(XpLedgerEntriesCompanion(
      id: Value(_uuid.v4()),
      actionType: const Value(XpActionTypeColumn.sevenDayStreak),
      pointsDelta: const Value(xp),
      explanation: Value('$streakDays-day streak milestone! 🔥'),
      timestamp: Value(DateTime.now()),
    ));

    return xp;
  }

  Future<void> _appendEntry(XpLedgerEntriesCompanion entry) async {
    await _ledgerDao.appendEntry(entry);
    await StreakService.recordActivity();
  }
}
