import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../data/local/database/app_database.dart';
import '../../../data/local/tables/energy_checkins_table.dart';
import '../../settings/providers/settings_providers.dart';
import '../services/history_aggregator.dart';
import '../../attention/repository/attention_data_repository.dart';
import '../../dashboard/providers/dashboard_providers.dart';

enum InsightPeriod { today, week, month }

/// Selected period for insights dashboard
final insightPeriodProvider = StateProvider<InsightPeriod>((ref) => InsightPeriod.today);

/// Today / 7-day / 30-day Score Provider.
/// Returns either DailyScoreResult, WeeklyAggregate, or MonthlyAggregate.
final insightScoreProvider = FutureProvider<dynamic>((ref) async {
  final period = ref.watch(insightPeriodProvider);
  final db = ref.watch(databaseProvider);
  
  final now = DateTime.now();
  final midnightToday = DateTime(now.year, now.month, now.day);

  switch (period) {
    case InsightPeriod.today:
      final dashboardScore = await ref.watch(dailyScoreProvider.future);
      return dashboardScore;
    case InsightPeriod.week:
      // Return WeeklyAggregate starting 6 days ago
      final weekStart = midnightToday.subtract(const Duration(days: 6));
      return HistoryAggregator.getWeeklyAggregate(db, weekStart);
    case InsightPeriod.month:
      // Return MonthlyAggregate starting 29 days ago
      final monthStart = midnightToday.subtract(const Duration(days: 29));
      return HistoryAggregator.getMonthlyAggregate(db, monthStart);
  }
});

/// List of completed focus sessions for the selected period (to build honest focus timeline).
final insightFocusTimelineProvider = FutureProvider<List<FocusSession>>((ref) async {
  final period = ref.watch(insightPeriodProvider);
  final db = ref.watch(databaseProvider);
  
  final now = DateTime.now();
  final midnightToday = DateTime(now.year, now.month, now.day);
  final DateTime start;

  switch (period) {
    case InsightPeriod.today:
      start = midnightToday;
      break;
    case InsightPeriod.week:
      start = midnightToday.subtract(const Duration(days: 6));
      break;
    case InsightPeriod.month:
      start = midnightToday.subtract(const Duration(days: 29));
      break;
  }

  final end = midnightToday.add(const Duration(days: 1));
  return db.focusSessionsDao.getByDateRange(start, end);
});

/// Top distracting apps with total minutes, filtered by the selected period.
final insightAppImpactProvider = FutureProvider<List<({String label, String packageName, int minutes, int budget})>>((ref) async {
  final period = ref.watch(insightPeriodProvider);
  final db = ref.watch(databaseProvider);
  
  final now = DateTime.now();
  final midnightToday = DateTime(now.year, now.month, now.day);
  final DateTime start;

  switch (period) {
    case InsightPeriod.today:
      start = midnightToday;
      break;
    case InsightPeriod.week:
      start = midnightToday.subtract(const Duration(days: 6));
      break;
    case InsightPeriod.month:
      start = midnightToday.subtract(const Duration(days: 29));
      break;
  }

  final end = midnightToday.add(const Duration(days: 1));
  
  // Load device usage records for Android distracting apps (read isDistracting directly as historic snapshot)
  final records = await (db.select(db.deviceUsageRecords)
        ..where((r) =>
            r.date.isBiggerOrEqualValue(start) &
            r.date.isSmallerThanValue(end) &
            r.source.equals('android_usage') &
            r.isDistracting.equals(true)))
      .get();

  final Map<String, ({String label, int minutes})> grouped = {};
  for (final r in records) {
    final current = grouped[r.packageName];
    final label = r.label ?? r.packageName;
    if (current == null) {
      grouped[r.packageName] = (label: label, minutes: r.minutes);
    } else {
      grouped[r.packageName] = (label: label, minutes: current.minutes + r.minutes);
    }
  }

  // Get user budgets to calculate budget delta
  final plan = await db.dailyPlansDao.getByDateRange(start, end);
  int budget = 30;
  if (plan != null) {
    budget = plan.scrollBudgetMinutes;
  } else if (period == InsightPeriod.today) {
    budget = ref.read(settingsProvider).scrollBudget;
  }

  final list = grouped.entries.map((e) => (
    packageName: e.key,
    label: e.value.label,
    minutes: e.value.minutes,
    budget: budget,
  )).toList();

  list.sort((a, b) => b.minutes.compareTo(a.minutes));
  return list;
});

