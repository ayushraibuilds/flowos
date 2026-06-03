import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../features/ai/services/ai_service.dart';

/// Weekly Review Screen — Sunday guided 5-min flow.
/// AI-generated reflection questions + week summary infographic.
class WeeklyReviewScreen extends StatefulWidget {
  const WeeklyReviewScreen({super.key});

  @override
  State<WeeklyReviewScreen> createState() => _WeeklyReviewScreenState();
}

class _WeeklyReviewScreenState extends State<WeeklyReviewScreen> {
  WeeklyReview? _review;
  bool _loading = true;
  int _currentStep = 0;

  // Placeholder week data (will be from DB)
  final _weekData = {
    'week_start': '2026-05-26',
    'week_end': '2026-06-01',
    'daily_scores': [65, 72, 80, 55, 78, 82, 70],
    'total_focus_hours': 18.5,
    'total_tasks_completed': 24,
    'total_xp': 2450,
    'scroll_total_minutes': 145,
    'recovery_actions': 6,
    'streak_days': 7,
    'best_day_score': 82,
    'worst_day_score': 55,
    'mits_completed': 15,
    'mits_total': 21,
    'private_mode': false,
    'prompt_version': 1,
  };

  @override
  void initState() {
    super.initState();
    _loadReview();
  }

  Future<void> _loadReview() async {
    final aiService = AiService();
    final review = await aiService.generateWeeklyReview(weekData: _weekData);

    setState(() {
      _review = review ?? WeeklyReview(
        summary: 'A solid week of building habits. Check the numbers below.',
        wins: ['Maintained a 7-day streak', '24 tasks completed'],
        growthAreas: ['Try protecting morning hours for deep work'],
        reflectionQuestions: [
          'What was your best focus session this week?',
          'What drained your energy most?',
          'If you could only do 3 things next week, what would they be?',
        ],
        nextWeekFocus: 'Start each day with one deep work session.',
      );
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: AppColors.background0,
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.emerald),
        ),
      );
    }

    final steps = [
      _buildSummaryStep(),
      _buildWinsStep(),
      _buildGrowthStep(),
      _buildReflectionStep(),
      _buildNextWeekStep(),
    ];

    return Scaffold(
      backgroundColor: AppColors.background0,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.xxl),
              // Progress
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (_currentStep + 1) / steps.length,
                  minHeight: 4,
                  backgroundColor: AppColors.background2,
                  valueColor: const AlwaysStoppedAnimation(AppColors.emerald),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Weekly Review',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                  Text(
                    '${_currentStep + 1}/${steps.length}',
                    style: AppTypography.monoSmall.copyWith(
                      color: AppColors.textTertiary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              // Content
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: steps[_currentStep],
              ),
              const Spacer(),
              // Navigation
              Row(
                children: [
                  if (_currentStep > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          setState(() => _currentStep--);
                        },
                        child: const Text('← Back'),
                      ),
                    ),
                  if (_currentStep > 0) const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        if (_currentStep < steps.length - 1) {
                          setState(() => _currentStep++);
                        } else {
                          Navigator.pop(context);
                        }
                      },
                      child: Text(
                        _currentStep < steps.length - 1
                            ? 'Continue →'
                            : 'Done ✓',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Skip review',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryStep() {
    final scores = _weekData['daily_scores'] as List;
    return Column(
      key: const ValueKey('summary'),
      children: [
        Text('📊', style: const TextStyle(fontSize: 48)),
        const SizedBox(height: AppSpacing.xxl),
        Text(
          'Your Week',
          style: AppTypography.h1.copyWith(color: AppColors.textPrimary),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          _review!.summary,
          style: AppTypography.body.copyWith(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xxl),
        // Mini score chart
        SizedBox(
          height: 80,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(scores.length, (i) {
              final score = scores[i] as int;
              final height = score / 100 * 60;
              final isToday = i == scores.length - 1;
              return Container(
                width: 28,
                height: height.toDouble(),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: isToday
                      ? AppColors.emerald
                      : AppColors.emerald.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: ['M', 'T', 'W', 'T', 'F', 'S', 'S'].map((d) {
            return SizedBox(
              width: 34,
              child: Text(
                d,
                style: AppTypography.caption.copyWith(
                  color: AppColors.textTertiary,
                ),
                textAlign: TextAlign.center,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildWinsStep() {
    return Column(
      key: const ValueKey('wins'),
      children: [
        Text('🏆', style: const TextStyle(fontSize: 48)),
        const SizedBox(height: AppSpacing.xxl),
        Text(
          'Wins',
          style: AppTypography.h1.copyWith(color: AppColors.emerald),
        ),
        const SizedBox(height: AppSpacing.xxl),
        ...(_review!.wins.map((win) => Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.emerald.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
              border: Border.all(
                color: AppColors.emerald.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                const Text('✓ ', style: TextStyle(color: AppColors.emerald)),
                Expanded(
                  child: Text(
                    win,
                    style: AppTypography.body.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ))),
      ],
    );
  }

  Widget _buildGrowthStep() {
    return Column(
      key: const ValueKey('growth'),
      children: [
        Text('🌱', style: const TextStyle(fontSize: 48)),
        const SizedBox(height: AppSpacing.xxl),
        Text(
          'Growth Areas',
          style: AppTypography.h1.copyWith(color: AppColors.textPrimary),
        ),
        const SizedBox(height: AppSpacing.xxl),
        ...(_review!.growthAreas.map((area) => Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.background2,
              borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
            ),
            child: Text(
              area,
              style: AppTypography.body.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ))),
      ],
    );
  }

  Widget _buildReflectionStep() {
    return Column(
      key: const ValueKey('reflection'),
      children: [
        Text('🪞', style: const TextStyle(fontSize: 48)),
        const SizedBox(height: AppSpacing.xxl),
        Text(
          'Reflect',
          style: AppTypography.h1.copyWith(color: AppColors.textPrimary),
        ),
        const SizedBox(height: AppSpacing.xxl),
        ...List.generate(_review!.reflectionQuestions.length, (i) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.lg),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.background2,
                borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
                border: Border(
                  left: BorderSide(
                    color: AppColors.focusBlue.withValues(alpha: 0.5),
                    width: 2,
                  ),
                ),
              ),
              child: Text(
                _review!.reflectionQuestions[i],
                style: AppTypography.body.copyWith(
                  color: AppColors.textPrimary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildNextWeekStep() {
    return Column(
      key: const ValueKey('next'),
      children: [
        Text('🚀', style: const TextStyle(fontSize: 48)),
        const SizedBox(height: AppSpacing.xxl),
        Text(
          'Next Week',
          style: AppTypography.h1.copyWith(color: AppColors.textPrimary),
        ),
        const SizedBox(height: AppSpacing.xxl),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.xxl),
          decoration: BoxDecoration(
            color: AppColors.emerald.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
            border: Border.all(
              color: AppColors.emerald.withValues(alpha: 0.2),
            ),
          ),
          child: Text(
            _review!.nextWeekFocus,
            style: AppTypography.h3.copyWith(
              color: AppColors.emerald,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
        Text(
          'Week reviewed. Ready for the next one. 💪',
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
