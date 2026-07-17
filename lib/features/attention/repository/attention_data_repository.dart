import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../data/local/database/app_database.dart';
import '../../focus/models/pending_trigger.dart';
import '../../../core/constants/distraction_packages.dart';

enum DataCoverage { complete, partial, manualOnly, notConnected, unsupported }

class PermissionStates {
  final bool usageAccess;
  final bool accessibility;
  final bool notificationAccess;
  final String platformSupport;

  const PermissionStates({
    required this.usageAccess,
    required this.accessibility,
    required this.notificationAccess,
    required this.platformSupport,
  });
}

class AttentionDay {
  final DateTime day;
  final DataCoverage coverage;
  final int nativeDistractingMinutes;
  final int manualScrollMinutes;
  final int effectiveDistractingMinutes;
  final int unlockCount;

  const AttentionDay({
    required this.day,
    required this.coverage,
    required this.nativeDistractingMinutes,
    required this.manualScrollMinutes,
    required this.effectiveDistractingMinutes,
    required this.unlockCount,
  });
}

class DeviceAttentionPlatform {
  static const _channel = MethodChannel('flowos/device_attention');

  Future<PermissionStates> getPermissionStates() async {
    if (!Platform.isAndroid) {
      return const PermissionStates(
        usageAccess: true,
        accessibility: true,
        notificationAccess: true,
        platformSupport: 'ios',
      );
    }
    try {
      final Map<dynamic, dynamic>? res =
          await _channel.invokeMethod('getPermissionStates');
      if (res != null) {
        return PermissionStates(
          usageAccess: res['usageAccess'] as bool? ?? false,
          accessibility: res['accessibility'] as bool? ?? false,
          notificationAccess: res['notificationAccess'] as bool? ?? false,
          platformSupport: res['platformSupport'] as String? ?? 'android',
        );
      }
    } catch (_) {}
    return const PermissionStates(
      usageAccess: false,
      accessibility: false,
      notificationAccess: false,
      platformSupport: 'android',
    );
  }

