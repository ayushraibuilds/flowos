import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import '../../../data/local/database/app_database.dart';
import '../../../data/local/tables/energy_checkins_table.dart';
import '../../settings/providers/settings_providers.dart';
import '../services/history_aggregator.dart';
import '../../attention/repository/attention_data_repository.dart';

// Helper to convert task quality score letter to a numerical value (0-100)
int _qualityScoreValue(String score) {
  return switch (score.toUpperCase()) {
    'A' => 100,
    'B' => 75,
    'C' => 50,
    'D' => 25,
    _ => 0,
  };
}

/// 1. Energy Forecast Provider
/// Returns a record: (hasEnoughData, totalCount, peaks)
final insightsEnergyForecastProvider = FutureProvider<({
  bool hasEnoughData,
  int totalCount,
  List<({String start, String end, String label, double level})> peaks
})>((ref) async {
  final db = ref.watch(databaseProvider);

  // Check total check-ins count threshold (>= 7 check-ins total)
  final allCheckins = await db.select(db.energyCheckIns).get();
  final totalCount = allCheckins.length;

  if (totalCount < 7) {
    return (hasEnoughData: false, totalCount: totalCount, peaks: <({String start, String end, String label, double level})>[]);
  }

  // Calculate averages per bucket over last 14 days
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

/// 2. Weekday Scores Provider
/// Returns: (hasEnoughData, activeDaysCount, scores) - scores is list of 7 values (Mon-Sun)
final insightsWeekdayScoresProvider = FutureProvider<({
  bool hasEnoughData,
  int activeDaysCount,
  List<int> scores
})>((ref) async {
  final db = ref.watch(databaseProvider);

  // Load last 30 days
  final end = DateTime.now();
  final start = end.subtract(const Duration(days: 29));

  final metrics = await HistoryAggregator.getDailyMetrics(db, start, end);

  // Count active days
  final activeDays = metrics.where((m) => m.hasActivity).length;
  if (activeDays < 7) {
    return (hasEnoughData: false, activeDaysCount: activeDays, scores: List.filled(7, 0));
  }

  // Group by weekday (1 = Monday, 7 = Sunday)
  final Map<int, List<int>> weekdayScores = {
    1: [], 2: [], 3: [], 4: [], 5: [], 6: [], 7: []
  };

  for (final m in metrics) {
    if (m.hasActivity) {
      weekdayScores[m.date.weekday]?.add(m.score);
    }
  }

  final List<int> scores = List.generate(7, (i) {
    final list = weekdayScores[i + 1] ?? [];
    if (list.isEmpty) return 0;
    final avg = list.reduce((a, b) => a + b) / list.length;
    return avg.round();
  });

  return (
    hasEnoughData: true,
    activeDaysCount: activeDays,
    scores: scores,
  );
});

/// 3. Hourly Heatmap Provider
/// Returns: (hasEnoughData, completedSessionsCount, hourlyScores) - hourlyScores is a list of 24 values
final insightsHourlyHeatmapProvider = FutureProvider<({
  bool hasEnoughData,
  int completedSessionsCount,
  List<int> hourlyScores
})>((ref) async {
  final db = ref.watch(databaseProvider);

  // Load all completed focus sessions
  final sessions = await (db.select(db.focusSessions)
        ..where((s) => s.completedAt.isNotNull()))
      .get();

  final completedSessionsCount = sessions.length;
  if (completedSessionsCount < 10) {
    return (hasEnoughData: false, completedSessionsCount: completedSessionsCount, hourlyScores: List.filled(24, 0));
  }

  final Map<int, List<int>> hourlyValues = {};
  for (int h = 0; h < 24; h++) {
    hourlyValues[h] = [];
  }

  for (final s in sessions) {
    final hour = s.startedAt.hour;
    final val = _qualityScoreValue(s.qualityScore);
    if (val > 0) {
      hourlyValues[hour]?.add(val);
    }
  }

  final List<int> hourlyScores = List.generate(24, (hour) {
    final list = hourlyValues[hour] ?? [];
    if (list.isEmpty) return 0;
    final avg = list.reduce((a, b) => a + b) / list.length;
    return avg.round();
  });

  return (
    hasEnoughData: true,
    completedSessionsCount: completedSessionsCount,
    hourlyScores: hourlyScores,
  );
});

/// 4. Scroll vs Focus Trend Provider (7 Days)
/// Returns: (hasEnoughData, focusData, scrollData)
final insightsScrollVsFocusProvider = FutureProvider<({
  bool hasEnoughData,
  List<int> focusData,
  List<int> scrollData
})>((ref) async {
  final db = ref.watch(databaseProvider);

  final end = DateTime.now();
  final start = end.subtract(const Duration(days: 6));

  final metrics = await HistoryAggregator.getDailyMetrics(db, start, end);

  final List<int> focusData = [];
  final List<int> scrollData = [];

  bool hasAnyData = false;

  for (final m in metrics) {
    focusData.add(m.focusMinutes);
    final effectiveScroll = m.deviceUsageMinutes > 0 ? m.deviceUsageMinutes : m.scrollMinutes;
    scrollData.add(effectiveScroll);
    if (m.focusMinutes > 0 || effectiveScroll > 0) {
      hasAnyData = true;
    }
  }

  return (
    hasEnoughData: hasAnyData,
    focusData: focusData,
    scrollData: scrollData,
  );
});

/// 5. Task Completion Funnel Provider
/// Returns: (created, started, completed)
final insightsCompletionFunnelProvider = FutureProvider<({
  int created,
  int started,
  int completed
})>((ref) async {
  final db = ref.watch(databaseProvider);

  // Get active tasks (non-deleted)
  final allTasks = await db.tasksDao.getAllActive();
  final created = allTasks.length;

  if (created == 0) {
    return (created: 0, started: 0, completed: 0);
  }

  final completed = allTasks.where((t) => t.isCompleted).length;

  // Started tasks = completed or has associated focus session
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

/// 6. App Breakdown Provider (7 Days distraction list)
final insightsAppBreakdownProvider = FutureProvider<List<({String label, String packageName, int minutes})>>((ref) async {
  final db = ref.watch(databaseProvider);
  final end = DateTime.now();
  final start = end.subtract(const Duration(days: 7));
  final records = await (db.select(db.deviceUsageRecords)
        ..where((r) =>
            r.date.isBiggerOrEqualValue(start) &
            r.date.isSmallerThanValue(end) &
            r.source.equals('android_usage')))
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
  
  final list = grouped.entries.map((e) => (
    packageName: e.key,
    label: e.value.label,
    minutes: e.value.minutes,
  )).toList();
  
  list.sort((a, b) => b.minutes.compareTo(a.minutes));
  return list;
});

/// 7. Overrides and Recovery Actions Provider
final insightsOverridesAndRecoveryProvider = FutureProvider<({
  int overridesCount,
  int recoveryCount,
  List<({String type, String app, int minutes})> recentRecoveries
})>((ref) async {
  final db = ref.watch(databaseProvider);
  
  final sessions = await db.select(db.focusSessions).get();
  int overrides = 0;
  for (final s in sessions) {
    overrides += s.appBackgroundCount + s.pauseCount;
  }
  
  final logs = await (db.select(db.scrollLogs)..where((l) => l.recoveryActionTaken)).get();
  
  final recent = logs.map((l) => (
    type: l.recoveryActionType ?? 'Breathing',
    app: l.appName,
    minutes: l.durationMinutes,
  )).toList();
  
  return (
    overridesCount: overrides,
    recoveryCount: logs.length,
    recentRecoveries: recent,
  );
});

/// 8. Attention Budget Today Provider
final insightsAttentionBudgetProvider = FutureProvider<({
  int scrollBudget,
  int scrollMinutes,
  double progressFraction,
})>((ref) async {
  final db = ref.watch(databaseProvider);
  final settings = ref.watch(settingsProvider);
  
  final plan = await db.dailyPlansDao.getToday();
  final budget = plan?.scrollBudgetMinutes ?? settings.scrollBudget;
  
  final attentionDay = await ref.read(attentionDataRepositoryProvider).getAttentionDay(DateTime.now());
  final totalScroll = attentionDay.effectiveDistractingMinutes;
  final fraction = budget > 0 ? totalScroll / budget : 0.0;
  
  return (
    scrollBudget: budget,
    scrollMinutes: totalScroll,
    progressFraction: fraction.clamp(0.0, 1.0),
  );
});
