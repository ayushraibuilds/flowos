import 'package:flutter_test/flutter_test.dart';
import 'package:flowos/features/focus/models/focus_protection.dart';

void main() {
  group('FocusProtectionLevel', () {
    test('Soft Return offers a cue without pausing or blocking exit', () {
      const level = FocusProtectionLevel.softReturn;

      expect(level.pausesWhenLeaving, isFalse);
      expect(level.requiresExitReflection, isFalse);
      expect(level.label, 'Soft Return');
    });

    test('Pause & Protect pauses on leave without adding exit friction', () {
      const level = FocusProtectionLevel.pauseAndProtect;

      expect(level.pausesWhenLeaving, isTrue);
      expect(level.requiresExitReflection, isFalse);
    });

    test('Intentional Exit is the strongest opt-in level', () {
      const level = FocusProtectionLevel.intentionalExit;

      expect(level.pausesWhenLeaving, isTrue);
      expect(level.requiresExitReflection, isTrue);
      expect(level.description, contains('five-second'));
    });
  });
}
