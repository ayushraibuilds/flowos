import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:uuid/uuid.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../data/local/database/app_database.dart';
import '../../features/rhythm/models/rhythm_recommendation.dart';
import '../../features/rhythm/providers/rhythm_providers.dart';
import 'flow_surface.dart';

class RhythmRecommendationCard extends ConsumerWidget {
  final RhythmRecommendation recommendation;

  const RhythmRecommendationCard({
    super.key,
    required this.recommendation,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FlowSurface(
      variant: FlowSurfaceVariant.standard,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('⚡', style: const TextStyle(fontSize: 18)),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'ADAPTIVE RHYTHM',
                style: AppTypography.monoSmall.copyWith(
                  color: AppColors.emerald,
                  letterSpacing: 1.2,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 16),
                color: AppColors.textTertiary,
                onPressed: () {
                  HapticFeedback.selectionClick();
                  ref
                      .read(rhythmRecommendationControllerProvider)
                      .dismissRecommendation(recommendation.id);
                },
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            recommendation.headline,
            style: AppTypography.h3.copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            recommendation.actionLabel,
            style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.md),
          
          // Evidence chips
          Wrap(
            spacing: AppSpacing.sm,
            children: recommendation.evidence.map((ev) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.background2,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
                ),
                child: Text(
                  ev,
                  style: AppTypography.caption.copyWith(color: AppColors.textTertiary),
                ),
              );
            }).toList(),
          ),
          
          const SizedBox(height: AppSpacing.lg),
          
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _showAcceptOptions(context, ref),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.emerald.withValues(alpha: 0.12),
                    foregroundColor: AppColors.emerald,
                    elevation: 0,
                    side: BorderSide(color: AppColors.emerald.withValues(alpha: 0.2)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
                    ),
                  ),
                  child: const Text('Accept Recommendation'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAcceptOptions(BuildContext context, WidgetRef ref) {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: AppColors.background1,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(AppSpacing.radiusCard),
            topRight: Radius.circular(AppSpacing.radiusCard),
          ),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.background2,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Accept Focus Rhythm', style: AppTypography.h3),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Convert this insight into an actionable plan.',
              style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary),
            ),
            const SizedBox(height: AppSpacing.xl),
            
            // 1. Schedule Next Window
            _buildAcceptTile(
              emoji: '📅',
              title: 'Schedule next window',
              desc: 'Will schedule focus window inside daily intentions',
              onTap: () async {
                Navigator.pop(ctx);
                HapticFeedback.mediumImpact();
                await _scheduleFocusWindow(ref);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Focus window successfully scheduled!')),
                  );
                }
              },
            ),
            const SizedBox(height: AppSpacing.md),
            
            // 2. Start now
            _buildAcceptTile(
              emoji: '🚀',
              title: 'Start focus now',
              desc: 'Launch a 45-minute deep focus session immediately',
              onTap: () {
                Navigator.pop(ctx);
                context.go('/focus', extra: {
                  'durationMinutes': 45,
                  'sessionLabel': 'Rhythm Deep Focus',
                  'autoStart': true,
                });
              },
            ),
            const SizedBox(height: AppSpacing.md),
            
            // 3. Pick hardest MIT
            _buildAcceptTile(
              emoji: '🎯',
              title: 'Divert to tasks list',
              desc: 'Select your most challenging MIT for this rhythm',
              onTap: () {
                Navigator.pop(ctx);
                context.go('/tasks');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAcceptTile({
    required String emoji,
    required String title,
    required String desc,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: AppColors.background2,
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
          border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.body.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    desc,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textTertiary.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _scheduleFocusWindow(WidgetRef ref) async {
    final db = ref.read(databaseProvider);
    DateTime targetDate = DateTime.now().add(const Duration(days: 1));
    if (recommendation.preferredWeekday != null) {
      while (targetDate.weekday != recommendation.preferredWeekday) {
        targetDate = targetDate.add(const Duration(days: 1));
      }
    }
    final dateOnly = DateTime(targetDate.year, targetDate.month, targetDate.day);
    
    final plan = await db.dailyPlansDao.getByDateRange(dateOnly, dateOnly.add(const Duration(days: 1)));
    if (plan == null) {
      await db.dailyPlansDao.insertPlan(DailyPlansCompanion(
        id: Value(const Uuid().v4()),
        date: Value(dateOnly),
        intentionNote: Value('Scheduled Focus Window: ${recommendation.headline.split("land ").last}'),
      ));
    } else {
      await db.dailyPlansDao.updatePlan(DailyPlansCompanion(
        id: Value(plan.id),
        date: Value(plan.date),
        intentionNote: Value('${plan.intentionNote ?? ""}\nScheduled Focus: ${recommendation.headline.split("land ").last}'.trim()),
      ));
    }
    
    // Save to SharedPreferences for notification / Home CTA checks
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('flowos_suggested_focus_start', recommendation.windowStartHour);
    await prefs.setInt('flowos_suggested_focus_end', recommendation.windowEndHour);
  }
}
