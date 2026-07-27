import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flowos/features/focus/models/focus_timer_stage.dart';
import 'package:flowos/features/focus/widgets/focus_session_type_selector.dart';
import 'package:flowos/features/focus/widgets/focus_timer_display.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TASK-017: Extracted Focus Widgets Component Tests', () {
    testWidgets(
      'FocusSessionTypeSelector renders chips and handles selection',
      (tester) async {
        int selectedIndex = 0;
        final sessionTypes = [
          (label: 'Classic', minutes: 25, breakMin: 5),
          (label: 'DeskTime', minutes: 52, breakMin: 17),
          (label: 'Deep Work', minutes: 90, breakMin: 15),
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) {
                  return FocusSessionTypeSelector(
                    sessionTypes: sessionTypes,
                    selectedIndex: selectedIndex,
                    onSelected: (idx) {
                      setState(() {
                        selectedIndex = idx;
                      });
                    },
                  );
                },
              ),
            ),
          ),
        );

        expect(find.text('Classic'), findsOneWidget);
        expect(find.text('DeskTime'), findsOneWidget);
        expect(find.text('Deep Work'), findsOneWidget);

        await tester.tap(find.text('Deep Work'));
        await tester.pumpAndSettle();

        expect(selectedIndex, equals(2));
      },
    );

    testWidgets(
      'FocusTimerDisplay renders idle state with Start Focus button',
      (tester) async {
        bool startPressed = false;
        final breatheController = AnimationController(
          vsync: const TestVSync(),
          duration: const Duration(seconds: 1),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FocusTimerDisplay(
                phase: FocusTimerPhase.idle,
                remainingSeconds: 1500,
                totalSeconds: 1500,
                formattedTime: '25:00',
                breatheAnimation: breatheController,
                onStart: () {
                  startPressed = true;
                },
              ),
            ),
          ),
        );

        expect(find.text('25:00'), findsOneWidget);
        expect(find.text('Ready'), findsOneWidget);
        expect(find.text('Start Focus'), findsOneWidget);

        await tester.tap(find.text('Start Focus'));
        expect(startPressed, isTrue);

        breatheController.dispose();
      },
    );

    testWidgets(
      'FocusTimerDisplay renders running state with pause and stop controls',
      (tester) async {
        bool pausePressed = false;
        bool stopPressed = false;

        final breatheController = AnimationController(
          vsync: const TestVSync(),
          duration: const Duration(seconds: 1),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FocusTimerDisplay(
                phase: FocusTimerPhase.running,
                remainingSeconds: 1200,
                totalSeconds: 1500,
                formattedTime: '20:00',
                breatheAnimation: breatheController,
                onPause: () {
                  pausePressed = true;
                },
                onStop: () {
                  stopPressed = true;
                },
              ),
            ),
          ),
        );

        expect(find.text('20:00'), findsOneWidget);
        expect(find.text('Focusing'), findsOneWidget);

        await tester.tap(find.byIcon(Icons.pause_circle_filled_rounded));
        expect(pausePressed, isTrue);

        await tester.tap(find.byIcon(Icons.stop_circle_rounded));
        expect(stopPressed, isTrue);

        breatheController.dispose();
      },
    );
  });
}
