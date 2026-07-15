import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flowos/features/onboarding/models/user_profile.dart';
import 'package:flowos/features/onboarding/services/user_profile_store.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('UserProfile Model Serialization & Deserialization', () {
    test('defaults() sets correct M2 default parameters', () {
      final profile = UserProfile.defaults();
      expect(profile.preferredFocusMinutes, 25);
      expect(profile.completedOnboardingVersion, 0);
      expect(profile.deviceSetupAcknowledged, false);
      expect(profile.protectedWindowConfigured, false);
    });

    test('fromJson successfully parses legacy v1 JSON and sets default fallback values', () {
      final v1Json = {
        'goals': ['Deep work'],
        'distractions': ['Instagram'],
        'protectedStartHour': 9,
        'protectedEndHour': 11,
        'protectedWeekdaysOnly': true,
        'protectionMode': 'gentle',
      };

      final profile = UserProfile.fromJson(v1Json);
      expect(profile.goals, ['Deep work']);
      expect(profile.distractions, ['Instagram']);
      expect(profile.protectedStartHour, 9);
      expect(profile.protectedEndHour, 11);
      expect(profile.protectedWeekdaysOnly, true);
      expect(profile.protectionMode, 'gentle');

      // Defaults for M2 fields
      expect(profile.preferredFocusMinutes, 25);
      expect(profile.completedOnboardingVersion, 0);
      expect(profile.deviceSetupAcknowledged, false);
      expect(profile.protectedWindowConfigured, false);
    });

    test('toJson and fromJson serialize all fields correctly', () {
      final profile = UserProfile(
        goals: ['Study'],
        distractions: ['TikTok'],
        protectedStartHour: 22,
        protectedEndHour: 6,
        protectedWeekdaysOnly: false,
        protectionMode: 'firm',
        preferredFocusMinutes: 45,
        completedOnboardingVersion: 2,
        deviceSetupAcknowledged: true,
        protectedWindowConfigured: true,
      );

      final json = profile.toJson();
      final decoded = UserProfile.fromJson(json);

      expect(decoded.preferredFocusMinutes, 45);
      expect(decoded.completedOnboardingVersion, 2);
      expect(decoded.deviceSetupAcknowledged, true);
      expect(decoded.protectedWindowConfigured, true);
      expect(decoded.protectionMode, 'firm');
    });
  });

  group('UserProfileStore Migration', () {
    test('upgrades legacy v1 profile to completedOnboardingVersion 1 when legacy complete flag is true', () async {
      SharedPreferences.setMockInitialValues({
        'flowos_onboarding_complete': true,
        'flowos_user_profile': jsonEncode({
          'goals': ['Rest'],
          'distractions': ['TikTok'],
          'protectedStartHour': 9,
          'protectedEndHour': 11,
          'protectedWeekdaysOnly': true,
          'protectionMode': 'gentle',
        }),
      });

      final prefs = await SharedPreferences.getInstance();
      final store = UserProfileStore(prefs);
      final profile = store.getProfile();

      expect(profile.completedOnboardingVersion, 1);
      expect(profile.protectedWindowConfigured, true);
      expect(profile.goals, ['Rest']);
    });

    test('retains completedOnboardingVersion 2 and does not overwrite with 1', () async {
      SharedPreferences.setMockInitialValues({
        'flowos_onboarding_complete': true,
        'flowos_user_profile': jsonEncode({
          'goals': ['Rest'],
          'distractions': ['TikTok'],
          'protectedStartHour': 9,
          'protectedEndHour': 11,
          'protectedWeekdaysOnly': true,
          'protectionMode': 'gentle',
          'completedOnboardingVersion': 2,
          'protectedWindowConfigured': false,
        }),
      });

      final prefs = await SharedPreferences.getInstance();
      final store = UserProfileStore(prefs);
      final profile = store.getProfile();

      expect(profile.completedOnboardingVersion, 2);
      expect(profile.protectedWindowConfigured, false);
    });
  });

  group('Protected Window Checks', () {
    test('isInProtectedWindow returns false if protectedWindowConfigured is false', () {
      final profile = UserProfile.defaults().copyWith(
        protectedWindowConfigured: false,
        protectedStartHour: 9,
        protectedEndHour: 17,
      );

      final date = DateTime(2026, 7, 15, 12, 0); // Wednesday 12:00 (inside window)
      expect(profile.isInProtectedWindow(date), false);
    });

    test('isInProtectedWindow returns true inside window if protectedWindowConfigured is true', () {
      final profile = UserProfile.defaults().copyWith(
        protectedWindowConfigured: true,
        protectedStartHour: 9,
        protectedEndHour: 17,
        protectedWeekdaysOnly: true,
      );

      final date = DateTime(2026, 7, 15, 12, 0); // Wednesday 12:00 (inside window)
      expect(profile.isInProtectedWindow(date), true);
    });
  });
}
