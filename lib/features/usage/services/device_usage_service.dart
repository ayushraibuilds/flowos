import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';

import '../../../data/local/database/app_database.dart';

/// Service interfacing with native device usage statistics (local-only).
class DeviceUsageService {
  final AppDatabase _db;
  static const _channel = MethodChannel('flowos/usage_stats');

  DeviceUsageService(this._db);

  /// Check whether usage permission is granted
  Future<bool> checkPermission() async {
    if (!Platform.isAndroid) return false; // iOS is stubbed out for now
    try {
      final granted = await _channel.invokeMethod<bool>('checkPermission');
      return granted ?? false;
    } catch (e) {
      debugPrint('Error checking usage stats permission: $e');
      return false;
    }
  }

  /// Request usage stats permission from settings screen
  Future<void> requestPermission() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('requestPermission');
    } catch (e) {
      debugPrint('Error requesting usage stats permission: $e');
    }
  }

  /// Fetch foreground usage logs from Android for [days] range,
  /// aggregate and write them to the local Drift database.
  Future<void> syncUsageLogs({int days = 7}) async {
    if (!Platform.isAndroid) return;

    final hasPerm = await checkPermission();
    if (!hasPerm) {
      debugPrint('⚠️ DeviceUsageService: No usage stats permission — skipping sync.');
      return;
    }

    try {
      final List<dynamic>? rawData = await _channel.invokeMethod<List<dynamic>>(
        'getUsageForDays',
        {'days': days},
      );

      if (rawData == null || rawData.isEmpty) {
        debugPrint('DeviceUsageService: No usage logs returned from native query.');
        return;
      }

      int count = 0;
      for (final rawRow in rawData) {
        final row = Map<String, dynamic>.from(rawRow);
        final dateStr = row['date'] as String;
        final packageName = row['packageName'] as String;
        final label = row['label'] as String?;
        final minutes = row['minutes'] as int;

        final uniqueId = '${dateStr}_$packageName';

        await _db.deviceUsageRecordsDao.upsertRecord(DeviceUsageRecordsCompanion(
          id: Value(uniqueId),
          date: Value(DateTime.parse(dateStr)),
          platform: const Value('android'),
          packageName: Value(packageName),
          label: Value(label),
          minutes: Value(minutes),
        ));
        count++;
      }

      debugPrint('✅ DeviceUsageService: Synced $count foreground usage records locally.');
    } catch (e) {
      debugPrint('Error syncing usage logs: $e');
    }
  }
}

/// Provider for DeviceUsageService
final deviceUsageServiceProvider = Provider<DeviceUsageService>((ref) {
  final db = ref.watch(databaseProvider);
  return DeviceUsageService(db);
});
