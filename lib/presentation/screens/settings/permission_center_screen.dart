import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../widgets/flow_surface.dart';
import '../../../features/attention/repository/attention_data_repository.dart';
import '../../../features/attention/widgets/accessibility_disclosure_dialog.dart';

/// Permission Center Screen — manage and check all system permission states in one hub.
class PermissionCenterScreen extends ConsumerStatefulWidget {
  const PermissionCenterScreen({super.key});

  @override
  ConsumerState<PermissionCenterScreen> createState() => _PermissionCenterScreenState();
}

class _PermissionCenterScreenState extends ConsumerState<PermissionCenterScreen> with WidgetsBindingObserver {
  bool _audioEnabled = true; // Always active by default
  bool _usageStatsEnabled = false;
  bool _accessibilityEnabled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkAllPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkAllPermissions();
    }
  }

  Future<void> _checkAllPermissions() async {
    try {
      final states = await ref.read(deviceAttentionPlatformProvider).getPermissionStates();
      if (mounted) {
        setState(() {
          _usageStatsEnabled = states.usageAccess;
          _accessibilityEnabled = states.accessibility;
        });
      }
    } catch (_) {}
  }

  Future<void> _requestPermission(String type) async {
    final platform = ref.read(deviceAttentionPlatformProvider);
    if (type == 'usage') {
      await platform.openUsageAccessSettings();
    } else if (type == 'accessibility') {
      if (!_accessibilityEnabled) {
        await showAccessibilityDisclosure(context, platform);
      } else {
        await platform.openAccessibilitySettings();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background0,
      appBar: AppBar(
        title: Text(
          'Permission Center',
          style: AppTypography.h3.copyWith(color: AppColors.textPrimary),
        ),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.lg,
        ),
        children: [
          Text(
            'Control what access FlowOS has on your device. All evaluation happens locally and private on-device.',
            style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.xl),

          // 1. Audio / Sound
          _buildPermissionCard(
            title: 'Ambient Sounds',
            status: _audioEnabled,
            why: 'Ambient sounds play loops in the focus timer to help keep you in deep flow.',
            limitation: 'Requires device volume to be unmuted.',
            actionLabel: 'Active',
            onPressed: null,
          ),
          const SizedBox(height: AppSpacing.lg),

          // 2. Usage Stats (Android)
          _buildPermissionCard(
            title: 'Usage Access (Android)',
            status: _usageStatsEnabled,
            why: 'Used to read device foreground screen time to calculate daily budgets and insights.',
            limitation: 'Cannot access app package contents or usage outside launcher names.',
            actionLabel: _usageStatsEnabled ? 'Configure Settings' : 'Grant Permission',
            onPressed: () => _requestPermission('usage'),
          ),
          const SizedBox(height: AppSpacing.lg),

          // 3. Accessibility Service (Android Blocker)
          _buildPermissionCard(
            title: 'Accessibility Blocker (Android)',
            status: _accessibilityEnabled,
            why: 'Used to intercept foreground distraction apps during focus sessions to show the shield overlay.',
            limitation: 'Cannot prevent disabling this service or uninstalling the app.',
            actionLabel: _accessibilityEnabled ? 'Configure Settings' : 'Grant Permission',
            onPressed: () => _requestPermission('accessibility'),
          ),
          const SizedBox(height: AppSpacing.lg),

          // 4. iOS Screen Time (Placeholder)
          _buildPermissionCard(
            title: 'iOS Screen Time & Shields',
            status: false,
            why: 'Used on iOS to pull attention statistics and enforce focus app shielding natively.',
            limitation: 'Unavailable on Android. Requires Apple entitlement authorization.',
            actionLabel: 'iOS Only',
            onPressed: null,
          ),
          const SizedBox(height: AppSpacing.xxl),

          Center(
            child: Text(
              'No background trackers or external analytics are configured.',
              style: AppTypography.caption.copyWith(color: AppColors.textTertiary),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Widget _buildPermissionCard({
    required String title,
    required bool status,
    required String why,
    required String limitation,
    required String actionLabel,
    required VoidCallback? onPressed,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.background2,
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        border: Border.all(
          color: status
              ? AppColors.emerald.withValues(alpha: 0.1)
              : AppColors.textTertiary.withValues(alpha: 0.05),
        ),
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
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: status
                      ? AppColors.emerald.withValues(alpha: 0.1)
                      : AppColors.warningAmber.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                ),
                child: Text(
                  status ? 'Active' : 'Inactive',
                  style: AppTypography.monoSmall.copyWith(
                    color: status ? AppColors.emerald : AppColors.warningAmber,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Purpose:',
            style: AppTypography.caption.copyWith(
              color: AppColors.textTertiary,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            why,
            style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Limitations:',
            style: AppTypography.caption.copyWith(
              color: AppColors.textTertiary,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            limitation,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
          if (onPressed != null) ...[
            const SizedBox(height: AppSpacing.lg),
            OutlinedButton(
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(36),
                side: BorderSide(
                  color: status ? AppColors.textTertiary.withValues(alpha: 0.2) : AppColors.emerald,
                ),
                foregroundColor: status ? AppColors.textPrimary : AppColors.emerald,
              ),
              child: Text(actionLabel),
            ),
          ],
        ],
      ),
    );
  }
}
