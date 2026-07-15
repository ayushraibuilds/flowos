import 'package:drift/drift.dart';
import '../../../data/local/database/app_database.dart';
import '../../xp/models/daily_score_calculator.dart';
import '../../attention/repository/attention_data_repository.dart';
import '../../../core/constants/xp_constants.dart';

class DailyMetric {
  final DateTime date;
  final int score;
  final String? grade;
  final int focusMinutes;
  final int scrollMinutes;
  final int deviceUsageMinutes;
  final int energyCheckInCount;
  final bool hasActivity;

  final DataCoverage coverage;
  final bool isIncomplete;
  final int scoringVersion;
  final int? unlockCount;
  final int? notificationCount;
  final bool intentionCompleted;
  final bool shutdownCompleted;
  
  final double focusPoints;
  final double intentPoints;
  final double? attentionPoints;
  final double carePoints;

  DailyMetric({
    required this.date,
    required this.score,
    required this.grade,
    required this.focusMinutes,
    required this.scrollMinutes,
    required this.deviceUsageMinutes,
    required this.energyCheckInCount,
    required this.hasActivity,
    required this.coverage,
    required this.isIncomplete,
    required this.scoringVersion,
    required this.unlockCount,
    required this.notificationCount,
    required this.intentionCompleted,
    required this.shutdownCompleted,
    required this.focusPoints,
    required this.intentPoints,
    required this.attentionPoints,
    required this.carePoints,
  });
}

class WeeklyAggregate {
  final DateTime weekStart;
  final int averageScore; // weighted average of complete V2 days only
  final int scoredDaysCount; // days with complete V2 coverage
  final int totalDays; // 7
  final List<DailyMetric> days;
  final String? topReclaimableApp;
  final int reclaimableMinutes;
  final bool hasReclaimableData; // false when budget or distracting apps are unconfigured

  WeeklyAggregate({
    required this.weekStart,
    required this.averageScore,
    required this.scoredDaysCount,
    required this.totalDays,
    required this.days,
    this.topReclaimableApp,
    required this.reclaimableMinutes,
    required this.hasReclaimableData,
  });
}

class MonthlyAggregate {
  final DateTime monthStart;
  final int averageScore; // weighted average of complete V2 days only
  final int scoredDaysCount; // days with complete V2 coverage
  final int totalDays; // 28-31
  final List<DailyMetric> days;
  final int totalFocusMinutes;
  final int totalReclaimableMinutes;
  final bool hasReclaimableData;

  MonthlyAggregate({
    required this.monthStart,
    required this.averageScore,
    required this.scoredDaysCount,
    required this.totalDays,
    required this.days,
    required this.totalFocusMinutes,
    required this.totalReclaimableMinutes,
    required this.hasReclaimableData,
  });
}

