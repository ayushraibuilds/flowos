import 'package:flutter_test/flutter_test.dart';

import 'package:flowos/features/xp/models/daily_score_calculator.dart';
import 'package:flowos/features/attention/repository/attention_data_repository.dart';

void main() {
  group('DailyScoreCalculator Coverage Tests', () {
    test('unconnected coverage omits attention and normalizes other weights', () {
      final result = DailyScoreCalculator.calculate(
        focusMinutes: 180,
        mitsCompleted: 3,
        scrollMinutes: 100, // ignored
        scrollBudget: 30,
        intentionCompleted: true,
        shutdownCompleted: true,
        energyCheckIns: 3,
        recoveryActions: 0,
        attentionCoverage: DataCoverage.notConnected,
      );
      expect(result.score, 93);
      expect(result.isIncomplete, true);
      expect(result.grade, isNull);
    });

    test('unsupported coverage omits attention and normalizes other weights', () {
      final result = DailyScoreCalculator.calculate(
        focusMinutes: 60, // focusScore = 60
        mitsCompleted: 1, // mitScore = 33.333333333333336
        scrollMinutes: 50, // ignored
        scrollBudget: 30,
        intentionCompleted: false,
        shutdownCompleted: false,
        energyCheckIns: 0, // ritualScore = 0
        recoveryActions: 0,
        attentionCoverage: DataCoverage.unsupported,
      );
      expect(result.score, 37);
      expect(result.isIncomplete, true);
      expect(result.grade, isNull);
    });

    test('complete coverage uses full formula with attention cost', () {
      final result = DailyScoreCalculator.calculate(
        focusMinutes: 180,
        mitsCompleted: 3,
        scrollMinutes: 60, // 2x budget -> attentionScore = 0
        scrollBudget: 30,
        intentionCompleted: true,
        shutdownCompleted: true,
        energyCheckIns: 3,
        recoveryActions: 0,
        attentionCoverage: DataCoverage.complete,
      );
      expect(result.score, 70);
      expect(result.isIncomplete, false);
      expect(result.grade, 'B');
    });
  });
}
