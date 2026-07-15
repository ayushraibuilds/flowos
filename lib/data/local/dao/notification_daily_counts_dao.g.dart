// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_daily_counts_dao.dart';

// ignore_for_file: type=lint
mixin _$NotificationDailyCountsDaoMixin on DatabaseAccessor<AppDatabase> {
  $NotificationDailyCountsTable get notificationDailyCounts =>
      attachedDatabase.notificationDailyCounts;
  $ProcessedNotificationBatchesTable get processedNotificationBatches =>
      attachedDatabase.processedNotificationBatches;
  NotificationDailyCountsDaoManager get managers =>
      NotificationDailyCountsDaoManager(this);
}

class NotificationDailyCountsDaoManager {
  final _$NotificationDailyCountsDaoMixin _db;
  NotificationDailyCountsDaoManager(this._db);
  $$NotificationDailyCountsTableTableManager get notificationDailyCounts =>
      $$NotificationDailyCountsTableTableManager(
        _db.attachedDatabase,
        _db.notificationDailyCounts,
      );
  $$ProcessedNotificationBatchesTableTableManager
  get processedNotificationBatches =>
      $$ProcessedNotificationBatchesTableTableManager(
        _db.attachedDatabase,
        _db.processedNotificationBatches,
      );
}
