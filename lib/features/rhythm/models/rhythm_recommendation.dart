class RhythmRecommendation {
  final String id; // hash of window+weekday for dismiss/accept
  final String headline; // "Your highest-quality sessions land 9–11 AM"
  final String actionLabel; // "Protect Tuesday morning for your hardest MIT"
  final int windowStartHour;
  final int windowEndHour;
  final int? preferredWeekday; // 1=Mon … 7=Sun
  final List<String> evidence; // "12 sessions · avg grade B · 6.2h total"
  final DateTime generatedAt;

  const RhythmRecommendation({
    required this.id,
    required this.headline,
    required this.actionLabel,
    required this.windowStartHour,
    required this.windowEndHour,
    this.preferredWeekday,
    required this.evidence,
    required this.generatedAt,
  });
}
