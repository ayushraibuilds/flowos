import 'package:flutter_test/flutter_test.dart';
import 'package:flowos/data/local/database/app_database.dart';
import 'package:flowos/data/local/tables/focus_sessions_table.dart';
import 'package:flowos/features/rhythm/services/rhythm_engine.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;

void main() {
  group('RhythmEngine Tests', () {
    test('Returns null if sessions count is less than threshold', () {
      final sessions = List<FocusSession>.generate(4, (i) => FocusSession(
        id: 'session_$i',
        sessionType: SessionTypeColumn.pomodoro,
        durationMinutes: 25,
        actualMinutes: 25,
        startedAt: DateTime.now().subtract(Duration(days: i)),
        completedAt: DateTime.now().subtract(Duration(days: i)),
        xpEarned: 25,
        qualityScore: 'A',
        pauseCount: 0,
        appBackgroundCount: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      final rec = RhythmEngine.generateRecommendation(sessions);
      expect(rec, isNull);
    });

    test('Returns null if distinct days count is less than threshold', () {
      // 10 sessions all logged on same day
      final now = DateTime.now();
      final sessions = List<FocusSession>.generate(10, (i) => FocusSession(
        id: 'session_$i',
        sessionType: SessionTypeColumn.pomodoro,
        durationMinutes: 25,
        actualMinutes: 25,
        startedAt: now,
        completedAt: now,
        xpEarned: 25,
        qualityScore: 'B',
        pauseCount: 0,
        appBackgroundCount: 0,
        createdAt: now,
        updatedAt: now,
      ));

      final rec = RhythmEngine.generateRecommendation(sessions);
      expect(rec, isNull);
    });

    test('Identifies the peak 2-hour window and preferred weekday correctly', () {
      final baseDate = DateTime(2026, 7, 13, 9, 30); // 9:30 AM is in 8-10 window
      // Monday = 1. We will log 5 sessions in 8-10 window on Mondays (baseDate - 7 days, etc.)
      final sessions = <FocusSession>[];

      // Add 6 sessions in 8-10 AM window on Mondays
      for (int i = 0; i < 6; i++) {
        final date = baseDate.subtract(Duration(days: i * 7)); // all Mondays
        sessions.add(FocusSession(
          id: 'mon_session_$i',
          sessionType: SessionTypeColumn.pomodoro,
          durationMinutes: 25,
          actualMinutes: 25,
          startedAt: date,
          completedAt: date,
          xpEarned: 25,
          qualityScore: 'A',
          pauseCount: 0,
          appBackgroundCount: 0,
          createdAt: date,
          updatedAt: date,
        ));
      }

      // Add 4 other random sessions at 4 PM (16:00, in 16-18 window) on other days (Tues, Wed, etc.)
      for (int i = 1; i <= 4; i++) {
        final date = DateTime(2026, 7, 13 + i, 16, 30); // Tue, Wed, Thu, Fri
        sessions.add(FocusSession(
          id: 'other_session_$i',
          sessionType: SessionTypeColumn.pomodoro,
          durationMinutes: 25,
          actualMinutes: 25,
          startedAt: date,
          completedAt: date,
          xpEarned: 25,
          qualityScore: 'C',
          pauseCount: 0,
          appBackgroundCount: 0,
          createdAt: date,
          updatedAt: date,
        ));
      }

      final rec = RhythmEngine.generateRecommendation(sessions);

      expect(rec, isNotNull);
      expect(rec!.windowStartHour, 8);
      expect(rec!.windowEndHour, 10);
      expect(rec!.preferredWeekday, 1); // Monday
      expect(rec.headline, contains('8 AM - 10 AM'));
      expect(rec.actionLabel, contains('Monday'));
      expect(rec.evidence, contains('6 sessions'));
      expect(rec.evidence, contains('Avg grade A'));
    });
  });
}
