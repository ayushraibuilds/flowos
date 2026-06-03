import 'package:shared_preferences/shared_preferences.dart';

/// Streak Service — grace day logic.
///
/// Rules:
/// - Miss 1 day → streak PAUSED (not reset). Resume counts from pause.
/// - Miss 2 consecutive days → streak RESET to 0.
/// - A "day" counts if you earned any XP that day.
class StreakService {
  static const _keyStreak = 'flowos_streak_count';
  static const _keyLastActive = 'flowos_streak_last_active';
  static const _keyPaused = 'flowos_streak_paused';
  static const _keyBestStreak = 'flowos_best_streak';

  /// Get current streak count
  static Future<int> getStreak() async {
    final prefs = await SharedPreferences.getInstance();
    await _checkAndUpdate(prefs);
    return prefs.getInt(_keyStreak) ?? 0;
  }

  /// Get best streak ever
  static Future<int> getBestStreak() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyBestStreak) ?? 0;
  }

  /// Check if streak is paused (1 grace day used)
  static Future<bool> isPaused() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyPaused) ?? false;
  }

  /// Record activity for today — call this whenever XP is earned.
  static Future<void> recordActivity() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _todayKey();
    final lastActive = prefs.getString(_keyLastActive);

    if (lastActive == today) return; // Already recorded today

    final streak = prefs.getInt(_keyStreak) ?? 0;
    final wasPaused = prefs.getBool(_keyPaused) ?? false;

    if (lastActive == null) {
      // First day ever
      await prefs.setInt(_keyStreak, 1);
    } else {
      final lastDate = DateTime.parse(lastActive);
      final daysSince = DateTime.now().difference(lastDate).inDays;

      if (daysSince == 1) {
        // Consecutive day — increment streak
        await prefs.setInt(_keyStreak, streak + 1);
        await prefs.setBool(_keyPaused, false);
      } else if (daysSince == 2 && !wasPaused) {
        // 1 day missed — grace day, pause streak
        await prefs.setBool(_keyPaused, true);
        // Don't increment, but don't reset
      } else {
        // 2+ days missed — reset
        await prefs.setInt(_keyStreak, 1);
        await prefs.setBool(_keyPaused, false);
      }
    }

    await prefs.setString(_keyLastActive, today);

    // Update best streak
    final current = prefs.getInt(_keyStreak) ?? 0;
    final best = prefs.getInt(_keyBestStreak) ?? 0;
    if (current > best) {
      await prefs.setInt(_keyBestStreak, current);
    }
  }

  /// Check and update streak status (called on app open).
  static Future<void> _checkAndUpdate(SharedPreferences prefs) async {
    final lastActive = prefs.getString(_keyLastActive);
    if (lastActive == null) return;

    final lastDate = DateTime.parse(lastActive);
    final daysSince = DateTime.now().difference(lastDate).inDays;
    final wasPaused = prefs.getBool(_keyPaused) ?? false;

    if (daysSince >= 3) {
      // 3+ days — definitely reset
      await prefs.setInt(_keyStreak, 0);
      await prefs.setBool(_keyPaused, false);
    } else if (daysSince == 2 && wasPaused) {
      // Already paused and missed another day — reset
      await prefs.setInt(_keyStreak, 0);
      await prefs.setBool(_keyPaused, false);
    }
  }

  static String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}
