import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/supabase_config.dart';

// ─── Supabase client provider ───────────────────────────────────

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

// ─── Auth state ─────────────────────────────────────────────────

/// Reactive auth state — emits on every login/logout/token refresh.
final authStateProvider = StreamProvider<AuthState>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange;
});

/// Current user (nullable)
final currentUserProvider = Provider<User?>((ref) {
  return Supabase.instance.client.auth.currentUser;
});

/// Whether user is logged in
final isLoggedInProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProvider) != null;
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
    return await _auth.signInWithPassword(
      email: email,
      password: password,
    );
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

  Future<void> signOut() async {
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
