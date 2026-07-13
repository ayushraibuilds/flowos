// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_usage_records_dao.dart';

// ignore_for_file: type=lint
mixin _$DeviceUsageRecordsDaoMixin on DatabaseAccessor<AppDatabase> {
  $DeviceUsageRecordsTable get deviceUsageRecords =>
      attachedDatabase.deviceUsageRecords;
  DeviceUsageRecordsDaoManager get managers =>
      DeviceUsageRecordsDaoManager(this);
}

class DeviceUsageRecordsDaoManager {
  final _$DeviceUsageRecordsDaoMixin _db;
  DeviceUsageRecordsDaoManager(this._db);
  $$DeviceUsageRecordsTableTableManager get deviceUsageRecords =>
      $$DeviceUsageRecordsTableTableManager(
        _db.attachedDatabase,
        _db.deviceUsageRecords,
      );
}
