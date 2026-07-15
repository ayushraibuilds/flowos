import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../tables/device_day_metrics_table.dart';

part 'device_day_metrics_dao.g.dart';

@DriftAccessor(tables: [DeviceDayMetrics])
class DeviceDayMetricsDao extends DatabaseAccessor<AppDatabase>
    with _$DeviceDayMetricsDaoMixin {
  DeviceDayMetricsDao(super.db);

  Future<DeviceDayMetric?> getForDay(DateTime day, String platform) {
    final date = DateTime(day.year, day.month, day.day);
    return (select(deviceDayMetrics)
          ..where((t) => t.day.equals(date) & t.platform.equals(platform)))
        .getSingleOrNull();
  }

  Future<void> upsertMetric(DeviceDayMetricsCompanion entry) =>
      into(deviceDayMetrics).insertOnConflictUpdate(entry);

  Future<void> clearAll() => delete(deviceDayMetrics).go();
}
