import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flowos/features/auth/models/app_session_state.dart';
import 'package:flowos/presentation/navigation/app_router.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget createRouterTestWidget(GoRouter testRouter) {
    return MaterialApp.router(routerConfig: testRouter);
  }

  GoRouter createTestRouter() {
    return GoRouter(
      initialLocation: '/home',
      redirect: appRouterRedirect,
      routes: [
        GoRoute(
          path: '/home',
          builder: (c, s) => const Scaffold(body: Text('HomeScreen')),
        ),
        GoRoute(
          path: '/onboarding',
          builder: (c, s) => const Scaffold(body: Text('OnboardingScreen')),
        ),
        GoRoute(
          path: '/device-setup',
          builder: (c, s) => const Scaffold(body: Text('DeviceSetupFlow')),
        ),
        GoRoute(
          path: '/update-rhythm',
          builder: (c, s) => const Scaffold(body: Text('UpdateRhythmScreen')),
        ),
        GoRoute(
          path: '/auth',
          builder: (c, s) => const Scaffold(body: Text('AuthScreen')),
        ),
      ],
    );
  }

  group('Router Redirect Rules (Lightweight)', () {
    testWidgets(
      'Unonboarded user navigating to /home is redirected to /onboarding',
      (tester) async {
        onboardingComplete = false;
        final router = createTestRouter();

        await tester.pumpWidget(createRouterTestWidget(router));
        await tester.pumpAndSettle();

        expect(find.text('OnboardingScreen'), findsOneWidget);
      },
    );

    testWidgets(
      'Onboarded user navigating to /onboarding is redirected to /home',
      (tester) async {
        onboardingComplete = true;
        final router = createTestRouter();
        router.go('/onboarding');

        await tester.pumpWidget(createRouterTestWidget(router));
        await tester.pumpAndSettle();

        expect(find.text('HomeScreen'), findsOneWidget);
      },
    );

    testWidgets('Onboarded user is allowed to access /device-setup', (
      tester,
    ) async {
      onboardingComplete = true;
      final router = createTestRouter();
      router.go('/device-setup');

      await tester.pumpWidget(createRouterTestWidget(router));
      await tester.pumpAndSettle();

      expect(find.text('DeviceSetupFlow'), findsOneWidget);
    });

    testWidgets('Onboarded user is allowed to access /update-rhythm', (
      tester,
    ) async {
      onboardingComplete = true;
      final router = createTestRouter();
      router.go('/update-rhythm');

      await tester.pumpWidget(createRouterTestWidget(router));
      await tester.pumpAndSettle();

      expect(find.text('UpdateRhythmScreen'), findsOneWidget);
    });

    testWidgets(
      'Onboarded user navigating to /auth is redirected to /home when Supabase is not configured',
      (tester) async {
        onboardingComplete = true;
        final router = createTestRouter();
        router.go('/auth');

        await tester.pumpWidget(createRouterTestWidget(router));
        await tester.pumpAndSettle();

        expect(find.text('HomeScreen'), findsOneWidget);
      },
    );
  });

  group('calculateAppRedirect Session State Matrix', () {
    test('unonboarded session forces /onboarding from any normal route', () {
      final session = AppSessionState.unauthenticated(
        isOnboardingComplete: false,
      );
      expect(calculateAppRedirect('/home', session: session), '/onboarding');
      expect(calculateAppRedirect('/tasks', session: session), '/onboarding');
      expect(calculateAppRedirect('/profile', session: session), '/onboarding');
    });

    test('unonboarded session allows /onboarding and /auth', () {
      final session = AppSessionState.unauthenticated(
        isOnboardingComplete: false,
      );
      expect(calculateAppRedirect('/onboarding', session: session), null);
      expect(calculateAppRedirect('/auth', session: session), null);
    });

    test(
      'onboarded authenticated session redirects /auth and /onboarding to /home',
      () {
        final session = AppSessionState(
          status: AppSessionStatus.authenticated,
          isOnboardingComplete: true,
        );
        expect(calculateAppRedirect('/auth', session: session), '/home');
        expect(calculateAppRedirect('/onboarding', session: session), '/home');
        expect(calculateAppRedirect('/home', session: session), null);
      },
    );

    test(
      'onboarded unauthenticated session allows /auth and redirects /onboarding to /home',
      () {
        final session = AppSessionState.unauthenticated(
          isOnboardingComplete: true,
        );
        expect(calculateAppRedirect('/auth', session: session), null);
        expect(calculateAppRedirect('/onboarding', session: session), '/home');
        expect(calculateAppRedirect('/home', session: session), null);
      },
    );

    test('localOnly session redirects /auth to /home when onboarded', () {
      final session = AppSessionState.localOnly(isOnboardingComplete: true);
      expect(calculateAppRedirect('/auth', session: session), '/home');
      expect(calculateAppRedirect('/onboarding', session: session), '/home');
      expect(calculateAppRedirect('/home', session: session), null);
    });
  });
}
