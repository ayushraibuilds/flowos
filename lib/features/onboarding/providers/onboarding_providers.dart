import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';
import '../services/user_profile_store.dart';

class UserProfileNotifier extends StateNotifier<UserProfile> {
  UserProfileNotifier() : super(UserProfile.defaults()) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final store = UserProfileStore(prefs);
    state = store.getProfile();
  }

  Future<void> updateProfile(UserProfile profile) async {
    state = profile;
    final prefs = await SharedPreferences.getInstance();
    final store = UserProfileStore(prefs);
    await store.saveProfile(profile);
  }
}

final userProfileProvider = StateNotifierProvider<UserProfileNotifier, UserProfile>((ref) {
  return UserProfileNotifier();
});
