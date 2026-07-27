import 'package:flutter/foundation.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// FlowOS Timezone Service — manages device IANA timezone discovery,
/// test overrides, and fallback handling for recurring notifications.
class TimezoneService {
  static String? _overrideTimezone;
  static bool _tzDataInitialized = false;

  /// Override timezone for unit & integration testing (e.g. 'Asia/Kolkata', 'America/New_York', 'UTC').
  static void setOverrideTimezoneForTesting(String? timezone) {
    _overrideTimezone = timezone;
  }

  /// Discover device IANA timezone string (or test override).
  static Future<String> getDeviceTimezoneName() async {
    if (_overrideTimezone != null && _overrideTimezone!.isNotEmpty) {
      return _overrideTimezone!;
    }
    try {
      final String deviceTz = await FlutterTimezone.getLocalTimezone();
      if (deviceTz.isNotEmpty) {
        return deviceTz;
      }
    } catch (e) {
      debugPrint(
        '⚠️ FlutterTimezone discovery failed ($e) — falling back to UTC.',
      );
    }
    return 'UTC';
  }

  /// Initialize IANA timezone database and set `tz.local` to the device's actual timezone.
  /// Falls back safely to 'UTC' on resolution failure.
  static Future<tz.Location> initializeLocalTimezone() async {
    if (!_tzDataInitialized) {
      tz.initializeTimeZones();
      _tzDataInitialized = true;
    }

    final timezoneName = await getDeviceTimezoneName();
    tz.Location resolvedLocation;

    try {
      resolvedLocation = tz.getLocation(timezoneName);
    } catch (e) {
      debugPrint(
        '⚠️ Timezone "$timezoneName" not found in IANA database ($e) — falling back to UTC.',
      );
      resolvedLocation = tz.getLocation('UTC');
    }

    tz.setLocalLocation(resolvedLocation);
    debugPrint(
      '🔔 Local timezone initialized: ${resolvedLocation.name} (offset: ${resolvedLocation.currentTimeZone.offset / 1000}s)',
    );
    return resolvedLocation;
  }

  /// Current configured local timezone location.
  static tz.Location get currentLocalLocation => tz.local;

  /// Current configured local timezone name.
  static String get currentLocalTimezoneName => tz.local.name;
}
