import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../../../data/local/database/app_database.dart';
import '../models/rhythm_recommendation.dart';

class RhythmEngine {
  static const int minSessions = 8;
  static const int minDistinctDays = 5;
  static const int minQualitySessions = 5;

  static RhythmRecommendation? generateRecommendation(List<FocusSession> sessions) {
    // 1. Filter: Completed sessions with actualMinutes >= 5
    final completed = sessions.where((s) => s.completedAt != null && s.actualMinutes >= 5).toList();

    // 2. Threshold checks
    if (completed.length < minSessions) return null;

    final distinctDays = completed.map((s) => s.startedAt.toIso8601String().split('T')[0]).toSet();
    if (distinctDays.length < minDistinctDays) return null;

    final qualitySessions = completed.where((s) => s.qualityScore.isNotEmpty).toList();
    if (qualitySessions.length < minQualitySessions) return null;

    // 3. Group by 2-hour windows (e.g. 0-2, 2-4, ...)
    final windows = <int, List<FocusSession>>{};
    for (final s in completed) {
      final hourBucket = (s.startedAt.hour ~/ 2) * 2;
      windows.putIfAbsent(hourBucket, () => []).add(s);
    }

    // 4. Score each bucket
    int? bestWindowStartHour;
    double bestScore = -1.0;
    List<FocusSession> bestWindowSessions = [];

    windows.forEach((startHour, list) {
      if (list.length >= 3) {
        double totalScore = 0.0;
        for (final s in list) {
          final double weight = switch (s.qualityScore) {
            'A' => 1.0,
            'B' => 0.85,
            'C' => 0.65,
            'D' => 0.40,
            _ => 0.50,
          };
          totalScore += s.actualMinutes * weight;
        }
        final double score = totalScore / list.length;
        if (score > bestScore) {
          bestScore = score;
          bestWindowStartHour = startHour;
          bestWindowSessions = list;
        }
      }
    });

    if (bestWindowStartHour == null) return null;

    final startHour = bestWindowStartHour!;
    final endHour = startHour + 2;

    // 5. Pick best weekday among those sessions in best window
    final weekdayCounts = <int, int>{};
    for (final s in bestWindowSessions) {
      weekdayCounts[s.startedAt.weekday] = (weekdayCounts[s.startedAt.weekday] ?? 0) + 1;
    }

    int bestWeekday = 1;
    int maxCount = -1;
    weekdayCounts.forEach((day, count) {
      if (count > maxCount) {
        maxCount = count;
        bestWeekday = day;
      }
    });

    // 6. Format details & evidence
    final weekdayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final weekdayName = weekdayNames[bestWeekday - 1];

    final startHourStr = _formatHour(startHour);
    final endHourStr = _formatHour(endHour);

    final totalMinutes = bestWindowSessions.fold<int>(0, (sum, s) => sum + s.actualMinutes);
    final totalHoursStr = (totalMinutes / 60.0).toStringAsFixed(1);

    // Calculate average quality grade
    double sumWeight = 0.0;
    int weightCount = 0;
    for (final s in bestWindowSessions) {
      if (s.qualityScore.isNotEmpty) {
        sumWeight += switch (s.qualityScore) {
          'A' => 1.0,
          'B' => 0.85,
          'C' => 0.65,
          'D' => 0.40,
          _ => 0.50,
        };
        weightCount++;
      }
    }
    final avgWeight = weightCount > 0 ? sumWeight / weightCount : 0.5;
    final avgGrade = avgWeight >= 0.90
        ? 'A'
        : avgWeight >= 0.75
            ? 'B'
            : avgWeight >= 0.50
                ? 'C'
                : 'D';

    final evidence = [
      '${bestWindowSessions.length} sessions',
      'Avg grade $avgGrade',
      '${totalHoursStr}h focus total',
    ];

    // Generate unique ID
    final idBytes = utf8.encode('rhythm_${startHour}_${endHour}_$bestWeekday');
    final id = sha1.convert(idBytes).toString().substring(0, 12);

    final timeOfDayPrefix = startHour < 12
        ? 'morning'
        : startHour < 17
            ? 'afternoon'
            : 'evening';

    return RhythmRecommendation(
      id: id,
      headline: 'Your highest-quality sessions land $startHourStr - $endHourStr',
      actionLabel: 'Protect $weekdayName $timeOfDayPrefix for your hardest MIT',
      windowStartHour: startHour,
      windowEndHour: endHour,
      preferredWeekday: bestWeekday,
      evidence: evidence,
      generatedAt: DateTime.now(),
    );
  }

  static String _formatHour(int hour) {
    if (hour == 0) return '12 AM';
    if (hour == 12) return '12 PM';
    return hour < 12 ? '$hour AM' : '${hour - 12} PM';
  }
}
