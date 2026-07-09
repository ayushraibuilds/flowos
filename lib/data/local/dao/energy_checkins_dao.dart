import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../database/app_database.dart';
import '../tables/energy_checkins_table.dart';

part 'energy_checkins_dao.g.dart';

const _uuid = Uuid();

@DriftAccessor(tables: [EnergyCheckIns])
class EnergyCheckInsDao extends DatabaseAccessor<AppDatabase>
    with _$EnergyCheckInsDaoMixin {
  EnergyCheckInsDao(super.db);

  Future<void> insertCheckIn(EnergyCheckInsCompanion entry) =>
      into(energyCheckIns).insert(entry);

  /// Get check-ins for a specific date
  Future<List<EnergyCheckIn>> getForDate(DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return (select(energyCheckIns)
          ..where((e) =>
              e.date.isBiggerOrEqualValue(start) &
              e.date.isSmallerThanValue(end)))
        .get();
  }

  /// Count check-ins today (for 3x daily achievement)
  Future<int> countToday() async {
    final checkins = await getForDate(DateTime.now());
    return checkins.length;
  }

  /// Get check-ins since a given timestamp (for sync push).
  Future<List<EnergyCheckIn>> getModifiedSince(DateTime since) =>
      (select(energyCheckIns)
            ..where((e) => e.date.isBiggerOrEqualValue(since)))
          .get();

  /// Get the latest energy check-in
  Future<EnergyCheckIn?> getLatest() =>
      (select(energyCheckIns)
            ..orderBy([(e) => OrderingTerm.desc(e.date)])
            ..limit(1))
          .getSingleOrNull();

  /// Get energy check-in for a specific bucket today
  Future<EnergyCheckIn?> getForBucket(TimeOfDayColumn bucket, DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return (select(energyCheckIns)
          ..where((e) =>
              e.date.isBiggerOrEqualValue(start) &
              e.date.isSmallerThanValue(end) &
              e.timeOfDay.equalsValue(bucket)))
        .getSingleOrNull();
  }

  /// Upsert energy check-in (same-day same-bucket updates, otherwise inserts)
  Future<void> upsertCheckIn(TimeOfDayColumn bucket, int value) async {
    final now = DateTime.now();
    final existing = await getForBucket(bucket, now);
    if (existing != null) {
      await (update(energyCheckIns)..where((e) => e.id.equals(existing.id)))
          .write(EnergyCheckInsCompanion(
        value: Value(value),
        date: Value(now),
      ));
    } else {
      await into(energyCheckIns).insert(EnergyCheckInsCompanion(
        id: Value(_uuid.v4()),
        timeOfDay: Value(bucket),
        value: Value(value),
        date: Value(now),
      ));
    }
  }

  /// Watch check-ins today (reactive stream)
  Stream<List<EnergyCheckIn>> watchToday() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));
    return (select(energyCheckIns)
          ..where((e) =>
              e.date.isBiggerOrEqualValue(start) &
              e.date.isSmallerThanValue(end)))
        .watch();
  }

  /// Get check-ins in date range
  Future<List<EnergyCheckIn>> getCheckInsInRange(DateTime start, DateTime end) {
    return (select(energyCheckIns)
          ..where((e) =>
              e.date.isBiggerOrEqualValue(start) &
              e.date.isSmallerThanValue(end)))
        .get();
  }

  /// Average check-in value per bucket over last N days
  Future<Map<TimeOfDayColumn, double>> averageByBucket(int days) async {
    final start = DateTime.now().subtract(Duration(days: days));
    final checkins = await (select(energyCheckIns)
          ..where((e) => e.date.isBiggerOrEqualValue(start)))
        .get();

    final Map<TimeOfDayColumn, List<int>> values = {
      TimeOfDayColumn.morning: [],
      TimeOfDayColumn.afternoon: [],
      TimeOfDayColumn.evening: [],
    };

    for (final c in checkins) {
      values[c.timeOfDay]?.add(c.value);
    }

    return values.map((bucket, list) {
      if (list.isEmpty) return MapEntry(bucket, 0.0);
      final avg = list.reduce((a, b) => a + b) / list.length;
      return MapEntry(bucket, avg);
    });
  }
}
