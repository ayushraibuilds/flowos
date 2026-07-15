import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import '../../../data/local/database/app_database.dart';
import '../services/sleep_config_writer.dart';

class SleepModeNotifier extends StateNotifier<SleepSchedule?> {
  final AppDatabase _db;
  final SleepConfigWriter _configWriter;

  SleepModeNotifier(this._db, this._configWriter) : super(null) {
    load();
  }

  Future<void> load() async {
    var schedule = await _db.sleepSchedulesDao.getSchedule('default');
    if (schedule == null) {
      // Initialize with defaults: 22:30 Bedtime, 07:00 Wake time, Everyday, Enabled = false, Guard protectionLevel
      final weekdaysJson = jsonEncode([1, 2, 3, 4, 5, 6, 7]);
      final companion = SleepSchedulesCompanion.insert(
        id: 'default',
        weekdays: weekdaysJson,
        bedtimeMinute: 1350, // 22:30
        wakeMinute: 420,     // 07:00
        timezoneId: 'UTC',   // default placeholder
        protectionLevel: 'guard',
        enabled: false,
      );
      await _db.sleepSchedulesDao.upsertSchedule(companion);
      schedule = await _db.sleepSchedulesDao.getSchedule('default');
    }
    state = schedule;
    await _configWriter.writeSleepConfig();
  }

  Future<void> toggleEnabled(bool enabled) async {
    final current = state;
    if (current == null) return;

    final updated = SleepSchedulesCompanion(
      id: const Value('default'),
      enabled: Value(enabled),
      weekdays: Value(current.weekdays),
      bedtimeMinute: Value(current.bedtimeMinute),
      wakeMinute: Value(current.wakeMinute),
      timezoneId: Value(current.timezoneId),
      protectionLevel: Value(current.protectionLevel),
    );

    await _db.sleepSchedulesDao.upsertSchedule(updated);
    state = await _db.sleepSchedulesDao.getSchedule('default');
    await _configWriter.writeSleepConfig();
  }

  Future<bool> updateTimes({
    required int bedtimeMinute,
    required int wakeMinute,
    required List<int> weekdays,
    required String protectionLevel,
  }) async {
    // Validate bedtimeMinute != wakeMinute
    if (bedtimeMinute == wakeMinute) {
      return false;
    }

    final weekdaysJson = jsonEncode(weekdays);

    final updated = SleepSchedulesCompanion(
      id: const Value('default'),
      enabled: const Value(true), // Turn on if updated
      weekdays: Value(weekdaysJson),
      bedtimeMinute: Value(bedtimeMinute),
      wakeMinute: Value(wakeMinute),
      timezoneId: const Value('UTC'),
      protectionLevel: Value(protectionLevel),
    );

    await _db.sleepSchedulesDao.upsertSchedule(updated);
    state = await _db.sleepSchedulesDao.getSchedule('default');
    await _configWriter.writeSleepConfig();
    return true;
  }

  Future<void> updateProtectionLevel(String level) async {
    final current = state;
    if (current == null) return;

    final updated = SleepSchedulesCompanion(
      id: const Value('default'),
      enabled: Value(current.enabled),
      weekdays: Value(current.weekdays),
      bedtimeMinute: Value(current.bedtimeMinute),
      wakeMinute: Value(current.wakeMinute),
      timezoneId: Value(current.timezoneId),
      protectionLevel: Value(level),
    );

    await _db.sleepSchedulesDao.upsertSchedule(updated);
    state = await _db.sleepSchedulesDao.getSchedule('default');
    await _configWriter.writeSleepConfig();
  }
}

/// Provider for SleepConfigWriter
final sleepConfigWriterProvider = Provider<SleepConfigWriter>((ref) {
  final db = ref.watch(databaseProvider);
  return SleepConfigWriter(db);
});

/// Provider for SleepMode State
final sleepModeProvider = StateNotifierProvider<SleepModeNotifier, SleepSchedule?>((ref) {
  final db = ref.watch(databaseProvider);
  final writer = ref.watch(sleepConfigWriterProvider);
  return SleepModeNotifier(db, writer);
});
