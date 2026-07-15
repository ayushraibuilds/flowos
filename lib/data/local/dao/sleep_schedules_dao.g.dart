// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sleep_schedules_dao.dart';

// ignore_for_file: type=lint
mixin _$SleepSchedulesDaoMixin on DatabaseAccessor<AppDatabase> {
  $SleepSchedulesTable get sleepSchedules => attachedDatabase.sleepSchedules;
  SleepSchedulesDaoManager get managers => SleepSchedulesDaoManager(this);
}

class SleepSchedulesDaoManager {
  final _$SleepSchedulesDaoMixin _db;
  SleepSchedulesDaoManager(this._db);
  $$SleepSchedulesTableTableManager get sleepSchedules =>
      $$SleepSchedulesTableTableManager(
        _db.attachedDatabase,
        _db.sleepSchedules,
      );
}
