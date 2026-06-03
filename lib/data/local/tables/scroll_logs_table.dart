import 'package:drift/drift.dart';

/// Scroll logs — manual scroll time tracking per app.
class ScrollLogs extends Table {
  TextColumn get id => text()();

  TextColumn get appName => text()(); // instagram, youtube, twitter, reddit, other
  IntColumn get durationMinutes => integer()();
  IntColumn get dailyScoreImpact => integer()(); // negative value

  BoolColumn get recoveryActionTaken => boolean().withDefault(const Constant(false))();
  TextColumn get recoveryActionType => text().nullable()(); // breathing, walk, tinyTask, focusSprint

  DateTimeColumn get timestamp => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
