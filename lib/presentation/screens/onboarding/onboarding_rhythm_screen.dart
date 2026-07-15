import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

class OnboardingRhythmScreen extends StatefulWidget {
  final void Function(List<String> goals, int focusMinutes) onContinue;

  const OnboardingRhythmScreen({
    super.key,
    required this.onContinue,
  });

  @override
  State<OnboardingRhythmScreen> createState() => _OnboardingRhythmScreenState();
}

class _OnboardingRhythmScreenState extends State<OnboardingRhythmScreen> {
  final List<String> _selectedGoals = [];
  int _preferredFocusMinutes = 25;

  final List<String> _goalsOptions = [
    'Deep work',
    'Study',
    'Creative',
    'Less scrolling',
    'Rest',
  ];

  final List<int> _durationOptions = [15, 25, 45, 90];

  bool get _isNextEnabled => _selectedGoals.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background0,
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl,
                  vertical: AppSpacing.xxl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Shape your rhythm', style: AppTypography.h1),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Choose how you want to invest your attention.',
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: AppSpacing.xxxl),

                    // Section 1: Goals Selection
                    Text(
                      'What are your main goals?',
                      style: AppTypography.h3.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Select at least one priority.',
                      style: AppTypography.caption.copyWith(color: AppColors.textTertiary),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Wrap(
                      spacing: AppSpacing.md,
                      runSpacing: AppSpacing.md,
                      children: _goalsOptions.map((goal) {
                        final isSelected = _selectedGoals.contains(goal);
                        return InkWell(
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                _selectedGoals.remove(goal);
                              } else {
                                _selectedGoals.add(goal);
                              }
                            });
                          },
                          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.lg,
                              vertical: AppSpacing.md,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.emerald.withValues(alpha: 0.1)
                                  : AppColors.background2,
                              borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.emerald
                                    : Colors.white.withValues(alpha: 0.05),
                              ),
                            ),
                            child: Text(
                              goal,
                              style: AppTypography.body.copyWith(
                                color: isSelected ? AppColors.emerald : AppColors.textSecondary,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: AppSpacing.xxxl),

                    // Section 2: Preferred Focus Duration
                    Text(
                      'Default focus duration',
                      style: AppTypography.h3.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'We will start focus timers with this length.',
                      style: AppTypography.caption.copyWith(color: AppColors.textTertiary),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: _durationOptions.map((duration) {
                        final isSelected = _preferredFocusMinutes == duration;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4.0),
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _preferredFocusMinutes = duration;
                                });
                              },
                              borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.emerald.withValues(alpha: 0.1)
                                      : AppColors.background2,
                                  borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.emerald
                                        : Colors.white.withValues(alpha: 0.05),
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    '${duration}m',
                                    style: AppTypography.body.copyWith(
                                      color: isSelected ? AppColors.emerald : AppColors.textSecondary,
                                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),

            // Continue button
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isNextEnabled
                      ? () {
                          HapticFeedback.mediumImpact();
                          widget.onContinue(_selectedGoals, _preferredFocusMinutes);
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.emerald,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.background2,
                    disabledForegroundColor: AppColors.textTertiary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
                    ),
                  ),
                  child: Text(
                    'Continue',
                    style: AppTypography.button,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