class HistoryAggregator {
  static Future<List<DailyMetric>> getDailyMetrics(AppDatabase db, DateTime start, DateTime end) async {
    final startOfDay = DateTime(start.year, start.month, start.day);
    final endOfDay = DateTime(end.year, end.month, end.day);
    final nextDayOfEnd = endOfDay.add(const Duration(days: 1));

    // 1. Fetch completed tasks in range
    final completedTasks = await (db.select(db.tasks)
          ..where((t) =>
              t.isCompleted.equals(true) &
              t.completedAt.isBiggerOrEqualValue(startOfDay) &
              t.completedAt.isSmallerThanValue(nextDayOfEnd)))
        .get();

    // 2. Fetch focus sessions in range
    final sessions = await db.focusSessionsDao.getByDateRange(startOfDay, nextDayOfEnd);

    // 3. Fetch scroll logs in range
    final scrollLogs = await (db.select(db.scrollLogs)
          ..where((l) =>
              l.timestamp.isBiggerOrEqualValue(startOfDay) &
              l.timestamp.isSmallerThanValue(nextDayOfEnd)))
        .get();

    // 4. Fetch energy check-ins in range
    final energyCheckins = await db.energyCheckInsDao.getCheckInsInRange(startOfDay, nextDayOfEnd);

    // 5. Fetch daily plans in range
    final dailyPlans = await (db.select(db.dailyPlans)
          ..where((p) =>
              p.date.isBiggerOrEqualValue(startOfDay) &
              p.date.isSmallerThanValue(nextDayOfEnd)))
        .get();

    // 6. Fetch device usage records in range (native only)
    final deviceUsageRecords = await (db.select(db.deviceUsageRecords)
          ..where((r) =>
              r.date.isBiggerOrEqualValue(startOfDay) &
              r.date.isSmallerThanValue(nextDayOfEnd) &
              r.source.equals('android_usage')))
        .get();

    // 7. Fetch device day metrics in range
    final dayMetrics = await (db.select(db.deviceDayMetrics)
          ..where((t) =>
              t.day.isBiggerOrEqualValue(startOfDay) &
              t.day.isSmallerThanValue(nextDayOfEnd)))
        .get();

    // 8. Fetch notification daily counts in range
    final notificationCounts = await (db.select(db.notificationDailyCounts)
          ..where((t) =>
              t.day.isBiggerOrEqualValue(startOfDay) &
              t.day.isSmallerThanValue(nextDayOfEnd)))
        .get();

    // 9. Fetch persisted daily scores
    final persistedScores = await db.dailyScoresDao.getScoresInRange(startOfDay, endOfDay);

    final List<DailyMetric> metrics = [];
    var day = startOfDay;

    while (day.isBefore(nextDayOfEnd)) {
      final dayEnd = day.add(const Duration(days: 1));

      // Filter plans
      DailyPlan? plan;
      for (final p in dailyPlans) {
        if (p.date.isAfter(day.subtract(const Duration(seconds: 1))) && p.date.isBefore(dayEnd)) {
          plan = p;
          break;
        }
      }

      final hasIntention = plan?.intentionCompleted ?? false;
      final hasShutdown = plan?.shutdownCompleted ?? false;
      final budget = plan?.scrollBudgetMinutes ?? 30;

      // Filter sessions
      final daySessions = sessions.where((s) =>
          s.startedAt.isAfter(day.subtract(const Duration(seconds: 1))) &&
          s.startedAt.isBefore(dayEnd));
      final dayFocusMinutes = daySessions
          .where((s) => s.completedAt != null)
          .fold<int>(0, (sum, s) => sum + s.actualMinutes);

      // Filter completed tasks
      final dayCompletedTasks = completedTasks.where((t) =>
          t.completedAt != null &&
          t.completedAt!.isAfter(day.subtract(const Duration(seconds: 1))) &&
          t.completedAt!.isBefore(dayEnd));
      final dayMits = dayCompletedTasks.where((t) => t.isMIT).length;

      // Filter manual scroll logs (excluding auto logs)
      final dayScrollLogs = scrollLogs.where((l) =>
          l.timestamp.isAfter(day.subtract(const Duration(seconds: 1))) &&
          l.timestamp.isBefore(dayEnd) &&
          !l.appName.contains('[Auto]'));
      final dayScrollMinutes = dayScrollLogs.fold<int>(0, (sum, l) => sum + l.durationMinutes);
      final dayRecoveryCount = dayScrollLogs.where((l) => l.recoveryActionTaken).length;

      // Filter device usage records
      final dayDeviceUsageRecords = deviceUsageRecords.where((r) =>
          r.date.isAfter(day.subtract(const Duration(seconds: 1))) &&
          r.date.isBefore(dayEnd) &&
          r.isDistracting == true);
      final dayDeviceUsageMinutes = dayDeviceUsageRecords.fold<int>(0, (sum, r) => sum + r.minutes);

      // Filter energy check-ins
      final dayEnergyCheckins = energyCheckins.where((e) =>
          e.date.isAfter(day.subtract(const Duration(seconds: 1))) &&
          e.date.isBefore(dayEnd));
      final dayEnergyCount = dayEnergyCheckins.length;

      // Find metric for coverage determination
      DeviceDayMetric? metric;
      for (final m in dayMetrics) {
        if (m.day.year == day.year && m.day.month == day.month && m.day.day == day.day) {
          metric = m;
          break;
        }
      }

      final DataCoverage coverage;
      if (metric == null) {
        coverage = DataCoverage.manualOnly;
      } else {
        coverage = DataCoverage.values.firstWhere(
          (c) => c.name == metric!.coverageState,
          orElse: () => DataCoverage.manualOnly,
        );
      }

      final hasNative = coverage == DataCoverage.complete;
      final unlockCount = metric?.unlockCount;

      // Find total notification counts for this day
      final dayNotifs = notificationCounts
          .where((c) => c.day.year == day.year && c.day.month == day.month && c.day.day == day.day)
          .fold<int>(0, (sum, c) => sum + c.count);

      // Find persisted score record if available
      DailyScore? persisted;
      for (final s in persistedScores) {
        if (s.day.year == day.year && s.day.month == day.month && s.day.day == day.day) {
          persisted = s;
          break;
        }
      }

      final int score;
      final String? grade;
      final bool isIncomplete;
      final int scoringVersion;
      final double focusPoints;
      final double intentPoints;
      final double? attentionPoints;
      final double carePoints;

      if (persisted != null) {
        score = persisted.score;
        grade = persisted.grade;
        isIncomplete = persisted.isIncomplete;
        scoringVersion = persisted.scoringVersion;
        focusPoints = persisted.focusPoints;
        intentPoints = persisted.intentPoints;
        attentionPoints = persisted.attentionPoints;
        carePoints = persisted.carePoints;
      } else {
        // Fallback live calculate
        final result = DailyScoreCalculator.calculate(
          focusMinutes: dayFocusMinutes,
          mitsCompleted: dayMits,
          scrollMinutes: hasNative ? dayDeviceUsageMinutes : dayScrollMinutes,
          scrollBudget: budget,
          intentionCompleted: hasIntention,
          shutdownCompleted: hasShutdown,
          energyCheckIns: dayEnergyCount,
          recoveryActions: dayRecoveryCount,
          attentionCoverage: coverage,
        );
        score = result.score;
        grade = result.grade;
        isIncomplete = result.isIncomplete;
        scoringVersion = result.scoringVersion;
        focusPoints = result.focusPoints;
        intentPoints = result.intentPoints;
        attentionPoints = result.attentionPoints;
        carePoints = result.carePoints;
      }

      // Check if there was any actual activity on this day
      final hasActivity = dayFocusMinutes > 0 ||
          dayMits > 0 ||
          dayScrollMinutes > 0 ||
          dayDeviceUsageMinutes > 0 ||
          dayEnergyCount > 0 ||
          hasIntention ||
          hasShutdown;

      metrics.add(DailyMetric(
        date: day,
        score: score,
        grade: grade,
        focusMinutes: dayFocusMinutes,
        scrollMinutes: dayScrollMinutes,
        deviceUsageMinutes: dayDeviceUsageMinutes,
        energyCheckInCount: dayEnergyCount,
        hasActivity: hasActivity,
        coverage: coverage,
        isIncomplete: isIncomplete,
        scoringVersion: scoringVersion,
        unlockCount: unlockCount,
        notificationCount: dayNotifs > 0 ? dayNotifs : null,
        intentionCompleted: hasIntention,
        shutdownCompleted: hasShutdown,
        focusPoints: focusPoints,
        intentPoints: intentPoints,
        attentionPoints: attentionPoints,
        carePoints: carePoints,
      ));

      day = day.add(const Duration(days: 1));
    }

    return metrics;
  }

