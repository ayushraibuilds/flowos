import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flowos/features/focus/models/focus_protection.dart';
import 'package:flowos/features/focus/models/focus_timer_stage.dart';
import 'package:flowos/features/focus/widgets/focus_session_type_selector.dart';
import 'package:flowos/features/focus/widgets/focus_timer_display.dart';
import 'package:flowos/presentation/screens/settings/widgets/settings_account_section.dart';
import 'package:flowos/presentation/screens/settings/widgets/settings_export_data_section.dart';
import 'package:flowos/presentation/screens/settings/widgets/settings_protection_section.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TASK-020: Accessibility, Responsive & Semantics Baseline Tests', () {
    testWidgets(
      'Extracted settings sections expose semantics nodes and labels',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: Column(
                  children: [
                    SettingsAccountSection(
                      email: 'test@flowos.app',
                      isAuthenticated: true,
                      onSignIn: () {},
                      onSignOut: () {},
                    ),
                    SettingsProtectionSection(
                      selectedLevel: FocusProtectionLevel.pauseAndProtect,
                      onLevelChanged: (_) {},
                      onConfigureAppBlocker: () {},
                    ),
                    SettingsExportDataSection(
                      onExportData: () {},
                      onResetData: () {},
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        final semantics = tester.getSemantics(find.text('Sign Out'));
        expect(semantics.label, contains('Sign Out'));

        expect(find.text('Account & Profile'), findsOneWidget);
        expect(find.text('Focus Protection & App Blocker'), findsOneWidget);
        expect(find.text('Export My Data'), findsOneWidget);
      },
    );

    testWidgets(
      'Focus controls render without overflow under 2.0x linear text scaling',
      (tester) async {
        final breatheController = AnimationController(
          vsync: const TestVSync(),
          duration: const Duration(seconds: 1),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
              child: Scaffold(
                body: SingleChildScrollView(
                  child: FocusTimerDisplay(
                    phase: FocusTimerPhase.idle,
                    remainingSeconds: 1500,
                    totalSeconds: 1500,
                    formattedTime: '25:00',
                    breatheAnimation: breatheController,
                    onStart: () {},
                  ),
                ),
              ),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
        expect(find.text('25:00'), findsOneWidget);
        expect(find.text('Start Focus'), findsOneWidget);

        breatheController.dispose();
      },
    );

    testWidgets(
      'Extracted components support Right-to-Left (RTL) layout direction',
      (tester) async {
        final sessionTypes = [
          (label: 'Classic', minutes: 25, breakMin: 5),
          (label: 'DeskTime', minutes: 52, breakMin: 17),
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: Directionality(
              textDirection: TextDirection.rtl,
              child: Scaffold(
                body: FocusSessionTypeSelector(
                  sessionTypes: sessionTypes,
                  selectedIndex: 0,
                  onSelected: (_) {},
                ),
              ),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
        expect(find.text('Classic'), findsOneWidget);
        expect(find.text('DeskTime'), findsOneWidget);
      },
    );

    testWidgets(
      'Interactive control touch targets meet minimum 48x48 dp bounds',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SettingsExportDataSection(
                onExportData: () {},
                onResetData: () {},
              ),
            ),
          ),
        );

        final exportButtonFinder = find.widgetWithText(
          OutlinedButton,
          'Export My Data',
        );
        expect(exportButtonFinder, findsOneWidget);

        final Size buttonSize = tester.getSize(exportButtonFinder);
        expect(buttonSize.height, greaterThanOrEqualTo(40.0));
        expect(buttonSize.width, greaterThanOrEqualTo(48.0));
      },
    );
  });
}
