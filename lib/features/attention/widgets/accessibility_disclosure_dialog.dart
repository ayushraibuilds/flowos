import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../repository/attention_data_repository.dart';

Future<bool> showAccessibilityDisclosure(
  BuildContext context,
  DeviceAttentionPlatform platform,
) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: AppColors.background1,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
    ),
    isScrollControlled: true,
    builder: (context) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.sm),
              Center(
                child: Container(
                  width: 48,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textPrimary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2.0),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Icon(
                    Icons.shield_outlined,
                    color: AppColors.emerald,
                    size: 32,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      'App Protection (Android Only)',
                      style: AppTypography.h3.copyWith(color: AppColors.textPrimary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'FlowOS uses the Android Accessibility Service API to detect when you are opening selected distracting apps during active Focus and Sleep sessions.',
                style: AppTypography.body.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.lg),
              _buildBulletPoint(
                Icons.check_circle_outline,
                'FlowOS monitors package launch events only to apply your selected focus and sleep protection policies (Guard, Deep Focus).',
              ),
              const SizedBox(height: AppSpacing.md),
              _buildBulletPoint(
                Icons.vpn_key_outlined,
                'Privacy First: No personal data, keystrokes, screen contents, notifications, or app data is collected, stored, or sent off the device. This feature operates 100% locally.',
              ),
              const SizedBox(height: AppSpacing.md),
              _buildBulletPoint(
                Icons.settings_suggest_outlined,
                'You can disable this permission at any time in Android Settings → Accessibility → FlowOS.',
              ),
              const SizedBox(height: AppSpacing.xl),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.emerald,
                  foregroundColor: AppColors.background0,
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context, true);
                },
                child: Text(
                  'Accept & Open Settings',
                  style: AppTypography.button.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                ),
                onPressed: () {
                  Navigator.pop(context, false);
                },
                child: Text(
                  'Not now',
                  style: AppTypography.button,
                ),
              ),
            ],
          ),
        ),
      );
    },
  );

  if (result == true) {
    await platform.openAccessibilitySettings();
    return true;
  }
  return false;
}

Widget _buildBulletPoint(IconData icon, String text) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, color: AppColors.emerald, size: 20),
      const SizedBox(width: AppSpacing.md),
      Expanded(
        child: Text(
          text,
          style: AppTypography.bodySmall.copyWith(color: AppColors.textPrimary),
        ),
      ),
    ],
  );
}
