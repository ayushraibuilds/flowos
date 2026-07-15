import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../tables/notification_daily_counts_table.dart';
import '../tables/processed_notification_batches_table.dart';

part 'notification_daily_counts_dao.g.dart';

@DriftAccessor(tables: [NotificationDailyCounts, ProcessedNotificationBatches])
class NotificationDailyCountsDao extends DatabaseAccessor<AppDatabase>
    with _$NotificationDailyCountsDaoMixin {
  NotificationDailyCountsDao(super.db);

  Future<List<NotificationDailyCount>> getForDay(DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    return (select(notificationDailyCounts)
          ..where((t) => t.day.equals(startOfDay)))
        .get();
  }

  Future<bool> markBatchProcessed(String batchId) async {
    try {
      final existing = await (select(processedNotificationBatches)
            ..where((t) => t.batchId.equals(batchId)))
          .getSingleOrNull();
      if (existing != null) {
        return false;
      }
      await into(processedNotificationBatches).insert(
        ProcessedNotificationBatchesCompanion.insert(
          batchId: batchId,
          processedAt: DateTime.now(),
        ),
        mode: InsertMode.insertOrIgnore,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> incrementCount(
    DateTime date,
    String platform,
    String appRef,
    String displayName,
    int increment,
  ) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final query = select(notificationDailyCounts)
      ..where((t) =>
          t.day.equals(startOfDay) &
          t.platform.equals(platform) &
          t.appRef.equals(appRef));
    final existing = await query.getSingleOrNull();

    if (existing != null) {
      await (update(notificationDailyCounts)
            ..where((t) =>
                t.day.equals(startOfDay) &
                t.platform.equals(platform) &
                t.appRef.equals(appRef)))
          .write(NotificationDailyCountsCompanion(
        count: Value(existing.count + increment),
        syncedAt: Value(DateTime.now()),
      ));
    } else {
      await into(notificationDailyCounts).insert(
        NotificationDailyCountsCompanion.insert(
          day: startOfDay,
          platform: platform,
          appRef: appRef,
          displayName: displayName,
          count: increment,
          syncedAt: DateTime.now(),
        ),
      );
    }
  }

  Future<void> clearAll() async {
    await delete(notificationDailyCounts).go();
    await delete(processedNotificationBatches).go();
  }
}
