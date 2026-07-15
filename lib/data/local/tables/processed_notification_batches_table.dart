import 'package:drift/drift.dart';

/// Database table to deduplicate processed notification sync batches.
class ProcessedNotificationBatches extends Table {
  TextColumn get batchId => text()();
  DateTimeColumn get processedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {batchId};
}
