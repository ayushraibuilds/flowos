import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flowos/core/config/supabase_config.dart';
import 'package:flowos/features/auth/models/app_session_state.dart';
import 'package:flowos/features/auth/services/auth_service.dart';
import 'package:flowos/presentation/navigation/app_router.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AppSessionState & Provider Tests', () {
    test(
      'AppSessionState factory constructors and properties work correctly',
      () {
        final loadingState = AppSessionState.loading();
        expect(loadingState.isLoading, isTrue);
        expect(loadingState.status, AppSessionStatus.loading);

        final localState = AppSessionState.localOnly(
          isOnboardingComplete: true,
        );
        expect(localState.isLocalOnly, isTrue);
        expect(localState.isOnboardingComplete, isTrue);

        final unauth = AppSessionState.unauthenticated(
          isOnboardingComplete: false,
        );
        expect(unauth.isUnauthenticated, isTrue);
        expect(unauth.isOnboardingComplete, isFalse);
      },
    );

    test(
      'Local-only mode appSessionProvider never throws and returns localOnly status',
      () {
        expect(SupabaseConfig.isConfigured, isFalse);

        final container = ProviderContainer();
        addTearDown(container.dispose);

        final session = container.read(appSessionProvider);
        expect(session.status, AppSessionStatus.localOnly);
        expect(session.isLocalOnly, isTrue);

        final user = container.read(currentUserProvider);
        expect(user, isNull);

        final loggedIn = container.read(isLoggedInProvider);
        expect(loggedIn, isFalse);
      },
    );

    test(
      'onboardingCompleteProvider updates appSessionProvider reactively',
      () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        expect(
          container.read(appSessionProvider).isOnboardingComplete,
          isFalse,
        );

        container.read(onboardingCompleteProvider.notifier).state = true;

        expect(container.read(appSessionProvider).isOnboardingComplete, isTrue);
      },
    );

    test('RouterRefreshListenable disposes stream subscriptions cleanly', () {
      final listenable = RouterRefreshListenable();
      expect(() => listenable.dispose(), returnsNormally);
    });
  });
}
