import 'package:drift/drift.dart';

/// Persisted daily score snapshots.
class DailyScores extends Table {
  DateTimeColumn get day => dateTime()(); // midnight timestamp of the day

  IntColumn get score => integer()(); // 0-100
  TextColumn get grade => text().nullable()(); // null when incomplete
  BoolColumn get isIncomplete => boolean()();
  RealColumn get availableWeight => real()(); // 1.0 (complete) or 0.75 (Attention omitted)
  IntColumn get scoringVersion => integer()(); // 1 for V1, 2 for V2

  // Pillar scores breakdown
  RealColumn get focusPoints => real()();
  RealColumn get intentPoints => real()();
  RealColumn get attentionPoints => real().nullable()();
  RealColumn get carePoints => real()();

  DateTimeColumn get computedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {day};
}
