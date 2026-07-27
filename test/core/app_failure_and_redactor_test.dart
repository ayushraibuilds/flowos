import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flowos/core/error/app_failure.dart';
import 'package:flowos/core/error/app_logger.dart';
import 'package:flowos/core/error/app_redactor.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TASK-018: Typed Failures & Redacted Observability Tests', () {
    test('AppRedactor sanitizes JWT tokens, emails, and sensitive keys', () {
      const rawJwt =
          'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c';
      final redactedJwt = AppRedactor.redactText(rawJwt);
      expect(
        redactedJwt,
        isNot(contains('eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9')),
      );
      expect(redactedJwt, contains('[REDACTED_JWT]'));

      const rawEmail = 'Contact user at john.doe@example.com for support';
      final redactedEmail = AppRedactor.redactText(rawEmail);
      expect(redactedEmail, isNot(contains('john.doe@example.com')));
      expect(redactedEmail, contains('[REDACTED_EMAIL]'));

      final sensitiveMap = {
        'user_id': '123',
        'email': 'user@flowos.app',
        'password': 'super_secret_password',
        'access_token': 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.token.sig',
        'task_title': 'Top Secret Project',
      };
      final redactedMap = AppRedactor.redactMap(sensitiveMap);

      expect(redactedMap['user_id'], equals('123'));
      expect(redactedMap['password'], equals('[REDACTED]'));
      expect(redactedMap['access_token'], equals('[REDACTED]'));
      expect(redactedMap['task_title'], equals('[REDACTED]'));
      expect(redactedMap['email'], equals('[REDACTED]'));
    });

    test(
      'AppFailure.fromError classifies SocketException as network failure',
      () {
        final failure = AppFailure.fromError(
          const SocketException('Failed host lookup: api.supabase.co'),
          operation: 'sync_push',
        );

        expect(failure.category, equals(AppFailureCategory.network));
        expect(failure.isRetryable, isTrue);
        expect(failure.userRecoveryAction, contains('internet connection'));
      },
    );

    test(
      'AppFailure.fromError classifies PlatformException with permission code',
      () {
        final failure = AppFailure.fromError(
          PlatformException(
            code: 'PERMISSION_DENIED',
            message: 'Usage stats permission required',
          ),
          operation: 'check_usage_stats',
        );

        expect(failure.category, equals(AppFailureCategory.permission));
        expect(failure.isRetryable, isFalse);
        expect(failure.userRecoveryAction, contains('device settings'));
      },
    );

    test('AppFailure.fromError classifies Auth and SQLite storage errors', () {
      final authFailure = AppFailure.fromError(
        Exception('401 Unauthorized JWT expired'),
        operation: 'fetch_profile',
      );
      expect(authFailure.category, equals(AppFailureCategory.auth));
      expect(authFailure.isRetryable, isFalse);

      final storageFailure = AppFailure.fromError(
        Exception('SqliteException(787): foreign key constraint failed'),
        operation: 'insert_task',
      );
      expect(storageFailure.category, equals(AppFailureCategory.storage));
      expect(storageFailure.isRetryable, isTrue);
    });

    test(
      'AppLogger.handleUnhandledError processes unhandled async dispatcher errors',
      () {
        final handled = AppLogger.handleUnhandledError(
          Exception('Async background task unexpected failure'),
          StackTrace.current,
        );

        expect(handled, isTrue);
      },
    );
  });
}
