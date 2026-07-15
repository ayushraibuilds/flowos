import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../data/local/database/app_database.dart';

class NotificationSyncManager {
  final AppDatabase _db;
  static const _channel = MethodChannel('flowos/device_attention');

  NotificationSyncManager(this._db);

  /// Checks and syncs unacknowledged batches from native.
  Future<void> syncPendingNotifications() async {
    try {
      final bool collectionEnabled = await isCollectionEnabled();
      if (!collectionEnabled) return;

      // 1. Recover and process unacknowledged native batches
      final dynamic rawUnacked = await _channel.invokeMethod('getUnacknowledgedBatches');
      if (rawUnacked is Map) {
        for (final entry in rawUnacked.entries) {
          final String batchId = entry.key as String;
          final String dataStr = entry.value as String;
          await _processBatch(batchId, dataStr);
        }
      }

      // 2. Start a new in-flight batch for any newly collected notifications
      final String? batchJson = await _channel.invokeMethod('startInFlightBatch');
      if (batchJson != null && batchJson.isNotEmpty) {
        final decoded = jsonDecode(batchJson) as Map<String, dynamic>;
        final String batchId = decoded['batchId'] as String;
        final Map<String, dynamic> data = decoded['data'] as Map<String, dynamic>;
        await _processBatch(batchId, jsonEncode(data));
      }
    } catch (_) {}
  }

  Future<void> _processBatch(String batchId, String dataStr) async {
    await _db.transaction(() async {
      // 1. Attempt to mark the batch as processed (insert-or-ignore)
      final bool isNew = await _db.notificationDailyCountsDao.markBatchProcessed(batchId);
      if (!isNew) {
        // Already processed, tell native to clear
        await _channel.invokeMethod('acknowledgeBatch', {'batchId': batchId});
        return;
      }

      // 2. Parse batch data and increment SQLite daily totals
      final Map<String, dynamic> daysData = jsonDecode(dataStr) as Map<String, dynamic>;
      for (final dayEntry in daysData.entries) {
        final String dateStr = dayEntry.key;
        final DateTime date = DateTime.parse(dateStr);
        final Map<String, dynamic> appsData = dayEntry.value as Map<String, dynamic>;

        for (final appEntry in appsData.entries) {
          final String appRef = appEntry.key;
          final int count = appEntry.value as int;
          final String displayName = _inferAppName(appRef);

          await _db.notificationDailyCountsDao.incrementCount(
            date,
            'android',
            appRef,
            displayName,
            count,
          );
        }
      }
    });

    // 3. Batches successfully committed to sqlite can be safely acknowledged natively
    await _channel.invokeMethod('acknowledgeBatch', {'batchId': batchId});
  }

  String _inferAppName(String packageName) {
    // Basic package utility mapping fallback
    final parts = packageName.split('.');
    if (parts.length > 1) {
      final name = parts[parts.length - 1];
      return name[0].toUpperCase() + name.substring(1);
    }
    return packageName;
  }

  Future<bool> isCollectionEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('flowos_interruption_collection_enabled') ?? false;
  }

  Future<void> setCollectionEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('flowos_interruption_collection_enabled', enabled);
    // Write directly to SharedPreferences so native code reads it instantly
    await _channel.invokeMethod('openNotificationListenerSettings'); // Trigger settings request or just sync SharedPreferences
  }
}

final notificationSyncManagerProvider = Provider<NotificationSyncManager>((ref) {
  final db = ref.watch(databaseProvider);
  return NotificationSyncManager(db);
});
