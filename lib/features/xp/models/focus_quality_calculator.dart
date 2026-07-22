/// Focus Quality Calculator — grades a focus session A/B/C/D.
///
/// Factors:
/// - Completion percentage (did you finish the session?)
/// - Pause count (how many times you paused)
/// - App background count (how many times you left the app)
/// - Energy delta (energy before vs after — optional)
class FocusQualityCalculator {
  /// Calculate quality grade for a focus session.
  static String calculate({
    required int durationMinutes,
    required int actualMinutes,
    required int pauseCount,
    required int backgroundCount,
    int? energyBefore,
    int? energyAfter,
  }) {
    final score = _calculateScore(
      durationMinutes: durationMinutes,
      actualMinutes: actualMinutes,
      pauseCount: pauseCount,
      backgroundCount: backgroundCount,
      energyBefore: energyBefore,
      energyAfter: energyAfter,
    );

    if (score >= 90) return 'A';
    if (score >= 70) return 'B';
    if (score >= 50) return 'C';
    return 'D';
  }

  /// Calculate raw quality score (0-100).
  static int _calculateScore({
    required int durationMinutes,
    required int actualMinutes,
    required int pauseCount,
    required int backgroundCount,
    int? energyBefore,
    int? energyAfter,
  }) {
    double score = 100;

    // Completion ratio (0-40 points)
    final completion = durationMinutes > 0
        ? actualMinutes / durationMinutes
        : 1.0;
    score -= (1 - completion.clamp(0, 1)) * 40;

    // Pause penalty (-5 per pause, max -20)
    score -= (pauseCount * 5).clamp(0, 20);

    // Background penalty (-8 per background switch, max -25)
    score -= (backgroundCount * 8).clamp(0, 25);

    // Energy bonus: if energy went up or stayed same during session (+5)
    if (energyBefore != null && energyAfter != null) {
      if (energyAfter >= energyBefore) {
        score += 5;
      } else {
        score -= 5; // Energy dropped — slight penalty
      }
    }

    return score.round().clamp(0, 100);
  }

  /// Emoji for quality grade
  static String emoji(String grade) => switch (grade) {
    'A' => '🏆',
    'B' => '⚡',
    'C' => '🌱',
    _ => '💪',
  };

  /// Description for quality grade
  static String description(String grade) => switch (grade) {
    'A' => 'Pure flow. Zero distractions.',
    'B' => 'Solid focus. Minor breaks.',
    'C' => 'Decent effort. Room to improve.',
    _ => "Struggled, but you showed up. That counts.",
  };
}