/// Android notification counts and unlock trends for Android users with consent.
final insightInterruptionProvider = FutureProvider<({
  bool isAvailable,
  List<({String appName, String appRef, int count})> notificationCounts,
  int totalUnlocks,
})>((ref) async {
  final period = ref.watch(insightPeriodProvider);
  final db = ref.watch(databaseProvider);
  final prefs = await SharedPreferences.getInstance();
  final hasConsent = prefs.getBool('flowos_interruption_collection_enabled') ?? false;
  if (!hasConsent) {
    return (isAvailable: false, notificationCounts: <({String appName, String appRef, int count})>[], totalUnlocks: 0);
  }

  final now = DateTime.now();
  final midnightToday = DateTime(now.year, now.month, now.day);
  final DateTime start;

  switch (period) {
    case InsightPeriod.today:
      start = midnightToday;
      break;
    case InsightPeriod.week:
      start = midnightToday.subtract(const Duration(days: 6));
      break;
    case InsightPeriod.month:
      start = midnightToday.subtract(const Duration(days: 29));
      break;
  }

  final end = midnightToday.add(const Duration(days: 1));

  // Fetch notification counts
  final notifs = await (db.select(db.notificationDailyCounts)
        ..where((t) =>
            t.day.isBiggerOrEqualValue(start) &
            t.day.isSmallerThanValue(end)))
      .get();

  final Map<String, ({String label, int count})> groupedNotifs = {};
  for (final n in notifs) {
    final current = groupedNotifs[n.appRef];
    if (current == null) {
      groupedNotifs[n.appRef] = (label: n.displayName, count: n.count);
    } else {
      groupedNotifs[n.appRef] = (label: n.displayName, count: current.count + n.count);
    }
  }

  final sortedNotifs = groupedNotifs.entries.map((e) => (
    appName: e.value.label,
    appRef: e.key,
    count: e.value.count,
  )).toList()..sort((a, b) => b.count.compareTo(a.count));

  // Fetch unlock counts from device day metrics
  final dayMetrics = await (db.select(db.deviceDayMetrics)
        ..where((t) =>
            t.day.isBiggerOrEqualValue(start) &
            t.day.isSmallerThanValue(end)))
      .get();

  final totalUnlocks = dayMetrics.fold<int>(0, (sum, m) => sum + (m.unlockCount ?? 0));

  return (
    isAvailable: true,
    notificationCounts: sortedNotifs,
    totalUnlocks: totalUnlocks,
  );
});

/// 30-day heatmap score provider. Returns list of up to 42 calendar grid cells.
final insightCalendarHeatmapProvider = FutureProvider<List<DailyMetric>>((ref) async {
  final db = ref.watch(databaseProvider);
  
  // Load last 30 days of metrics for calendar heatmap
  final now = DateTime.now();
  final end = DateTime(now.year, now.month, now.day);
  final start = end.subtract(const Duration(days: 29));

  return HistoryAggregator.getDailyMetrics(db, start, end);
});

