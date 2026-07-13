import 'package:flutter_test/flutter_test.dart';
import 'package:flowos/data/local/database/app_database.dart';
import 'package:flowos/features/onboarding/models/user_profile.dart';
import 'package:flowos/features/reports/models/weekly_action.dart';
import 'package:flowos/features/reports/services/weekly_action_engine.dart';
import 'package:flowos/data/local/tables/focus_sessions_table.dart';

void main() {
  group('WeeklyActionEngine Tests', () {
    test('Trigger rule 1 (distraction app > 40% of scroll)', () {
      final List<ScrollLog> logs = [
        ScrollLog(
          id: '1',
          appName: 'Instagram',
          durationMinutes: 30,
          dailyScoreImpact: -15,
          recoveryActionTaken: false,
          wasTimeboxed: false,
          timestamp: DateTime.now(),
        ),
        ScrollLog(
          id: '2',
          appName: 'YouTube',
          durationMinutes: 10,
          dailyScoreImpact: -5,
          recoveryActionTaken: false,
          wasTimeboxed: false,
          timestamp: DateTime.now(),
        ),
      ];
      final action = WeeklyActionEngine.generateWeeklyAction(
        sessions: [],
        scrollLogs: logs,
        incompleteTasks: [],
        profile: UserProfile.defaults(),
      );

      expect(action.type, WeeklyActionType.reduceOneTrigger);
      expect(action.targetApp, 'Instagram');
    });

    test('Trigger rule 3 (focus minutes < 60)', () {
      final action = WeeklyActionEngine.generateWeeklyAction(
        sessions: [],
        scrollLogs: [],
        incompleteTasks: [],
        profile: UserProfile.defaults(),
      );

      expect(action.type, WeeklyActionType.scheduleFocusWindow);
      expect(action.startHour, 9);
      expect(action.endHour, 10);
    });
  });
}
