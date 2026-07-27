abstract final class AppRedactor {
  static final RegExp _jwtRegex = RegExp(
    r'eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}',
  );

  static final RegExp _emailRegex = RegExp(
    r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}',
  );

  static final Set<String> _sensitiveKeys = {
    'password',
    'access_token',
    'refresh_token',
    'auth_token',
    'secret',
    'api_key',
    'bearer',
    'task_title',
    'title',
    'notification_text',
    'body',
    'email',
  };

  /// Redacts JWT tokens, email addresses, and credential patterns from raw text.
  static String redactText(String input) {
    if (input.isEmpty) return input;
    var sanitized = input.replaceAll(_jwtRegex, '[REDACTED_JWT]');
    sanitized = sanitized.replaceAll(_emailRegex, '[REDACTED_EMAIL]');
    return sanitized;
  }

  /// Sanitizes key-value maps by redacting sensitive keys and values.
  static Map<String, dynamic> redactMap(Map<String, dynamic> input) {
    final result = <String, dynamic>{};
    for (final entry in input.entries) {
      final keyLower = entry.key.toLowerCase();
      if (_sensitiveKeys.contains(keyLower)) {
        result[entry.key] = '[REDACTED]';
      } else if (entry.value is Map<String, dynamic>) {
        result[entry.key] = redactMap(entry.value as Map<String, dynamic>);
      } else if (entry.value is String) {
        result[entry.key] = redactText(entry.value as String);
      } else {
        result[entry.key] = entry.value;
      }
    }
    return result;
  }
}
