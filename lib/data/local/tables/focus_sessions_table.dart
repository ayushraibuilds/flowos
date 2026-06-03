import 'package:drift/drift.dart';

/// Focus sessions table — records every focused work session.
/// Tracks duration, pauses, background switches, and quality score.
class FocusSessions extends Table {
  TextColumn get id => text()();

  // Linked task (nullable — standalone allowed but lower XP)
  TextColumn get taskId => text().nullable()();

  // Session configuration
  TextColumn get sessionType => textEnum<SessionTypeColumn>()();
  IntColumn get durationMinutes => integer()();

  // Actual performance
  IntColumn get actualMinutes => integer().withDefault(const Constant(0))();
  IntColumn get pauseCount => integer().withDefault(const Constant(0))();
  IntColumn get appBackgroundCount => integer().withDefault(const Constant(0))();

  // Extras
  TextColumn get ambientSound => text().nullable()();
  IntColumn get energyBefore => integer().nullable()();
  IntColumn get energyAfter => integer().nullable()();

  // Results
  IntColumn get xpEarned => integer().withDefault(const Constant(0))();
  TextColumn get qualityScore => text().withDefault(const Constant(''))(); // A/B/C/D

  // Timestamps
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get completedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

enum SessionTypeColumn { pomodoro, deepWork, custom }
