import 'package:drift/drift.dart';

/// Database table for local daily notification count summaries.
class NotificationDailyCounts extends Table {
  DateTimeColumn get day => dateTime()(); // Start of day
  TextColumn get platform => text()(); // 'android' or 'ios'
  TextColumn get appRef => text()(); // Package name / bundle ID
  TextColumn get displayName => text()(); // App label
  IntColumn get count => integer()();
  DateTimeColumn get syncedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {day, platform, appRef};
}
