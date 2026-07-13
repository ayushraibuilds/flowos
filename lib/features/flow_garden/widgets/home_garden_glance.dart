import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../providers/garden_providers.dart';
import 'garden_plot.dart';

/// A small, living reason to return placed directly on Home.
class HomeGardenGlance extends ConsumerWidget {
  const HomeGardenGlance({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gardenAsync = ref.watch(todayGardenProvider);
    return gardenAsync.when(
      loading: () => const SizedBox(height: 140),
      error: (_, __) => const SizedBox.shrink(),
      data: (day) => Semantics(
        button: true,
        label: 'Open Flow Garden',
        child: GestureDetector(
          onTap: () => context.push('/garden'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Today’s Garden',
                    style: AppTypography.h2.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Visit →',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.emerald,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              GardenPlot(day: day, height: 156),
            ],
          ),
        ),
      ),
    );
  }
}
