import 'package:drift/drift.dart';

/// Scroll logs — manual scroll time tracking per app.
class ScrollLogs extends Table {
  TextColumn get id => text()();

  TextColumn get appName => text()(); // instagram, youtube, twitter, reddit, other
  IntColumn get durationMinutes => integer()();
  IntColumn get dailyScoreImpact => integer()(); // negative value

  BoolColumn get recoveryActionTaken => boolean().withDefault(const Constant(false))();
  TextColumn get recoveryActionType => text().nullable()(); // breathing, walk, tinyTask, focusSprint

  TextColumn get intent => text().nullable()(); // reply | lookup | rest | avoiding | scrolling
  BoolColumn get wasTimeboxed => boolean().withDefault(const Constant(false))();
  IntColumn get plannedMinutes => integer().nullable()();

  DateTimeColumn get timestamp => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
