import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../providers/garden_providers.dart';
import 'home_garden_scene.dart';

/// A small, living reason to return placed directly on Home.
class HomeGardenGlance extends ConsumerWidget {
  const HomeGardenGlance({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gardenAsync = ref.watch(todayGardenProvider);
    return gardenAsync.when(
      loading: () => const SizedBox(height: 140),
      error: (_, __) => const SizedBox.shrink(),
      data: (day) => Column(
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
              TextButton.icon(
                onPressed: () => context.push('/garden'),
                icon: const Icon(Icons.arrow_outward_rounded, size: 16),
                label: const Text('Visit'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.emerald,
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          HomeGardenScene(
            day: day,
            onFocusTap: () => context.push('/focus'),
            onRecoveryTap: () => context.push(
              '/rest',
              extra: const {'defaultMinutes': 2, 'autoStart': true},
            ),
            onGardenTap: () => context.push('/garden'),
          ),
        ],
      ),
    );
  }
}
