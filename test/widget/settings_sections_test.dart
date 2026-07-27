import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flowos/features/focus/models/focus_protection.dart';
import 'package:flowos/presentation/screens/settings/widgets/settings_account_section.dart';
import 'package:flowos/presentation/screens/settings/widgets/settings_export_data_section.dart';
import 'package:flowos/presentation/screens/settings/widgets/settings_protection_section.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TASK-017: Extracted Settings Sections Component Tests', () {
    testWidgets(
      'SettingsAccountSection renders unauthenticated local mode state',
      (tester) async {
        bool signInTapped = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SettingsAccountSection(
                isAuthenticated: false,
                onSignIn: () {
                  signInTapped = true;
                },
                onSignOut: () {},
              ),
            ),
          ),
        );

        expect(find.text('Account & Profile'), findsOneWidget);
        expect(find.text('Local Mode'), findsOneWidget);
        expect(find.text('Sign In'), findsOneWidget);

        await tester.tap(find.text('Sign In'));
        expect(signInTapped, isTrue);
      },
    );

    testWidgets('SettingsAccountSection renders authenticated state', (
      tester,
    ) async {
      bool signOutTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SettingsAccountSection(
              email: 'test@flowos.app',
              isAuthenticated: true,
              onSignIn: () {},
              onSignOut: () {
                signOutTapped = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('test@flowos.app'), findsOneWidget);
      expect(find.text('Sign Out'), findsOneWidget);

      await tester.tap(find.text('Sign Out'));
      expect(signOutTapped, isTrue);
    });

    testWidgets('SettingsProtectionSection renders protection mode choices', (
      tester,
    ) async {
      FocusProtectionLevel selectedLevel = FocusProtectionLevel.pauseAndProtect;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SettingsProtectionSection(
              selectedLevel: selectedLevel,
              onLevelChanged: (level) {
                selectedLevel = level;
              },
              onConfigureAppBlocker: () {},
            ),
          ),
        ),
      );

      expect(find.text('Focus Protection & App Blocker'), findsOneWidget);
      expect(find.text('GUARDRAIL'), findsOneWidget);

      await tester.tap(find.text('SHIELD'));
      expect(selectedLevel, equals(FocusProtectionLevel.intentionalExit));
    });

    testWidgets('SettingsExportDataSection handles export and reset actions', (
      tester,
    ) async {
      bool exportTapped = false;
      bool resetTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SettingsExportDataSection(
              onExportData: () {
                exportTapped = true;
              },
              onResetData: () {
                resetTapped = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('Export My Data'), findsOneWidget);
      expect(find.text('Reset Local Data'), findsOneWidget);

      await tester.tap(find.text('Export My Data'));
      expect(exportTapped, isTrue);

      await tester.tap(find.text('Reset Local Data'));
      expect(resetTapped, isTrue);
    });
  });
}
