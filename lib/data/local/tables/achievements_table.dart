import 'package:drift/drift.dart';

/// Achievements — unlocked badges.
class Achievements extends Table {
  TextColumn get id => text()();

  TextColumn get achievementKey => text()(); // matches AchievementKey enum
  DateTimeColumn get unlockedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
