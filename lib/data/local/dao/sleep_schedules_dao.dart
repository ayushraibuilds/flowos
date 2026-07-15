import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../tables/sleep_schedules_table.dart';

part 'sleep_schedules_dao.g.dart';

@DriftAccessor(tables: [SleepSchedules])
class SleepSchedulesDao extends DatabaseAccessor<AppDatabase>
    with _$SleepSchedulesDaoMixin {
  SleepSchedulesDao(super.db);

  Future<SleepSchedule?> getSchedule(String id) =>
      (select(sleepSchedules)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<void> upsertSchedule(SleepSchedulesCompanion entry) =>
      into(sleepSchedules).insertOnConflictUpdate(entry);
}
