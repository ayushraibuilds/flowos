import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../models/weekly_action.dart';

class DailyActionEngine {
  static WeeklyAction generateDailyAction({
    required int todayFocusMinutes,
    required int todayScrollMinutes,
    required int todayScrollBudget,
    required int todayMitsCompleted,
  }) {
    // Rule 1: Scroll exceeded budget
    if (todayScrollMinutes > todayScrollBudget) {
      return WeeklyAction(
        id: _generateId('daily_reduce_scroll'),
        type: WeeklyActionType.reduceOneTrigger,
        description: 'Set a tighter scroll budget of ${todayScrollBudget - 5 > 5 ? todayScrollBudget - 5 : 5} minutes for tomorrow.',
      );
    }

    // Rule 2: Missed MITs target
    if (todayMitsCompleted < 3) {
      return WeeklyAction(
        id: _generateId('daily_mit_reset'),
        type: WeeklyActionType.scheduleFocusWindow,
        description: 'Schedule your first MIT during your protected window tomorrow.',
      );
    }

    // Rule 3: Maintain momentum
    return WeeklyAction(
      id: _generateId('daily_momentum'),
      type: WeeklyActionType.scheduleFocusWindow,
      description: 'Schedule one 45-minute focus session for tomorrow morning.',
      startHour: 9,
      endHour: 10,
    );
  }

  static String _generateId(String seed) {
    final bytes = utf8.encode(seed);
    return sha1.convert(bytes).toString().substring(0, 12);
  }
}
