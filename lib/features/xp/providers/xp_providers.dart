import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/local/database/app_database.dart';
import '../../../data/local/dao/tasks_dao.dart';
import '../../../data/local/dao/focus_sessions_dao.dart';
import '../../../data/local/dao/xp_ledger_dao.dart';
import '../../../data/local/dao/scroll_logs_dao.dart';
import '../../../data/local/dao/energy_checkins_dao.dart';
import '../../../data/local/dao/daily_plans_dao.dart';
import '../../../data/local/dao/daily_reports_dao.dart';
import '../../../data/local/dao/achievements_dao.dart';
import '../../attention/repository/attention_data_repository.dart';
import '../models/xp_calculator.dart';
import '../models/streak_service.dart';
import '../../achievements/models/achievement_checker.dart';

// ─── DAO Providers ──────────────────────────────────────────────

final tasksDaoProvider = Provider<TasksDao>((ref) {
  return ref.watch(databaseProvider).tasksDao;
});

final focusSessionsDaoProvider = Provider<FocusSessionsDao>((ref) {
  return ref.watch(databaseProvider).focusSessionsDao;
});

final xpLedgerDaoProvider = Provider<XpLedgerDao>((ref) {
  return ref.watch(databaseProvider).xpLedgerDao;
});

final scrollLogsDaoProvider = Provider<ScrollLogsDao>((ref) {
  return ref.watch(databaseProvider).scrollLogsDao;
});

final energyCheckInsDaoProvider = Provider<EnergyCheckInsDao>((ref) {
  return ref.watch(databaseProvider).energyCheckInsDao;
});

final dailyPlansDaoProvider = Provider<DailyPlansDao>((ref) {
  return ref.watch(databaseProvider).dailyPlansDao;
});

final dailyReportsDaoProvider = Provider<DailyReportsDao>((ref) {
  return ref.watch(databaseProvider).dailyReportsDao;
});

final achievementsDaoProvider = Provider<AchievementsDao>((ref) {
  return ref.watch(databaseProvider).achievementsDao;
});

// ─── Service Providers ──────────────────────────────────────────

final xpCalculatorProvider = Provider<XpCalculator>((ref) {
  return XpCalculator(ref.watch(xpLedgerDaoProvider));
});

final achievementCheckerProvider = Provider<AchievementChecker>((ref) {
  return AchievementChecker(
    achievementsDao: ref.watch(achievementsDaoProvider),
    xpLedgerDao: ref.watch(xpLedgerDaoProvider),
    sessionsDao: ref.watch(focusSessionsDaoProvider),
    db: ref.watch(databaseProvider),
  );
});

// ─── Reactive Data Providers ────────────────────────────────────

/// Watch lifetime XP (reactive stream)
final lifetimeXPProvider = StreamProvider<int>((ref) {
  return ref.watch(xpLedgerDaoProvider).watchLifetimeXP();
});

/// Watch daily XP (reactive stream)
final dailyXPProvider = StreamProvider<int>((ref) {
  return ref.watch(xpLedgerDaoProvider).watchDailyXP();
});

/// Watch all active tasks
final activeTasksProvider = StreamProvider<List<Task>>((ref) {
  return ref.watch(tasksDaoProvider).watchAllActive();
});

/// Watch MITs
final mitsProvider = StreamProvider<List<Task>>((ref) {
  return ref.watch(tasksDaoProvider).watchMITs();
});

/// Watch today's focus sessions
final todaySessionsProvider = StreamProvider<List<FocusSession>>((ref) {
  return ref.watch(focusSessionsDaoProvider).watchToday();
});

/// Watch today's daily plan
final todayPlanProvider = StreamProvider<DailyPlan?>((ref) {
  return ref.watch(dailyPlansDaoProvider).watchToday();
});

/// Watch today's scroll total
final dailyScrollTotalProvider = StreamProvider<int>((ref) {
  return ref.watch(attentionDataRepositoryProvider)
      .watchTodayAttention()
      .map((day) => day.effectiveDistractingMinutes);
});

/// Watch all achievements
final achievementsProvider = StreamProvider<List<Achievement>>((ref) {
  return ref.watch(achievementsDaoProvider).watchAll();
});

/// Current streak (future, not stream — check on load)
final streakProvider = FutureProvider<int>((ref) {
  return StreakService.getStreak();
});

/// Best streak
final bestStreakProvider = FutureProvider<int>((ref) {
  return StreakService.getBestStreak();
});

/// Is streak paused
final streakPausedProvider = FutureProvider<bool>((ref) {
  return StreakService.isPaused();
});
