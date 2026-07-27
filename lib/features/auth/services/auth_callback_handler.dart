enum AuthCallbackStatus {
  /// Valid callback URL with tokens / session payload
  success,

  /// Error payload from provider / Supabase (e.g. canceled, expired, invalid code)
  error,

  /// Unrecognized scheme, host, or malicious deep link attempt
  invalid,
}

class AuthCallbackResult {
  final AuthCallbackStatus status;
  final String? error;
  final String? errorDescription;
  final String? type;

  const AuthCallbackResult({
    required this.status,
    this.error,
    this.errorDescription,
    this.type,
  });

  bool get isSuccess => status == AuthCallbackStatus.success;
  bool get isError => status == AuthCallbackStatus.error;
  bool get isInvalid => status == AuthCallbackStatus.invalid;

  /// Parse and validate deep link callback URI for Supabase auth flows.
  /// Expects scheme: `io.supabase.flowos` and host: `login-callback`.
  static AuthCallbackResult parse(Uri uri) {
    if (uri.scheme != 'io.supabase.flowos' || uri.host != 'login-callback') {
      return const AuthCallbackResult(status: AuthCallbackStatus.invalid);
    }

    final queryParams = uri.queryParameters;
    final fragment = uri.fragment;
    final fragmentParams = Uri.splitQueryString(fragment);

    final error = queryParams['error'] ?? fragmentParams['error'];
    final errorDesc =
        queryParams['error_description'] ?? fragmentParams['error_description'];
    final type = queryParams['type'] ?? fragmentParams['type'];

    if (error != null && error.isNotEmpty) {
      return AuthCallbackResult(
        status: AuthCallbackStatus.error,
        error: error,
        errorDescription: errorDesc,
        type: type,
      );
    }

    return AuthCallbackResult(status: AuthCallbackStatus.success, type: type);
  }
}
