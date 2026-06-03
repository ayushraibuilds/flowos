import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../tables/energy_checkins_table.dart';

part 'energy_checkins_dao.g.dart';

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
}
