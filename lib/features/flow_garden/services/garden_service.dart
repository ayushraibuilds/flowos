import 'dart:async';
import 'package:drift/drift.dart';

import '../../../data/local/database/app_database.dart';
import '../models/garden_day.dart';

/// Builds garden scenes from the activity the person has already chosen to do.
/// There are no streak penalties, decay mechanics, or garden-destruction paths.
class GardenService {
  final AppDatabase _db;

  GardenService(this._db);

  Future<GardenDay> buildDay(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    final sessions = await _db.focusSessionsDao.getByDateRange(start, end);
    final focusSessions = sessions
        .where(
          (session) =>
              session.completedAt != null &&
              session.qualityScore != 'F' &&
              session.actualMinutes > 0,
        )
        .toList();
    final logs =
        await (_db.select(_db.scrollLogs)..where(
              (log) =>
                  log.timestamp.isBiggerOrEqualValue(start) &
                  log.timestamp.isSmallerThanValue(end),
            ))
            .get();
    final checkIns = await _db.energyCheckInsDao.getForDate(start);
    final plan = await _db.dailyPlansDao.getByDateRange(start, end);

    // Fetch device usage records in range
    final deviceUsageRecords =
        await (_db.select(_db.deviceUsageRecords)..where(
              (r) =>
                  r.date.isBiggerOrEqualValue(start) &
                  r.date.isSmallerThanValue(end) &
                  r.source.equals('android_usage'),
            ))
            .get();

    final metrics =
        await (_db.select(_db.deviceDayMetrics)..where(
              (t) =>
                  t.day.isBiggerOrEqualValue(start) &
                  t.day.isSmallerThanValue(end),
            ))
            .get();

    final hasNative =
        metrics.isNotEmpty && metrics.first.coverageState != 'notConnected';

    final nativeDistractingMinutes = deviceUsageRecords
        .where((r) => r.isDistracting == true)
        .fold<int>(0, (sum, r) => sum + r.minutes);

    final focusMinutes = focusSessions.fold<int>(
      0,
      (total, session) => total + session.actualMinutes,
    );
    final manualScrollMinutes = logs
        .where((log) => !log.appName.contains('[Auto]'))
        .fold<int>(0, (total, log) => total + log.durationMinutes);

    final scrollMinutes = hasNative
        ? nativeDistractingMinutes
        : manualScrollMinutes;

    final recoveryCount = logs
        .where(
          (log) => !log.appName.contains('[Auto]') && log.recoveryActionTaken,
        )
        .length;
    final budget = plan?.scrollBudgetMinutes ?? 30;
    final objects = <GardenObject>[];

    // Batch task lookups: collect all non-null taskIds and query in 1 query
    final taskIds = focusSessions
        .map((s) => s.taskId)
        .whereType<String>()
        .toSet();
    final Map<String, Task> taskMap = {};
    if (taskIds.isNotEmpty) {
      final tasks = await (_db.select(
        _db.tasks,
      )..where((t) => t.id.isIn(taskIds))).get();
      for (final t in tasks) {
        taskMap[t.id] = t;
      }
    }

    for (final session in focusSessions) {
      final task = session.taskId == null ? null : taskMap[session.taskId];
      if (session.gardenSeedKind != null) {
        objects.add(
          GardenObject.fromPersistedSeed(session, taskTitle: task?.title),
        );
      } else {
        objects.add(
          GardenObject.fromFocusSession(
            sessionId: session.id,
            sessionType: session.sessionType,
            actualMinutes: session.actualMinutes,
            taskTitle: task?.title,
          ),
        );
      }
    }

    if (recoveryCount > 0) {
      objects.add(
        const GardenObject(
          id: 'recovery-water',
          kind: GardenObjectKind.water,
          emoji: '💧',
          seedEmoji: '💧',
          title: 'Recovery water',
          detail: 'You chose a reset after distraction.',
          x: 0.16,
          y: 0.67,
        ),
      );
    }

    if (checkIns.isNotEmpty) {
      objects.add(
        const GardenObject(
          id: 'energy-light',
          kind: GardenObjectKind.light,
          emoji: '☀️',
          seedEmoji: '☀️',
          title: 'Energy light',
          detail: 'Checking in helps you tend your capacity.',
          x: 0.81,
          y: 0.14,
        ),
      );
    }

    final isPastDay = start.isBefore(_startOfToday());
    final isCompleted = plan?.shutdownCompleted ?? false;
    final isProtected =
        (isCompleted || isPastDay) &&
        focusSessions.isNotEmpty &&
        scrollMinutes <= budget;
    if (isProtected) {
      objects.add(
        const GardenObject(
          id: 'protected-wildlife',
          kind: GardenObjectKind.wildlife,
          emoji: '🦋',
          seedEmoji: '🦋',
          title: 'Wildlife visitor',
          detail: 'A low-scroll day made room for attention to return.',
          x: 0.72,
          y: 0.56,
        ),
      );
    } else {
      final today = _startOfToday();
      final isToday =
          start.year == today.year &&
          start.month == today.month &&
          start.day == today.day;
      if (isToday) {
        // Always add today's wildlife companion so they can tap for recovery actions
        objects.add(
          const GardenObject(
            id: 'today-companion',
            kind: GardenObjectKind.wildlife,
            emoji: '🦋',
            seedEmoji: '🦋',
            title: 'Wildlife Companion',
            detail: 'Tap your companion to start a 2-minute recovery session.',
            x: 0.15,
            y: 0.48,
          ),
        );
      }
    }

    return GardenDay(
      date: start,
      objects: objects,
      focusMinutes: focusMinutes,
      recoveryCount: recoveryCount,
      scrollMinutes: scrollMinutes,
      scrollBudgetMinutes: budget,
      isCompleted: isCompleted,
      isProtected: isProtected,
    );
  }

