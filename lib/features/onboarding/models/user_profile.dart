class UserProfile {
  final List<String> goals;
  final List<String> distractions;
  final int protectedStartHour;
  final int protectedEndHour;
  final bool protectedWeekdaysOnly;
  final String protectionMode; // 'gentle' | 'firm'

  // New M2 fields
  final int preferredFocusMinutes;
  final int completedOnboardingVersion;
  final bool deviceSetupAcknowledged;
  final bool protectedWindowConfigured;

  const UserProfile({
    required this.goals,
    required this.distractions,
    required this.protectedStartHour,
    required this.protectedEndHour,
    required this.protectedWeekdaysOnly,
    required this.protectionMode,
    required this.preferredFocusMinutes,
    required this.completedOnboardingVersion,
    required this.deviceSetupAcknowledged,
    required this.protectedWindowConfigured,
  });

  factory UserProfile.defaults() {
    return const UserProfile(
      goals: ['Deep work'],
      distractions: ['Instagram', 'YouTube/Shorts', 'TikTok'],
      protectedStartHour: 9,
      protectedEndHour: 11,
      protectedWeekdaysOnly: true,
      protectionMode: 'gentle',
      preferredFocusMinutes: 25,
      completedOnboardingVersion: 0,
      deviceSetupAcknowledged: false,
      protectedWindowConfigured: false,
    );
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      goals: List<String>.from(json['goals'] ?? []),
      distractions: List<String>.from(json['distractions'] ?? []),
      protectedStartHour: json['protectedStartHour'] ?? 9,
      protectedEndHour: json['protectedEndHour'] ?? 11,
      protectedWeekdaysOnly: json['protectedWeekdaysOnly'] ?? true,
      protectionMode: json['protectionMode'] ?? 'gentle',
      preferredFocusMinutes: json['preferredFocusMinutes'] ?? 25,
      completedOnboardingVersion: json['completedOnboardingVersion'] ?? 0,
      deviceSetupAcknowledged: json['deviceSetupAcknowledged'] ?? false,
      protectedWindowConfigured: json['protectedWindowConfigured'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'goals': goals,
      'distractions': distractions,
      'protectedStartHour': protectedStartHour,
      'protectedEndHour': protectedEndHour,
      'protectedWeekdaysOnly': protectedWeekdaysOnly,
      'protectionMode': protectionMode,
      'preferredFocusMinutes': preferredFocusMinutes,
      'completedOnboardingVersion': completedOnboardingVersion,
      'deviceSetupAcknowledged': deviceSetupAcknowledged,
      'protectedWindowConfigured': protectedWindowConfigured,
    };
  }

  UserProfile copyWith({
    List<String>? goals,
    List<String>? distractions,
    int? protectedStartHour,
    int? protectedEndHour,
    bool? protectedWeekdaysOnly,
    String? protectionMode,
    int? preferredFocusMinutes,
    int? completedOnboardingVersion,
    bool? deviceSetupAcknowledged,
    bool? protectedWindowConfigured,
  }) {
    return UserProfile(
      goals: goals ?? this.goals,
      distractions: distractions ?? this.distractions,
      protectedStartHour: protectedStartHour ?? this.protectedStartHour,
      protectedEndHour: protectedEndHour ?? this.protectedEndHour,
      protectedWeekdaysOnly: protectedWeekdaysOnly ?? this.protectedWeekdaysOnly,
      protectionMode: protectionMode ?? this.protectionMode,
      preferredFocusMinutes: preferredFocusMinutes ?? this.preferredFocusMinutes,
      completedOnboardingVersion: completedOnboardingVersion ?? this.completedOnboardingVersion,
      deviceSetupAcknowledged: deviceSetupAcknowledged ?? this.deviceSetupAcknowledged,
      protectedWindowConfigured: protectedWindowConfigured ?? this.protectedWindowConfigured,
    );
  }

  bool isInProtectedWindow([DateTime? now]) {
    if (!protectedWindowConfigured) return false;
    final time = now ?? DateTime.now();

    // Check if weekdays only is enabled, and if today is a weekday
    if (protectedWeekdaysOnly) {
      if (time.weekday == DateTime.saturday || time.weekday == DateTime.sunday) {
        return false;
      }
    }

    final currentHour = time.hour;
    if (protectedStartHour <= protectedEndHour) {
      return currentHour >= protectedStartHour && currentHour < protectedEndHour;
    } else {
      // Overnight range, e.g. 22:00 to 06:00
      return currentHour >= protectedStartHour || currentHour < protectedEndHour;
    }
  }

  String get protectedWindowLabel {
    final start = _formatHour(protectedStartHour);
    final end = _formatHour(protectedEndHour);
    return '$start - $end';
  }

  static String _formatHour(int hour) {
    if (hour == 0) return '12 AM';
    if (hour == 12) return '12 PM';
    return hour < 12 ? '$hour AM' : '${hour - 12} PM';
  }
}
