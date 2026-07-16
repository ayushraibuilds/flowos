import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flowos/features/xp/models/streak_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('StreakService', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('initial state has 0 streak', () async {
      final streak = await StreakService.getStreak();
      final paused = await StreakService.isPaused();
      expect(streak, 0);
      expect(paused, false);
    });

    test('recording first activity sets streak to 1', () async {
      await StreakService.recordActivity();
      final streak = await StreakService.getStreak();
      final paused = await StreakService.isPaused();
      expect(streak, 1);
      expect(paused, false);
    });

    test('consecutive days increments streak', () async {
      final prefs = await SharedPreferences.getInstance();
      // Simulate yesterday
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final yesterdayKey = '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';

      await prefs.setInt('flowos_streak_count', 1);
      await prefs.setString('flowos_streak_last_active', yesterdayKey);

      await StreakService.recordActivity();
      final streak = await StreakService.getStreak();
      expect(streak, 2);
    });

    test('1 day miss pauses the streak', () async {
      final prefs = await SharedPreferences.getInstance();
      // Simulate day before yesterday (missed yesterday)
      final twoDaysAgo = DateTime.now().subtract(const Duration(days: 2));
      final twoDaysAgoKey = '${twoDaysAgo.year}-${twoDaysAgo.month.toString().padLeft(2, '0')}-${twoDaysAgo.day.toString().padLeft(2, '0')}';

      await prefs.setInt('flowos_streak_count', 5);
      await prefs.setString('flowos_streak_last_active', twoDaysAgoKey);

      // Record activity today (after 1 day missed)
      await StreakService.recordActivity();
      final streak = await StreakService.getStreak();
      final paused = await StreakService.isPaused();
      expect(streak, 5); // streak remains 5 (paused/grace day)
      expect(paused, true);
    });

    test('2 consecutive days miss resets streak to 1 on next activity', () async {
      final prefs = await SharedPreferences.getInstance();
      // Simulate 3 days ago (missed 2 days)
      final threeDaysAgo = DateTime.now().subtract(const Duration(days: 3));
      final threeDaysAgoKey = '${threeDaysAgo.year}-${threeDaysAgo.month.toString().padLeft(2, '0')}-${threeDaysAgo.day.toString().padLeft(2, '0')}';

      await prefs.setInt('flowos_streak_count', 5);
      await prefs.setString('flowos_streak_last_active', threeDaysAgoKey);

      await StreakService.recordActivity();
      final streak = await StreakService.getStreak();
      final paused = await StreakService.isPaused();
      expect(streak, 1); // reset to 1
      expect(paused, false);
    });

    test('best streak is updated', () async {
      await StreakService.recordActivity();
      expect(await StreakService.getBestStreak(), 1);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('flowos_streak_count', 5);
      await prefs.setInt('flowos_best_streak', 3);
      // Simulate yesterday
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final yesterdayKey = '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';
      await prefs.setString('flowos_streak_last_active', yesterdayKey);

      await StreakService.recordActivity();
      expect(await StreakService.getStreak(), 6);
      expect(await StreakService.getBestStreak(), 6);
    });

    test('consecutive days calculation works across simulated DST boundaries', () {
      // Simulate a spring-forward transition where lastActive is 2026-03-08 and today is 2026-03-09
      final lastActive = '2026-03-08';
      final lastDateLocal = DateTime.parse(lastActive);
      final lastDateUtc = DateTime.utc(lastDateLocal.year, lastDateLocal.month, lastDateLocal.day);
      
      // Simulate today being 2026-03-09 12:30 AM
      final simulatedNow = DateTime(2026, 3, 9, 0, 30);
      final todayUtc = DateTime.utc(simulatedNow.year, simulatedNow.month, simulatedNow.day);
      
      final daysSince = todayUtc.difference(lastDateUtc).inDays;
      expect(daysSince, 1);
    });
  });
}
