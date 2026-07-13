import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';

class UserProfileStore {
  static const _key = 'flowos_user_profile';

  final SharedPreferences _prefs;

  UserProfileStore(this._prefs);

  UserProfile getProfile() {
    final raw = _prefs.getString(_key);
    if (raw == null) {
      return UserProfile.defaults();
    }
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return UserProfile.fromJson(json);
    } catch (_) {
      return UserProfile.defaults();
    }
  }

  Future<void> saveProfile(UserProfile profile) async {
    final raw = jsonEncode(profile.toJson());
    await _prefs.setString(_key, raw);
  }
}
