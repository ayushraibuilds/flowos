import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' hide Column;

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/local/database/app_database.dart';
import '../services/usage_stats_service.dart';

/// Provider to stream today's scroll logs.
final todayScrollLogsProvider = StreamProvider<List<ScrollLog>>((ref) {
  final db = ref.watch(databaseProvider);
  final now = DateTime.now();
  final start = DateTime(now.year, now.month, now.day);
  return (db.select(db.scrollLogs)
        ..where((l) => l.timestamp.isBiggerOrEqualValue(start)))
      .watch();
});

/// Attention Radar Card — displaying auto-tracked scroll metrics,
/// budget burn ratios, and brand-colored app progress meters.
class AttentionRadarCard extends ConsumerWidget {
  final int budgetMinutes;

  const AttentionRadarCard({
    super.key,
    required this.budgetMinutes,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scrollLogsAsync = ref.watch(todayScrollLogsProvider);
    final usageService = ref.watch(usageStatsServiceProvider);

    return scrollLogsAsync.maybeWhen(
      data: (logs) {
        // Separate totals by app
        final map = <String, int>{};
        int totalMinutes = 0;

        for (final log in logs) {
          // Normalize app name, removing "[Auto]" flag for clean UI display
          final cleanName = log.appName.replaceAll(' [Auto]', '').trim();
          map[cleanName] = (map[cleanName] ?? 0) + log.durationMinutes;
          totalMinutes += log.durationMinutes;
        }

        final ratio = budgetMinutes > 0 ? (totalMinutes / budgetMinutes).clamp(0.0, 1.0) : 0.0;
        final isOver = totalMinutes > budgetMinutes;
        final radarColor = isOver ? AppColors.dangerCoral : AppColors.emerald;

        // Custom colors for tracked doomscroll platforms
        final appColors = {
          'Instagram': const Color(0xFFE4405F),
          'YouTube': const Color(0xFFFF0000),
          'TikTok': const Color(0xFF26C6DA), // Cyan vibe
          'Twitter/X': const Color(0xFF1DA1F2),
          'Reddit': const Color(0xFFFF4500),
          'Quick Log': AppColors.textSecondary,
        };

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.background2,
            borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
            border: Border.all(
              color: isOver
                  ? AppColors.dangerCoral.withValues(alpha: 0.25)
                  : Colors.white.withValues(alpha: 0.05),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Text(
                        '👁️',
                        style: TextStyle(fontSize: 18),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        'Attention Radar',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: () async {
                      HapticFeedback.lightImpact();
                      await usageService.syncUsageStats();
                    },
                    icon: Icon(
                      Icons.sync_rounded,
                      size: 14,
                      color: AppColors.emerald,
                    ),
                    label: Text(
                      'Sync',
                      style: AppTypography.caption.copyWith(color: AppColors.emerald),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // Overall Budget Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Budget Burned',
                    style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                  ),
                  Text(
                    '$totalMinutes / $budgetMinutes min',
                    style: AppTypography.monoSmall.copyWith(
                      color: radarColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                child: LinearProgressIndicator(
                  value: ratio,
                  minHeight: 8,
                  backgroundColor: AppColors.background0,
                  valueColor: AlwaysStoppedAnimation<Color>(radarColor),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Individual Platform Bars
              if (map.isNotEmpty) ...[
                Text(
                  'Distraction Breakdown',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                ...map.entries.map((entry) {
                  final appName = entry.key;
                  final min = entry.value;
                  final color = appColors[appName] ?? AppColors.textTertiary;
                  final maxLimit = budgetMinutes > 0 ? budgetMinutes : 60;
                  final appRatio = (min / maxLimit).clamp(0.0, 1.0);

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              appName,
                              style: AppTypography.caption.copyWith(color: AppColors.textPrimary),
                            ),
                            Text(
                              '$min m',
                              style: AppTypography.monoSmall.copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            value: appRatio,
                            minHeight: 4,
                            backgroundColor: AppColors.background0,
                            valueColor: AlwaysStoppedAnimation<Color>(color),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ] else ...[
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                    child: Text(
                      'No screen time logged today. Keep protecting your flow!',
                      style: AppTypography.caption.copyWith(color: AppColors.textTertiary),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],

              // Over-budget Warning
              if (isOver) ...[
                const SizedBox(height: AppSpacing.lg),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.dangerCoral.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
                    border: Border.all(
                      color: AppColors.dangerCoral.withValues(alpha: 0.2),
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Text(
                        '🧘',
                        style: TextStyle(fontSize: 22),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Attention overload detected',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.dangerCoral,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Take a 3-minute Box Breathing break to restore focus.',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}
