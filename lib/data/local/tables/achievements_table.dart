import 'package:drift/drift.dart';

/// Achievements — unlocked badges.
class Achievements extends Table {
  TextColumn get id => text()();

  TextColumn get achievementKey => text()(); // matches AchievementKey enum
  DateTimeColumn get unlockedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
