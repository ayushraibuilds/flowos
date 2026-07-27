import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../features/focus/models/focus_protection.dart';
import 'settings_section_card.dart';

class SettingsProtectionSection extends StatelessWidget {
  final FocusProtectionLevel selectedLevel;
  final ValueChanged<FocusProtectionLevel> onLevelChanged;
  final VoidCallback onConfigureAppBlocker;

  const SettingsProtectionSection({
    super.key,
    required this.selectedLevel,
    required this.onLevelChanged,
    required this.onConfigureAppBlocker,
  });

  @override
  Widget build(BuildContext context) {
    return SettingsSectionCard(
      icon: Icons.shield_outlined,
      title: 'Focus Protection & App Blocker',
      subtitle: 'Control app-blocking intensity during active focus sessions.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: FocusProtectionLevel.values.map((level) {
              final isSelected = selectedLevel == level;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2.0),
                  child: FilterChip(
                    selected: isSelected,
                    label: Text(
                      level.shortLabel.toUpperCase(),
                      style: AppTypography.caption.copyWith(
                        color: isSelected
                            ? Colors.white
                            : AppColors.textSecondary,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    selectedColor: AppColors.emerald,
                    backgroundColor: AppColors.background2,
                    onSelected: (_) => onLevelChanged(level),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(
            onPressed: onConfigureAppBlocker,
            icon: const Icon(Icons.apps_rounded, size: 18),
            label: const Text('Configure Protected Apps'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textPrimary,
              side: BorderSide(color: AppColors.glassBorder),
            ),
          ),
        ],
      ),
    );
  }
}
