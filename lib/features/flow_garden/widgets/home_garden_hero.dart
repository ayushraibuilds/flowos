import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../focus/providers/focus_timer_provider.dart';
import '../../focus/models/focus_timer_stage.dart';
import '../../focus/models/effective_policy.dart';
import '../../focus/services/focus_session_service.dart';
import '../../focus/services/protection_policy_service.dart';
import '../../../data/local/database/app_database.dart';
import '../../../data/local/tables/focus_sessions_table.dart';
import '../providers/garden_providers.dart';
import 'home_garden_scene.dart';

class HomeGardenHero extends ConsumerWidget {
  const HomeGardenHero({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gardenAsync = ref.watch(todayGardenProvider);
    final activeTimer = ref.watch(focusTimerNotifierProvider);
    final isRecovery = ref.watch(isRecoveryActiveProvider);

    final width = MediaQuery.of(context).size.width;
    final isTablet = width >= 600;
    final cardHeight = isTablet ? 320.0 : (width * 0.9).clamp(280.0, 420.0);

    return gardenAsync.when(
      loading: () => Container(
        height: cardHeight,
        decoration: BoxDecoration(
          color: AppColors.background2,
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        ),
        child: const Center(child: CircularProgressIndicator()),
      ),
      error: (err, __) => Container(
        height: cardHeight,
        decoration: BoxDecoration(
          color: AppColors.background2,
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🌱', style: TextStyle(fontSize: 40)),
              const SizedBox(height: 8),
              Text(
                'Garden is resting',
                style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
      data: (day) {
        // Compute CTA Action
        final String ctaText;
        final VoidCallback ctaCallback;

        if (activeTimer != null) {
          ctaText = 'Return to Focus 🎯';
          ctaCallback = () {
            if (activeTimer.sessionType == SessionTypeColumn.deepWork) {
              context.push('/deep-work', extra: {
                'taskId': activeTimer.taskId,
                'taskTitle': activeTimer.taskTitle,
              });
            } else {
              context.push('/focus');
            }
          };
        } else if (isRecovery) {
          ctaText = 'Continue Recovery ⚡';
          ctaCallback = () {
            context.push('/rest');
          };
        } else {
          ctaText = 'Start Focus Session 🎯';
          ctaCallback = () {
            context.push('/focus');
          };
        }

        return Container(
          height: cardHeight,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
            child: Stack(
              children: [
                // Full bleed garden scene
                Positioned.fill(
                  child: HomeGardenScene(
                    day: day,
                    isHero: true,
                    onFocusTap: () => context.push('/focus'),
                    onRecoveryTap: () => context.push(
                      '/rest',
                      extra: const {'defaultMinutes': 2, 'autoStart': true},
                    ),
                    onGardenTap: () => context.push('/garden'),
                  ),
                ),

                // Text overlays (headline & subtext) at top-left
                Positioned(
                  top: AppSpacing.lg,
                  left: AppSpacing.lg,
                  right: 80, // leave space for visit button
                  child: IgnorePointer(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          day.headline,
                          style: AppTypography.h2.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              const Shadow(
                                color: Colors.black54,
                                offset: Offset(0, 1),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          day.supportingText,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                            shadows: [
                              const Shadow(
                                color: Colors.black54,
                                offset: Offset(0, 1),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Top-right visit garden button
                Positioned(
                  top: AppSpacing.md,
                  right: AppSpacing.md,
                  child: Semantics(
                    button: true,
                    label: 'Open full Garden plot',
                    child: SizedBox(
                      width: 48,
                      height: 48,
                      child: IconButton(
                        iconSize: 24,
                        onPressed: () => context.push('/garden'),
                        tooltip: 'Open Garden',
                        color: AppColors.emerald,
                        icon: const Icon(Icons.arrow_outward_rounded),
                      ),
                    ),
                  ),
                ),

                // State-aware overlay CTA Button at the bottom
                Positioned(
                  left: AppSpacing.lg,
                  right: AppSpacing.lg,
                  bottom: AppSpacing.lg,
                  child: Semantics(
                    button: true,
                    label: ctaText,
                    child: SizedBox(
                      height: 48, // ensure 48dp minimum target size
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black.withValues(alpha: 0.65),
                          foregroundColor: AppColors.textPrimary,
                          side: BorderSide(color: AppColors.emerald.withValues(alpha: 0.5), width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
                          ),
                          elevation: 0,
                        ),
                        onPressed: ctaCallback,
                        child: Text(
                          ctaText,
                          style: AppTypography.body.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
