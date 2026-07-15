import 'package:drift/drift.dart';

/// Daily device-level metrics and coverage tracking.
class DeviceDayMetrics extends Table {
  TextColumn get id => text()(); // '{dateStr}_{platform}'
  DateTimeColumn get day => dateTime()();
  TextColumn get platform => text()(); // 'android' or 'ios'
  IntColumn get unlockCount => integer().nullable()();
  IntColumn get screenWakeCount => integer().nullable()();
  TextColumn get coverageState => text()(); // 'complete', 'partial', 'notConnected', 'unsupported'
  DateTimeColumn get usageSyncedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
