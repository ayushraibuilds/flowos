import 'dart:async';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/local/database/app_database.dart';
import '../../attention/repository/attention_data_repository.dart';
import '../../settings/providers/settings_providers.dart';
import '../models/daily_score_calculator.dart';

/// Service to calculate, snapshot, and persist Daily Score entries.
class DailyScoreSnapshotService {
  final AppDatabase _db;
  final AttentionDataRepository _attentionRepo;
  final Ref _ref;

  StreamSubscription? _changeSubscription;
  Timer? _debounceTimer;

  DailyScoreSnapshotService(this._db, this._attentionRepo, this._ref);

  /// Initialize: Sync usage stats and snapshot yesterday + today.
  Future<void> initialize() async {
    try {
      // 1. Sync usage for yesterday and today on launch/resume
      await _attentionRepo.syncUsage(days: 2);
    } catch (e) {
      debugPrint('⚠️ DailyScoreSnapshotService: initial sync failed: $e');
    }

    // 2. Finalize yesterday's score
    await finalizeYesterdayScore();

    // 3. Listen to score-relevant table updates for today
    _setupTodayObserver();
  }

  /// Force finalization of yesterday's score.
  /// If Usage Access is granted later, yesterday's score can improve from incomplete to complete.
  Future<void> finalizeYesterdayScore() async {
    final now = DateTime.now();
    final yesterday = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 1));
    await snapshotDay(yesterday);
  }

  /// Calculates and persists the score for a specific date.
  Future<void> snapshotDay(DateTime date) async {
    final midnightDate = DateTime(date.year, date.month, date.day);
    final nextDay = midnightDate.add(const Duration(days: 1));

    // Fetch existing snapshot to respect V1 version locking
    final existing = await _db.dailyScoresDao.getForDay(midnightDate);
    if (existing != null && existing.scoringVersion == 1) {
      // Keep legacy V1 scores intact; do not overwrite
      return;
    }

    // Load inputs for the given day
    final sessions = await _db.focusSessionsDao.getByDateRange(midnightDate, nextDay);
    final focusMinutes = sessions
        .where((s) => s.completedAt != null)
        .fold<int>(0, (sum, s) => sum + s.actualMinutes);

    final mits = await (_db.select(_db.tasks)
          ..where((t) =>
              t.isMIT.equals(true) &
              t.isCompleted.equals(true) &
              t.completedAt.isBiggerOrEqualValue(midnightDate) &
              t.completedAt.isSmallerThanValue(nextDay)))
        .get();
    final mitsCompleted = mits.length;

    final scrollLogs = await (_db.select(_db.scrollLogs)
          ..where((l) =>
              l.timestamp.isBiggerOrEqualValue(midnightDate) &
              l.timestamp.isSmallerThanValue(nextDay)))
        .get();
    final recoveryActions = scrollLogs
        .where((l) => !l.appName.contains('[Auto]') && l.recoveryActionTaken)
        .length;

    final energyLogs = await _db.energyCheckInsDao.getCheckInsInRange(midnightDate, nextDay);
    final energyCheckIns = energyLogs.length;

    final plan = await _db.dailyPlansDao.getByDateRange(midnightDate, nextDay);
    final intentionCompleted = plan?.intentionCompleted ?? false;
    final shutdownCompleted = plan?.shutdownCompleted ?? false;

    // Retrieve daily budget: use plan budget, fallback to settings for today, no placeholder budget for historic days
    int budget = 30;
    if (plan != null) {
      budget = plan.scrollBudgetMinutes;
    } else {
      final today = DateTime.now();
      final isToday = date.year == today.year && date.month == today.month && date.day == today.day;
      if (isToday) {
        budget = _ref.read(settingsProvider).scrollBudget;
      } else {
        // Do not calculate reclaimable or score if budget is not set for historic days
        budget = 0; 
      }
    }

    // Retrieve attention coverage
    final attentionDay = await _attentionRepo.getAttentionDay(date);
    
    // Calculate new V2 score
    final result = DailyScoreCalculator.calculate(
      focusMinutes: focusMinutes,
      mitsCompleted: mitsCompleted,
      scrollMinutes: attentionDay.effectiveDistractingMinutes,
      scrollBudget: budget,
      intentionCompleted: intentionCompleted,
      shutdownCompleted: shutdownCompleted,
      energyCheckIns: energyCheckIns,
      recoveryActions: recoveryActions,
      attentionCoverage: attentionDay.coverage,
    );

    // Save to daily_scores
    await _db.dailyScoresDao.upsertScore(
      DailyScoresCompanion.insert(
        day: midnightDate,
        score: result.score,
        grade: Value(result.grade),
        isIncomplete: result.isIncomplete,
        availableWeight: result.availableWeight,
        scoringVersion: result.scoringVersion,
        focusPoints: result.focusPoints,
        intentPoints: result.intentPoints,
        attentionPoints: Value(result.attentionPoints),
        carePoints: result.carePoints,
        computedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Sets up stream watchers on Drift tables to trigger debounced updates of today's score
  void _setupTodayObserver() {
    _changeSubscription?.cancel();

    // Watchers for focus sessions, tasks, scroll logs, daily plans, device day metrics, energy check-ins
    final today = DateTime.now();
    final midnightToday = DateTime(today.year, today.month, today.day);
    final nextDay = midnightToday.add(const Duration(days: 1));

    final streams = [
      _db.select(_db.focusSessions).watch(),
      _db.select(_db.tasks).watch(),
      _db.select(_db.scrollLogs).watch(),
      _db.select(_db.dailyPlans).watch(),
      _db.select(_db.deviceDayMetrics).watch(),
      _db.select(_db.energyCheckIns).watch(),
    ];

    // Combine streams and trigger debounced updates
    final combined = StreamController<void>();
    for (final stream in streams) {
      stream.listen((_) => combined.add(null));
    }

    _changeSubscription = combined.stream.listen((_) {
      _debounceUpdateToday();
    });
  }

  void _debounceUpdateToday() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(seconds: 2), () async {
      await snapshotDay(DateTime.now());
    });
  }

  void dispose() {
    _changeSubscription?.cancel();
    _debounceTimer?.cancel();
  }
}

/// Provider for DailyScoreSnapshotService
final dailyScoreSnapshotServiceProvider = Provider<DailyScoreSnapshotService>((ref) {
  final db = ref.watch(databaseProvider);
  final attentionRepo = ref.watch(attentionDataRepositoryProvider);
  final service = DailyScoreSnapshotService(db, attentionRepo, ref);
  ref.onDispose(() => service.dispose());
  return service;
});
