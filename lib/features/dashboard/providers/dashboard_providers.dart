import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/xp_constants.dart';
import '../../../data/local/database/app_database.dart';
import '../../../features/xp/models/daily_score_calculator.dart';
import '../../settings/providers/settings_providers.dart';

/// Riverpod providers for dashboard data — bridges home screen + report to DAOs.

/// Watch lifetime XP (reactive — updates when any XP entry is added).
final lifetimeXpProvider = StreamProvider<int>((ref) {
  final db = ref.watch(databaseProvider);
  return db.xpLedgerDao.watchLifetimeXP();
});

/// Watch today's XP.
final dailyXpProvider = StreamProvider<int>((ref) {
  final db = ref.watch(databaseProvider);
  return db.xpLedgerDao.watchDailyXP();
});

/// Watch today's scroll total.
final dailyScrollProvider = StreamProvider<int>((ref) {
  final db = ref.watch(databaseProvider);
  return db.scrollLogsDao.watchDailyTotal();
});

/// Watch today's focus sessions.
final todaySessionsProvider = StreamProvider<List<FocusSession>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.focusSessionsDao.watchToday();
});

/// Computed: current level from lifetime XP.
final currentLevelProvider = Provider<int>((ref) {
  final xp = ref.watch(lifetimeXpProvider).valueOrNull ?? 0;
  return XpConstants.levelFromXP(xp);
});

/// Computed: tier name from level.
final currentTierProvider = Provider<String>((ref) {
  final level = ref.watch(currentLevelProvider);
  return XpConstants.tierName(level);
});

/// Today's daily score — computed from all DAO sources.
final dailyScoreProvider = FutureProvider<DashboardScore>((ref) async {
  final db = ref.watch(databaseProvider);
  final settings = ref.watch(settingsProvider);

  final focusMinutes = await db.focusSessionsDao.totalFocusMinutesToday();
  final mits = await db.tasksDao.getMITs();
  final mitsCompleted = mits.where((t) => t.isCompleted).length;
  final scrollMinutes = await db.scrollLogsDao.getDailyTotal();
  final plan = await db.dailyPlansDao.getToday();

  final energyCheckIns = await db.energyCheckInsDao.countToday();
  final budget = plan?.scrollBudgetMinutes ?? settings.scrollBudget;

  final score = DailyScoreCalculator.calculate(
    focusMinutes: focusMinutes,
    mitsCompleted: mitsCompleted,
    scrollMinutes: scrollMinutes,
    scrollBudget: budget,
    intentionCompleted: plan?.intentionCompleted ?? false,
    shutdownCompleted: plan?.shutdownCompleted ?? false,
    energyCheckIns: energyCheckIns,
  );

  return DashboardScore(
    score: score,
    grade: DailyScoreCalculator.gradeFromScore(score),
    message: DailyScoreCalculator.messageForGrade(
        DailyScoreCalculator.gradeFromScore(score)),
    focusMinutes: focusMinutes,
    mitsCompleted: mitsCompleted,
    scrollMinutes: scrollMinutes,
    scrollBudget: budget,
    intentionCompleted: plan?.intentionCompleted ?? false,
  );
});


/// Aggregated dashboard data.
class DashboardScore {
  final int score;
  final String grade;
  final String message;
  final int focusMinutes;
  final int mitsCompleted;
  final int scrollMinutes;
  final int scrollBudget;
  final bool intentionCompleted;

  const DashboardScore({
    required this.score,
    required this.grade,
    required this.message,
    required this.focusMinutes,
    required this.mitsCompleted,
    required this.scrollMinutes,
    required this.scrollBudget,
    required this.intentionCompleted,
  });
}
