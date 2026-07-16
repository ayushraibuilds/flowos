import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' hide Column;

import '../../../core/constants/xp_constants.dart';
import '../../../data/local/database/app_database.dart';
import '../../../features/xp/models/daily_score_calculator.dart';
import '../../settings/providers/settings_providers.dart';
import '../../attention/repository/attention_data_repository.dart';

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
  return ref.watch(attentionDataRepositoryProvider)
      .watchTodayAttention()
      .map((day) => day.effectiveDistractingMinutes);
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

/// Watch if the user has any focus sessions in history.
final hasFocusHistoryProvider = StreamProvider<bool>((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.focusSessions)..limit(1))
      .watch()
      .map((list) => list.isNotEmpty);
});

/// Today's daily score — computed from persisted daily_scores or calculated live if missing.
final dailyScoreProvider = FutureProvider<DashboardScore>((ref) async {
  final db = ref.watch(databaseProvider);
  final settings = ref.watch(settingsProvider);
  final attentionRepo = ref.watch(attentionDataRepositoryProvider);

  final today = DateTime.now();
  final midnightToday = DateTime(today.year, today.month, today.day);

  // Fetch current live metrics from components
  final focusMinutes = await db.focusSessionsDao.totalFocusMinutesToday();
  final mits = await db.tasksDao.getMITs();
  final mitsCompleted = mits.where((t) => t.isCompleted).length;
  final todayAttention = await attentionRepo.getAttentionDay(today);
  final scrollMinutes = todayAttention.effectiveDistractingMinutes;
  final plan = await db.dailyPlansDao.getToday();

  // Scroll log recovery actions count today
  final start = midnightToday;
  final end = start.add(const Duration(days: 1));
  final scrollLogs = await (db.select(db.scrollLogs)
        ..where((l) =>
            l.timestamp.isBiggerOrEqualValue(start) &
            l.timestamp.isSmallerThanValue(end)))
      .get();
  final recoveryActions = scrollLogs
      .where((l) => !l.appName.contains('[Auto]') && l.recoveryActionTaken)
      .length;

  final energyCheckIns = await db.energyCheckInsDao.countToday();
  final budget = plan?.scrollBudgetMinutes ?? settings.scrollBudget;
  final intentionCompleted = plan?.intentionCompleted ?? false;
  final shutdownCompleted = plan?.shutdownCompleted ?? false;

  final scoreRecord = await db.dailyScoresDao.getForDay(today);
  final DailyScoreResult scoreResult;

  if (scoreRecord != null && scoreRecord.scoringVersion == XpConstants.currentScoringVersion) {
    scoreResult = DailyScoreResult(
      score: scoreRecord.score,
      grade: scoreRecord.grade,
      message: scoreRecord.grade != null
          ? DailyScoreCalculator.messageForGrade(scoreRecord.grade!)
          : "Coverage incomplete. Keep building your daily rhythm.",
      isIncomplete: scoreRecord.isIncomplete,
      availableWeight: scoreRecord.availableWeight,
      coverageLabel: scoreRecord.isIncomplete
          ? "Incomplete — attention data unavailable"
          : "Complete",
      scoringVersion: scoreRecord.scoringVersion,
      focusPoints: scoreRecord.focusPoints,
      intentPoints: scoreRecord.intentPoints,
      attentionPoints: scoreRecord.attentionPoints,
      carePoints: scoreRecord.carePoints,
    );
  } else {
    final hasEngagedToday = focusMinutes > 0 ||
        mitsCompleted > 0 ||
        intentionCompleted ||
        shutdownCompleted ||
        energyCheckIns > 0 ||
        recoveryActions > 0;

    if (!hasEngagedToday) {
      scoreResult = DailyScoreResult(
        score: 0,
        grade: null,
        message: "Your day hasn't started yet — set an intention or start a focus session.",
        isIncomplete: true,
        availableWeight: 1.0,
        coverageLabel: "Incomplete",
        scoringVersion: XpConstants.currentScoringVersion,
        focusPoints: 0.0,
        intentPoints: 0.0,
        attentionPoints: null,
        carePoints: 0.0,
      );
    } else {
      // Calculate live fallback
      scoreResult = DailyScoreCalculator.calculate(
        focusMinutes: focusMinutes,
        mitsCompleted: mitsCompleted,
        scrollMinutes: scrollMinutes,
        scrollBudget: budget,
        intentionCompleted: intentionCompleted,
        shutdownCompleted: shutdownCompleted,
        energyCheckIns: energyCheckIns,
        recoveryActions: recoveryActions,
        attentionCoverage: todayAttention.coverage,
      );
    }
  }

  return DashboardScore(
    score: scoreResult.score,
    grade: scoreResult.grade,
    message: scoreResult.message,
    focusMinutes: focusMinutes,
    mitsCompleted: mitsCompleted,
    scrollMinutes: scrollMinutes,
    scrollBudget: budget,
    intentionCompleted: intentionCompleted,
    coverage: todayAttention.coverage,
    isIncomplete: scoreResult.isIncomplete,
    availableWeight: scoreResult.availableWeight,
    coverageLabel: scoreResult.coverageLabel,
    scoringVersion: scoreResult.scoringVersion,
    focusPoints: scoreResult.focusPoints,
    intentPoints: scoreResult.intentPoints,
    attentionPoints: scoreResult.attentionPoints,
    carePoints: scoreResult.carePoints,
  );
});


/// Aggregated dashboard data.
class DashboardScore {
  final int score;
  final String? grade; // null when incomplete
  final String message;
  final int focusMinutes;
  final int mitsCompleted;
  final int scrollMinutes;
  final int scrollBudget;
  final bool intentionCompleted;
  final DataCoverage coverage;
  final bool isIncomplete;
  final double availableWeight;
  final String coverageLabel;
  final int scoringVersion;

  // Breakdown
  final double focusPoints;
  final double intentPoints;
  final double? attentionPoints;
  final double carePoints;

  const DashboardScore({
    required this.score,
    required this.grade,
    required this.message,
    required this.focusMinutes,
    required this.mitsCompleted,
    required this.scrollMinutes,
    required this.scrollBudget,
    required this.intentionCompleted,
    required this.coverage,
    required this.isIncomplete,
    required this.availableWeight,
    required this.coverageLabel,
    required this.scoringVersion,
    required this.focusPoints,
    required this.intentPoints,
    required this.attentionPoints,
    required this.carePoints,
  });
}
