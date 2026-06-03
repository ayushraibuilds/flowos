import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

/// Morning Intention — start your day with energy, MITs, and scroll budget.
class MorningIntentionScreen extends ConsumerStatefulWidget {
  const MorningIntentionScreen({super.key});

  @override
  ConsumerState<MorningIntentionScreen> createState() =>
      _MorningIntentionScreenState();
}

class _MorningIntentionScreenState
    extends ConsumerState<MorningIntentionScreen> {
  int _energy = 3; // 1-5
  int _scrollBudget = 30; // minutes
  final _energyEmojis = ['😴', '😐', '🙂', '⚡', '🔥'];

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final greeting = now.hour < 12
        ? 'Good morning'
        : now.hour < 17
            ? 'Good afternoon'
            : 'Good evening';

    final weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday',
        'Friday', 'Saturday', 'Sunday'];
    final months = ['January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'];
    final dateStr = '${weekdays[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}';

    return Scaffold(
      backgroundColor: AppColors.background0,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: AppSpacing.xxxl * 2),
              // ─── Greeting ─────────────────────────────────────
              Text(
                '$greeting.',
                style: AppTypography.h1.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                dateStr,
                style: AppTypography.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.xxxl),
              // ─── Quote ────────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.background2,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
                  border: Border(
                    left: BorderSide(color: AppColors.emerald, width: 2),
                  ),
                ),
                child: Text(
                  '"Energy, not time, is the fundamental currency of high performance."\n— Jim Loehr',
                  style: AppTypography.body.copyWith(
                    color: AppColors.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xxxl),
              // ─── Energy Check-in ──────────────────────────────
              Text(
                "How's your energy right now?",
                style: AppTypography.h3.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  final isActive = i == _energy - 1;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _energy = i + 1);
                      HapticFeedback.selectionClick();
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 52,
                      height: 52,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isActive
                            ? AppColors.emerald.withValues(alpha: 0.15)
                            : AppColors.background2,
                        border: Border.all(
                          color: isActive
                              ? AppColors.emerald
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          _energyEmojis[i],
                          style: TextStyle(fontSize: isActive ? 24 : 20),
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: AppSpacing.xxxl),
              // ─── MITs ─────────────────────────────────────────
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Pick 3 MITs for today',
                  style: AppTypography.h3.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              // Placeholder — will be populated from tasks DB
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.xxl),
                decoration: BoxDecoration(
                  color: AppColors.background2,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
                ),
                child: Column(
                  children: [
                    Text(
                      'No tasks yet',
                      style: AppTypography.body.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Add tasks first, then pick your MITs here',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              // ─── Scroll Budget ────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Today's scroll budget",
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          if (_scrollBudget > 0) {
                            setState(() => _scrollBudget -= 5);
                          }
                        },
                        icon: const Icon(Icons.remove_circle_outline,
                            size: 20, color: AppColors.textSecondary),
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(4),
                      ),
                      Text(
                        '${_scrollBudget}m',
                        style: AppTypography.monoSmall.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          setState(() => _scrollBudget += 5);
                        },
                        icon: const Icon(Icons.add_circle_outline,
                            size: 20, color: AppColors.textSecondary),
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(4),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xxxl),
              // ─── Start Your Day CTA ───────────────────────────
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    HapticFeedback.heavyImpact();
                    // TODO: Save daily plan to DB
                    context.go('/home');
                  },
                  child: const Text('Start Your Day'),
                ),
              ),
              const SizedBox(height: AppSpacing.xxxl),
            ],
          ),
        ),
      ),
    );
  }
}