  static Future<WeeklyAggregate> getWeeklyAggregate(AppDatabase db, DateTime weekStart) async {
    final start = DateTime(weekStart.year, weekStart.month, weekStart.day);
    final end = start.add(const Duration(days: 6));
    final metrics = await getDailyMetrics(db, start, end);

    // Filter complete V2 scores only for averaging
    final completeV2Days = metrics.where((m) => !m.isIncomplete && m.scoringVersion == 2).toList();
    
    int averageScore = 0;
    if (completeV2Days.isNotEmpty) {
      final sum = completeV2Days.fold<int>(0, (total, m) => total + m.score);
      averageScore = (sum / completeV2Days.length).round();
    }

    // Determine reclaimable time
    int totalReclaimableMinutes = 0;
    bool hasReclaimableData = false;

    // Check if user has distracting apps configured
    final protectedApps = await db.protectedAppsDao.getAll();
    final distractingApps = protectedApps.where((a) => a.protectsFocus && !a.isEssential).toList();

    if (distractingApps.isNotEmpty) {
      for (final metric in metrics) {
        // Query daily plan budget for historic day. If not set, do not calculate/invent budget
        final plan = await db.dailyPlansDao.getByDateRange(
          DateTime(metric.date.year, metric.date.month, metric.date.day),
          DateTime(metric.date.year, metric.date.month, metric.date.day).add(const Duration(days: 1)),
        );
        
        int? budget;
        if (plan != null) {
          budget = plan.scrollBudgetMinutes;
        } else {
          final today = DateTime.now();
          final isToday = metric.date.year == today.year && metric.date.month == today.month && metric.date.day == today.day;
          if (isToday) {
            // fallback only for today
            // budget can be fetched from setting, but aggregator doesn't have settings ref easily
            // we will fallback to a default budget of 30, but marked as configured
            budget = 30;
          }
        }

        if (budget != null && budget > 0 && metric.coverage == DataCoverage.complete) {
          hasReclaimableData = true;
          final distractingUsage = metric.deviceUsageMinutes;
          final reclaimable = distractingUsage - budget;
          if (reclaimable > 0) {
            totalReclaimableMinutes += reclaimable;
          }
        }
      }
    }

    // Find top reclaimable app across the week
    String? topReclaimableApp;
    if (hasReclaimableData) {
      final records = await (db.select(db.deviceUsageRecords)
            ..where((r) =>
                r.date.isBiggerOrEqualValue(start) &
                r.date.isSmallerThanValue(end.add(const Duration(days: 1))) &
                r.source.equals('android_usage') &
                r.isDistracting.equals(true)))
          .get();

      final Map<String, int> appTotals = {};
      for (final r in records) {
        final label = r.label ?? r.packageName;
        appTotals[label] = (appTotals[label] ?? 0) + r.minutes;
      }

      if (appTotals.isNotEmpty) {
        final sorted = appTotals.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
        topReclaimableApp = sorted.first.key;
      }
    }

    return WeeklyAggregate(
      weekStart: start,
      averageScore: averageScore,
      scoredDaysCount: completeV2Days.length,
      totalDays: 7,
      days: metrics,
      topReclaimableApp: topReclaimableApp,
      reclaimableMinutes: totalReclaimableMinutes,
      hasReclaimableData: hasReclaimableData,
    );
  }

