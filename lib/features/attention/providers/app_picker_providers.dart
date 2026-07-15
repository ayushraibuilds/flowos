import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../repository/attention_data_repository.dart';
import '../../../data/local/database/app_database.dart';

final launchableAppsProvider = FutureProvider<List<Map<String, String>>>((ref) async {
  final platform = ref.watch(deviceAttentionPlatformProvider);
  return platform.getLaunchableApps();
});

final essentialPackagesProvider = FutureProvider<List<Map<String, String>>>((ref) async {
  final platform = ref.watch(deviceAttentionPlatformProvider);
  return platform.getDefaultEssentialPackages();
});

final protectedAppsStreamProvider = StreamProvider<List<ProtectedApp>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.protectedAppsDao.watchAll();
});

final appIconProvider = FutureProvider.family<Uint8List?, String>((ref, packageName) async {
  final platform = ref.watch(deviceAttentionPlatformProvider);
  return platform.loadAppIcon(packageName);
});

final legacySuggestionsProvider = FutureProvider<List<String>>((ref) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    
    // Check if legacy suggestions were already processed/shown
    final shown = prefs.getBool('flowos_legacy_suggestions_shown') ?? false;
    if (shown) return [];

    final rawProfile = prefs.getString('flowos_user_profile');
    if (rawProfile != null) {
      final json = jsonDecode(rawProfile) as Map<String, dynamic>;
      final distractions = List<String>.from(json['distractions'] ?? []);
      if (distractions.isEmpty) return [];

      final launchable = await ref.read(launchableAppsProvider.future);

      final suggestions = <String>[];
      for (final label in distractions) {
        final pkg = _mapLabelToPackageName(label);
        if (pkg != null) {
          // Verify it's actually installed
          final isInstalled = launchable.any((app) => app['packageName'] == pkg);
          if (isInstalled) {
            suggestions.add(pkg);
          }
        }
      }
      return suggestions;
    }
  } catch (_) {}
  return [];
});

String? _mapLabelToPackageName(String label) {
  return switch (label.toLowerCase()) {
    'instagram' => 'com.instagram.android',
    'youtube/shorts' || 'youtube' => 'com.google.android.youtube',
    'tiktok' => 'com.zhiliaoapp.musically',
    'x/twitter' || 'twitter' || 'x' => 'com.twitter.android',
    'reddit' => 'com.reddit.frontpage',
    'browser' => 'com.android.chrome',
    _ => null,
  };
}
