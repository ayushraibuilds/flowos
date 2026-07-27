import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import 'settings_section_card.dart';

class SettingsExportDataSection extends StatelessWidget {
  final VoidCallback onExportData;
  final VoidCallback onResetData;

  const SettingsExportDataSection({
    super.key,
    required this.onExportData,
    required this.onResetData,
  });

  @override
  Widget build(BuildContext context) {
    return SettingsSectionCard(
      icon: Icons.data_usage_rounded,
      title: 'Data Portability & Management',
      subtitle:
          'Export your local task history and metrics or manage local database storage.',
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onExportData,
              icon: const Icon(Icons.download_rounded, size: 18),
              label: const Text('Export My Data'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textPrimary,
                side: BorderSide(color: AppColors.glassBorder),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onResetData,
              icon: const Icon(
                Icons.delete_outline_rounded,
                size: 18,
                color: Colors.redAccent,
              ),
              label: const Text(
                'Reset Local Data',
                style: TextStyle(color: Colors.redAccent),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.redAccent),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
