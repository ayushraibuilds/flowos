import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/config/supabase_config.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../features/auth/services/auth_service.dart';
import '../../../features/themes/models/flow_theme.dart';
import '../../../features/settings/providers/settings_providers.dart';
import '../../../features/export/services/data_export_service.dart';
import '../../../features/sync/providers/sync_providers.dart';
import '../../../features/dashboard/providers/dashboard_providers.dart';
import '../../../data/local/database/app_database.dart';
import '../../../features/focus/widgets/focus_protection_selector.dart';
import '../../../features/focus/models/focus_protection.dart';
import '../../../features/onboarding/providers/onboarding_providers.dart';
import '../../../features/attention/repository/attention_data_repository.dart';
import '../../../features/attention/widgets/accessibility_disclosure_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'widgets/shape_focus_sheet.dart';

/// Full Settings Screen — notification prefs, themes, scroll budget,
/// sync controls, account management.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> with WidgetsBindingObserver {
  bool _isAccessibilityEnabled = false;
  bool _isInterruptionCollectionEnabled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkAccessibility();
    _loadInterruptionConsent();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkAccessibility();
      _loadInterruptionConsent();
    }
  }

  Future<void> _checkAccessibility() async {
    try {
      final states = await ref.read(deviceAttentionPlatformProvider).getPermissionStates();
      if (mounted) {
        setState(() {
          _isAccessibilityEnabled = states.accessibility;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadInterruptionConsent() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _isInterruptionCollectionEnabled = prefs.getBool('flowos_interruption_collection_enabled') ?? false;
      });
    }
  }

  Future<void> _toggleAccessibilityService(bool enable) async {
    if (enable && !_isAccessibilityEnabled) {
      final platform = DeviceAttentionPlatform();
      await showAccessibilityDisclosure(context, platform);
    }
  }

  Future<void> _toggleInterruptionConsent(bool enable) async {
    if (enable) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.background2,
          title: Text(
            'Interruption Insights Disclosure',
            style: AppTypography.h3.copyWith(color: AppColors.textPrimary),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'FlowOS records only the app that posted a notification and a daily count. It never reads notification text, names, senders, or content. This data stays on your device.',
                style: AppTypography.bodySmall.copyWith(color: AppColors.textPrimary),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'By enabling this, you consent to locally count incoming notification events.',
                style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(
                'Cancel',
                style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(
                'I Consent',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.emerald,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );

      if (confirm == true) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('flowos_interruption_collection_enabled', true);
        if (prefs.getInt('flowos_notification_observed_from') == null) {
          await prefs.setInt('flowos_notification_observed_from', DateTime.now().millisecondsSinceEpoch);
        }
        setState(() {
          _isInterruptionCollectionEnabled = true;
        });

        // Trigger settings request
        final platform = ref.read(deviceAttentionPlatformProvider);
        final states = await platform.getPermissionStates();
        if (!states.notificationAccess) {
          await platform.openNotificationListenerSettings();
        }
      }
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('flowos_interruption_collection_enabled', false);
      setState(() {
        _isInterruptionCollectionEnabled = false;
      });
    }
  }

  Future<void> _confirmDeleteInterruptionHistory() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.background2,
        title: Text(
          'Delete Interruption History',
          style: AppTypography.h3.copyWith(color: AppColors.textPrimary),
        ),
        content: Text(
          'This will permanently delete all daily notification logs, set unlocks to null, and temporarily disable future logs collection. This cannot be undone.',
          style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Delete',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.dangerCoral,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(attentionDataRepositoryProvider).deleteInterruptionHistory();
      setState(() {
        _isInterruptionCollectionEnabled = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Interruption history deleted.'),
            backgroundColor: AppColors.dangerCoral,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentTheme = ref.watch(themeProvider);
    final isLoggedIn = ref.watch(isLoggedInProvider);
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      backgroundColor: AppColors.background0,
      appBar: AppBar(
        title: Text(
          'Settings',
          style: AppTypography.h3.copyWith(color: AppColors.textPrimary),
        ),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        children: [
          const SizedBox(height: AppSpacing.lg),

          // ─── Theme ─────────────────────────────────────
          _sectionHeader('🎨 Theme'),
          _buildThemeSelector(currentTheme),
          const SizedBox(height: AppSpacing.xxl),

          // ─── Notifications ─────────────────────────────
          _sectionHeader('🔔 Notifications'),
          _toggleTile(
            title: 'Energy check-in reminders',
            subtitle: '3× daily (9 AM, 1 PM, 5 PM)',
            value: settings.energyReminders,
            onChanged: (v) =>
                ref.read(settingsProvider.notifier).setEnergyReminders(v),
          ),
          _toggleTile(
            title: 'Daily report reminder',
            subtitle: '9 PM — "Your day in review"',
            value: settings.reportReminder,
            onChanged: (v) =>
                ref.read(settingsProvider.notifier).setReportReminder(v),
          ),
          _toggleTile(
            title: 'Streak warning',
            subtitle: '8 PM if no activity today',
            value: settings.streakWarning,
            onChanged: (v) =>
                ref.read(settingsProvider.notifier).setStreakWarning(v),
          ),
          _toggleTile(
            title: 'Weekly review',
            subtitle: 'Sunday 8 PM — 5-min guided flow',
            value: settings.weeklyReview,
            onChanged: (v) =>
                ref.read(settingsProvider.notifier).setWeeklyReview(v),
          ),
          const SizedBox(height: AppSpacing.xxl),

          // ─── Focus & Attention ─────────────────────────
          _sectionHeader('⏱️ Focus & Attention'),
          _sliderTile(
            title: 'Daily scroll budget',
            value: settings.scrollBudget,
            min: 10,
            max: 120,
            suffix: 'min',
            onChanged: (v) =>
                ref.read(settingsProvider.notifier).setScrollBudget(v.round()),
          ),
          _toggleTile(
            title: 'Ambient sounds',
            subtitle: 'Play background audio during focus',
            value: settings.soundEnabled,
            onChanged: (v) =>
                ref.read(settingsProvider.notifier).setSoundEnabled(v),
          ),
          _actionTile(
            title: 'Focus protection: ${settings.focusProtection.label}',
            subtitle: settings.focusProtection.description,
            icon: Icons.shield_outlined,
            onTap: _showFocusProtectionSheet,
          ),
          _toggleTile(
            title: 'App Shielding (Android)',
            subtitle: _isAccessibilityEnabled
                ? 'Active — Distraction apps will be shielded'
                : 'Tap to configure Accessibility permission',
            value: _isAccessibilityEnabled,
            onChanged: _toggleAccessibilityService,
          ),
          _toggleTile(
            title: 'Interruption Insights (Android)',
            subtitle: _isInterruptionCollectionEnabled
                ? 'Active — Daily notification count and unlocks tracked'
                : 'Consent to collect local notification counts and device unlocks',
            value: _isInterruptionCollectionEnabled,
            onChanged: _toggleInterruptionConsent,
          ),
          _actionTile(
            title: 'System Permissions & Privacy',
            subtitle: 'Manage usage access, accessibility blocker, and notification status',
            icon: Icons.lock_outline_rounded,
            onTap: () => context.push('/permissions'),
          ),
          _actionTile(
            title: 'Manage protected apps',
            subtitle: 'Choose which apps are blocked during focus and sleep',
            icon: Icons.app_blocking_outlined,
            onTap: () => context.push('/app-picker'),
          ),
          _actionTile(
            title: 'Sleep Mode',
            subtitle: 'Configure bedtime app shielding and quiet hours',
            icon: Icons.nights_stay_outlined,
            onTap: () => context.push('/sleep-mode'),
          ),
          _actionTile(
            title: 'Update your rhythm',
            subtitle: 'Update goals and default focus duration',
            icon: Icons.repeat_rounded,
            onTap: () => context.push('/update-rhythm'),
          ),
          _actionTile(
            title: 'Shape my focus',
            subtitle: 'Customize goals, distractions, and protected focus hours',
            icon: Icons.tune_rounded,
            onTap: () => _showShapeFocusSheet(context),
          ),
          const SizedBox(height: AppSpacing.xxl),

          // ─── Sync ──────────────────────────────────────
          _sectionHeader('☁️ Sync'),
          _toggleTile(
            title: 'Auto sync',
            subtitle: 'Sync data to cloud after every change',
            value: settings.autoSync,
            onChanged: (v) =>
                ref.read(settingsProvider.notifier).setAutoSync(v),
          ),
          _actionTile(
            title: 'Sync now',
            subtitle: 'Force a full sync with the server',
            icon: Icons.sync_rounded,
            onTap: () async {
              HapticFeedback.mediumImpact();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Syncing...'),
                  duration: Duration(seconds: 1),
                ),
              );
              try {
                final result = await ref.read(syncControllerProvider).sync();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        result.isPaused
                            ? 'Sync temporarily paused while we improve reliability.'
                            : (result.hasErrors
                                ? 'Sync completed with errors.'
                                : 'Sync successful!'),
                      ),
                      backgroundColor: result.isPaused
                          ? AppColors.warningAmber
                          : (result.hasErrors
                              ? AppColors.dangerCoral
                              : AppColors.emerald),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Sync failed: $e'),
                      backgroundColor: AppColors.dangerCoral,
                    ),
                  );
                }
              }
            },
          ),
          _actionTile(
            title: 'Pair browser extension',
            subtitle: 'Generate a pairing token for your Chrome extension',
            icon: Icons.extension_rounded,
            onTap: () => _showPairingSheet(context),
          ),
          const SizedBox(height: AppSpacing.xxl),

          // ─── Data & Privacy ────────────────────────────
          _sectionHeader('🔒 Data & Privacy'),
          _actionTile(
            title: 'Export my data',
            subtitle: 'Download task, session, and XP history to a JSON file',
            icon: Icons.download_rounded,
            onTap: () => _exportData(context),
          ),
          _actionTile(
            title: 'Delete interruption history (Android)',
            subtitle: 'Permanently remove notification logs and unlock counts',
            icon: Icons.delete_sweep_outlined,
            onTap: () => _confirmDeleteInterruptionHistory(),
          ),
          const SizedBox(height: AppSpacing.xxl),

          // ─── Account ───────────────────────────────────
          _sectionHeader('👤 Account'),
          if (isLoggedIn) ...[
            _actionTile(
              title: 'Sign out',
              subtitle: 'Your local data will be preserved',
              icon: Icons.logout_rounded,
              onTap: () => _confirmSignOut(),
            ),
            _actionTile(
              title: 'Delete all data',
              subtitle: 'Permanently removes all your data',
              icon: Icons.delete_forever_rounded,
              color: AppColors.dangerCoral,
              onTap: () => _confirmDeleteData(),
            ),
          ] else ...[
            _actionTile(
              title: 'Sign in',
              subtitle: 'Sync your data across devices',
              icon: Icons.login_rounded,
              onTap: () => context.push('/auth'),
            ),
          ],
          const SizedBox(height: AppSpacing.xxl),

          // ─── About ─────────────────────────────────────
          _sectionHeader('ℹ️ About'),
          _actionTile(
            title: 'Privacy Policy',
            icon: Icons.privacy_tip_outlined,
            onTap: () => _showPrivacyPolicy(),
          ),
          _actionTile(
            title: 'Terms of Service',
            icon: Icons.description_outlined,
            onTap: () => _showTermsOfService(),
          ),
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                Text(
                  'FlowOS v0.1.0',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Built with 🧠 for deep work.',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xxxl),
        ],
      ),
    );
  }

  // ─── Components ──────────────────────────────────────────

  Widget _sectionHeader(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Text(
        text,
        style: AppTypography.bodySmall.copyWith(
          color: AppColors.textTertiary,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  void _showFocusProtectionSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.background1,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: FocusProtectionSelector(
            value: ref.read(settingsProvider).focusProtection,
            onChanged: (level) {
              ref.read(settingsProvider.notifier).setFocusProtection(level);
              Navigator.pop(sheetContext);
            },
          ),
        ),
      ),
    );
  }

  Widget _toggleTile({
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.background2,
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.body.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeTrackColor: AppColors.emerald,
          ),
        ],
      ),
    );
  }

  Widget _sliderTile({
    required String title,
    required int value,
    required int min,
    required int max,
    required String suffix,
    required ValueChanged<double> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.background2,
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: AppTypography.body.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                '$value $suffix',
                style: AppTypography.monoSmall.copyWith(
                  color: AppColors.emerald,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: AppColors.emerald,
              inactiveTrackColor: AppColors.background0,
              thumbColor: AppColors.emerald,
              overlayColor: AppColors.emerald.withValues(alpha: 0.1),
              trackHeight: 4,
            ),
            child: Slider(
              value: value.toDouble(),
              min: min.toDouble(),
              max: max.toDouble(),
              divisions: (max - min) ~/ 5,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionTile({
    required String title,
    String? subtitle,
    required IconData icon,
    required VoidCallback onTap,
    Color? color,
  }) {
    final tileColor = color ?? AppColors.textPrimary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
        decoration: BoxDecoration(
          color: AppColors.background2,
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: tileColor),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.body.copyWith(color: tileColor),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: AppColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }

  // ─── Theme Selector ──────────────────────────────────────

  Widget _buildThemeSelector(FlowTheme currentTheme) {
    final currentLevel = ref.watch(currentLevelProvider);
    final themeNotifier = ref.read(themeProvider.notifier);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.background2,
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
      ),
      child: Column(
        children: FlowThemes.all.map((theme) {
          final isSelected = currentTheme.id == theme.id;
          final isUnlocked = theme.isUnlocked(currentLevel);

          return GestureDetector(
            onTap: isUnlocked
                ? () {
                    HapticFeedback.selectionClick();
                    themeNotifier.setTheme(theme);
                  }
                : null,
            child: Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.accent.withValues(alpha: 0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(AppSpacing.radiusButton),
                border: Border.all(
                  color: isSelected
                      ? theme.accent.withValues(alpha: 0.4)
                      : Colors.transparent,
                ),
              ),
              child: Row(
                children: [
                  // Color preview
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      gradient: LinearGradient(
                        colors: [theme.background0, theme.accent],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${theme.emoji} ${theme.name}',
                          style: AppTypography.body.copyWith(
                            color: isUnlocked
                                ? AppColors.textPrimary
                                : AppColors.textTertiary,
                          ),
                        ),
                        if (!isUnlocked)
                          Text(
                            '🔒 Unlocks at Level ${theme.unlockLevel}',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textTertiary,
                              fontSize: 10,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    Icon(
                      Icons.check_circle_rounded,
                      size: 20,
                      color: theme.accent,
                    ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─── Confirmations ────────────────────────────────────────

  void _confirmSignOut() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.background2,
        title: Text(
          'Sign out?',
          style: AppTypography.h3.copyWith(color: AppColors.textPrimary),
        ),
        content: Text(
          'Your local data will be preserved. You can sign in again anytime.',
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(authServiceProvider).signOut();
              if (mounted) context.go('/auth');
            },
            child: Text(
              'Sign Out',
              style: TextStyle(color: AppColors.warningAmber),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteData() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.background2,
        title: Text(
          'Delete all data?',
          style: AppTypography.h3.copyWith(color: AppColors.dangerCoral),
        ),
        content: Text(
          'This will permanently delete all your tasks, sessions, XP, and achievements. This cannot be undone.',
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(attentionDataRepositoryProvider).resetAllLocalData();

              final isLoggedIn = ref.read(isLoggedInProvider);
              if (isLoggedIn) {
                await ref.read(authServiceProvider).signOut();
              }

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('All data deleted successfully'),
                    backgroundColor: AppColors.dangerCoral,
                  ),
                );
                context.go('/auth');
              }
            },
            child: Text(
              'Delete Everything',
              style: TextStyle(color: AppColors.dangerCoral),
            ),
          ),
        ],
      ),
    );
  }

  void _showScrollableDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.background2,
        title: Text(
          title,
          style: AppTypography.h3.copyWith(color: AppColors.textPrimary),
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: SingleChildScrollView(
            child: Text(
              content,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicy() {
    _showScrollableDialog(
      'Privacy Policy',
      '''Last Updated: July 2026

Overview
FlowOS ("the App") is a productivity and focus tracking application. Your privacy is important to us.

Data We Collect & Access
- Task Data: Titles, descriptions, energy levels, completion status
- Focus Sessions: Session type, duration, quality grades
- Energy Check-ins: Energy level readings (1-5 scale) with optional notes
- Brain Dump Text: Free-text entries you submit for AI sorting
- XP & Achievements: Experience points and achievements unlocked
- Scroll Tracking: Self-reported scrolling time on social media apps
- Native Device Screen Time (Android): Foreground usage minutes of distracting apps (mapped locally on your device). This data is kept strictly local and is never synced to the cloud or shared with third parties.
- Accessibility Data (Android): Active package name tracking. We only observe window state changes to intercept and shield distraction apps during active focus sessions. No text content, keyboard inputs, or personal information is recorded or stored.

Data Storage, Control & Revocation
- Local-First Storage: All task data, focus session history, and screen time usage records are stored in a local SQLite database on your device.
- Suppabase Sync: If you register an account, your task, focus sessions, and check-in history are backed up securely. Usage logs are NOT backed up.
- Revoke Access: You can disable accessibility shielding or usage stats tracking at any time by toggling the settings inside System Settings → Accessibility or System Settings → Special Access.
- Permanent Deletion: You can clear all local databases by clearing app storage, or delete your account and all data permanently from Settings → Account → Delete All Data.''',
    );
  }

  void _exportData(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.background2,
        title: Text(
          'Export My Data',
          style: AppTypography.h3.copyWith(color: AppColors.textPrimary),
        ),
        content: Text(
          'This will package all your tasks, focus sessions, XP ledger history, and local settings into a JSON backup file and open the system share sheet.\n\nThe export includes task titles and activity history. It does not include authentication tokens.',
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              HapticFeedback.mediumImpact();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Preparing export...'),
                  duration: Duration(seconds: 1),
                ),
              );
              try {
                await ref.read(dataExportServiceProvider).exportAndShare();
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Export failed: $e'),
                      backgroundColor: AppColors.dangerCoral,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.emerald,
              foregroundColor: AppColors.textInverse,
            ),
            child: Text(
              'Export & Share',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textInverse,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPairingSheet(BuildContext context) {
    final bool isConfigured = SupabaseConfig.isConfigured;
    final user = isConfigured ? Supabase.instance.client.auth.currentUser : null;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background2,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusCard)),
      ),
      builder: (ctx) {
        if (!isConfigured || user == null) {
          return Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Account Pair Required',
                  style: AppTypography.h3.copyWith(color: AppColors.textPrimary),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'To connect your browser extension and sync active focus state, you must be signed in to your FlowOS account.',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: AppSpacing.lg),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.emerald,
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: const Text('Okay'),
                ),
              ],
            ),
          );
        }

        // Generate Pairing Token
        final session = Supabase.instance.client.auth.currentSession;
        final tokenData = {
          'userId': user.id,
          'supabaseUrl': SupabaseConfig.supabaseUrl,
          'supabaseKey': SupabaseConfig.supabaseAnonKey,
          'refreshToken': session?.refreshToken ?? '',
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        };
        final pairingToken = base64Encode(utf8.encode(jsonEncode(tokenData)));

        return Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pair Browser Extension',
                style: AppTypography.h3.copyWith(color: AppColors.textPrimary),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Copy this pairing token and paste it into the FlowOS Chrome Extension Settings under "Pair with FlowOS Mobile App".',
                style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.lg),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.background0,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
                  border: Border.all(color: AppColors.textTertiary.withValues(alpha: 0.1)),
                ),
                child: SelectableText(
                  pairingToken,
                  maxLines: 4,
                  style: AppTypography.monoSmall.copyWith(
                    color: AppColors.emerald,
                    fontSize: 10,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: pairingToken));
                  HapticFeedback.mediumImpact();
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Pairing token copied to clipboard!'),
                      backgroundColor: AppColors.emerald,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.emerald,
                  minimumSize: const Size.fromHeight(48),
                ),
                child: const Text('Copy Token'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showShapeFocusSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background2,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusCard)),
      ),
      builder: (ctx) => const ShapeFocusSheet(),
    );
  }

  void _showTermsOfService() {
    _showScrollableDialog(
      'Terms of Service',
      '''Last Updated: June 2026

1. Acceptance of Terms
By downloading or using FlowOS, you agree to these Terms of Service.

2. Description of Service
FlowOS provides tools for productivity, time management, and attention tracking, including local database persistence, AI task sorting, and cloud backup capabilities.

3. Account Registration
To use cloud sync, you must create a Supabase account. You are responsible for maintaining account confidentiality.

4. User Content
You retain all ownership of the tasks, notes, and text dumps you input into the app. We do not claim ownership of your data.

5. AI Feature Use
The app includes AI-powered task classification and report generation. The AI-generated output is provided "as is". FlowOS is not liable for any inaccuracies in AI recommendations.

6. Disclaimer of Warranties
FlowOS is provided "as is" without warranty of any kind, either express or implied.

7. Termination
We reserve the right to suspend accounts that violate these terms or engage in abuse of server APIs.''',
    );
  }
}
