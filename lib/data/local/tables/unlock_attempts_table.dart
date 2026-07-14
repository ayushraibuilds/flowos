import 'package:drift/drift.dart';

/// Unlock attempts — logs user intervention bypass tries and waits on shielded targets.
/// Used for private reflection/insights.
class UnlockAttempts extends Table {
  TextColumn get id => text()();

  TextColumn get platform => text()(); // 'android' or 'chrome-extension'
  TextColumn get target => text()(); // App package name or website domain being bypassed
  TextColumn get level => text()(); // 'reflect', 'guard', 'deep'
  IntColumn get requestedBreakMinutes => integer()(); // Break length (0 if Reflect)
  TextColumn get intention => text().nullable()(); // User-entered reason/intention
  TextColumn get waitOutcome => text()(); // 'completed_wait', 'abandoned', 'skipped'
  TextColumn get sessionId => text().nullable()(); // Current focus session ID context
  DateTimeColumn get timestamp => dateTime()(); // When the attempt happened

  @override
  Set<Column> get primaryKey => {id};
}
