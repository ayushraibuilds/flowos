import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../features/flow_garden/models/garden_day.dart';
import '../../../features/flow_garden/providers/garden_providers.dart';
import '../../../features/flow_garden/widgets/garden_plot.dart';
import '../../widgets/flow_surface.dart';

/// The Garden is a visual record of care. Quiet or missed days become rest,
/// never loss; completed days are saved as small landscape cards.
class GardenScreen extends ConsumerWidget {
  const GardenScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todayAsync = ref.watch(todayGardenProvider);
    final weekAsync = ref.watch(gardenWeekProvider);

    return Scaffold(
      backgroundColor: AppColors.background0,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.md,
            AppSpacing.xl,
            AppSpacing.xxxl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    color: AppColors.textPrimary,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    'Flow Garden',
                    style: AppTypography.h1.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                child: Text(
                  'A gentle record of the focus and care you have already given.',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              todayAsync.when(
                loading: () => const SizedBox(
                  height: 260,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (_, __) => _errorCard(),
                data: (today) => _todaySection(today),
              ),
              const SizedBox(height: AppSpacing.xxl),
              _seasonSection(weekAsync),
              const SizedBox(height: AppSpacing.xxl),
              Text(
                'How your garden grows',
                style: AppTypography.h2.copyWith(color: AppColors.textPrimary),
              ),
              const SizedBox(height: AppSpacing.md),
              const _CareGuide(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _todaySection(GardenDay today) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GardenPlot(day: today, height: 278),
        const SizedBox(height: AppSpacing.md),
        FlowSurface(
          variant: FlowSurfaceVariant.standard,
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              _stat('Focus', '${today.focusMinutes}m', AppColors.emerald),
              _divider(),
              _stat('Care', '${today.recoveryCount}', AppColors.recoveryTeal),
              _divider(),
              _stat(
                'Attention',
                '${today.scrollMinutes}/${today.scrollBudgetMinutes}m',
                AppColors.warningAmber,
              ),
            ],
          ),
        ),
        if (!today.isResting) ...[
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: today.objects
                .map((object) => _ObjectChip(object: object))
                .toList(),
          ),
        ],
      ],
    );
  }

  Widget _seasonSection(AsyncValue<List<GardenDay>> weekAsync) {
    return weekAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (week) {
        final season = GardenSeason.forDate(DateTime.now());
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'This week’s season',
                  style: AppTypography.h2.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                Text(
                  '${season.emoji} ${season.name}',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.emerald,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              season.description,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: 160,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: week.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(width: AppSpacing.md),
                itemBuilder: (context, index) =>
                    _LandscapeCard(day: week[index]),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _stat(String label, String value, Color color) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: AppTypography.monoSmall.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => Container(
    width: 1,
    height: 28,
    color: Colors.white.withValues(alpha: 0.08),
  );

  Widget _errorCard() => FlowSurface(
    variant: FlowSurfaceVariant.standard,
    child: Text(
      'Your garden will be ready shortly.',
      style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
    ),
  );
}

class _LandscapeCard extends StatelessWidget {
  final GardenDay day;

  const _LandscapeCard({required this.day});

  @override
  Widget build(BuildContext context) {
    final isToday = day.date == DateUtils.dateOnly(DateTime.now());
    const weekdayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final label = isToday ? 'Today' : weekdayLabels[day.date.weekday - 1];
    return SizedBox(
      width: 126,
      child: FlowSurface(
        variant: FlowSurfaceVariant.standard,
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTypography.caption.copyWith(
                color: isToday ? AppColors.emerald : AppColors.textSecondary,
              ),
            ),
            const Spacer(),
            Text(
              day.isResting
                  ? '🌙'
                  : day.objects.map((object) => object.emoji).take(3).join(' '),
              style: const TextStyle(fontSize: 22),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              day.isCompleted
                  ? 'Saved landscape'
                  : day.isResting
                  ? 'Resting plot'
                  : 'In progress',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.caption.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ObjectChip extends StatelessWidget {
  final GardenObject object;

  const _ObjectChip({required this.object});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.background2,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Text(
        '${object.emoji} ${object.detail ?? object.title}',
        style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
      ),
    );
  }
}

class _CareGuide extends StatelessWidget {
  const _CareGuide();

  @override
  Widget build(BuildContext context) {
    const items = [
      ('🌳', 'Deep work becomes a tree'),
      ('🌸', 'Short focus becomes a flower'),
      ('💧 ☀️', 'Recovery and energy check-ins tend the plot'),
      ('🦋', 'A protected low-scroll day welcomes wildlife'),
    ];
    return FlowSurface(
      variant: FlowSurfaceVariant.standard,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: items
            .map(
              (item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                child: Row(
                  children: [
                    SizedBox(
                      width: 52,
                      child: Text(
                        item.$1,
                        style: const TextStyle(fontSize: 17),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        item.$2,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
