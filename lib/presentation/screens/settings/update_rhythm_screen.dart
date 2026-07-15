import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../features/onboarding/providers/onboarding_providers.dart';

class UpdateRhythmScreen extends ConsumerStatefulWidget {
  const UpdateRhythmScreen({super.key});

  @override
  ConsumerState<UpdateRhythmScreen> createState() => _UpdateRhythmScreenState();
}

class _UpdateRhythmScreenState extends ConsumerState<UpdateRhythmScreen> {
  final List<String> _selectedGoals = [];
  int _preferredFocusMinutes = 25;
  bool _initialized = false;

  final List<String> _goalsOptions = [
    'Deep work',
    'Study',
    'Creative',
    'Less scrolling',
    'Rest',
  ];

  final List<int> _durationOptions = [15, 25, 45, 90];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      final profile = ref.read(userProfileProvider);
      _selectedGoals.addAll(profile.goals);
      _preferredFocusMinutes = profile.preferredFocusMinutes;
    }
  }

  Future<void> _save() async {
    if (_selectedGoals.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one goal.')),
      );
      return;
    }

    HapticFeedback.mediumImpact();
    final notifier = ref.read(userProfileProvider.notifier);
    final updated = ref.read(userProfileProvider).copyWith(
          goals: _selectedGoals,
          preferredFocusMinutes: _preferredFocusMinutes,
        );

    await notifier.updateProfile(updated);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Rhythm configuration updated successfully.'),
          backgroundColor: AppColors.emerald,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background0,
      appBar: AppBar(
        backgroundColor: AppColors.background0,
        elevation: 0,
        title: Text(
          'Update your rhythm',
          style: AppTypography.h3.copyWith(color: AppColors.textPrimary),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl,
                  vertical: AppSpacing.md,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Main Goals',
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

                    Text(
                      'Default focus duration',
                      style: AppTypography.h3.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Focus sessions will default to this duration.',
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

            // Save button
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.emerald,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
                    ),
                  ),
                  child: Text(
                    'Save Settings',
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
