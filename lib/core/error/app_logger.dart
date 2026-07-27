import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'app_failure.dart';
import 'app_redactor.dart';

abstract final class AppLogger {
  /// Structured redacted failure logging and Sentry reporting.
  static void logFailure(AppFailure failure) {
    final sanitizedMsg = AppRedactor.redactText(failure.message);
    final sanitizedOp = AppRedactor.redactText(failure.operation);

    debugPrint(
      '⚠️ AppFailure[${failure.category.name}] ($sanitizedOp): $sanitizedMsg | Recovery: ${failure.userRecoveryAction ?? "None"}',
    );

    if (Sentry.isEnabled && failure.category != AppFailureCategory.permission) {
      Sentry.captureException(
        failure.originalError ?? failure,
        stackTrace: failure.stackTrace,
        withScope: (scope) {
          scope.setTag('failure_category', failure.category.name);
          scope.setTag('operation', sanitizedOp);
          scope.setContexts('failure_details', {
            'is_retryable': failure.isRetryable,
          });
        },
      );
    }
  }

  /// Redacted info logging.
  static void logInfo(
    String message, {
    String category = 'app',
    Map<String, dynamic>? details,
  }) {
    final sanitizedMsg = AppRedactor.redactText(message);
    final sanitizedDetails = details != null
        ? AppRedactor.redactMap(details)
        : null;

    debugPrint(
      'ℹ️ [$category] $sanitizedMsg${sanitizedDetails != null ? " | $sanitizedDetails" : ""}',
    );
  }

  /// Handler for PlatformDispatcher.onError to capture unhandled async errors.
  static bool handleUnhandledError(Object error, StackTrace stackTrace) {
    final failure = AppFailure.fromError(
      error,
      operation: 'unhandled_async_dispatcher',
      stackTrace: stackTrace,
    );

    logFailure(failure);
    return true;
  }
}
