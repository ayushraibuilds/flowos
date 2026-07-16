import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../attention/providers/app_picker_providers.dart';
import '../models/focus_protection.dart';

class FocusProtectionSelector extends ConsumerWidget {
  final FocusProtectionLevel value;
  final ValueChanged<FocusProtectionLevel> onChanged;

  const FocusProtectionSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final protectedAppsAsync = ref.watch(protectedAppsStreamProvider);
    final protectedApps = protectedAppsAsync.valueOrNull ?? [];
    final focusProtectedCount = protectedApps.where((a) => a.protectsFocus).length;
    final hasProtectedApps = focusProtectedCount > 0;

    final String description = switch (value) {
      FocusProtectionLevel.softReturn =>
        'A kind cue welcomes you back; your timer keeps moving.',
      FocusProtectionLevel.pauseAndProtect => hasProtectedApps
        ? 'Your timer pauses when you leave FlowOS. Your $focusProtectedCount Protected App(s) will also redirect you back.'
        : 'Your timer pauses when you leave FlowOS. (Add apps to your Protected list in settings to block them during focus.)',
      FocusProtectionLevel.intentionalExit => hasProtectedApps
        ? 'Pause on leave, a 5-second reflection before exiting, and blocking active for your $focusProtectedCount Protected App(s).'
        : 'Pause on leave, a 5-second reflection before exiting. (Add apps to your Protected list in settings to block them.)',
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.background2,
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        border: Border.all(color: AppColors.focusBlue.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Focus Protection',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Choose the support you want for this session.',
            style: AppTypography.caption.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: FocusProtectionLevel.values.map((level) {
              final selected = level == value;
              return ChoiceChip(
                label: Text(level.shortLabel),
                selected: selected,
                onSelected: (_) => onChanged(level),
                selectedColor: AppColors.focusBlue.withValues(alpha: 0.24),
                backgroundColor: AppColors.background0,
                side: BorderSide(
                  color: selected
                      ? AppColors.focusBlue
                      : Colors.white.withValues(alpha: 0.08),
                ),
                labelStyle: AppTypography.caption.copyWith(
                  color: selected
                      ? AppColors.focusBlue
                      : AppColors.textSecondary,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            description,
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}
