/// Supabase configuration constants.
/// These should be moved to .env / flutter_dotenv for production.
class SupabaseConfig {
  SupabaseConfig._();

  // TODO: Replace with your Supabase project values
  static const supabaseUrl = 'https://YOUR_PROJECT.supabase.co';
  static const supabaseAnonKey = 'YOUR_ANON_KEY';

  // Deep link scheme for auth callbacks (Apple/Google Sign-In)
  static const authCallbackUrlScheme = 'io.supabase.flowos';
  static const authRedirectUrl = '$authCallbackUrlScheme://login-callback/';

  // Device ID for sync conflict resolution
  static String get deviceId {
    // Platform-specific device identifier
    // In production, use device_info_plus package
    return 'flutter-dev';
  }
}
