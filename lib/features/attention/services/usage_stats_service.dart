import 'dart:io';
import 'package:drift/drift.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../data/local/database/app_database.dart';

enum UsageSyncStatus { synced, permissionRequired, unsupported, failed }

class UsageSyncResult {
  const UsageSyncResult(this.status, {this.message});

  final UsageSyncStatus status;
  final String? message;
}

/// Service to fetch foreground usage statistics on Android after the user has
/// explicitly granted Usage Access. Other platforms continue to use the
/// app's manual scroll log rather than showing invented usage data.
class UsageStatsService {
  final AppDatabase _db;
  static const _channel = MethodChannel('flowos/usage_stats');

  UsageStatsService(this._db);

  /// Check if Usage access permission is granted (Android only)
  Future<bool> checkPermission() async {
    if (!Platform.isAndroid) return true;
    try {
      final bool granted =
          await _channel.invokeMethod('checkPermission') ?? false;
      return granted;
    } catch (_) {
      return false;
    }
  }

  /// Open Usage settings to request permission (Android only)
  Future<void> requestPermission() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('requestPermission');
    } catch (_) {}
  }

  /// Sync today's actual device usage for FlowOS' distraction watchlist.
  Future<UsageSyncResult> syncUsageStats() async {
    if (!Platform.isAndroid) {
      return const UsageSyncResult(UsageSyncStatus.unsupported);
    }

    if (!await checkPermission()) {
      return const UsageSyncResult(UsageSyncStatus.permissionRequired);
    }

    try {
      final Map<dynamic, dynamic>? stats = await _channel.invokeMethod(
        'getTodayUsage',
      );
      if (stats == null) {
        return const UsageSyncResult(
          UsageSyncStatus.failed,
          message: 'No device usage was returned.',
        );
      }

      final now = DateTime.now();
      final start = DateTime(now.year, now.month, now.day);

      // The app shows actual foreground minutes. Risk interpretation belongs in
      // future, user-configurable coaching—not in silently inflated data.
      final watchlist = {
        'com.instagram.android': 'Instagram',
        'com.google.android.youtube': 'YouTube',
        'com.ss.android.ugc.trill': 'TikTok',
        'com.zhiliaoapp.musically': 'TikTok',
        'com.twitter.android': 'Twitter/X',
        'com.reddit.frontpage': 'Reddit',
      };

      await _db.scrollLogsDao.deleteAllAutoLogsForToday(start);

      for (final entry in stats.entries) {
        final package = entry.key as String;
        final rawMinutes = (entry.value as num).toInt();
        if (rawMinutes <= 0) continue;

        final appName = watchlist[package];
        if (appName == null) continue;

        final impact = (rawMinutes ~/ 10) * -10;

        await _db.scrollLogsDao.insertLog(
          ScrollLogsCompanion(
            id: Value(const Uuid().v4()),
            appName: Value('$appName [Auto]'),
            durationMinutes: Value(rawMinutes),
            dailyScoreImpact: Value(impact),
            timestamp: Value(DateTime.now()),
          ),
        );
      }
      return const UsageSyncResult(UsageSyncStatus.synced);
    } on PlatformException catch (error) {
      if (error.code == 'permission_denied') {
        return const UsageSyncResult(UsageSyncStatus.permissionRequired);
      }
      return UsageSyncResult(UsageSyncStatus.failed, message: error.message);
    } catch (_) {
      return const UsageSyncResult(
        UsageSyncStatus.failed,
        message: 'Could not sync device usage.',
      );
    }
  }
}

/// Provider for UsageStatsService
final usageStatsServiceProvider = Provider<UsageStatsService>((ref) {
  final db = ref.watch(databaseProvider);
  return UsageStatsService(db);
});
