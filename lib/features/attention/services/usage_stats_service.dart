import 'dart:io';
import 'package:drift/drift.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../data/local/database/app_database.dart';

/// Service to fetch foreground usage statistics on Android
/// or mock them on iOS/Simulator so Attention Radar has real-time interactivity.
class UsageStatsService {
  final AppDatabase _db;
  static const _channel = MethodChannel('flowos/usage_stats');

  UsageStatsService(this._db);

  /// Check if Usage access permission is granted (Android only)
  Future<bool> checkPermission() async {
    if (!Platform.isAndroid) return true;
    try {
      final bool granted = await _channel.invokeMethod('checkPermission') ?? false;
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

  /// Sync today's auto usage stats for the watchlist packages.
  /// Mapped and weighted according to "short-form risk apps" heuristics:
  /// - Instagram: 1.5x weight
  /// - YouTube: 1.2x weight
  /// - TikTok: 2.0x weight
  /// - Twitter: 1.2x weight
  /// - Reddit: 1.2x weight
  Future<void> syncUsageStats() async {
    if (!Platform.isAndroid) {
      // Mock tracking data injected for visual debugging / testing
      await _injectSimulatedUsageStats();
      return;
    }

    try {
      final Map<dynamic, dynamic>? stats = await _channel.invokeMethod('getTodayUsage');
      if (stats == null) return;

      final now = DateTime.now();
      final start = DateTime(now.year, now.month, now.day);

      // short-form risk apps watchlist
      final watchlist = {
        'com.instagram.android': (name: 'Instagram', weight: 1.5),
        'com.google.android.youtube': (name: 'YouTube', weight: 1.2),
        'com.ss.android.ugc.trill': (name: 'TikTok', weight: 2.0),
        'com.zhiliaoapp.musically': (name: 'TikTok', weight: 2.0),
        'com.twitter.android': (name: 'Twitter/X', weight: 1.2),
        'com.reddit.frontpage': (name: 'Reddit', weight: 1.2),
      };

      for (final entry in stats.entries) {
        final package = entry.key as String;
        final rawMinutes = (entry.value as num).toInt();
        if (rawMinutes <= 0) continue;

        final config = watchlist[package];
        if (config == null) continue;

        // Apply short-form risk multipliers
        final weightedMinutes = (rawMinutes * config.weight).round();
        final appName = '${config.name} [Auto]';

        // Delete previous sync logs of today to prevent duplicating
        await _db.scrollLogsDao.deleteAutoLogsForToday(appName, start);

        // Daily impact
        final impact = (weightedMinutes ~/ 10) * -10;

        await _db.scrollLogsDao.insertLog(ScrollLogsCompanion(
          id: Value(const Uuid().v4()),
          appName: Value(appName),
          durationMinutes: Value(weightedMinutes),
          dailyScoreImpact: Value(impact),
          timestamp: Value(DateTime.now()),
        ));
      }
    } catch (_) {}
  }

  Future<void> _injectSimulatedUsageStats() async {
    // Check if we already logged auto-mock stats today
    final logs = await _db.scrollLogsDao.getTodayLogs();
    final hasAuto = logs.any((l) => l.appName.contains('[Auto]'));
    if (hasAuto) return;

    final mockData = [
      (name: 'Instagram [Auto]', min: 14, impact: -10),
      (name: 'YouTube [Auto]', min: 20, impact: -15),
      (name: 'TikTok [Auto]', min: 8, impact: -15),
    ];

    for (final m in mockData) {
      await _db.scrollLogsDao.insertLog(ScrollLogsCompanion(
        id: Value(const Uuid().v4()),
        appName: Value(m.name),
        durationMinutes: Value(m.min),
        dailyScoreImpact: Value(m.impact),
        timestamp: Value(DateTime.now()),
      ));
    }
  }
}

/// Provider for UsageStatsService
final usageStatsServiceProvider = Provider<UsageStatsService>((ref) {
  final db = ref.watch(databaseProvider);
  return UsageStatsService(db);
});