  static Future<MonthlyAggregate> getMonthlyAggregate(AppDatabase db, DateTime monthStart) async {
    final start = DateTime(monthStart.year, monthStart.month, monthStart.day);
    // Find last day of month
    final nextMonth = DateTime(start.year, start.month + 1, 1);
    final end = nextMonth.subtract(const Duration(days: 1));
    final metrics = await getDailyMetrics(db, start, end);

    final completeV2Days = metrics.where((m) => !m.isIncomplete && m.scoringVersion == 2).toList();
    
    int averageScore = 0;
    if (completeV2Days.isNotEmpty) {
      final sum = completeV2Days.fold<int>(0, (total, m) => total + m.score);
      averageScore = (sum / completeV2Days.length).round();
    }

    final totalFocusMinutes = metrics.fold<int>(0, (sum, m) => sum + m.focusMinutes);

    // Reclaimable time
    int totalReclaimableMinutes = 0;
    bool hasReclaimableData = false;

    final protectedApps = await db.protectedAppsDao.getAll();
    final distractingApps = protectedApps.where((a) => a.protectsFocus && !a.isEssential).toList();

    if (distractingApps.isNotEmpty) {
      for (final metric in metrics) {
        final plan = await db.dailyPlansDao.getByDateRange(
          DateTime(metric.date.year, metric.date.month, metric.date.day),
          DateTime(metric.date.year, metric.date.month, metric.date.day).add(const Duration(days: 1)),
        );

        int? budget;
        if (plan != null) {
          budget = plan.scrollBudgetMinutes;
        } else {
          final today = DateTime.now();
          final isToday = metric.date.year == today.year && metric.date.month == today.month && metric.date.day == today.day;
          if (isToday) {
            budget = 30;
          }
        }

        if (budget != null && budget > 0 && metric.coverage == DataCoverage.complete) {
          hasReclaimableData = true;
          final distractingUsage = metric.deviceUsageMinutes;
          final reclaimable = distractingUsage - budget;
          if (reclaimable > 0) {
            totalReclaimableMinutes += reclaimable;
          }
        }
      }
    }

    return MonthlyAggregate(
      monthStart: start,
      averageScore: averageScore,
      scoredDaysCount: completeV2Days.length,
      totalDays: end.day,
      days: metrics,
      totalFocusMinutes: totalFocusMinutes,
      totalReclaimableMinutes: totalReclaimableMinutes,
      hasReclaimableData: hasReclaimableData,
    );
  }
}
