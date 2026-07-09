import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:confetti/confetti.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/local/tables/energy_checkins_table.dart';
import '../../../core/utils/time_of_day_bucket.dart';
import '../providers/energy_providers.dart';

class EnergyCheckInSheet extends ConsumerStatefulWidget {
  const EnergyCheckInSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const EnergyCheckInSheet(),
    );
  }

  @override
  ConsumerState<EnergyCheckInSheet> createState() => _EnergyCheckInSheetState();
}

class _EnergyCheckInSheetState extends ConsumerState<EnergyCheckInSheet> {
  late ConfettiController _confettiController;
  late TimeOfDayColumn _selectedBucket;
  int _selectedValue = 3;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
    _selectedBucket = bucketFor(DateTime.now());
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  final List<({int value, String label, String emoji, Color color})> _levels = [
    (value: 1, label: 'Drained', emoji: '😴', color: const Color(0xFF64748B)),
    (value: 2, label: 'Low', emoji: '🌤', color: const Color(0xFFF59E0B)),
    (value: 3, label: 'Steady', emoji: '⚡', color: const Color(0xFF3B82F6)),
    (value: 4, label: 'High', emoji: '🔥', color: const Color(0xFFF97316)),
    (value: 5, label: 'Peak', emoji: '🚀', color: const Color(0xFF10B981)),
  ];

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);
    HapticFeedback.mediumImpact();

    try {
      final awardedBonus = await ref
          .read(energyCheckInServiceProvider)
          .logEnergy(_selectedBucket, _selectedValue);

      if (mounted) {
        if (awardedBonus) {
          _confettiController.play();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('🎉 3/3 daily check-ins done! +20 XP awarded!'),
              backgroundColor: AppColors.emerald,
            ),
          );
          await Future.delayed(const Duration(milliseconds: 1500));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Energy logged · ${_selectedBucket.name} $_selectedValue/5',
              ),
              backgroundColor: AppColors.emerald,
            ),
          );
        }
        if (mounted) Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error logging energy: $e'),
            backgroundColor: AppColors.dangerCoral,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        ConfettiWidget(
          confettiController: _confettiController,
          blastDirectionality: BlastDirectionality.explosive,
          maxBlastForce: 15,
          minBlastForce: 5,
          emissionFrequency: 0.05,
          numberOfParticles: 20,
          gravity: 0.2,
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.background1,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(AppSpacing.radiusSheet),
              topRight: Radius.circular(AppSpacing.radiusSheet),
            ),
          ),
          padding: EdgeInsets.only(
            top: AppSpacing.xl,
            left: AppSpacing.xl,
            right: AppSpacing.xl,
            bottom: AppSpacing.xl + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handlebar
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textTertiary.withAlpha(50),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              Text(
                "How's your energy?",
                style: AppTypography.h2.copyWith(color: AppColors.textPrimary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                "Tune in with yourself to match hard tasks to high energy.",
                style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),

              // Bucket selector chips
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: TimeOfDayColumn.values.map((bucket) {
                  final isSelected = _selectedBucket == bucket;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                    child: ChoiceChip(
                      label: Text(
                        bucket.name[0].toUpperCase() + bucket.name.substring(1),
                        style: AppTypography.monoSmall.copyWith(
                          color: isSelected ? AppColors.textInverse : AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _selectedBucket = bucket);
                        }
                      },
                      selectedColor: AppColors.emerald,
                      backgroundColor: AppColors.background2,
                      side: BorderSide.none,
                      showCheckmark: false,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSpacing.xl),

              // 5 large level selector cards
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: _levels.map((level) {
                  final isSelected = _selectedValue == level.value;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedValue = level.value);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? level.color.withAlpha(38)
                              : AppColors.background2,
                          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
                          border: Border.all(
                            color: isSelected
                                ? level.color
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              level.emoji,
                              style: const TextStyle(fontSize: 28),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              level.label,
                              style: AppTypography.monoSmall.copyWith(
                                color: isSelected
                                    ? level.color
                                    : AppColors.textSecondary,
                                fontSize: 10,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${level.value}',
                              style: AppTypography.h3.copyWith(
                                color: isSelected
                                    ? level.color
                                    : AppColors.textTertiary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSpacing.xxl),

              ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.emerald,
                  foregroundColor: AppColors.textInverse,
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusButton),
                  ),
                  elevation: 0,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : Text(
                        'Log Energy',
                        style: AppTypography.h3.copyWith(color: AppColors.textInverse),
                      ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ],
    );
  }
}