  Future<List<GardenDay>> buildCurrentWeek() async {
    final today = _startOfToday();
    final monday = today.subtract(
      Duration(days: today.weekday - DateTime.monday),
    );
    return Future.wait(
      List.generate(7, (index) => buildDay(monday.add(Duration(days: index)))),
    );
  }

  Stream<GardenDay>? _sharedTodayStream;
  Stream<List<GardenDay>>? _sharedWeekStream;

  Stream<GardenDay> watchToday() {
    return _sharedTodayStream ??=
        _createCoalescedStream<GardenDay>(
          () => buildDay(DateTime.now()),
        ).asBroadcastStream(
          onCancel: (sub) {
            _sharedTodayStream = null;
          },
        );
  }

  Stream<List<GardenDay>> watchCurrentWeek() {
    return _sharedWeekStream ??=
        _createCoalescedStream<List<GardenDay>>(
          () => buildCurrentWeek(),
        ).asBroadcastStream(
          onCancel: (sub) {
            _sharedWeekStream = null;
          },
        );
  }

  Stream<T> _createCoalescedStream<T>(Future<T> Function() builder) {
    late StreamController<T> controller;
    StreamSubscription? tableSub;
    Timer? debounceTimer;
    int buildGen = 0;

    void triggerBuild() {
      debounceTimer?.cancel();
      debounceTimer = Timer(const Duration(milliseconds: 50), () async {
        final currentGen = ++buildGen;
        try {
          final result = await builder();
          if (currentGen == buildGen && !controller.isClosed) {
            controller.add(result);
          }
        } catch (_) {}
      });
    }

    controller = StreamController<T>(
      onListen: () {
        tableSub = _db
            .tableUpdates(
              TableUpdateQuery.onAllTables({
                _db.focusSessions,
                _db.scrollLogs,
                _db.energyCheckIns,
                _db.dailyPlans,
                _db.deviceUsageRecords,
                _db.deviceDayMetrics,
              }),
            )
            .listen((_) => triggerBuild());
        triggerBuild(); // Initial build
      },
      onCancel: () {
        debounceTimer?.cancel();
        tableSub?.cancel();
      },
    );

    return controller.stream;
  }

  DateTime _startOfToday() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }
}
