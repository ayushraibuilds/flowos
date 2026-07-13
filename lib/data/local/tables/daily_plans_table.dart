import 'package:drift/drift.dart';

/// Daily plans — the Morning Intention record.
/// Links to 3 MITs, records energy, scroll budget, and ritual completion.
class DailyPlans extends Table {
  TextColumn get id => text()();

  DateTimeColumn get date => dateTime()();

  // MITs (up to 3)
  TextColumn get mit1Id => text().nullable()();
  TextColumn get mit2Id => text().nullable()();
  TextColumn get mit3Id => text().nullable()();

  // Morning state
  IntColumn get morningEnergy => integer().withDefault(const Constant(3))(); // 1-5
  IntColumn get scrollBudgetMinutes => integer().withDefault(const Constant(30))();

  // Ritual tracking
  BoolColumn get intentionCompleted => boolean().withDefault(const Constant(false))();
  BoolColumn get shutdownCompleted => boolean().withDefault(const Constant(false))();
  TextColumn get intentionNote => text().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
