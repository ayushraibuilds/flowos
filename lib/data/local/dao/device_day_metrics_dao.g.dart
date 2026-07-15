// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_day_metrics_dao.dart';

// ignore_for_file: type=lint
mixin _$DeviceDayMetricsDaoMixin on DatabaseAccessor<AppDatabase> {
  $DeviceDayMetricsTable get deviceDayMetrics =>
      attachedDatabase.deviceDayMetrics;
  DeviceDayMetricsDaoManager get managers => DeviceDayMetricsDaoManager(this);
}

class DeviceDayMetricsDaoManager {
  final _$DeviceDayMetricsDaoMixin _db;
  DeviceDayMetricsDaoManager(this._db);
  $$DeviceDayMetricsTableTableManager get deviceDayMetrics =>
      $$DeviceDayMetricsTableTableManager(
        _db.attachedDatabase,
        _db.deviceDayMetrics,
      );
}
