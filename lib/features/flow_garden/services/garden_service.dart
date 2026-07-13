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
    final focusMinutes = focusSessions.fold<int>(
      0,
      (total, session) => total + session.actualMinutes,
    );
    final scrollMinutes = logs.fold<int>(
      0,
      (total, log) => total + log.durationMinutes,
    );
    final recoveryCount = logs.where((log) => log.recoveryActionTaken).length;
    final budget = plan?.scrollBudgetMinutes ?? 30;
    final objects = <GardenObject>[];

    for (final session in focusSessions) {
      final task = session.taskId == null
          ? null
          : await _db.tasksDao.getById(session.taskId!);
      objects.add(
        GardenObject.fromFocusSession(
          sessionId: session.id,
          sessionType: session.sessionType,
          actualMinutes: session.actualMinutes,
          taskTitle: task?.title,
        ),
      );
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

  Stream<GardenDay> watchToday() => _poll(() => buildDay(DateTime.now()));

  Stream<List<GardenDay>> watchCurrentWeek() => _poll(buildCurrentWeek);

  Stream<T> _poll<T>(Future<T> Function() load) async* {
    yield await load();
    await for (final _ in Stream<void>.periodic(const Duration(seconds: 12))) {
      yield await load();
    }
  }

  DateTime _startOfToday() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }
}
