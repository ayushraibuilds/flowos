import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../features/auth/services/auth_service.dart';
import '../../../features/themes/models/flow_theme.dart';
import '../../../features/notifications/services/notification_service.dart';

/// Full Settings Screen — notification prefs, themes, scroll budget,
/// sync controls, account management.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  // Notification prefs
  bool _energyReminders = true;
  bool _reportReminder = true;
  bool _streakWarning = true;
  bool _weeklyReview = true;

  // Focus prefs
  int _scrollBudget = 30;
  bool _soundEnabled = true;

  // Sync
  bool _autoSync = true;

  @override
  Widget build(BuildContext context) {
    final currentTheme = ref.watch(themeProvider);
    final isLoggedIn = ref.watch(isLoggedInProvider);

    return Scaffold(
      backgroundColor: AppColors.background0,
      appBar: AppBar(
        title: Text('Settings',
            style: AppTypography.h3.copyWith(color: AppColors.textPrimary)),
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
            value: _energyReminders,
            onChanged: (v) {
              setState(() => _energyReminders = v);
              if (v) {
                NotificationService.scheduleEnergyCheckIns();
              }
            },
          ),
          _toggleTile(
            title: 'Daily report reminder',
            subtitle: '9 PM — "Your day in review"',
            value: _reportReminder,
            onChanged: (v) {
              setState(() => _reportReminder = v);
              if (v) {
                NotificationService.scheduleReportReminder();
              }
            },
          ),
          _toggleTile(
            title: 'Streak warning',
            subtitle: '8 PM if no activity today',
            value: _streakWarning,
            onChanged: (v) {
              setState(() => _streakWarning = v);
              if (v) {
                NotificationService.scheduleStreakWarning();
              }
            },
          ),
          _toggleTile(
            title: 'Weekly review',
            subtitle: 'Sunday 8 PM — 5-min guided flow',
            value: _weeklyReview,
            onChanged: (v) {
              setState(() => _weeklyReview = v);
              if (v) {
                NotificationService.scheduleWeeklyReview();
              }
            },
          ),
          const SizedBox(height: AppSpacing.xxl),

          // ─── Focus & Attention ─────────────────────────
          _sectionHeader('⏱️ Focus & Attention'),
          _sliderTile(
            title: 'Daily scroll budget',
            value: _scrollBudget,
            min: 10,
            max: 120,
            suffix: 'min',
            onChanged: (v) => setState(() => _scrollBudget = v.round()),
          ),
          _toggleTile(
            title: 'Ambient sounds',
            subtitle: 'Play background audio during focus',
            value: _soundEnabled,
            onChanged: (v) => setState(() => _soundEnabled = v),
          ),
          const SizedBox(height: AppSpacing.xxl),

          // ─── Sync ──────────────────────────────────────
          _sectionHeader('☁️ Sync'),
          _toggleTile(
            title: 'Auto sync',
            subtitle: 'Sync data to cloud after every change',
            value: _autoSync,
            onChanged: (v) => setState(() => _autoSync = v),
          ),
          _actionTile(
            title: 'Sync now',
            subtitle: 'Force a full sync with the server',
            icon: Icons.sync_rounded,
            onTap: () {
              HapticFeedback.mediumImpact();
              // TODO: Trigger full sync via SyncController
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Syncing...'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
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
            onTap: () {
              // TODO: Open privacy policy URL
            },
          ),
          _actionTile(
            title: 'Terms of Service',
            icon: Icons.description_outlined,
            onTap: () {
              // TODO: Open ToS URL
            },
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
    // TODO: Get real level from XP provider
    const currentLevel = 5;
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
                    Icon(Icons.check_circle_rounded,
                        size: 20, color: theme.accent),
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
        title: Text('Sign out?',
            style: AppTypography.h3.copyWith(color: AppColors.textPrimary)),
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
            child: Text('Sign Out',
                style: TextStyle(color: AppColors.warningAmber)),
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
        title: Text('Delete all data?',
            style: AppTypography.h3.copyWith(color: AppColors.dangerCoral)),
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
            onPressed: () {
              Navigator.pop(ctx);
              // TODO: Delete all local + Supabase data
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('All data deleted'),
                  backgroundColor: AppColors.dangerCoral,
                ),
              );
            },
            child: Text('Delete Everything',
                style: TextStyle(color: AppColors.dangerCoral)),
          ),
        ],
      ),
    );
  }
}
