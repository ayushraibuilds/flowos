class UserProfile {
  final List<String> goals;
  final List<String> distractions;
  final int protectedStartHour;
  final int protectedEndHour;
  final bool protectedWeekdaysOnly;
  final String protectionMode; // 'gentle' | 'firm'

  const UserProfile({
    required this.goals,
    required this.distractions,
    required this.protectedStartHour,
    required this.protectedEndHour,
    required this.protectedWeekdaysOnly,
    required this.protectionMode,
  });

  factory UserProfile.defaults() {
    return const UserProfile(
      goals: ['Deep work'],
      distractions: ['Instagram', 'YouTube/Shorts', 'TikTok'],
      protectedStartHour: 9,
      protectedEndHour: 11,
      protectedWeekdaysOnly: true,
      protectionMode: 'gentle',
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
    };
  }
}
