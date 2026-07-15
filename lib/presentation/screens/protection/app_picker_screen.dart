import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart' show Value;

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/local/database/app_database.dart';
import '../../../features/attention/providers/app_picker_providers.dart';
import '../../../features/attention/widgets/app_picker_editor.dart';
import '../../../features/settings/providers/sleep_mode_provider.dart';

class AppPickerScreen extends ConsumerStatefulWidget {
  const AppPickerScreen({super.key});

  @override
  ConsumerState<AppPickerScreen> createState() => _AppPickerScreenState();
}

class _AppPickerScreenState extends ConsumerState<AppPickerScreen> {
  // Local state copy
  Map<String, bool> _focusState = {};
  Map<String, bool> _sleepState = {};
  bool _initialized = false;

  void _initializeState(List<ProtectedApp> savedApps) {
    if (_initialized) return;
    _initialized = true;
    for (final app in savedApps) {
      _focusState[app.appRef] = app.protectsFocus;
      _sleepState[app.appRef] = app.protectsSleep;
    }
  }

  Future<void> _savePolicy() async {
    final db = ref.read(databaseProvider);
    final now = DateTime.now();

    // Load launchable apps to save policy for all of them
    final launchable = await ref.read(launchableAppsProvider.future);

    for (final app in launchable) {
      final pkg = app['packageName'] ?? '';
      final label = app['label'] ?? '';
      final isFocusChecked = _focusState[pkg] ?? false;
      final isSleepChecked = _sleepState[pkg] ?? false;

      if (isFocusChecked || isSleepChecked) {
        final existing = await db.protectedAppsDao.getByPlatformAndRef('android', pkg);
        final entryId = existing?.id ?? const Uuid().v4();

        await db.protectedAppsDao.upsertApp(
          ProtectedAppsCompanion(
            id: Value(entryId),
            platform: const Value('android'),
            appRef: Value(pkg),
            displayName: Value(label),
            protectsFocus: Value(isFocusChecked),
            protectsSleep: Value(isSleepChecked),
            isEssential: const Value(false),
            createdAt: Value(now),
          ),
        );
      } else {
        // Deselecting both deletes or marks unprotected
        final existing = await db.protectedAppsDao.getByPlatformAndRef('android', pkg);
        if (existing != null) {
          await db.protectedAppsDao.updateFlags(
            platform: 'android',
            appRef: pkg,
            protectsFocus: false,
            protectsSleep: false,
          );
          await db.protectedAppsDao.deleteIfUnprotected('android', pkg);
        }
      }
    }

    // Refresh versioned native sleep config
    await ref.read(sleepConfigWriterProvider).writeSleepConfig();

    // Set suggestions shown flag
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('flowos_legacy_suggestions_shown', true);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('App protection policies saved successfully.'),
          backgroundColor: AppColors.emerald,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final protectedAsync = ref.watch(protectedAppsStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.background0,
      appBar: AppBar(
        backgroundColor: AppColors.background0,
        elevation: 0,
        title: Text(
          'Choose apps to protect',
          style: AppTypography.h3.copyWith(color: AppColors.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: _savePolicy,
            child: Text(
              'Save',
              style: AppTypography.button.copyWith(
                color: AppColors.emerald,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: protectedAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error loading policies: $err')),
        data: (savedApps) {
          _initializeState(savedApps);
          return AppPickerEditor(
            initialFocusState: _focusState,
            initialSleepState: _sleepState,
            showLegacySuggestions: true,
            onSelectionChanged: (focus, sleep) {
              _focusState = focus;
              _sleepState = sleep;
            },
          );
        },
      ),
    );
  }
}
