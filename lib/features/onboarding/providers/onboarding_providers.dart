import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';
import '../services/user_profile_store.dart';

final profileLoadedProvider = StateProvider<bool>((ref) => false);

class UserProfileNotifier extends StateNotifier<UserProfile> {
  final Ref _ref;

  UserProfileNotifier(this._ref) : super(UserProfile.defaults()) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final store = UserProfileStore(prefs);
    state = store.getProfile();
    _ref.read(profileLoadedProvider.notifier).state = true;
  }

  Future<void> updateProfile(UserProfile profile) async {
    state = profile;
    final prefs = await SharedPreferences.getInstance();
    final store = UserProfileStore(prefs);
    await store.saveProfile(profile);
  }

  bool get needsDeviceSetup => state.completedOnboardingVersion < 2 && !state.deviceSetupAcknowledged;

  Future<void> markDeviceSetupAcknowledged() async {
    await updateProfile(state.copyWith(
      completedOnboardingVersion: 2,
      deviceSetupAcknowledged: true,
    ));
  }
}

final userProfileProvider = StateNotifierProvider<UserProfileNotifier, UserProfile>((ref) {
  return UserProfileNotifier(ref);
});
