import 'package:drift/drift.dart';

/// Daily reports — stores the AI-generated or local report for each day.
class DailyReports extends Table {
  TextColumn get id => text()();

  DateTimeColumn get date => dateTime()();
  TextColumn get reportJson => text()(); // Full report as JSON string
  IntColumn get dailyScore => integer()(); // 0-100
  IntColumn get xpEarnedToday => integer()();
  IntColumn get attentionCostToday => integer().withDefault(const Constant(0))();
  IntColumn get promptVersion => integer().nullable()();

  DateTimeColumn get generatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
