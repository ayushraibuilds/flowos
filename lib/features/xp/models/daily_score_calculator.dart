import '../../../core/constants/xp_constants.dart';
import '../../attention/repository/attention_data_repository.dart';

/// Rich daily score result carrying scores, status, and breakdown.
class DailyScoreResult {
  final int score;
  final String? grade; // null when incomplete
  final String message;
  final bool isIncomplete;
  final double availableWeight; // 1.0 when complete, 0.75 when Attention is omitted
  final String coverageLabel;
  final int scoringVersion;

  // Pillar points contributions (weighted)
  final double focusPoints;
  final double intentPoints;
  final double? attentionPoints; // null when omitted
  final double carePoints;

  const DailyScoreResult({
    required this.score,
    required this.grade,
    required this.message,
    required this.isIncomplete,
    required this.availableWeight,
    required this.coverageLabel,
    required this.scoringVersion,
    required this.focusPoints,
    required this.intentPoints,
    required this.attentionPoints,
    required this.carePoints,
  });

  Map<String, dynamic> toJson() {
    return {
      'score': score,
      'grade': grade,
      'message': message,
      'isIncomplete': isIncomplete,
      'availableWeight': availableWeight,
      'coverageLabel': coverageLabel,
      'scoringVersion': scoringVersion,
      'focusPoints': focusPoints,
      'intentPoints': intentPoints,
      'attentionPoints': attentionPoints,
      'carePoints': carePoints,
    };
  }
}

/// Daily Score Calculator — V2 Scoring Engine (the "honest mirror").
/// Computes a 0-100 score based on focus sessions, tasks/MITs, distractions, and recovery/care.
class DailyScoreCalculator {
  /// Calculate the full daily score V2.
  static DailyScoreResult calculate({
    required int focusMinutes,
    required int mitsCompleted, // 0-3
    required int scrollMinutes,
    required int scrollBudget,
    required bool intentionCompleted,
    required bool shutdownCompleted,
    required int energyCheckIns, // 0-3
    required int recoveryActions, // scroll log recovery count
    required DataCoverage attentionCoverage,
  }) {
    final double focusScore = _focusScore(focusMinutes);
    final double mitScore = (mitsCompleted / 3.0 * 100.0).clamp(0.0, 100.0);
    final double intentionScore = intentionCompleted ? 100.0 : 0.0;
    
    // Care subweights: exactly 1/3 each
    final double recoveryScore = recoveryActions == 0 ? 0.0 : (recoveryActions == 1 ? 50.0 : 100.0);
    final double ritualShutdownScore = shutdownCompleted ? 100.0 : 0.0;
    final double energyScore = (energyCheckIns / 3.0 * 100.0).clamp(0.0, 100.0);
    final double careScore = (recoveryScore + ritualShutdownScore + energyScore) / 3.0;

    final double focusPoints = focusScore * XpConstants.focusWeight;
    final double intentPoints = (mitScore * 0.8 + intentionScore * 0.2) * XpConstants.intentWeight;
    final double carePoints = careScore * XpConstants.careWeight;

    // Check if attention data is incomplete or legacy manual-only
    final bool incompleteAttention = attentionCoverage != DataCoverage.complete;

    if (incompleteAttention) {
      // Omit Attention pillar (0.25 weight) and normalize the remaining 0.75 weight (Focus 0.35, Intent 0.25, Care 0.15)
      final double rawSum = focusPoints + intentPoints + carePoints;
      final double availableWeight = 0.75;
      final int normalizedScore = (rawSum / availableWeight).round().clamp(0, 100);

      return DailyScoreResult(
        score: normalizedScore,
        grade: null, // No letter grade for incomplete days
        message: "Coverage incomplete. Keep building your daily rhythm.",
        isIncomplete: true,
        availableWeight: availableWeight,
        coverageLabel: "Incomplete — attention data unavailable",
        scoringVersion: XpConstants.currentScoringVersion,
        focusPoints: focusPoints,
        intentPoints: intentPoints,
        attentionPoints: null,
        carePoints: carePoints,
      );
    }

    // Complete coverage: calculate Attention
    final double attentionScore = _attentionScore(scrollMinutes, scrollBudget);
    final double attentionPoints = attentionScore * XpConstants.attentionWeight;

    final double rawSum = focusPoints + intentPoints + attentionPoints + carePoints;
    final int finalScore = rawSum.round().clamp(0, 100);
    final String grade = gradeFromScore(finalScore);

    return DailyScoreResult(
      score: finalScore,
      grade: grade,
      message: messageForGrade(grade),
      isIncomplete: false,
      availableWeight: 1.0,
      coverageLabel: "Complete",
      scoringVersion: XpConstants.currentScoringVersion,
      focusPoints: focusPoints,
      intentPoints: intentPoints,
      attentionPoints: attentionPoints,
      carePoints: carePoints,
    );
  }

  /// Focus score (0-100): based on total focus minutes.
  /// 0 min = 0, 60 min = 60, 120 min = 85, 180+ min = 100
  static double _focusScore(int minutes) {
    if (minutes <= 0) return 0;
    if (minutes >= 180) return 100;
    if (minutes >= 120) return 85 + (15.0 * (minutes - 120) / 60.0);
    if (minutes >= 60) return 60 + (25.0 * (minutes - 60) / 60.0);
    return (60.0 * minutes / 60.0);
  }

  /// Attention score (0-100): how well you stayed within scroll budget.
  /// Under budget = 100, at budget = 60, 2x budget = 0
  static double _attentionScore(int scrollMinutes, int budget) {
    if (budget <= 0) {
      // No budget set — full score if no scrolling, else scale
      return scrollMinutes == 0 ? 100.0 : (100.0 - scrollMinutes * 2.0).clamp(0.0, 100.0);
    }

    if (scrollMinutes <= 0) return 100.0;
    if (scrollMinutes <= budget) {
      // Within budget: 100 → 60
      return 100.0 - (40.0 * scrollMinutes / budget);
    }
    // Over budget: 60 → 0
    final double overRatio = (scrollMinutes - budget) / budget;
    return (60.0 - 60.0 * overRatio).clamp(0.0, 100.0);
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
