import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart' show Value;
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/local/database/app_database.dart';
import '../../../features/attention/repository/attention_data_repository.dart';
import '../../../features/attention/widgets/accessibility_disclosure_dialog.dart';
import '../../../features/attention/widgets/app_picker_editor.dart';
import '../../../features/attention/providers/app_picker_providers.dart';
import '../../../features/settings/providers/sleep_mode_provider.dart';

class OnboardingConnectScreen extends ConsumerStatefulWidget {
  final VoidCallback onComplete;

  const OnboardingConnectScreen({
    super.key,
    required this.onComplete,
  });

  @override
  ConsumerState<OnboardingConnectScreen> createState() => _OnboardingConnectScreenState();
}

class _OnboardingConnectScreenState extends ConsumerState<OnboardingConnectScreen>
    with WidgetsBindingObserver {
  bool _usagePermissionActive = false;
  bool _accessibilityPermissionActive = false;
  bool _syncingUsage = false;
  String? _syncMessage;

  // Selected apps from picker modal
  Map<String, bool> _focusState = {};
  Map<String, bool> _sleepState = {};
  bool _pickerConfirmed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermissions();
    }
  }

  Future<void> _checkPermissions() async {
    try {
      final states = await ref.read(deviceAttentionPlatformProvider).getPermissionStates();
      if (!mounted) return;

      final previousUsage = _usagePermissionActive;
      setState(() {
        _usagePermissionActive = states.usageAccess;
        _accessibilityPermissionActive = states.accessibility;
      });

      // If Usage Access just turned true, trigger async 7-day sync
      if (states.usageAccess && !previousUsage) {
        _runAsyncSync();
      }
    } catch (_) {}
  }

  Future<void> _runAsyncSync() async {
    setState(() {
      _syncingUsage = true;
      _syncMessage = null;
    });

    try {
      // Sync last 7 days
      await ref.read(attentionDataRepositoryProvider).syncUsage(days: 7);
      
      final db = ref.read(databaseProvider);
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final yesterdayStart = DateTime(yesterday.year, yesterday.month, yesterday.day);
      final yesterdayEnd = yesterdayStart.add(const Duration(days: 1));
      
      final records = await db.deviceUsageRecordsDao.getForRange(yesterdayStart, yesterdayEnd);
      final distractingMins = records
          .where((r) => r.isDistracting)
          .fold<int>(0, (sum, r) => sum + r.minutes);

      if (mounted) {
        setState(() {
          _syncingUsage = false;
          if (distractingMins > 0) {
            _syncMessage = 'Yesterday: ${distractingMins}m on selected apps.';
          } else {
            _syncMessage = 'Screen time data will appear after a day of use.';
          }
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _syncingUsage = false;
          _syncMessage = 'Screen time data will appear after a day of use.';
        });
      }
    }
  }

  Future<void> _requestUsagePermission() async {
    try {
      await ref.read(deviceAttentionPlatformProvider).openUsageAccessSettings();
    } catch (_) {}
  }

  Future<void> _requestAccessibilityPermission() async {
    try {
      final platform = ref.read(deviceAttentionPlatformProvider);
      if (!_accessibilityPermissionActive) {
        await showAccessibilityDisclosure(context, platform);
      } else {
        await platform.openAccessibilitySettings();
      }
    } catch (_) {}
  }

  void _openAppPickerModal() {
    Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => _OnboardingAppPickerModal(
          initialFocusState: _focusState,
          initialSleepState: _sleepState,
          onSelectionConfirmed: (focus, sleep) {
            setState(() {
              _focusState = focus;
              _sleepState = sleep;
              _pickerConfirmed = true;
            });
          },
        ),
      ),
    );
  }

  int get _selectedAppsCount {
    return _focusState.entries.where((e) => e.value).length +
        _sleepState.entries.where((e) => e.value).length;
  }

  Future<void> _saveAndFinish() async {
    HapticFeedback.mediumImpact();
    
    // Only write policies to database if they were confirmed
    if (_pickerConfirmed) {
      final db = ref.read(databaseProvider);
      final now = DateTime.now();
      
      // Load launchable apps to match packages with labels
      final launchable = await ref.read(launchableAppsProvider.future);

      for (final entry in _focusState.entries) {
        final pkg = entry.key;
        final isFocusChecked = entry.value;
        final isSleepChecked = _sleepState[pkg] ?? false;

        if (isFocusChecked || isSleepChecked) {
          final existing = await db.protectedAppsDao.getByPlatformAndRef('android', pkg);
          final entryId = existing?.id ?? const Uuid().v4();
          final appInfo = launchable.firstWhere(
            (a) => a['packageName'] == pkg,
            orElse: () => <String, String>{},
          );
          final label = appInfo['label'] ?? pkg;

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
        }
      }
    }

    // Refresh versioned native sleep config after picker selection completes
    await ref.read(sleepConfigWriterProvider).writeSleepConfig();

    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    final isAndroid = Theme.of(context).platform == TargetPlatform.android;

    return Scaffold(
      backgroundColor: AppColors.background0,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl,
                  vertical: AppSpacing.xxl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Connect & Protect', style: AppTypography.h1),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Decide what FlowOS protects and enable integrations.',
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: AppSpacing.xxl),

                    if (isAndroid) ...[
                      // App Protection Summary Card
                      Text(
                        'App Protection',
                        style: AppTypography.h3.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _buildAppPickerCTA(),
                      
                      const SizedBox(height: AppSpacing.xxl),

                      // Permissions
                      Text(
                        'Device Integrations',
                        style: AppTypography.h3.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      _buildPermissionCard(
                        title: 'Usage Access (Optional)',
                        description: 'See which selected apps use your time so your daily score reflects reality.',
                        status: _usagePermissionActive,
                        onTap: _requestUsagePermission,
                        extraWidget: _buildSyncStatus(),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _buildPermissionCard(
                        title: 'Accessibility Blocker (Optional)',
                        description: 'Apply your focus shields to selected apps during focus sessions.',
                        status: _accessibilityPermissionActive,
                        onTap: _requestAccessibilityPermission,
                      ),
                    ] else ...[
                      // iOS Placeholder
                      _buildIosPlaceholder(),
                    ],
                  ],
                ),
              ),
            ),

            // Finish button (always active)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _saveAndFinish,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.emerald,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
                    ),
                  ),
                  child: Text(
                    'Finish',
                    style: AppTypography.button,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppPickerCTA() {
    final count = _selectedAppsCount;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.background2,
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        border: Border.all(
          color: _pickerConfirmed && count > 0
              ? AppColors.emerald.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Choose what pulls you away',
                style: AppTypography.body.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              if (_pickerConfirmed)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.emerald.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                  ),
                  child: Text(
                    '$count apps selected',
                    style: AppTypography.monoSmall.copyWith(
                      color: AppColors.emerald,
                      fontSize: 10,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Select installed apps that FlowOS should shield during focus sessions.',
            style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton(
            onPressed: _openAppPickerModal,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(40),
              side: BorderSide(color: AppColors.emerald),
              foregroundColor: AppColors.emerald,
            ),
            child: Text(
              _pickerConfirmed ? 'Manage Selection' : 'Select Apps',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionCard({
    required String title,
    required String description,
    required bool status,
    required VoidCallback onTap,
    Widget? extraWidget,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.background2,
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        border: Border.all(
          color: status
              ? AppColors.emerald.withValues(alpha: 0.1)
              : Colors.white.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
                decoration: BoxDecoration(
                  color: status
                      ? AppColors.emerald.withValues(alpha: 0.1)
                      : AppColors.warningAmber.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                ),
                child: Text(
                  status ? 'Connected' : 'Pending',
                  style: AppTypography.monoSmall.copyWith(
                    color: status ? AppColors.emerald : AppColors.warningAmber,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            description,
            style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
          ),
          if (extraWidget != null) extraWidget,
          const SizedBox(height: AppSpacing.md),
          OutlinedButton(
            onPressed: onTap,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(36),
              side: BorderSide(
                color: status ? AppColors.textTertiary.withValues(alpha: 0.2) : AppColors.emerald,
              ),
              foregroundColor: status ? AppColors.textPrimary : AppColors.emerald,
            ),
            child: Text(status ? 'Settings Configured' : 'Grant Permission'),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncStatus() {
    if (_syncingUsage) {
      return Padding(
        padding: const EdgeInsets.only(top: AppSpacing.md),
        child: Row(
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.emerald),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'Syncing device usage...',
              style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    if (_syncMessage != null) {
      return Padding(
        padding: const EdgeInsets.only(top: AppSpacing.md),
        child: Text(
          _syncMessage!,
          style: AppTypography.caption.copyWith(
            color: AppColors.emerald,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildIosPlaceholder() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.background2,
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline_rounded, color: AppColors.emerald),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'iOS Screen Time Permissions',
                style: AppTypography.body.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'App selection and device metrics will be available after native iOS Screen Time support is approved and implemented.\n\nYou can use FlowOS for focus sessions, prioritize tasks, and grow your garden dashboard now.',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingAppPickerModal extends ConsumerStatefulWidget {
  final Map<String, bool> initialFocusState;
  final Map<String, bool> initialSleepState;
  final void Function(Map<String, bool> focus, Map<String, bool> sleep) onSelectionConfirmed;

  const _OnboardingAppPickerModal({
    required this.initialFocusState,
    required this.initialSleepState,
    required this.onSelectionConfirmed,
  });

  @override
  ConsumerState<_OnboardingAppPickerModal> createState() => _OnboardingAppPickerModalState();
}

class _OnboardingAppPickerModalState extends ConsumerState<_OnboardingAppPickerModal> {
  late Map<String, bool> _focusState;
  late Map<String, bool> _sleepState;

  @override
  void initState() {
    super.initState();
    _focusState = Map.from(widget.initialFocusState);
    _sleepState = Map.from(widget.initialSleepState);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background0,
      appBar: AppBar(
        backgroundColor: AppColors.background0,
        elevation: 0,
        title: Text(
          'Choose apps to protect',
          style: AppTypography.h3.copyWith(color: AppColors.textPrimary),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: () {
              widget.onSelectionConfirmed(_focusState, _sleepState);
              Navigator.pop(context);
            },
            child: Text(
              'Done',
              style: AppTypography.button.copyWith(
                color: AppColors.emerald,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: AppPickerEditor(
        initialFocusState: _focusState,
        initialSleepState: _sleepState,
        showLegacySuggestions: true,
        onSelectionChanged: (focus, sleep) {
          _focusState = focus;
          _sleepState = sleep;
        },
      ),
    );
  }
}
