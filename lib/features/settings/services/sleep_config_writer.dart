import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../data/local/database/app_database.dart';

class SleepConfigWriter {
  final AppDatabase _db;

  SleepConfigWriter(this._db);

  /// Regenerates and writes the versioned sleep configuration payload to native SharedPreferences.
  Future<void> writeSleepConfig() async {
    final schedule = await _db.sleepSchedulesDao.getSchedule('default');
    final prefs = await SharedPreferences.getInstance();

    if (schedule == null || !schedule.enabled) {
      // If disabled or non-existent, write disabled config
      final disabledConfig = {
        'schemaVersion': 1,
        'enabled': false,
        'bedtimeMinute': 1350, // 22:30 default
        'wakeMinute': 420,     // 07:00 default
        'weekdays': [1, 2, 3, 4, 5, 6, 7],
        'protectionLevel': 'guard',
        'selectedPackages': [],
      };
      await prefs.setString('flowos_sleep_config', jsonEncode(disabledConfig));
      return;
    }

    // Query packages that have protectsSleep set to true
    final sleepApps = await _db.protectedAppsDao.getSleepProtected();
    final selectedPackages = sleepApps.map((a) => a.appRef).toList();

    // Parse weekdays list from JSON
    List<int> weekdaysList = [1, 2, 3, 4, 5, 6, 7];
    try {
      final decoded = jsonDecode(schedule.weekdays);
      if (decoded is List) {
        weekdaysList = decoded.cast<int>();
      }
    } catch (_) {}

    final config = {
      'schemaVersion': 1,
      'enabled': schedule.enabled,
      'bedtimeMinute': schedule.bedtimeMinute,
      'wakeMinute': schedule.wakeMinute,
      'weekdays': weekdaysList,
      'protectionLevel': schedule.protectionLevel,
      'selectedPackages': selectedPackages,
    };

    await prefs.setString('flowos_sleep_config', jsonEncode(config));
  }
}
