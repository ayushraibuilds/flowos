enum AiErrorType {
  /// User is not signed in / running in local-only mode
  unauthenticated,

  /// Device has no internet connection or server socket failed
  offline,

  /// Connection, send, or receive timeout
  timeout,

  /// Invalid credentials or token expired and refresh failed (HTTP 401/403)
  unauthorized,

  /// Rate limit or quota exceeded (HTTP 429)
  quotaExceeded,

  /// Request validation failed or payload invalid (HTTP 422)
  validationError,

  /// Backend server error (HTTP 500-599)
  serverError,

  /// Unexpected failure
  unknown,
}

class AiException implements Exception {
  final AiErrorType type;
  final String message;
  final int? statusCode;

  const AiException({
    required this.type,
    required this.message,
    this.statusCode,
  });

  bool get isLocalOrLoggedOut => type == AiErrorType.unauthenticated;
  bool get isNetworkIssue =>
      type == AiErrorType.offline || type == AiErrorType.timeout;

  @override
  String toString() => 'AiException($type, status: $statusCode): $message';
}
