import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flowos/presentation/navigation/app_router.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget createRouterTestWidget(GoRouter testRouter) {
    return MaterialApp.router(
      routerConfig: testRouter,
    );
  }

  GoRouter createTestRouter() {
    return GoRouter(
      initialLocation: '/home',
      redirect: appRouterRedirect,
      routes: [
        GoRoute(path: '/home', builder: (c, s) => const Scaffold(body: Text('HomeScreen'))),
        GoRoute(path: '/onboarding', builder: (c, s) => const Scaffold(body: Text('OnboardingScreen'))),
        GoRoute(path: '/device-setup', builder: (c, s) => const Scaffold(body: Text('DeviceSetupFlow'))),
        GoRoute(path: '/update-rhythm', builder: (c, s) => const Scaffold(body: Text('UpdateRhythmScreen'))),
        GoRoute(path: '/auth', builder: (c, s) => const Scaffold(body: Text('AuthScreen'))),
      ],
    );
  }

  group('Router Redirect Rules (Lightweight)', () {
    testWidgets('Unonboarded user navigating to /home is redirected to /onboarding', (tester) async {
      onboardingComplete = false;
      final router = createTestRouter();

      await tester.pumpWidget(createRouterTestWidget(router));
      await tester.pumpAndSettle();

      expect(find.text('OnboardingScreen'), findsOneWidget);
    });

    testWidgets('Onboarded user navigating to /onboarding is redirected to /home', (tester) async {
      onboardingComplete = true;
      final router = createTestRouter();
      router.go('/onboarding');

      await tester.pumpWidget(createRouterTestWidget(router));
      await tester.pumpAndSettle();

      expect(find.text('HomeScreen'), findsOneWidget);
    });

    testWidgets('Onboarded user is allowed to access /device-setup', (tester) async {
      onboardingComplete = true;
      final router = createTestRouter();
      router.go('/device-setup');

      await tester.pumpWidget(createRouterTestWidget(router));
      await tester.pumpAndSettle();

      expect(find.text('DeviceSetupFlow'), findsOneWidget);
    });

    testWidgets('Onboarded user is allowed to access /update-rhythm', (tester) async {
      onboardingComplete = true;
      final router = createTestRouter();
      router.go('/update-rhythm');

      await tester.pumpWidget(createRouterTestWidget(router));
      await tester.pumpAndSettle();

      expect(find.text('UpdateRhythmScreen'), findsOneWidget);
    });

    testWidgets('Onboarded user navigating to /auth is redirected to /home when Supabase is not configured', (tester) async {
      onboardingComplete = true;
      final router = createTestRouter();
      router.go('/auth');

      await tester.pumpWidget(createRouterTestWidget(router));
      await tester.pumpAndSettle();

      expect(find.text('HomeScreen'), findsOneWidget);
    });
  });
}
