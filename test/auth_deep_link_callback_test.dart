import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flowos/features/auth/services/auth_callback_handler.dart';

void main() {
  group('TASK-006: Mobile Auth Callback Registration & Deep Link Tests', () {
    test('AuthCallbackResult parses valid callback URIs', () {
      final uri = Uri.parse(
        'io.supabase.flowos://login-callback/#access_token=test_token_123&refresh_token=ref_123&type=signup',
      );
      final result = AuthCallbackResult.parse(uri);

      expect(result.status, equals(AuthCallbackStatus.success));
      expect(result.isSuccess, isTrue);
      expect(result.type, equals('signup'));
      expect(result.error, isNull);
    });

    test('AuthCallbackResult parses canceled / error callback URIs', () {
      final uri = Uri.parse(
        'io.supabase.flowos://login-callback/?error=access_denied&error_description=User+canceled+auth',
      );
      final result = AuthCallbackResult.parse(uri);

      expect(result.status, equals(AuthCallbackStatus.error));
      expect(result.isError, isTrue);
      expect(result.error, equals('access_denied'));
      expect(result.errorDescription, equals('User canceled auth'));
    });

    test('AuthCallbackResult rejects unrelated schemes and hosts', () {
      final wrongScheme = Uri.parse('https://flowos.app/login-callback');
      expect(AuthCallbackResult.parse(wrongScheme).isInvalid, isTrue);

      final wrongHost = Uri.parse(
        'io.supabase.flowos://malicious-host/login-callback',
      );
      expect(AuthCallbackResult.parse(wrongHost).isInvalid, isTrue);
    });

    test(
      'Android Manifest contains exact deep link intent filter for auth callbacks',
      () {
        final manifestFile = File('android/app/src/main/AndroidManifest.xml');
        expect(
          manifestFile.existsSync(),
          isTrue,
          reason: 'AndroidManifest.xml must exist',
        );

        final content = manifestFile.readAsStringSync();
        expect(content.contains('android:scheme="io.supabase.flowos"'), isTrue);
        expect(content.contains('android:host="login-callback"'), isTrue);
        expect(content.contains('android.intent.action.VIEW'), isTrue);
        expect(content.contains('android.intent.category.BROWSABLE'), isTrue);
      },
    );

    test(
      'iOS Info.plist contains CFBundleURLTypes registration for auth callbacks',
      () {
        final plistFile = File('ios/Runner/Info.plist');
        expect(plistFile.existsSync(), isTrue, reason: 'Info.plist must exist');

        final content = plistFile.readAsStringSync();
        expect(content.contains('<key>CFBundleURLTypes</key>'), isTrue);
        expect(content.contains('<string>io.supabase.flowos</string>'), isTrue);
      },
    );
  });
}
