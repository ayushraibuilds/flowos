import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../tables/device_usage_records_table.dart';

part 'device_usage_records_dao.g.dart';

@DriftAccessor(tables: [DeviceUsageRecords])
class DeviceUsageRecordsDao extends DatabaseAccessor<AppDatabase>
    with _$DeviceUsageRecordsDaoMixin {
  DeviceUsageRecordsDao(super.db);

  /// Insert a single usage record
  Future<void> insertRecord(DeviceUsageRecordsCompanion entry) =>
      into(deviceUsageRecords).insert(entry);

  /// Upsert a usage record (update on primary key conflict)
  Future<void> upsertRecord(DeviceUsageRecordsCompanion entry) =>
      into(deviceUsageRecords).insertOnConflictUpdate(entry);

  /// Get usage records for a specific date range
  Future<List<DeviceUsageRecord>> getForRange(DateTime start, DateTime end) =>
      (select(deviceUsageRecords)
            ..where((r) =>
                r.date.isBiggerOrEqualValue(start) &
                r.date.isSmallerOrEqualValue(end))
            ..orderBy([(r) => OrderingTerm.desc(r.minutes)]))
          .get();

  /// Watch usage records for today
  Stream<List<DeviceUsageRecord>> watchToday() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));
    return (select(deviceUsageRecords)
          ..where((r) =>
              r.date.isBiggerOrEqualValue(start) &
              r.date.isSmallerThanValue(end))
          ..orderBy([(r) => OrderingTerm.desc(r.minutes)]))
        .watch();
  }

  /// Get total distracting minutes today
  Future<int> getTodayTotalMinutes() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));
    final list = await (select(deviceUsageRecords)
          ..where((r) =>
              r.date.isBiggerOrEqualValue(start) &
              r.date.isSmallerThanValue(end)))
        .get();
    return list.fold<int>(0, (sum, r) => sum + r.minutes);
  }

  /// Clear all usage records
  Future<void> clearAll() => delete(deviceUsageRecords).go();
}
