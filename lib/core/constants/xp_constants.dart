/// FlowOS XP System Constants
///
/// EARNING: Lifetime XP — only goes up. Never negative.
/// ATTENTION COST: Daily Score impact — can be negative, resets daily.
/// ANTI-GAMING: Daily caps prevent exploit strategies.
abstract final class XpConstants {
  // ─── EARNING (lifetime XP — only goes up) ──────────────────────

  /// Completing a Pomodoro session (25 min)
  static const int pomodoroComplete = 40;

  /// Completing a Deep Work session (90 min)
  static const int deepWorkComplete = 120;

  /// Completing any task
  static const int taskComplete = 20;

  /// Completing a MIT (Most Important Task)
  static const int mitComplete = 75;

  /// All 3 MITs done in one day
  static const int allMitsDaily = 100;

  /// Starting work before 8 AM
  static const int earlyStart = 30;

  /// Using break content (riddle/fact/breathing)
  static const int breakContentUsed = 15;

  /// 7-day streak bonus
  static const int sevenDayStreak = 200;

  /// All 3 energy check-ins in one day
  static const int energyCheckin3x = 20;

  /// Completing focus ritual (pre-focus checklist)
  static const int focusRitualComplete = 10;

  /// Completing shutdown ritual (end of day)
  static const int shutdownRitualComplete = 25;

  /// Recovery action after scrolling
  static const int bounceBackBonus = 25;

  // ─── ATTENTION COST (daily score impact only) ──────────────────

  /// Daily score penalty per 10 min of scroll time
  static const int scrollCostPer10Min = -5;

  /// Daily score penalty for incomplete MIT
  static const int mitIncompleteCost = -10;

  /// Daily score penalty for abandoned session (< 60% completion)
  static const int sessionAbandonedCost = -5;

  // ─── ANTI-GAMING ───────────────────────────────────────────────

  /// Max XP from light tasks per day
  static const int dailyCapLightTasks = 200;

  /// Max total XP per day
  static const int dailyCapTotal = 2000;

  /// Standalone session multiplier (no task attached = 60% XP)
  static const double standaloneSessionMultiplier = 0.6;

  /// MITs added after this hour don't get MIT bonus
  static const int mitCutoffHour = 9;

  // ─── STREAK MULTIPLIERS ────────────────────────────────────────

  /// 7 consecutive days = 1.1x
  static const double streak7Multiplier = 1.1;

  /// 30 consecutive days = 1.25x
  static const double streak30Multiplier = 1.25;

  /// 100 consecutive days = 1.5x
  static const double streak100Multiplier = 1.5;

  /// Get streak multiplier for a given streak length
  static double streakMultiplier(int streakDays) {
    if (streakDays >= 100) return streak100Multiplier;
    if (streakDays >= 30) return streak30Multiplier;
    if (streakDays >= 7) return streak7Multiplier;
    return 1.0;
  }

  // ─── LEVELS ────────────────────────────────────────────────────

  /// XP required for a given level (quadratic scaling)
  static int xpForLevel(int level) => (level * level * 100).toInt();

  /// Current level from lifetime XP
  static int levelFromXP(int xp) {
    int level = 0;
    while (xpForLevel(level + 1) <= xp) {
      level++;
    }
    return level;
  }

  /// Level tier names
  static const tiers = [
    '🌱 Seedling',      // 0-4
    '⚡ Focuser',        // 5-14
    '🔥 Flow Rider',    // 15-24
    '🎯 Deep Worker',   // 25-34
    '🧠 Mind Master',   // 35-49
    '🌌 Flow State God', // 50+
  ];

  /// Get tier name for a given level
  static String tierName(int level) {
    if (level >= 50) return tiers[5];
    if (level >= 35) return tiers[4];
    if (level >= 25) return tiers[3];
    if (level >= 15) return tiers[2];
    if (level >= 5) return tiers[1];
    return tiers[0];
  }

  // ─── DAILY SCORE FORMULA ───────────────────────────────────────

  /// Daily score weights
  static const double focusWeight = 0.35;
  static const double intentWeight = 0.25;
  static const double attentionWeight = 0.25;
  static const double careWeight = 0.15;

  static const int currentScoringVersion = 2;
}
