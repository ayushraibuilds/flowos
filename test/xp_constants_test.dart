import 'package:flutter_test/flutter_test.dart';

import 'package:flowos/core/constants/xp_constants.dart';

void main() {
  group('XpConstants', () {
    group('levelFromXP', () {
      test('0 XP = level 0', () {
        expect(XpConstants.levelFromXP(0), 0);
      });

      test('99 XP = level 0 (need 100 for level 1)', () {
        expect(XpConstants.levelFromXP(99), 0);
      });

      test('100 XP = level 1', () {
        expect(XpConstants.levelFromXP(100), 1);
      });

      test('400 XP = level 2 (need 400 for level 2)', () {
        expect(XpConstants.levelFromXP(400), 2);
      });

      test('399 XP = level 1', () {
        expect(XpConstants.levelFromXP(399), 1);
      });

      test('900 XP = level 3', () {
        expect(XpConstants.levelFromXP(900), 3);
      });

      test('10000 XP = level 10', () {
        expect(XpConstants.levelFromXP(10000), 10);
      });

      test('very high XP returns correct level', () {
        // Level 50 = 50*50*100 = 250,000
        expect(XpConstants.levelFromXP(250000), 50);
      });
    });

    group('xpForLevel', () {
      test('level 0 = 0 XP', () {
        expect(XpConstants.xpForLevel(0), 0);
      });

      test('level 1 = 100 XP', () {
        expect(XpConstants.xpForLevel(1), 100);
      });

      test('level 5 = 2500 XP', () {
        expect(XpConstants.xpForLevel(5), 2500);
      });

      test('quadratic scaling: level 10 = 10000', () {
        expect(XpConstants.xpForLevel(10), 10000);
      });
    });

    group('tierName', () {
      test('level 0 = Seedling', () {
        expect(XpConstants.tierName(0), '🌱 Seedling');
      });

      test('level 4 = Seedling', () {
        expect(XpConstants.tierName(4), '🌱 Seedling');
      });

      test('level 5 = Focuser', () {
        expect(XpConstants.tierName(5), '⚡ Focuser');
      });

      test('level 15 = Flow Rider', () {
        expect(XpConstants.tierName(15), '🔥 Flow Rider');
      });

      test('level 25 = Deep Worker', () {
        expect(XpConstants.tierName(25), '🎯 Deep Worker');
      });

      test('level 35 = Mind Master', () {
        expect(XpConstants.tierName(35), '🧠 Mind Master');
      });

      test('level 50 = Flow State God', () {
        expect(XpConstants.tierName(50), '🌌 Flow State God');
      });

      test('level 99 = Flow State God (caps at 50)', () {
        expect(XpConstants.tierName(99), '🌌 Flow State God');
      });
    });

    group('streakMultiplier', () {
      test('0 days = 1.0x', () {
        expect(XpConstants.streakMultiplier(0), 1.0);
      });

      test('6 days = 1.0x', () {
        expect(XpConstants.streakMultiplier(6), 1.0);
      });

      test('7 days = 1.1x', () {
        expect(XpConstants.streakMultiplier(7), 1.1);
      });

      test('29 days = 1.1x', () {
        expect(XpConstants.streakMultiplier(29), 1.1);
      });

      test('30 days = 1.25x', () {
        expect(XpConstants.streakMultiplier(30), 1.25);
      });

      test('99 days = 1.25x', () {
        expect(XpConstants.streakMultiplier(99), 1.25);
      });

      test('100 days = 1.5x', () {
        expect(XpConstants.streakMultiplier(100), 1.5);
      });

      test('365 days = 1.5x (caps at 100)', () {
        expect(XpConstants.streakMultiplier(365), 1.5);
      });
    });

    group('XP values are positive', () {
      test('all earning constants are positive', () {
        expect(XpConstants.pomodoroComplete, greaterThan(0));
        expect(XpConstants.deepWorkComplete, greaterThan(0));
        expect(XpConstants.taskComplete, greaterThan(0));
        expect(XpConstants.mitComplete, greaterThan(0));
        expect(XpConstants.allMitsDaily, greaterThan(0));
        expect(XpConstants.bounceBackBonus, greaterThan(0));
      });

      test('deep work > pomodoro (reward longer focus)', () {
        expect(XpConstants.deepWorkComplete,
            greaterThan(XpConstants.pomodoroComplete));
      });

      test('MIT completion > regular task (reward priority)', () {
        expect(XpConstants.mitComplete,
            greaterThan(XpConstants.taskComplete));
      });
    });
  });
}
