import 'dart:io';
import 'package:flutter/services.dart';

enum AppFailureCategory {
  auth,
  permission,
  storage,
  network,
  platform,
  unknown,
}

class AppFailure implements Exception {
  final AppFailureCategory category;
  final String operation;
  final String message;
  final String? userRecoveryAction;
  final bool isRetryable;
  final Object? originalError;
  final StackTrace? stackTrace;
  final DateTime timestamp;

  AppFailure({
    required this.category,
    required this.operation,
    required this.message,
    this.userRecoveryAction,
    this.isRetryable = false,
    this.originalError,
    this.stackTrace,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory AppFailure.fromError(
    Object error, {
    required String operation,
    StackTrace? stackTrace,
    String? userRecoveryAction,
  }) {
    if (error is AppFailure) {
      return error;
    }

    if (error is SocketException ||
        error.toString().contains('SocketException') ||
        error.toString().contains('TimeoutException')) {
      return AppFailure(
        category: AppFailureCategory.network,
        operation: operation,
        message: 'Network connection unavailable or timed out.',
        userRecoveryAction:
            userRecoveryAction ?? 'Check internet connection and retry.',
        isRetryable: true,
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    if (error is PlatformException) {
      final isPermission =
          error.code.toLowerCase().contains('permission') ||
          error.message?.toLowerCase().contains('permission') == true;
      return AppFailure(
        category: isPermission
            ? AppFailureCategory.permission
            : AppFailureCategory.platform,
        operation: operation,
        message: error.message ?? 'Platform operation failed (${error.code}).',
        userRecoveryAction: isPermission
            ? 'Grant required system permission in device settings.'
            : 'Retry operation or restart app.',
        isRetryable: !isPermission,
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    final errStr = error.toString().toLowerCase();
    if (errStr.contains('auth') ||
        errStr.contains('jwt') ||
        errStr.contains('unauthorized') ||
        errStr.contains('401') ||
        errStr.contains('403')) {
      return AppFailure(
        category: AppFailureCategory.auth,
        operation: operation,
        message: 'Authentication or session expired.',
        userRecoveryAction: userRecoveryAction ?? 'Sign in again to continue.',
        isRetryable: false,
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    if (errStr.contains('sqlite') ||
        errStr.contains('drift') ||
        errStr.contains('database') ||
        errStr.contains('storage')) {
      return AppFailure(
        category: AppFailureCategory.storage,
        operation: operation,
        message: 'Local storage operation encountered an error.',
        userRecoveryAction:
            userRecoveryAction ?? 'Restart application to retry.',
        isRetryable: true,
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    return AppFailure(
      category: AppFailureCategory.unknown,
      operation: operation,
      message: error.toString(),
      userRecoveryAction: userRecoveryAction ?? 'Retry operation.',
      isRetryable: false,
      originalError: error,
      stackTrace: stackTrace,
    );
  }

  @override
  String toString() {
    return 'AppFailure[$category] (op: $operation): $message';
  }
}
