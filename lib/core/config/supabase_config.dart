import 'dart:io' show Platform;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

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

  static String _deviceId = 'flutter-device';

  // Device ID for sync conflict resolution
  static String get deviceId => _deviceId;

  /// Initialize persistent unique device ID.
  static Future<void> initializeDeviceId(SharedPreferences prefs) async {
    String? devId = prefs.getString('flowos_device_id');
    if (devId == null) {
      try {
        final platform = Platform.isIOS ? 'ios' : Platform.isAndroid ? 'android' : 'device';
        devId = '$platform-${const Uuid().v4()}';
      } catch (_) {
        devId = 'device-${const Uuid().v4()}';
      }
      await prefs.setString('flowos_device_id', devId);
    }
    _deviceId = devId;
  }
}
