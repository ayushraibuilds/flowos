import 'package:flutter_test/flutter_test.dart';

import 'package:flowos/features/xp/models/daily_score_calculator.dart';
import 'package:flowos/features/attention/repository/attention_data_repository.dart';

void main() {
  group('DailyScoreCalculator Coverage Tests', () {
    test('unconnected coverage omits attention and normalizes other weights', () {
      // If coverage is notConnected:
      // Focus minutes 180 -> focusScore = 100
      // mitsCompleted 3 -> mitScore = 100
      // intentionCompleted, shutdownCompleted, energyCheckIns 3 -> ritualScore = 100
      // Normalized score = 100 * 0.4375 + 100 * 0.375 + 100 * 0.1875 = 100
      final score = DailyScoreCalculator.calculate(
        focusMinutes: 180,
        mitsCompleted: 3,
        scrollMinutes: 100, // ignored
        scrollBudget: 30,
        intentionCompleted: true,
        shutdownCompleted: true,
        energyCheckIns: 3,
        attentionCoverage: DataCoverage.notConnected,
      );
      expect(score, 100);
    });

    test('unsupported coverage omits attention and normalizes other weights', () {
      final score = DailyScoreCalculator.calculate(
        focusMinutes: 60, // focusScore = 60
        mitsCompleted: 1, // mitScore = 33.333333333333336
        scrollMinutes: 50, // ignored
        scrollBudget: 30,
        intentionCompleted: false,
        shutdownCompleted: false,
        energyCheckIns: 0, // ritualScore = 0
        attentionCoverage: DataCoverage.unsupported,
      );
      // Expected normalized score: (60 * 0.4375) + (33.333333333333336 * 0.375) = 26.25 + 12.5 = 38.75 -> round to 39
      expect(score, 39);
    });

    test('complete coverage uses full formula with attention cost', () {
      final score = DailyScoreCalculator.calculate(
        focusMinutes: 180,
        mitsCompleted: 3,
        scrollMinutes: 60, // 2x budget -> attentionScore = 0
        scrollBudget: 30,
        intentionCompleted: true,
        shutdownCompleted: true,
        energyCheckIns: 3,
        attentionCoverage: DataCoverage.complete,
      );
      // Expected: Focus 100 * 0.35 + MIT 100 * 0.30 + Attention 0 * 0.20 + Ritual 100 * 0.15 = 80
      expect(score, 80);
    });
  });
}
