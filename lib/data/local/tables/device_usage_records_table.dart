import 'package:drift/drift.dart';

/// Device usage records — stores normalized aggregate foreground-usage logs.
/// This table remains entirely local/offline for privacy.
class DeviceUsageRecords extends Table {
  TextColumn get id => text()();

  DateTimeColumn get date => dateTime()(); // Day of usage
  TextColumn get platform => text()(); // 'android' or 'ios'
  TextColumn get packageName => text()(); // Package name (Android) or token (iOS)
  TextColumn get label => text().nullable()(); // App display name or category
  IntColumn get minutes => integer()(); // Aggregate foreground minutes
  TextColumn get source => text().withDefault(const Constant('android_usage'))();
  TextColumn get category => text().nullable()();
  BoolColumn get isDistracting => boolean().withDefault(const Constant(false))();
  DateTimeColumn get syncTime => dateTime().withDefault(currentDateAndTime)(); // Log sync timestamp

  @override
  Set<Column> get primaryKey => {id};
}