// Keep legacy forecasts & funnels for compatibility
final insightsEnergyForecastProvider = FutureProvider<({
  bool hasEnoughData,
  int totalCount,
  List<({String start, String end, String label, double level})> peaks
})>((ref) async {
  final db = ref.watch(databaseProvider);
  final allCheckins = await db.select(db.energyCheckIns).get();
  final totalCount = allCheckins.length;

  if (totalCount < 7) {
    return (hasEnoughData: false, totalCount: totalCount, peaks: <({String end, String label, double level, String start})>[]);
  }

  final averages = await db.energyCheckInsDao.averageByBucket(14);
  final morning = averages[TimeOfDayColumn.morning] ?? 0.0;
  final afternoon = averages[TimeOfDayColumn.afternoon] ?? 0.0;
  final evening = averages[TimeOfDayColumn.evening] ?? 0.0;

  final List<({String start, String end, String label, double level})> peaksList = [];

  if (morning > 0.0) {
    peaksList.add((start: '9:00', end: '11:30', label: 'Morning Peak', level: morning));
  }
  if (afternoon > 0.0) {
    peaksList.add((start: '14:30', end: '16:00', label: 'Afternoon Focus', level: afternoon));
  }
  if (evening > 0.0) {
    peaksList.add((start: '19:00', end: '20:30', label: 'Evening Calm', level: evening));
  }

  return (
    hasEnoughData: peaksList.isNotEmpty && totalCount >= 7,
    totalCount: totalCount,
    peaks: peaksList,
  );
});

final insightsCompletionFunnelProvider = FutureProvider<({
  int created,
  int started,
  int completed
})>((ref) async {
  final db = ref.watch(databaseProvider);
  final allTasks = await db.tasksDao.getAllActive();
  final created = allTasks.length;

  if (created == 0) {
    return (created: 0, started: 0, completed: 0);
  }

  final completed = allTasks.where((t) => t.isCompleted).length;

  final sessions = await db.select(db.focusSessions).get();
  final startedTaskIds = sessions
      .map((s) => s.taskId)
      .whereType<String>()
      .toSet();

  final started = allTasks.where((t) {
    return t.isCompleted || startedTaskIds.contains(t.id);
  }).length;

  return (
    created: created,
    started: started,
    completed: completed,
  );
});

/// Aggregates focus protection unlock attempts statistics for the selected period
final insightUnlockAttemptsProvider = FutureProvider<({
  bool hasData,
  String mostBlockedTarget,
  int totalAttempts,
  int peakHour,
})>((ref) async {
  final db = ref.watch(databaseProvider);
  final period = ref.watch(insightPeriodProvider);

  final now = DateTime.now();
  final midnightToday = DateTime(now.year, now.month, now.day);
  final DateTime start;

  switch (period) {
    case InsightPeriod.today:
      start = midnightToday;
      break;
    case InsightPeriod.week:
      start = midnightToday.subtract(const Duration(days: 6));
      break;
    case InsightPeriod.month:
      start = midnightToday.subtract(const Duration(days: 29));
      break;
  }
  final end = midnightToday.add(const Duration(days: 1));

  final attempts = await (db.select(db.unlockAttempts)
        ..where((t) =>
            t.timestamp.isBiggerOrEqualValue(start) &
            t.timestamp.isSmallerThanValue(end)))
      .get();

  if (attempts.isEmpty) {
    return (
      hasData: false,
      mostBlockedTarget: '',
      totalAttempts: 0,
      peakHour: -1,
    );
  }

  // Find the target with most blocked attempts
  final Map<String, int> targetCounts = {};
  for (final a in attempts) {
    targetCounts[a.target] = (targetCounts[a.target] ?? 0) + 1;
  }
  
  final sortedTargets = targetCounts.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  final mostBlocked = sortedTargets.first.key;

  // Find the peak hour of day
  final Map<int, int> hourCounts = {};
  for (final a in attempts) {
    final hour = a.timestamp.hour;
    hourCounts[hour] = (hourCounts[hour] ?? 0) + 1;
  }
  
  final sortedHours = hourCounts.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  final peakHour = sortedHours.first.key;

  return (
    hasData: true,
    mostBlockedTarget: mostBlocked,
    totalAttempts: attempts.length,
    peakHour: peakHour,
  );
});
