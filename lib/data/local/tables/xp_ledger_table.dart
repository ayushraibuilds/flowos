import 'package:drift/drift.dart';

/// XP Ledger — APPEND-ONLY. No UPDATE or DELETE operations.
/// Every XP change is a record. This is an auditable ledger, not a mutable counter.
class XpLedgerEntries extends Table {
  TextColumn get id => text()();

  // What happened
  TextColumn get actionType => textEnum<XpActionTypeColumn>()();
  IntColumn get pointsDelta => integer()(); // Always positive for XP

  // What caused it
  TextColumn get sourceEntityId => text().nullable()(); // taskId, sessionId, etc.
  TextColumn get explanation => text()(); // "Completed 25-min Pomodoro on 'Write proposal'"

  // Metadata
  BoolColumn get isReversible => boolean().withDefault(const Constant(false))();
  IntColumn get promptVersion => integer().nullable()();
  DateTimeColumn get timestamp => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// All XP-earning action types
enum XpActionTypeColumn {
  focusComplete,
  taskComplete,
  mitComplete,
  allMitsDaily,
  earlyStart,
  breakContentUsed,
  sevenDayStreak,
  energyCheckin3x,
  focusRitualComplete,
  shutdownRitualComplete,
  bounceBackBonus,
}
