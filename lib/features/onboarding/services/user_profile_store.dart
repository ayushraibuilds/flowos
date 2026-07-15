import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';

class UserProfileStore {
  static const _key = 'flowos_user_profile';

  final SharedPreferences _prefs;

  UserProfileStore(this._prefs);

  UserProfile getProfile() {
    final raw = _prefs.getString(_key);
    final onboardingComplete = _prefs.getBool('flowos_onboarding_complete') ?? false;

    if (raw == null) {
      if (onboardingComplete) {
        return UserProfile.defaults().copyWith(
          completedOnboardingVersion: 1,
          protectedWindowConfigured: true,
        );
      }
      return UserProfile.defaults();
    }
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      var profile = UserProfile.fromJson(json);
      
      final completedVersion = json['completedOnboardingVersion'] ?? (onboardingComplete ? 1 : 0);
      final windowConfigured = json['protectedWindowConfigured'] ?? (onboardingComplete || completedVersion == 1);

      profile = profile.copyWith(
        completedOnboardingVersion: completedVersion,
        protectedWindowConfigured: windowConfigured,
      );
      return profile;
    } catch (_) {
      if (onboardingComplete) {
        return UserProfile.defaults().copyWith(
          completedOnboardingVersion: 1,
          protectedWindowConfigured: true,
        );
      }
      return UserProfile.defaults();
    }
  }

  Future<void> saveProfile(UserProfile profile) async {
    final raw = jsonEncode(profile.toJson());
    await _prefs.setString(_key, raw);
  }
}
