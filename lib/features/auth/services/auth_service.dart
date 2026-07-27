import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/supabase_config.dart';
import '../../sync/services/sync_engine.dart';
import '../models/app_session_state.dart';

// ─── Supabase client provider ───────────────────────────────────

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  if (!SupabaseConfig.isConfigured) {
    throw StateError('Supabase not configured — running in local-only mode');
  }
  return Supabase.instance.client;
});

// ─── Onboarding state ───────────────────────────────────────────

final onboardingCompleteProvider = StateProvider<bool>((ref) => false);

// ─── Auth state ─────────────────────────────────────────────────

/// Reactive auth state — emits on every login/logout/token refresh.
/// Returns empty stream if Supabase not configured.
final authStateProvider = StreamProvider<AuthState>((ref) {
  if (!SupabaseConfig.isConfigured) return const Stream.empty();
  return Supabase.instance.client.auth.onAuthStateChange;
});

/// Current user (nullable) — reactively updates on authStateProvider stream changes.
final currentUserProvider = Provider<User?>((ref) {
  if (!SupabaseConfig.isConfigured) return null;
  final authAsync = ref.watch(authStateProvider);
  return authAsync.when(
    data: (authState) =>
        authState.session?.user ?? Supabase.instance.client.auth.currentUser,
    loading: () => Supabase.instance.client.auth.currentUser,
    error: (_, __) => null,
  );
});

/// Whether user is logged in
final isLoggedInProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProvider) != null;
});

/// Centralized AppSessionState provider — combining auth stream and onboarding state.
final appSessionProvider = Provider<AppSessionState>((ref) {
  final isOnboardingDone = ref.watch(onboardingCompleteProvider);

  if (!SupabaseConfig.isConfigured) {
    return AppSessionState.localOnly(isOnboardingComplete: isOnboardingDone);
  }

  final authAsync = ref.watch(authStateProvider);
  return authAsync.when(
    data: (authState) {
      final user =
          authState.session?.user ?? Supabase.instance.client.auth.currentUser;
      if (user != null) {
        return AppSessionState.authenticated(
          user: user,
          session:
              authState.session ?? Supabase.instance.client.auth.currentSession,
          isOnboardingComplete: isOnboardingDone,
        );
      }
      return AppSessionState.unauthenticated(
        isOnboardingComplete: isOnboardingDone,
      );
    },
    loading: () {
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser != null) {
        return AppSessionState.authenticated(
          user: currentUser,
          session: Supabase.instance.client.auth.currentSession,
          isOnboardingComplete: isOnboardingDone,
        );
      }
      return AppSessionState.loading(isOnboardingComplete: isOnboardingDone);
    },
    error: (_, __) =>
        AppSessionState.unauthenticated(isOnboardingComplete: isOnboardingDone),
  );
});

// ─── Auth Service ───────────────────────────────────────────────

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref.watch(supabaseClientProvider));
});

/// FlowOS Auth Service — wraps Supabase Auth.
/// Supports Apple Sign-In (iOS), Google Sign-In (Android), and email fallback.
class AuthService {
  final SupabaseClient _client;

  AuthService(this._client);

  GoTrueClient get _auth => _client.auth;

  /// Current session
  Session? get session => _auth.currentSession;

  /// Current user
  User? get user => _auth.currentUser;

  /// Is authenticated
  bool get isAuthenticated => user != null;

  // ─── Email / Password ───────────────────────────────────────

  /// Sign up with email + password
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    return await _auth.signUp(
      email: email,
      password: password,
      emailRedirectTo: SupabaseConfig.authRedirectUrl,
    );
  }

  /// Sign in with email + password
  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithPassword(email: email, password: password);
  }

  // ─── Social Auth ────────────────────────────────────────────

  /// Apple Sign-In (primary on iOS)
  Future<bool> signInWithApple() async {
    try {
      await _auth.signInWithOAuth(
        OAuthProvider.apple,
        redirectTo: SupabaseConfig.authRedirectUrl,
      );
      return true;
    } catch (e) {
      debugPrint('Apple Sign-In failed: $e');
      return false;
    }
  }

  /// Google Sign-In (primary on Android)
  Future<bool> signInWithGoogle() async {
    try {
      await _auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: SupabaseConfig.authRedirectUrl,
      );
      return true;
    } catch (e) {
      debugPrint('Google Sign-In failed: $e');
      return false;
    }
  }

  // ─── Password Reset ────────────────────────────────────────

  Future<void> resetPassword(String email) async {
    await _auth.resetPasswordForEmail(
      email,
      redirectTo: SupabaseConfig.authRedirectUrl,
    );
  }

  // ─── Sign Out ──────────────────────────────────────────────

  Future<void> signOut({SyncEngine? syncEngine}) async {
    syncEngine?.cancelSync();
    await _auth.signOut();
  }

  // ─── Session Management ────────────────────────────────────

  /// Refresh session token if expired
  Future<void> refreshSession() async {
    final session = _auth.currentSession;
    if (session != null && session.isExpired) {
      await _auth.refreshSession();
    }
  }

  /// Get a valid access token (refreshes if needed)
  Future<String?> getAccessToken() async {
    await refreshSession();
    return _auth.currentSession?.accessToken;
  }
}
