import '../../../core/constants/xp_constants.dart';
import '../../attention/repository/attention_data_repository.dart';

/// Daily Score Calculator — the "honest mirror."
/// Computes a 0-100 score that resets every day. No lifetime impact.
///
/// Formula:
///   (focusScore × 0.35) + (mitScore × 0.30) +
///   (attentionScore × 0.20) + (ritualScore × 0.15)
class DailyScoreCalculator {
  /// Calculate the full daily score.
  static int calculate({
    required int focusMinutes,
    required int mitsCompleted, // 0-3
    required int scrollMinutes,
    required int scrollBudget,
    required bool intentionCompleted,
    required bool shutdownCompleted,
    required int energyCheckIns, // 0-3
    DataCoverage attentionCoverage = DataCoverage.complete,
  }) {
    final focusScore = _focusScore(focusMinutes);
    final mitScore = _mitScore(mitsCompleted);
    final ritualScore = _ritualScore(
      intentionCompleted: intentionCompleted,
      shutdownCompleted: shutdownCompleted,
      energyCheckIns: energyCheckIns,
    );

    if (attentionCoverage == DataCoverage.notConnected ||
        attentionCoverage == DataCoverage.unsupported) {
      // Omit attention pillar, normalize remaining weights (Focus 0.35, MIT 0.30, Ritual 0.15)
      // Normalized: Focus = 0.35 / 0.8 = 0.4375, MIT = 0.30 / 0.8 = 0.375, Ritual = 0.15 / 0.8 = 0.1875
      final raw = (focusScore * 0.4375) +
          (mitScore * 0.375) +
          (ritualScore * 0.1875);
      return raw.round().clamp(0, 100);
    }

    final attentionScore = _attentionScore(scrollMinutes, scrollBudget);

    final raw = (focusScore * XpConstants.focusWeight) +
        (mitScore * XpConstants.mitWeight) +
        (attentionScore * XpConstants.attentionWeight) +
        (ritualScore * XpConstants.ritualWeight);

    return raw.round().clamp(0, 100);
  }

  /// Focus score (0-100): based on total focus minutes.
  /// 0 min = 0, 60 min = 60, 120 min = 85, 180+ min = 100
  static double _focusScore(int minutes) {
    if (minutes <= 0) return 0;
    if (minutes >= 180) return 100;
    if (minutes >= 120) return 85 + (15 * (minutes - 120) / 60);
    if (minutes >= 60) return 60 + (25 * (minutes - 60) / 60);
    return (60 * minutes / 60);
  }

  /// MIT score (0-100): 0/3=0, 1/3=33, 2/3=67, 3/3=100
  static double _mitScore(int completed) {
    return (completed / 3 * 100).clamp(0, 100);
  }

  /// Attention score (0-100): how well you stayed within scroll budget.
  /// Under budget = 100, at budget = 60, 2x budget = 0
  static double _attentionScore(int scrollMinutes, int budget) {
    if (budget <= 0) {
      // No budget set — full score if no scrolling, else scale
      return scrollMinutes == 0 ? 100 : (100 - scrollMinutes * 2.0).clamp(0, 100);
    }

    if (scrollMinutes <= 0) return 100;
    if (scrollMinutes <= budget) {
      // Within budget: 100 → 60
      return 100 - (40 * scrollMinutes / budget);
    }
    // Over budget: 60 → 0
    final overRatio = (scrollMinutes - budget) / budget;
    return (60 - 60 * overRatio).clamp(0, 100);
  }

  /// Ritual score (0-100): morning intention + shutdown + energy check-ins
  static double _ritualScore({
    required bool intentionCompleted,
    required bool shutdownCompleted,
    required int energyCheckIns,
  }) {
    double score = 0;
    if (intentionCompleted) score += 35;
    if (shutdownCompleted) score += 35;
    score += (energyCheckIns / 3 * 30).clamp(0, 30);
    return score.clamp(0, 100);
  }

  /// Get letter grade from score
  static String gradeFromScore(int score) {
    if (score >= 90) return 'A+';
    if (score >= 80) return 'A';
    if (score >= 70) return 'B';
    if (score >= 55) return 'C';
    if (score >= 40) return 'D';
    return 'F';
  }

  /// Get motivational message for grade
  static String messageForGrade(String grade) => switch (grade) {
    'A+' => "Legendary day. You crushed it. 🏆",
    'A' => "Exceptional focus. This is what flow looks like. 🔥",
    'B' => "Solid effort. Momentum is building. ⚡",
    'C' => "Decent day. Small adjustments, big impact tomorrow. 🌱",
    'D' => "Rough start. Recovery is strength, not weakness. 💪",
    _ => "Tomorrow is fresh. Show up, that's all that matters. 🌅",
  };
}
