import 'dart:io' show Platform;

/// Supabase configuration — reads from environment at compile time.
///
/// Usage:
///   flutter run --dart-define-from-file=.env
///   flutter build --dart-define-from-file=.env
///
/// Falls back to empty strings if not provided (app will show auth screen
/// but Supabase calls will fail gracefully).
class SupabaseConfig {
  SupabaseConfig._();

  /// Supabase project URL — set via --dart-define or .env
  static const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );

  /// Supabase anonymous key — set via --dart-define or .env
  static const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  /// Whether Supabase is configured (not placeholder/empty).
  static bool get isConfigured =>
      supabaseUrl.isNotEmpty &&
      supabaseAnonKey.isNotEmpty &&
      !supabaseUrl.contains('YOUR_PROJECT');

  // Deep link scheme for auth callbacks (Apple/Google Sign-In)
  static const authCallbackUrlScheme = 'io.supabase.flowos';
  static const authRedirectUrl = '$authCallbackUrlScheme://login-callback/';

  // Device ID for sync conflict resolution
  static String get deviceId {
    // In production, use device_info_plus package for unique device ID.
    // For now, differentiate by platform.
    try {
      if (Platform.isIOS) return 'ios-device';
      if (Platform.isAndroid) return 'android-device';
      return 'flutter-device';
    } catch (_) {
      return 'flutter-device';
    }
  }
}
