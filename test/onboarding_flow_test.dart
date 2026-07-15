import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drift/native.dart';

import 'package:flowos/data/local/database/app_database.dart';
import 'package:flowos/presentation/screens/onboarding/onboarding_welcome_screen.dart';
import 'package:flowos/presentation/screens/onboarding/onboarding_rhythm_screen.dart';
import 'package:flowos/presentation/screens/onboarding/onboarding_connect_screen.dart';
import 'package:flowos/features/attention/providers/app_picker_providers.dart';
import 'package:flowos/features/attention/repository/attention_data_repository.dart';

class MockDeviceAttentionPlatform extends DeviceAttentionPlatform {
  @override
  Future<PermissionStates> getPermissionStates() async {
    return const PermissionStates(
      usageAccess: false,
      accessibility: false,
      notificationAccess: false,
      platformSupport: 'android',
    );
  }

  @override
  Future<List<Map<String, String>>> getLaunchableApps() async {
    return [
      {'packageName': 'com.instagram.android', 'label': 'Instagram'},
    ];
  }

  @override
  Future<List<Map<String, String>>> getDefaultEssentialPackages() async {
    return [];
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('Onboarding Welcome Screen Tests', () {
    testWidgets('Renders sprouting plant and trust copy, and handles skip/continue buttons', (tester) async {
      bool continued = false;
      bool skipped = false;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: OnboardingWelcomeScreen(
            onContinue: () => continued = true,
            onSkip: () => skipped = true,
          ),
        ),
      ));

      expect(find.text('Welcome to your Garden'), findsOneWidget);
      expect(find.textContaining('Your device activity stays on this device'), findsOneWidget);

      await tester.tap(find.text('Continue'));
      await tester.pump(const Duration(milliseconds: 100));
      expect(continued, true);

      await tester.tap(find.text('Set up later'));
      await tester.pump(const Duration(milliseconds: 100));
      expect(skipped, true);
    });
  });

  group('Onboarding Rhythm Screen Tests', () {
    testWidgets('Goals multiselect validation and focus minutes segmented choice', (tester) async {
      List<String>? selectedGoals;
      int? selectedMinutes;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: OnboardingRhythmScreen(
            onContinue: (goals, minutes) {
              selectedGoals = goals;
              selectedMinutes = minutes;
            },
          ),
        ),
      ));

      // Continue button should be disabled initially (no goals selected)
      final continueButtonFinder = find.widgetWithText(ElevatedButton, 'Continue');
      ElevatedButton btn = tester.widget<ElevatedButton>(continueButtonFinder);
      expect(btn.onPressed, isNull);

      // Select 'Deep work' and 'Study'
      await tester.tap(find.text('Deep work'));
      await tester.pumpAndSettle();

      btn = tester.widget<ElevatedButton>(continueButtonFinder);
      expect(btn.onPressed, isNotNull); // enabled now

      await tester.tap(find.text('Creative'));
      await tester.pumpAndSettle();

      // Select default focus duration 45m
      await tester.tap(find.text('45m'));
      await tester.pumpAndSettle();

      // Submit
      await tester.tap(continueButtonFinder);
      await tester.pumpAndSettle();

      expect(selectedGoals, containsAll(['Deep work', 'Creative']));
      expect(selectedMinutes, 45);
    });
  });

  group('Onboarding Connect Screen Tests', () {
    Widget createConnectScreenWidget() {
      return ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          deviceAttentionPlatformProvider.overrideWithValue(MockDeviceAttentionPlatform()),
          launchableAppsProvider.overrideWith((ref) async => [
            {'packageName': 'com.instagram.android', 'label': 'Instagram'},
          ]),
          essentialPackagesProvider.overrideWith((ref) async => []),
        ],
        child: MaterialApp(
          theme: ThemeData(platform: TargetPlatform.android),
          home: Scaffold(
            body: OnboardingConnectScreen(
              onComplete: () {},
            ),
          ),
        ),
      );
    }

    testWidgets('Renders app selection card and device integrations list', (tester) async {
      await tester.pumpWidget(createConnectScreenWidget());
      await tester.pumpAndSettle();

      expect(find.text('Choose what pulls you away'), findsOneWidget);
      expect(find.text('Device Integrations'), findsOneWidget);
      expect(find.textContaining('Usage Access (Optional)'), findsOneWidget);
      expect(find.textContaining('Accessibility Blocker (Optional)'), findsOneWidget);

      // Finish is enabled by default (no permissions forced)
      final finishButton = find.widgetWithText(ElevatedButton, 'Finish');
      expect(tester.widget<ElevatedButton>(finishButton).onPressed, isNotNull);
    });
  });
}
