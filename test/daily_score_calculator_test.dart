import 'package:flutter_test/flutter_test.dart';

import 'package:flowos/features/xp/models/daily_score_calculator.dart';

void main() {
  group('DailyScoreCalculator', () {
    group('calculate — full formula', () {
      test('perfect day = high score', () {
        final score = DailyScoreCalculator.calculate(
          focusMinutes: 180,
          mitsCompleted: 3,
          scrollMinutes: 0,
          scrollBudget: 30,
          intentionCompleted: true,
          shutdownCompleted: true,
          energyCheckIns: 3,
        );
        // 100*0.35 + 100*0.30 + 100*0.20 + 100*0.15 = 100
        expect(score, 100);
      });

      test('zero effort = 0 score', () {
        final score = DailyScoreCalculator.calculate(
          focusMinutes: 0,
          mitsCompleted: 0,
          scrollMinutes: 60,
          scrollBudget: 30,
          intentionCompleted: false,
          shutdownCompleted: false,
          energyCheckIns: 0,
        );
        expect(score, 0);
      });

      test('moderate day', () {
        final score = DailyScoreCalculator.calculate(
          focusMinutes: 60,
          mitsCompleted: 1,
          scrollMinutes: 15,
          scrollBudget: 30,
          intentionCompleted: true,
          shutdownCompleted: false,
          energyCheckIns: 1,
        );
        // focusScore = 60, mitScore = 33.3, attentionScore = 80, ritualScore = 45
        // 60*0.35 + 33.3*0.30 + 80*0.20 + 45*0.15 = 21+10+16+6.75 = 53.75 ≈ 54
        expect(score, inInclusiveRange(50, 58));
      });

      test('score clamped between 0 and 100', () {
        final score = DailyScoreCalculator.calculate(
          focusMinutes: 500,
          mitsCompleted: 10,
          scrollMinutes: 0,
          scrollBudget: 30,
          intentionCompleted: true,
          shutdownCompleted: true,
          energyCheckIns: 10,
        );
        expect(score, lessThanOrEqualTo(100));
        expect(score, greaterThanOrEqualTo(0));
      });
    });

    group('gradeFromScore', () {
      test('90+ = A+', () {
        expect(DailyScoreCalculator.gradeFromScore(90), 'A+');
        expect(DailyScoreCalculator.gradeFromScore(100), 'A+');
      });

      test('80-89 = A', () {
        expect(DailyScoreCalculator.gradeFromScore(80), 'A');
        expect(DailyScoreCalculator.gradeFromScore(89), 'A');
      });

      test('70-79 = B', () {
        expect(DailyScoreCalculator.gradeFromScore(70), 'B');
        expect(DailyScoreCalculator.gradeFromScore(79), 'B');
      });

      test('55-69 = C', () {
        expect(DailyScoreCalculator.gradeFromScore(55), 'C');
        expect(DailyScoreCalculator.gradeFromScore(69), 'C');
      });

      test('40-54 = D', () {
        expect(DailyScoreCalculator.gradeFromScore(40), 'D');
        expect(DailyScoreCalculator.gradeFromScore(54), 'D');
      });

      test('0-39 = F', () {
        expect(DailyScoreCalculator.gradeFromScore(0), 'F');
        expect(DailyScoreCalculator.gradeFromScore(39), 'F');
      });

      test('grade boundaries are contiguous', () {
        // Every score 0-100 must produce a valid grade
        for (int i = 0; i <= 100; i++) {
          final grade = DailyScoreCalculator.gradeFromScore(i);
          expect(['A+', 'A', 'B', 'C', 'D', 'F'], contains(grade),
              reason: 'Score $i produced invalid grade: $grade');
        }
      });
    });

    group('messageForGrade', () {
      test('every grade has a non-empty message', () {
        for (final grade in ['A+', 'A', 'B', 'C', 'D', 'F']) {
          expect(DailyScoreCalculator.messageForGrade(grade).isNotEmpty, true,
              reason: 'Grade $grade has empty message');
        }
      });
    });

    group('edge cases', () {
      test('zero scroll budget does not divide by zero', () {
        final score = DailyScoreCalculator.calculate(
          focusMinutes: 60,
          mitsCompleted: 2,
          scrollMinutes: 10,
          scrollBudget: 0,
          intentionCompleted: true,
          shutdownCompleted: true,
          energyCheckIns: 2,
        );
        expect(score, isNotNull);
        expect(score, inInclusiveRange(0, 100));
      });

      test('negative scroll minutes treated as 0', () {
        final score = DailyScoreCalculator.calculate(
          focusMinutes: 60,
          mitsCompleted: 2,
          scrollMinutes: -5,
          scrollBudget: 30,
          intentionCompleted: true,
          shutdownCompleted: true,
          energyCheckIns: 2,
        );
        expect(score, inInclusiveRange(0, 100));
      });

      test('very large focus minutes capped at 100', () {
        final score = DailyScoreCalculator.calculate(
          focusMinutes: 999,
          mitsCompleted: 0,
          scrollMinutes: 0,
          scrollBudget: 30,
          intentionCompleted: false,
          shutdownCompleted: false,
          energyCheckIns: 0,
        );
        // Only focus contributes: 100 * 0.35 + 100 * 0.20 = 55
        expect(score, inInclusiveRange(50, 60));
      });

      test('more focus → higher score (monotonic)', () {
        int prevScore = -1;
        for (final mins in [0, 30, 60, 90, 120, 150, 180]) {
          final score = DailyScoreCalculator.calculate(
            focusMinutes: mins,
            mitsCompleted: 0,
            scrollMinutes: 0,
            scrollBudget: 30,
            intentionCompleted: false,
            shutdownCompleted: false,
            energyCheckIns: 0,
          );
          expect(score, greaterThanOrEqualTo(prevScore),
              reason: '$mins min should score >= $prevScore');
          prevScore = score;
        }
      });

      test('more scroll → lower score (inversely monotonic)', () {
        int prevScore = 101;
        for (final mins in [0, 10, 20, 30, 40, 50, 60]) {
          final score = DailyScoreCalculator.calculate(
            focusMinutes: 60,
            mitsCompleted: 2,
            scrollMinutes: mins,
            scrollBudget: 30,
            intentionCompleted: true,
            shutdownCompleted: true,
            energyCheckIns: 2,
          );
          expect(score, lessThanOrEqualTo(prevScore),
              reason: '$mins min scroll should score <= $prevScore');
          prevScore = score;
        }
      });
    });
  });
}
