import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../../../data/local/database/app_database.dart';
import '../../onboarding/models/user_profile.dart';
import '../../rhythm/services/rhythm_engine.dart';
import '../models/weekly_action.dart';

class WeeklyActionEngine {
  static WeeklyAction generateWeeklyAction({
    required List<FocusSession> sessions,
    required List<ScrollLog> scrollLogs,
    required List<Task> incompleteTasks,
    required UserProfile profile,
  }) {
    // Rule 1: If one distraction app > 40% of scroll -> reduceOneTrigger (that app)
    final totalScrollMin = scrollLogs.fold<int>(0, (sum, l) => sum + l.durationMinutes);
    if (totalScrollMin > 0) {
      final appDurations = <String, int>{};
      for (final l in scrollLogs) {
        appDurations[l.appName] = (appDurations[l.appName] ?? 0) + l.durationMinutes;
      }
      
      String? highestScrollApp;
      int maxScroll = -1;
      appDurations.forEach((app, min) {
        if (min > maxScroll) {
          maxScroll = min;
          highestScrollApp = app;
        }
      });
      
      if (highestScrollApp != null && (maxScroll / totalScrollMin) > 0.40) {
        final app = highestScrollApp!;
        return WeeklyAction(
          id: _generateId('reduce_$app'),
          type: WeeklyActionType.reduceOneTrigger,
          description: 'Treat $app as firm for 7 days (intent check-in gate required).',
          targetApp: app,
        );
      }
    }

    // Rule 2: Else if best quality window known (RhythmEngine) and user has incomplete tasks -> moveTaskToEnergy
    final rhythmRec = RhythmEngine.generateRecommendation(sessions);
    if (rhythmRec != null && incompleteTasks.isNotEmpty) {
      final task = incompleteTasks.first;
      final startHourStr = _formatHour(rhythmRec.windowStartHour);
      final endHourStr = _formatHour(rhythmRec.windowEndHour);
      return WeeklyAction(
        id: _generateId('move_${task.id}'),
        type: WeeklyActionType.moveTaskToEnergy,
        description: "Move '${task.title}' to your $startHourStr - $endHourStr deep window.",
        taskId: task.id,
        startHour: rhythmRec.windowStartHour,
        endHour: rhythmRec.windowEndHour,
        weekday: rhythmRec.preferredWeekday,
      );
    }

    // Rule 3: Else if focus minutes < 60 for week -> scheduleFocusWindow (25m tomorrow morning)
    final totalFocusMin = sessions.fold<int>(0, (sum, s) => sum + s.actualMinutes);
    if (totalFocusMin < 60) {
      return WeeklyAction(
        id: _generateId('schedule_morning_25'),
        type: WeeklyActionType.scheduleFocusWindow,
        description: 'Schedule one 25-minute focus window tomorrow at 9:00 AM.',
        startHour: 9,
        endHour: 10,
      );
    }

    // Rule 4: Else -> scheduleFocusWindow using protected window from onboarding
    final profileStartStr = _formatHour(profile.protectedStartHour);
    final profileEndStr = _formatHour(profile.protectedEndHour);
    return WeeklyAction(
      id: _generateId('schedule_onboarding_window'),
      type: WeeklyActionType.scheduleFocusWindow,
      description: 'Schedule focus window tomorrow during your protected hours ($profileStartStr - $profileEndStr).',
      startHour: profile.protectedStartHour,
      endHour: profile.protectedEndHour,
    );
  }

  static String _generateId(String seed) {
    final bytes = utf8.encode(seed);
    return sha1.convert(bytes).toString().substring(0, 12);
  }

  static String _formatHour(int hour) {
    if (hour == 0) return '12 AM';
    if (hour == 12) return '12 PM';
    return hour < 12 ? '$hour AM' : '${hour - 12} PM';
  }
}
