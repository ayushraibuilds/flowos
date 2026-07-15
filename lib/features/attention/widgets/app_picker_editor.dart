import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../features/attention/providers/app_picker_providers.dart';

class AppPickerEditor extends ConsumerStatefulWidget {
  final Map<String, bool> initialFocusState;
  final Map<String, bool> initialSleepState;
  final void Function(Map<String, bool> focusState, Map<String, bool> sleepState) onSelectionChanged;
  final bool showLegacySuggestions;

  const AppPickerEditor({
    super.key,
    required this.initialFocusState,
    required this.initialSleepState,
    required this.onSelectionChanged,
    this.showLegacySuggestions = false,
  });

  @override
  ConsumerState<AppPickerEditor> createState() => _AppPickerEditorState();
}

class _AppPickerEditorState extends ConsumerState<AppPickerEditor> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  final _searchController = TextEditingController();

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

  void _initializeState(List<Map<String, String>> launchable) {
    if (_initialized) return;
    _initialized = true;

    // Load initial states
    for (final app in launchable) {
      final pkg = app['packageName'] ?? '';
      _localFocusState[pkg] = widget.initialFocusState[pkg] ?? false;
      _localSleepState[pkg] = widget.initialSleepState[pkg] ?? false;
    }

    // Load legacy suggestions if configured
    if (widget.showLegacySuggestions) {
      ref.read(legacySuggestionsProvider.future).then((suggestions) {
        if (suggestions.isNotEmpty && mounted) {
          setState(() {
            _suggestedPackages = suggestions;
            _showBanner = true;
          });
        }
      });
    }
  }

  void _dismissBanner() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('flowos_legacy_suggestions_shown', true);
    if (mounted) {
      setState(() {
        _showBanner = false;
      });
    }
  }

  void _prefillSuggestions() {
    setState(() {
      for (final pkg in _suggestedPackages) {
        _localFocusState[pkg] = true;
      }
      _showBanner = false;
    });
    widget.onSelectionChanged(_localFocusState, _localSleepState);
  }

  @override
  Widget build(BuildContext context) {
    final launchableAsync = ref.watch(launchableAppsProvider);
    final essentialAsync = ref.watch(essentialPackagesProvider);

    return launchableAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error loading apps: $err')),
      data: (launchable) {
        _initializeState(launchable);

        return essentialAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Error loading essential apps: $err')),
          data: (essentials) {
            final essentialPackageNames = essentials.map((e) => e['packageName']).toSet();

            // Filter distracting apps by search query
            final distractingApps = launchable.where((app) {
              final pkg = app['packageName'] ?? '';
              final label = app['label'] ?? '';
              final isEssential = essentialPackageNames.contains(pkg);
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
                // Tab Header
                TabBar(
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
                    widget.onSelectionChanged(_localFocusState, _localSleepState);
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
                    widget.onSelectionChanged(_localFocusState, _localSleepState);
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
