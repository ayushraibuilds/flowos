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

class AppPickerScreen extends ConsumerStatefulWidget {
  const AppPickerScreen({super.key});

  @override
  ConsumerState<AppPickerScreen> createState() => _AppPickerScreenState();
}

class _AppPickerScreenState extends ConsumerState<AppPickerScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  final _searchController = TextEditingController();

  // Local checkbox state during edit
  // Key: packageName
  final Map<String, bool> _localFocusState = {};
  final Map<String, bool> _localSleepState = {};

  bool _initialized = false;
  bool _showBanner = false;
  List<String> _suggestedPackages = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _initializeState(List<Map<String, String>> launchable, List<ProtectedApp> savedApps) {
    if (_initialized) return;
    _initialized = true;

    // Initialize map flags from DB
    for (final app in launchable) {
      final pkg = app['packageName'] ?? '';
      final saved = savedApps.firstWhere(
        (s) => s.appRef == pkg,
        orElse: () => ProtectedApp(
          id: '',
          platform: 'android',
          appRef: pkg,
          displayName: '',
          protectsFocus: false,
          protectsSleep: false,
          isEssential: false,
          createdAt: DateTime.now(),
        ),
      );
      _localFocusState[pkg] = saved.protectsFocus;
      _localSleepState[pkg] = saved.protectsSleep;
    }

    // Load legacy suggestions
    ref.read(legacySuggestionsProvider.future).then((suggestions) {
      if (suggestions.isNotEmpty && mounted) {
        setState(() {
          _suggestedPackages = suggestions;
          _showBanner = true;
        });
      }
    });
  }

  Future<void> _savePolicy(List<Map<String, String>> launchable) async {
    final db = ref.read(databaseProvider);
    final now = DateTime.now();

    for (final app in launchable) {
      final pkg = app['packageName'] ?? '';
      final label = app['label'] ?? '';
      final isFocusChecked = _localFocusState[pkg] ?? false;
      final isSleepChecked = _localSleepState[pkg] ?? false;

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

  void _dismissBanner() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('flowos_legacy_suggestions_shown', true);
    setState(() {
      _showBanner = false;
    });
  }

  void _prefillSuggestions() {
    setState(() {
      for (final pkg in _suggestedPackages) {
        _localFocusState[pkg] = true;
      }
      _showBanner = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final launchableAsync = ref.watch(launchableAppsProvider);
    final essentialAsync = ref.watch(essentialPackagesProvider);
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
          launchableAsync.maybeWhen(
            data: (apps) => TextButton(
              onPressed: () => _savePolicy(apps),
              child: Text(
                'Save',
                style: AppTypography.button.copyWith(
                  color: AppColors.emerald,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.emerald,
          labelColor: AppColors.textPrimary,
          unselectedLabelColor: AppColors.textSecondary,
          labelStyle: AppTypography.body.copyWith(fontWeight: FontWeight.bold),
          unselectedLabelStyle: AppTypography.bodySmall,
          tabs: const [
            Tab(text: 'Distracting'),
            Tab(text: 'Always Available'),
          ],
        ),
      ),
      body: launchableAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error loading apps: $err')),
        data: (launchable) {
          return essentialAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Error loading essential apps: $err')),
            data: (essentials) {
              return protectedAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text('Error loading policies: $err')),
                data: (savedApps) {
                  _initializeState(launchable, savedApps);

                  // Extract package lists
                  final essentialPackgeNames = essentials.map((e) => e['packageName']).toSet();

                  // Filter distracting apps by search query
                  final distractingApps = launchable.where((app) {
                    final pkg = app['packageName'] ?? '';
                    final label = app['label'] ?? '';
                    final isEssential = essentialPackgeNames.contains(pkg);
                    if (isEssential) return false;

                    if (_searchQuery.isEmpty) return true;
                    return label.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                        pkg.toLowerCase().contains(_searchQuery.toLowerCase());
                  }).toList();

                  final essentialApps = essentials.where((app) {
                    final pkg = app['packageName'] ?? '';
                    final label = app['packageName'] == 'com.flowos.flowos' ? 'FlowOS' : (app['reason'] ?? 'System app');
                    if (_searchQuery.isEmpty) return true;
                    return label.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                        pkg.toLowerCase().contains(_searchQuery.toLowerCase());
                  }).toList();

                  return Column(
                    children: [
                      // Legacy suggestion banner
                      if (_showBanner && _suggestedPackages.isNotEmpty)
                        MaterialBanner(
                          backgroundColor: AppColors.background1,
                          content: Text(
                            'We found ${_suggestedPackages.length} apps from your earlier setup. Pre-fill them as distracting?',
                            style: AppTypography.bodySmall.copyWith(color: AppColors.textPrimary),
                          ),
                          actions: [
                            TextButton(
                              onPressed: _prefillSuggestions,
                              child: Text('Pre-fill', style: TextStyle(color: AppColors.emerald)),
                            ),
                            TextButton(
                              onPressed: _dismissBanner,
                              child: const Text('Dismiss', style: TextStyle(color: AppColors.textSecondary)),
                            ),
                          ],
                        ),

                      // Search bar
                      Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: TextField(
                          controller: _searchController,
                          style: AppTypography.body.copyWith(color: AppColors.textPrimary),
                          decoration: InputDecoration(
                            hintText: 'Search apps...',
                            hintStyle: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                            prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                            fillColor: AppColors.background1,
                            filled: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(vertical: 0),
                          ),
                          onChanged: (val) {
                            setState(() {
                              _searchQuery = val;
                            });
                          },
                        ),
                      ),

                      // TabViews
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            // 1. Distracting Tab
                            distractingApps.isEmpty
                                ? Center(
                                    child: Text(
                                      _searchQuery.isEmpty ? 'No apps found.' : 'No matching apps found.',
                                      style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                                    ),
                                  )
                                : ListView.builder(
                                    itemCount: distractingApps.length,
                                    itemBuilder: (context, index) {
                                      final app = distractingApps[index];
                                      final pkg = app['packageName'] ?? '';
                                      final label = app['label'] ?? '';

                                      return _buildDistractionRow(pkg, label);
                                    },
                                  ),

                            // 2. Always Available Tab
                            essentialApps.isEmpty
                                ? Center(
                                    child: Text(
                                      _searchQuery.isEmpty ? 'No essential apps.' : 'No matching essential apps.',
                                      style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                                    ),
                                  )
                                : ListView.builder(
                                    itemCount: essentialApps.length,
                                    itemBuilder: (context, index) {
                                      final app = essentialApps[index];
                                      final pkg = app['packageName'] ?? '';
                                      final reason = app['reason'] ?? 'Essential App';

                                      return _buildEssentialRow(pkg, reason);
                                    },
                                  ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildDistractionRow(String packageName, String label) {
    final iconAsync = ref.watch(appIconProvider(packageName));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.background1,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // Lazily loaded app icon
            SizedBox(
              width: 40,
              height: 40,
              child: iconAsync.when(
                loading: () => const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                error: (_, __) => const Icon(Icons.android, color: AppColors.textSecondary),
                data: (bytes) => bytes != null
                    ? Image.memory(bytes, width: 40, height: 40, fit: BoxFit.contain)
                    : const Icon(Icons.android, color: AppColors.textSecondary),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTypography.body.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    packageName,
                    style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            // Focus Toggle
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Checkbox(
                  activeColor: AppColors.emerald,
                  value: _localFocusState[packageName] ?? false,
                  onChanged: (val) {
                    setState(() {
                      _localFocusState[packageName] = val ?? false;
                    });
                  },
                ),
                Text(
                  'Focus',
                  style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(width: AppSpacing.xs),
            // Sleep Toggle
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Checkbox(
                  activeColor: AppColors.emerald,
                  value: _localSleepState[packageName] ?? false,
                  onChanged: (val) {
                    setState(() {
                      _localSleepState[packageName] = val ?? false;
                    });
                  },
                ),
                Text(
                  'Sleep',
                  style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEssentialRow(String packageName, String reason) {
    final iconAsync = ref.watch(appIconProvider(packageName));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.background1.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 40,
              height: 40,
              child: iconAsync.when(
                loading: () => const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                error: (_, __) => const Icon(Icons.android, color: AppColors.textSecondary),
                data: (bytes) => bytes != null
                    ? Image.memory(bytes, width: 40, height: 40, fit: BoxFit.contain)
                    : const Icon(Icons.android, color: AppColors.textSecondary),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    packageName == 'com.flowos.flowos' ? 'FlowOS' : reason,
                    style: AppTypography.body.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    packageName,
                    style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.lock_outline_rounded, color: AppColors.textSecondary, size: 20),
            const SizedBox(width: AppSpacing.sm),
          ],
        ),
      ),
    );
  }
}
