import 'package:drift/drift.dart';

/// Database table for repeating bedtime Sleep Mode schedules.
class SleepSchedules extends Table {
  TextColumn get id => text()(); // Should be 'default' for single schedule
  TextColumn get weekdays => text()(); // JSON stringified list of integers (1=Mon ... 7=Sun)
  IntColumn get bedtimeMinute => integer()(); // minutes from midnight
  IntColumn get wakeMinute => integer()(); // minutes from midnight
  TextColumn get timezoneId => text()(); // informational
  TextColumn get protectionLevel => text()(); // 'nudge', 'guard', 'deep'
  BoolColumn get enabled => boolean()();

  @override
  Set<Column> get primaryKey => {id};
}
