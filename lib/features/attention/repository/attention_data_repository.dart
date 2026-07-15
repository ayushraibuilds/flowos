import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../data/local/database/app_database.dart';

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

  Future<void> syncUsage({int days = 1}) async {
    if (!Platform.isAndroid) return;

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
      final rawUsage = await _platform.getDailyUsage(start, end);
      final rawUnlocks = await _platform.getDailyUnlockEvents(start, end);

      final prefs = await SharedPreferences.getInstance();
      final rawProfile = prefs.getString('flowos_user_profile');
      final watchlist = <String>{};
      if (rawProfile != null) {
        try {
          final json = jsonDecode(rawProfile) as Map<String, dynamic>;
          final distractions = List<String>.from(json['distractions'] ?? []);
          for (final d in distractions) {
            final pkg = _mapToPackageName(d);
            if (pkg != null) watchlist.add(pkg);
          }
        } catch (_) {}
      }

      for (final row in rawUsage) {
        final dateStr = row['date'] as String;
        final packageName = row['packageName'] as String;
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

      for (int i = 0; i < days; i++) {
        final d = now.subtract(Duration(days: i));
        final date = DateTime(d.year, d.month, d.day);
        final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        final unlocks = unlockMap[dateStr];

        await _db.deviceDayMetricsDao.upsertMetric(DeviceDayMetricsCompanion(
          id: Value('${dateStr}_android'),
          day: Value(date),
          platform: const Value('android'),
          unlockCount: Value(unlocks),
          coverageState: const Value('complete'),
          usageSyncedAt: Value(DateTime.now()),
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
    if (metric == null || metric.coverageState == 'notConnected') {
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

    return AttentionDay(
      day: targetDate,
      coverage: DataCoverage.complete,
      nativeDistractingMinutes: nativeDistracting,
      manualScrollMinutes: manualMinutes,
      effectiveDistractingMinutes: nativeDistracting,
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

  String? _mapToPackageName(String label) {
    return switch (label.toLowerCase()) {
      'instagram' => 'com.instagram.android',
      'youtube/shorts' || 'youtube' => 'com.google.android.youtube',
      'tiktok' => 'com.zhiliaoapp.musically',
      'x/twitter' || 'twitter' || 'x' => 'com.twitter.android',
      'reddit' => 'com.reddit.frontpage',
      'browser' => 'com.android.chrome',
      _ => null,
    };
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
}

final deviceAttentionPlatformProvider = Provider<DeviceAttentionPlatform>((ref) {
  return DeviceAttentionPlatform();
});

final attentionDataRepositoryProvider = Provider<AttentionDataRepository>((ref) {
  final db = ref.watch(databaseProvider);
  final platform = ref.watch(deviceAttentionPlatformProvider);
  return AttentionDataRepository(db, platform);
});
