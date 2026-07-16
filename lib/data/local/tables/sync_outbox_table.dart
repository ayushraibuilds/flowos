import 'package:drift/drift.dart';

/// Transactional Sync Outbox — records local writes that need to be synchronized to the cloud.
class SyncOutbox extends Table {
  TextColumn get id => text()(); // Unique operational UUID

  TextColumn get entityTable => text()(); // 'tasks', 'focus_sessions', 'daily_plans', 'daily_reports', 'scroll_logs', 'energy_checkins', 'achievements'
  TextColumn get entityId => text()(); // Primary key ID of the record being mutated
  TextColumn get operation => text()(); // 'upsert', 'delete'
  TextColumn get serializedData => text()(); // JSON-serialized representation of the record at the time of modification

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
