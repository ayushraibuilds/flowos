import 'package:drift/drift.dart';
import '../../../data/local/database/app_database.dart';
import '../../xp/models/daily_score_calculator.dart';
import '../../attention/repository/attention_data_repository.dart';

class HistoryAggregator {
  static Future<List<DailyMetric>> getDailyMetrics(AppDatabase db, DateTime start, DateTime end) async {
    // 1. Fetch completed tasks in range
    final completedTasks = await (db.select(db.tasks)
          ..where((t) =>
              t.isCompleted.equals(true) &
              t.completedAt.isBiggerOrEqualValue(start) &
              t.completedAt.isSmallerThanValue(end)))
        .get();

    // 2. Fetch focus sessions in range
    final sessions = await db.focusSessionsDao.getByDateRange(start, end);

    // 3. Fetch scroll logs in range
    final scrollLogs = await (db.select(db.scrollLogs)
          ..where((l) =>
              l.timestamp.isBiggerOrEqualValue(start) &
              l.timestamp.isSmallerThanValue(end)))
        .get();

    // 4. Fetch energy check-ins in range
    final energyCheckins = await db.energyCheckInsDao.getCheckInsInRange(start, end);

    // 5. Fetch daily plans in range
    final dailyPlans = await (db.select(db.dailyPlans)
          ..where((p) =>
              p.date.isBiggerOrEqualValue(start) &
              p.date.isSmallerThanValue(end)))
        .get();

    // 6. Fetch device usage records in range
    final deviceUsageRecords = await (db.select(db.deviceUsageRecords)
          ..where((r) =>
              r.date.isBiggerOrEqualValue(start) &
              r.date.isSmallerThanValue(end) &
              r.source.equals('android_usage')))
        .get();

    // 7. Fetch device day metrics in range
    final dayMetrics = await (db.select(db.deviceDayMetrics)
          ..where((t) =>
              t.day.isBiggerOrEqualValue(start) &
              t.day.isSmallerThanValue(end)))
        .get();

    final List<DailyMetric> metrics = [];

    // Loop day-by-day from start to end (inclusive of end day)
    var day = DateTime(start.year, start.month, start.day);
    final lastDay = DateTime(end.year, end.month, end.day);

    while (day.isBefore(lastDay) || day.isAtSameMomentAs(lastDay)) {
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
      final scrollBudget = plan?.scrollBudgetMinutes ?? 30;

      // Filter sessions
      final daySessions = sessions.where((s) =>
          s.startedAt.isAfter(day.subtract(const Duration(seconds: 1))) &&
          s.startedAt.isBefore(dayEnd));
      final dayFocusMinutes = daySessions.fold<int>(0, (sum, s) => sum + s.durationMinutes);

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

      final hasNative = metric != null && metric.coverageState != 'notConnected';
      final effectiveDistractionMinutes = hasNative ? dayDeviceUsageMinutes : dayScrollMinutes;
      final coverage = hasNative ? DataCoverage.complete : DataCoverage.manualOnly;

      final score = DailyScoreCalculator.calculate(
        focusMinutes: dayFocusMinutes,
        mitsCompleted: dayMits,
        scrollMinutes: effectiveDistractionMinutes,
        scrollBudget: scrollBudget,
        intentionCompleted: hasIntention,
        shutdownCompleted: hasShutdown,
        energyCheckIns: dayEnergyCount,
        attentionCoverage: coverage,
      );

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
        focusMinutes: dayFocusMinutes,
        scrollMinutes: dayScrollMinutes,
        deviceUsageMinutes: dayDeviceUsageMinutes,
        energyCheckInCount: dayEnergyCount,
        hasActivity: hasActivity,
      ));

      day = day.add(const Duration(days: 1));
    }

    return metrics;
  }
}

class DailyMetric {
  final DateTime date;
  final int score;
  final int focusMinutes;
  final int scrollMinutes;
  final int deviceUsageMinutes;
  final int energyCheckInCount;
  final bool hasActivity;

  DailyMetric({
    required this.date,
    required this.score,
    required this.focusMinutes,
    required this.scrollMinutes,
    required this.deviceUsageMinutes,
    required this.energyCheckInCount,
    required this.hasActivity,
  });
}
