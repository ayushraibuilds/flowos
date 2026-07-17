import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../features/onboarding/providers/onboarding_providers.dart';
import '../../../../core/constants/distraction_packages.dart';

class ShapeFocusSheet extends ConsumerStatefulWidget {
  const ShapeFocusSheet({super.key});

  @override
  ConsumerState<ShapeFocusSheet> createState() => _ShapeFocusSheetState();
}

class _ShapeFocusSheetState extends ConsumerState<ShapeFocusSheet> {
  late List<String> _tempGoals;
  late List<String> _tempDistractions;
  late int _tempStartHour;
  late int _tempEndHour;
  late bool _tempWeekdaysOnly;
  late String _tempMode;

  final _goalsOptions = ['Deep work', 'Study', 'Rest', 'Less scrolling'];

  @override
  void initState() {
    super.initState();
    final profile = ref.read(userProfileProvider);
    _tempGoals = List.from(profile.goals);
    _tempDistractions = List.from(profile.distractions);
    _tempStartHour = profile.protectedStartHour;
    _tempEndHour = profile.protectedEndHour;
    _tempWeekdaysOnly = profile.protectedWeekdaysOnly;
    _tempMode = profile.protectionMode;
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(userProfileProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (scrollContext, scrollController) {
        return SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: AppColors.textTertiary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                'Shape Focus Settings',
                style: AppTypography.h2.copyWith(color: AppColors.textPrimary),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Customize your focus targets, distraction lists, and protected blocks.',
                style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.xxl),

              // 1. Core Focus Goals
              Text(
                'Core Focus Goals',
                style: AppTypography.h3.copyWith(color: AppColors.textPrimary),
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: _goalsOptions.map((g) {
                  final isSel = _tempGoals.contains(g);
                  return FilterChip(
                    label: Text(g),
                    selected: isSel,
                    selectedColor: AppColors.emerald.withValues(alpha: 0.2),
                    checkmarkColor: AppColors.emerald,
                    labelStyle: AppTypography.bodySmall.copyWith(
                      color: isSel ? AppColors.emerald : AppColors.textSecondary,
                    ),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _tempGoals.add(g);
                        } else {
                          _tempGoals.remove(g);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSpacing.xl),

              // 2. Distractions
              Text(
                'Distraction Apps',
                style: AppTypography.h3.copyWith(color: AppColors.textPrimary),
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: DistractionPackages.allOptions.map((d) {
                  final isSel = _tempDistractions.contains(d);
                  return FilterChip(
                    label: Text(d),
                    selected: isSel,
                    selectedColor: AppColors.dangerCoral.withValues(alpha: 0.2),
                    checkmarkColor: AppColors.dangerCoral,
                    labelStyle: AppTypography.bodySmall.copyWith(
                      color: isSel ? AppColors.dangerCoral : AppColors.textSecondary,
                    ),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _tempDistractions.add(d);
                          if (d == 'Games' || d == 'Other') {
                            if (context.mounted) {
                              context.push('/app-picker');
                            }
                          }
                        } else {
                          _tempDistractions.remove(d);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSpacing.xl),

              // 3. Protected Focus Hours
              Text(
                'Protected Focus Hours',
                style: AppTypography.h3.copyWith(color: AppColors.textPrimary),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _tempStartHour,
                      decoration: const InputDecoration(
                        labelText: 'Start Hour',
                        border: OutlineInputBorder(),
                      ),
                      dropdownColor: AppColors.background2,
                      items: List.generate(24, (i) {
                        return DropdownMenuItem<int>(
                          value: i,
                          child: Text('$i:00'),
                        );
                      }),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _tempStartHour = val);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _tempEndHour,
                      decoration: const InputDecoration(
                        labelText: 'End Hour',
                        border: OutlineInputBorder(),
                      ),
                      dropdownColor: AppColors.background2,
                      items: List.generate(24, (i) {
                        return DropdownMenuItem<int>(
                          value: i,
                          child: Text('$i:00'),
                        );
                      }),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _tempEndHour = val);
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              SwitchListTile(
                title: Text(
                  'Weekdays only',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textPrimary),
                ),
                subtitle: Text(
                  'Only shield target apps during weekdays (Mon-Fri)',
                  style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                ),
                value: _tempWeekdaysOnly,
                activeColor: AppColors.emerald,
                contentPadding: EdgeInsets.zero,
                onChanged: (val) {
                  setState(() => _tempWeekdaysOnly = val);
                },
              ),
              const SizedBox(height: AppSpacing.xl),

              // 4. Protection Level
              Text(
                'Shield Protection Mode',
                style: AppTypography.h3.copyWith(color: AppColors.textPrimary),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('Gentle (Reflect)')),
                      selected: _tempMode == 'gentle',
                      selectedColor: AppColors.emerald.withValues(alpha: 0.2),
                      labelStyle: AppTypography.bodySmall.copyWith(
                        color: _tempMode == 'gentle' ? AppColors.emerald : AppColors.textSecondary,
                      ),
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _tempMode = 'gentle');
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('Firm (Guard/Deep)')),
                      selected: _tempMode == 'firm',
                      selectedColor: AppColors.dangerCoral.withValues(alpha: 0.2),
                      labelStyle: AppTypography.bodySmall.copyWith(
                        color: _tempMode == 'firm' ? AppColors.dangerCoral : AppColors.textSecondary,
                      ),
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _tempMode = 'firm');
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xxl),

              // Action Button
              ElevatedButton(
                onPressed: () async {
                  HapticFeedback.mediumImpact();
                  final updated = profile.copyWith(
                    goals: _tempGoals,
                    distractions: _tempDistractions,
                    protectedStartHour: _tempStartHour,
                    protectedEndHour: _tempEndHour,
                    protectedWeekdaysOnly: _tempWeekdaysOnly,
                    protectionMode: _tempMode,
                  );
                  await ref.read(userProfileProvider.notifier).updateProfile(updated);
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Focus shape updated successfully!'),
                        backgroundColor: AppColors.emerald,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.emerald,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                  ),
                ),
                child: Text(
                  'Save Settings',
                  style: AppTypography.bodySmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
