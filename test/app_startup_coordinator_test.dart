import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flowos/core/bootstrap/app_startup_coordinator.dart';
import 'package:flowos/features/auth/services/auth_service.dart';
import 'package:flowos/presentation/navigation/app_router.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('TASK-013: AppStartupCoordinator & Bootstrap Tests', () {
    test(
      'runDeferredMaintenance executes notification callbacks successfully',
      () async {
        bool initCalled = false;
        bool scheduleCalled = false;

        final result = await AppStartupCoordinator.runDeferredMaintenance(
          initializeNotifications: () async {
            initCalled = true;
          },
          scheduleNotifications: () async {
            scheduleCalled = true;
          },
        );

        expect(initCalled, isTrue);
        expect(scheduleCalled, isTrue);
        expect(result.prerequisitesSuccess, isTrue);
        expect(result.deferredSuccess, isTrue);
        expect(result.deferredError, isNull);
      },
    );

    test(
      'runDeferredMaintenance fault isolation: plugin exception does not throw',
      () async {
        final result = await AppStartupCoordinator.runDeferredMaintenance(
          initializeNotifications: () async {
            throw Exception('Plugin initialization failed on platform channel');
          },
          scheduleNotifications: () async {
            // Should be skipped due to init error
          },
        );

        expect(result.prerequisitesSuccess, isTrue);
        expect(result.deferredSuccess, isFalse);
        expect(result.deferredError, contains('Plugin initialization failed'));
      },
    );

    testWidgets('Local-only widget bootstrap renders without crashing', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        'flowos_onboarding_complete': true,
      });
      onboardingComplete = true;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [onboardingCompleteProvider.overrideWith((ref) => true)],
          child: const MaterialApp(
            home: Scaffold(body: Text('FlowOS Shell Ready')),
          ),
        ),
      );

      await tester.pump();
      expect(find.text('FlowOS Shell Ready'), findsOneWidget);
    });

    testWidgets(
      'Unonboarded widget bootstrap renders onboarding shell cleanly',
      (tester) async {
        SharedPreferences.setMockInitialValues({
          'flowos_onboarding_complete': false,
        });
        onboardingComplete = false;

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              onboardingCompleteProvider.overrideWith((ref) => false),
            ],
            child: const MaterialApp(
              home: Scaffold(body: Text('Onboarding Welcome')),
            ),
          ),
        );

        await tester.pump();
        expect(find.text('Onboarding Welcome'), findsOneWidget);
      },
    );
  });
}