  Future<void> openUsageAccessSettings() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('openUsageAccessSettings');
    } catch (_) {}
  }

  Future<void> openAccessibilitySettings() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('openAccessibilitySettings');
    } catch (_) {}
  }

  Future<void> openNotificationListenerSettings() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('openNotificationListenerSettings');
    } catch (_) {}
  }

  Future<List<Map<String, String>>> getLaunchableApps() async {
    if (!Platform.isAndroid) return [];
    try {
      final List<dynamic>? res = await _channel.invokeMethod('getLaunchableApps');
      if (res != null) {
        return res.map((item) {
          final m = Map<dynamic, dynamic>.from(item);
          return {
            'packageName': m['packageName'] as String? ?? '',
            'label': m['label'] as String? ?? '',
          };
        }).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<Uint8List?> loadAppIcon(String packageName) async {
    if (!Platform.isAndroid) return null;
    try {
      final Uint8List? res = await _channel.invokeMethod('loadAppIcon', {
        'packageName': packageName,
      });
      return res;
    } catch (_) {}
    return null;
  }

  Future<Map<String, dynamic>?> claimPendingBlockedAppTrigger() async {
    if (!Platform.isAndroid) return null;
    try {
      final Map<dynamic, dynamic>? res =
          await _channel.invokeMethod('claimPendingBlockedAppTrigger');
      if (res != null) {
        return Map<String, dynamic>.from(res);
      }
    } catch (_) {}
    return null;
  }

  Future<PendingNudge?> claimPendingNudge() async {
    if (!Platform.isAndroid) return null;
    try {
      final Map<dynamic, dynamic>? res = await _channel.invokeMethod('claimPendingNudge');
      if (res != null) {
        return PendingNudge.fromJson(Map<String, dynamic>.from(res));
      }
    } catch (_) {}
    return null;
  }

  Future<void> clearNudgesForSession(String sessionId) async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('clearNudgesForSession', {'sessionId': sessionId});
    } catch (_) {}
  }

  Future<List<Map<String, String>>> getDefaultEssentialPackages() async {
    if (!Platform.isAndroid) return [];
    try {
      final List<dynamic>? res =
          await _channel.invokeMethod('getDefaultEssentialPackages');
      if (res != null) {
        return res.map((item) {
          final m = Map<dynamic, dynamic>.from(item);
          return {
            'packageName': m['packageName'] as String? ?? '',
            'reason': m['reason'] as String? ?? '',
          };
        }).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<List<Map<String, dynamic>>> getDailyUsage(DateTime start, DateTime end) async {
    if (!Platform.isAndroid) return [];
    try {
      final List<dynamic>? res = await _channel.invokeMethod('getDailyUsage', {
        'startMs': start.millisecondsSinceEpoch,
        'endMs': end.millisecondsSinceEpoch,
      });
      if (res != null) {
        return res.map((item) => Map<String, dynamic>.from(item)).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<List<Map<String, dynamic>>> getDailyUnlockEvents(DateTime start, DateTime end) async {
    if (!Platform.isAndroid) return [];
    try {
      final List<dynamic>? res = await _channel.invokeMethod('getDailyUnlockEvents', {
        'startMs': start.millisecondsSinceEpoch,
        'endMs': end.millisecondsSinceEpoch,
      });
      if (res != null) {
        return res.map((item) => Map<String, dynamic>.from(item)).toList();
      }
    } catch (_) {}
    return [];
  }
}

class AttentionDataRepository {
  final AppDatabase _db;
  final DeviceAttentionPlatform _platform;

  AttentionDataRepository(this._db, this._platform);

  Future<void> syncUsage({int days = 1, bool forcePlatformCheck = true}) async {
    if (forcePlatformCheck && !Platform.isAndroid) return;

    final states = await _platform.getPermissionStates();
    if (!states.usageAccess) {
      for (int i = 0; i < days; i++) {
        final d = DateTime.now().subtract(Duration(days: i));
        final date = DateTime(d.year, d.month, d.day);
        final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        await _db.deviceDayMetricsDao.upsertMetric(DeviceDayMetricsCompanion(
          id: Value('${dateStr}_android'),
          day: Value(date),
          platform: const Value('android'),
          coverageState: const Value('notConnected'),
          usageSyncedAt: Value(DateTime.now()),
        ));
      }
      return;
    }

    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day).subtract(Duration(days: days - 1));
    final end = DateTime(now.year, now.month, now.day).add(const Duration(days: 1));

    try {
      final prefs = await SharedPreferences.getInstance();
      final deletedTimestamp = prefs.getInt('flowos_unlocks_deleted_timestamp') ?? 0;
      DateTime unlockStart = start;
      if (deletedTimestamp > start.millisecondsSinceEpoch) {
        unlockStart = DateTime.fromMillisecondsSinceEpoch(deletedTimestamp);
      }

      final rawUsage = await _platform.getDailyUsage(start, end);
      final rawUnlocks = await _platform.getDailyUnlockEvents(unlockStart, end);

      final rawProfile = prefs.getString('flowos_user_profile');
      final watchlist = <String>{};
      if (rawProfile != null) {
        try {
          final json = jsonDecode(rawProfile) as Map<String, dynamic>;
          final distractions = List<String>.from(json['distractions'] ?? []);
          for (final d in distractions) {
            final pkgs = DistractionPackages.allPackages(d);
            watchlist.addAll(pkgs);
          }
        } catch (_) {}
      }

      // Include all focus-protected apps from DB as distractions
      try {
        final dbApps = await _db.protectedAppsDao.getAll();
        for (final app in dbApps) {
          if (app.protectsFocus) {
            watchlist.add(app.appRef);
          }
        }
      } catch (_) {}

      for (final row in rawUsage) {
        final dateStr = row['date'] as String;
        final packageName = row['packageName'] as String;
        if (packageName.isEmpty) continue; // skip zero-usage placeholder rows
        final label = row['label'] as String?;
        final minutes = row['minutes'] as int;

        final isDistracting = watchlist.contains(packageName);
        final category = _inferCategory(packageName);

        await _db.deviceUsageRecordsDao.upsertRecord(DeviceUsageRecordsCompanion(
          id: Value('${dateStr}_$packageName'),
          date: Value(DateTime.parse(dateStr)),
          platform: const Value('android'),
          packageName: Value(packageName),
          label: Value(label),
          minutes: Value(minutes),
          source: const Value('android_usage'),
          category: Value(category),
          isDistracting: Value(isDistracting),
        ));
      }

      final unlockMap = {
        for (final item in rawUnlocks)
          item['date'] as String: item['count'] as int
      };

      final observedFromMs = prefs.getInt('flowos_notification_observed_from');
      final observedFrom = observedFromMs != null ? DateTime.fromMillisecondsSinceEpoch(observedFromMs) : null;

      for (int i = 0; i < days; i++) {
        final d = now.subtract(Duration(days: i));
        final date = DateTime(d.year, d.month, d.day);
        final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        final unlocks = unlockMap[dateStr];

        // 1. Calculate notificationCoverage
        String notifCoverage = 'none';
        if (observedFrom != null) {
          final obsDay = DateTime(observedFrom.year, observedFrom.month, observedFrom.day);
          if (date.isBefore(obsDay)) {
            notifCoverage = 'none';
          } else if (date.isAtSameMomentAs(obsDay)) {
            notifCoverage = 'partial';
          } else {
            final isToday = date.year == now.year && date.month == now.month && date.day == now.day;
            notifCoverage = isToday ? 'collecting' : 'complete';
          }
        }

        // 2. Calculate unlockCoverage
        String unlCoverage = 'none';
        if (states.usageAccess) {
          if (deletedTimestamp > 0) {
            final delDate = DateTime.fromMillisecondsSinceEpoch(deletedTimestamp);
            final delDay = DateTime(delDate.year, delDate.month, delDate.day);
            if (date.isBefore(delDay)) {
              unlCoverage = 'none';
            } else if (date.isAtSameMomentAs(delDay)) {
              unlCoverage = 'partial';
            } else {
              final isToday = date.year == now.year && date.month == now.month && date.day == now.day;
              unlCoverage = isToday ? 'collecting' : 'complete';
            }
          } else {
            final isToday = date.year == now.year && date.month == now.month && date.day == now.day;
            unlCoverage = isToday ? 'collecting' : 'complete';
          }
        }

        await _db.deviceDayMetricsDao.upsertMetric(DeviceDayMetricsCompanion(
          id: Value('${dateStr}_android'),
          day: Value(date),
          platform: const Value('android'),
          unlockCount: Value(unlocks),
          coverageState: const Value('complete'),
          usageSyncedAt: Value(DateTime.now()),
          notificationObservedFrom: Value(observedFrom),
          unlockCoverage: Value(unlCoverage),
          notificationCoverage: Value(notifCoverage),
        ));
      }
    } catch (_) {}
  }

  Future<AttentionDay> getAttentionDay(DateTime day) async {
    final targetDate = DateTime(day.year, day.month, day.day);
    final manualMinutes = await _getManualScrollMinutes(targetDate);

    final states = await _platform.getPermissionStates();
    if (states.platformSupport != 'android') {
      return AttentionDay(
        day: targetDate,
        coverage: DataCoverage.manualOnly,
        nativeDistractingMinutes: 0,
        manualScrollMinutes: manualMinutes,
        effectiveDistractingMinutes: manualMinutes,
        unlockCount: 0,
      );
    }

    final metric = await _db.deviceDayMetricsDao.getForDay(targetDate, 'android');
    if (metric == null) {
      return AttentionDay(
        day: targetDate,
        coverage: DataCoverage.notConnected,
        nativeDistractingMinutes: 0,
        manualScrollMinutes: manualMinutes,
        effectiveDistractingMinutes: manualMinutes,
        unlockCount: 0,
      );
    }

    final nativeList = await _db.deviceUsageRecordsDao.getForRange(targetDate, targetDate);
    final nativeDistracting = nativeList
        .where((r) => r.isDistracting == true && r.source == 'android_usage')
        .fold<int>(0, (sum, r) => sum + r.minutes);

    final DataCoverage coverage = switch (metric.coverageState) {
      'complete' => DataCoverage.complete,
      'partial' => DataCoverage.partial,
      'unsupported' => DataCoverage.unsupported,
      _ => DataCoverage.notConnected,
    };

    final effectiveDistracting = switch (coverage) {
      DataCoverage.complete => nativeDistracting,
      DataCoverage.partial => nativeDistracting > manualMinutes ? nativeDistracting : manualMinutes,
      _ => manualMinutes,
    };

    return AttentionDay(
      day: targetDate,
      coverage: coverage,
      nativeDistractingMinutes: nativeDistracting,
      manualScrollMinutes: manualMinutes,
      effectiveDistractingMinutes: effectiveDistracting,
      unlockCount: metric.unlockCount ?? 0,
    );
  }

  Stream<AttentionDay> watchTodayAttention() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final controller = StreamController<AttentionDay>();
    
    StreamSubscription? sub1;
    StreamSubscription? sub2;
    StreamSubscription? sub3;

    void update() async {
      try {
        final dayData = await getAttentionDay(today);
        if (!controller.isClosed) {
          controller.add(dayData);
        }
      } catch (_) {}
    }

    sub1 = (_db.select(_db.deviceDayMetrics)..where((t) => t.day.equals(today)))
        .watch()
        .listen((_) => update());
    sub2 = _db.deviceUsageRecordsDao.watchToday().listen((_) => update());
    sub3 = _db.scrollLogsDao.watchDailyTotal().listen((_) => update());

    controller.onCancel = () {
      sub1?.cancel();
      sub2?.cancel();
      sub3?.cancel();
    };

    update();
    return controller.stream;
  }

  Future<int> _getManualScrollMinutes(DateTime targetDate) async {
    final start = DateTime(targetDate.year, targetDate.month, targetDate.day);
    final logs = await (_db.select(_db.scrollLogs)
          ..where((l) =>
              l.timestamp.isBiggerOrEqualValue(start) &
              l.timestamp.isSmallerThanValue(start.add(const Duration(days: 1))) &
              // manual only: exclude any historical logs containing "[Auto]" or " [Auto]"
              l.appName.like('% [Auto]').not()))
        .get();
    return logs.fold<int>(0, (sum, l) => sum + l.durationMinutes);
  }



  String? _inferCategory(String packageName) {
    if (packageName.contains('instagram') ||
        packageName.contains('twitter') ||
        packageName.contains('reddit') ||
        packageName.contains('facebook')) {
      return 'social';
    }
    if (packageName.contains('youtube') ||
        packageName.contains('tiktok') ||
        packageName.contains('netflix')) {
      return 'entertainment';
    }
    if (packageName.contains('chrome') || packageName.contains('browser')) {
      return 'utility';
    }
    return null;
  }

  Future<void> deleteInterruptionHistory() async {
    // 1. Clear daily notification totals
    await _db.notificationDailyCountsDao.clearAll();

    // 2. Set current day's unlockCount to null, and coverage to partial
    final today = DateTime.now();
    final date = DateTime(today.year, today.month, today.day);
    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    
    await _db.deviceDayMetricsDao.upsertMetric(DeviceDayMetricsCompanion(
      id: Value('${dateStr}_android'),
      day: Value(date),
      platform: const Value('android'),
      unlockCount: const Value(null),
      unlockCoverage: const Value('partial'),
      notificationCoverage: const Value('partial'),
      usageSyncedAt: Value(DateTime.now()),
    ));

    // 3. Set a SharedPreferences timestamp to prevent re-importing old keyguard events
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('flowos_unlocks_deleted_timestamp', DateTime.now().millisecondsSinceEpoch);

    // 4. Wipe native pending notification tracker map
    if (Platform.isAndroid) {
      await DeviceAttentionPlatform._channel.invokeMethod('wipeNotificationTracker');
    }
  }

  Future<void> resetAllLocalData() async {
    // 1. Purge all tables in SQLite
    await _db.clearAllData();

    // 2. Wipe native notification tracker batches
    if (Platform.isAndroid) {
      await DeviceAttentionPlatform._channel.invokeMethod('wipeNotificationTracker');
    }

    // 3. Clear SharedPreferences configs
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('flowos_sleep_config');
    await prefs.remove('flowos_active_policies');
    await prefs.remove('flowos_interruption_collection_enabled');
    await prefs.remove('flutter.flowos_pending_trigger');
    await prefs.remove('flutter.flowos_nudge_events');
  }
}

final deviceAttentionPlatformProvider = Provider<DeviceAttentionPlatform>((ref) {
  return DeviceAttentionPlatform();
});

final attentionDataRepositoryProvider = Provider<AttentionDataRepository>((ref) {
  final db = ref.watch(databaseProvider);
  final platform = ref.watch(deviceAttentionPlatformProvider);
  return AttentionDataRepository(db, platform);
});
