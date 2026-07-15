import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart' show Value;

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/local/database/app_database.dart';
import '../../../features/attention/providers/app_picker_providers.dart';
import '../../../features/settings/providers/sleep_mode_provider.dart';
import '../../widgets/flow_surface.dart';

class SleepModeScreen extends ConsumerStatefulWidget {
  const SleepModeScreen({super.key});

  @override
  ConsumerState<SleepModeScreen> createState() => _SleepModeScreenState();
}

class _SleepModeScreenState extends ConsumerState<SleepModeScreen> {
  bool _isSaving = false;
  Map<String, bool> _localSleepState = {};
  bool _hasLocalChanges = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentSleepApps();
  }

  Future<void> _loadCurrentSleepApps() async {
    final db = ref.read(databaseProvider);
    final sleepApps = await db.protectedAppsDao.getSleepProtected();
    if (mounted) {
      setState(() {
        _localSleepState = {for (final app in sleepApps) app.appRef: true};
      });
    }
  }

  String _formatMinute(int minutes) {
    final hour = minutes ~/ 60;
    final min = minutes % 60;
    final ampm = hour >= 12 ? 'PM' : 'AM';
    final h12 = hour % 12 == 0 ? 12 : hour % 12;
    return '$h12:${min.toString().padLeft(2, '0')} $ampm';
  }

  Future<void> _selectTime({
    required bool isBedtime,
    required int currentMinutes,
    required SleepSchedule schedule,
  }) async {
    final initialTime = TimeOfDay(
      hour: currentMinutes ~/ 60,
      minute: currentMinutes % 60,
    );

    final selectedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppColors.emerald,
              onPrimary: Colors.white,
              surface: AppColors.background2,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (selectedTime != null) {
      final selectedMinutes = selectedTime.hour * 60 + selectedTime.minute;
      final otherMinutes = isBedtime ? schedule.wakeMinute : schedule.bedtimeMinute;

      if (selectedMinutes == otherMinutes) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Bedtime and wake time cannot be identical.'),
              backgroundColor: AppColors.dangerCoral,
            ),
          );
        }
        return;
      }

      List<int> weekdaysList = [1, 2, 3, 4, 5, 6, 7];
      try {
        weekdaysList = List<int>.from(jsonDecode(schedule.weekdays));
      } catch (_) {}

      final notifier = ref.read(sleepModeProvider.notifier);
      await notifier.updateTimes(
        bedtimeMinute: isBedtime ? selectedMinutes : schedule.bedtimeMinute,
        wakeMinute: isBedtime ? schedule.wakeMinute : selectedMinutes,
        weekdays: weekdaysList,
        protectionLevel: schedule.protectionLevel,
      );
    }
  }

  Future<void> _toggleWeekday(int day, SleepSchedule schedule) async {
    List<int> weekdaysList = [1, 2, 3, 4, 5, 6, 7];
    try {
      weekdaysList = List<int>.from(jsonDecode(schedule.weekdays));
    } catch (_) {}

    if (weekdaysList.contains(day)) {
      if (weekdaysList.length == 1) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sleep Mode must repeat on at least one day.'),
            backgroundColor: AppColors.dangerCoral,
          ),
        );
        return;
      }
      weekdaysList.remove(day);
    } else {
      weekdaysList.add(day);
    }

    final notifier = ref.read(sleepModeProvider.notifier);
    await notifier.updateTimes(
      bedtimeMinute: schedule.bedtimeMinute,
      wakeMinute: schedule.wakeMinute,
      weekdays: weekdaysList,
      protectionLevel: schedule.protectionLevel,
    );
  }

  Future<void> _saveAppPickerChanges() async {
    setState(() => _isSaving = true);
    final db = ref.read(databaseProvider);
    final now = DateTime.now();
    final launchable = await ref.read(launchableAppsProvider.future);

    for (final app in launchable) {
      final pkg = app['packageName'] ?? '';
      final label = app['label'] ?? '';
      final isSleepChecked = _localSleepState[pkg] ?? false;

      final existing = await db.protectedAppsDao.getByPlatformAndRef('android', pkg);

      if (isSleepChecked) {
        final entryId = existing?.id ?? const Uuid().v4();
        await db.protectedAppsDao.upsertApp(
          ProtectedAppsCompanion(
            id: Value(entryId),
            platform: const Value('android'),
            appRef: Value(pkg),
            displayName: Value(label),
            protectsFocus: Value(existing?.protectsFocus ?? false),
            protectsSleep: const Value(true),
            isEssential: const Value(false),
            createdAt: Value(now),
          ),
        );
      } else {
        if (existing != null) {
          await db.protectedAppsDao.updateFlags(
            platform: 'android',
            appRef: pkg,
            protectsSleep: false,
          );
          await db.protectedAppsDao.deleteIfUnprotected('android', pkg);
        }
      }
    }

    // Refresh versioned native sleep config *after* database transaction completes successfully
    await ref.read(sleepConfigWriterProvider).writeSleepConfig();

    if (mounted) {
      setState(() {
        _hasLocalChanges = false;
        _isSaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Apps to quiet tonight updated.'),
          backgroundColor: AppColors.emerald,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final schedule = ref.watch(sleepModeProvider);
    final launchableAppsAsync = ref.watch(launchableAppsProvider);
    final isAndroid = Theme.of(context).platform == TargetPlatform.android;

    if (!isAndroid) {
      return Scaffold(
        backgroundColor: AppColors.background0,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: const BackButton(color: AppColors.textPrimary),
          title: Text(
            'Sleep Mode',
            style: AppTypography.h3.copyWith(color: AppColors.textPrimary),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.nights_stay_outlined,
                  color: AppColors.textSecondary,
                  size: 64,
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Sleep Mode is currently unsupported on iOS.',
                  style: AppTypography.h3.copyWith(color: AppColors.textPrimary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Selected-app shielding during bedtime requires native Android permissions.',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (schedule == null) {
      return Scaffold(
        backgroundColor: AppColors.background0,
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.focusBlue),
        ),
      );
    }

    List<int> weekdaysList = [1, 2, 3, 4, 5, 6, 7];
    try {
      weekdaysList = List<int>.from(jsonDecode(schedule.weekdays));
    } catch (_) {}

    return Scaffold(
      backgroundColor: AppColors.background0,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: AppColors.textPrimary),
        title: Text(
          'Sleep Mode',
          style: AppTypography.h3.copyWith(color: AppColors.textPrimary),
        ),
        actions: [
          Row(
            children: [
              Text(
                schedule.enabled ? 'Enabled' : 'Disabled',
                style: AppTypography.bodySmall.copyWith(
                  color: schedule.enabled ? AppColors.emerald : AppColors.textTertiary,
                ),
              ),
              Switch(
                value: schedule.enabled,
                activeColor: AppColors.emerald,
                onChanged: (val) {
                  ref.read(sleepModeProvider.notifier).toggleEnabled(val);
                },
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Bedtime & Wake Time Card
              Text(
                ' Bedtime Boundary',
                style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.sm),
              FlowSurface(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => _selectTime(
                            isBedtime: true,
                            currentMinutes: schedule.bedtimeMinute,
                            schedule: schedule,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'BEDTIME',
                                style: AppTypography.caption.copyWith(color: AppColors.textTertiary),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                _formatMinute(schedule.bedtimeMinute),
                                style: AppTypography.h2.copyWith(color: AppColors.textPrimary),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Container(
                        height: 40,
                        width: 1,
                        color: AppColors.glassBorder,
                      ),
                      Expanded(
                        child: InkWell(
                          onTap: () => _selectTime(
                            isBedtime: false,
                            currentMinutes: schedule.wakeMinute,
                            schedule: schedule,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.only(left: AppSpacing.lg),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'WAKE TIME',
                                  style: AppTypography.caption.copyWith(color: AppColors.textTertiary),
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  _formatMinute(schedule.wakeMinute),
                                  style: AppTypography.h2.copyWith(color: AppColors.textPrimary),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // 2. Weekdays Selector
              Text(
                ' Repeat Days',
                style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.sm),
              FlowSurface(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: AppSpacing.sm),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      for (int day = 1; day <= 7; day++) ...[
                        _buildWeekdayChip(day, weekdaysList, schedule),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // 3. Strictness Selector
              Text(
                ' Protection Mode',
                style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.sm),
              FlowSurface(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    children: [
                      _buildProtectionLevelTile(
                        level: 'nudge',
                        title: 'Nudge',
                        description: 'gentle return cue',
                        currentLevel: schedule.protectionLevel,
                      ),
                      Divider(color: AppColors.glassBorder),
                      _buildProtectionLevelTile(
                        level: 'guard',
                        title: 'Guard (Default)',
                        description: 'reflection wait, then return to sleep',
                        currentLevel: schedule.protectionLevel,
                      ),
                      Divider(color: AppColors.glassBorder),
                      _buildProtectionLevelTile(
                        level: 'deep',
                        title: 'Deep',
                        description: 'no bypass until wake',
                        currentLevel: schedule.protectionLevel,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // 4. Apps to Quiet Tonight
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    ' Apps to Quiet Tonight',
                    style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                  ),
                  if (_hasLocalChanges)
                    TextButton(
                      onPressed: _isSaving ? null : _saveAppPickerChanges,
                      child: _isSaving
                          ? SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                color: AppColors.emerald,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              'Save App Choices',
                              style: TextStyle(color: AppColors.emerald, fontWeight: FontWeight.bold),
                            ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              FlowSurface(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: launchableAppsAsync.when(
                    data: (apps) {
                      final nonEssential = apps.where((app) {
                        final pkg = app['packageName'] ?? '';
                        return pkg != 'com.android.settings' && pkg != 'com.android.phone';
                      }).toList();

                      return ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: nonEssential.length,
                        separatorBuilder: (_, __) => Divider(color: AppColors.glassBorder, height: 1),
                        itemBuilder: (ctx, idx) {
                          final app = nonEssential[idx];
                          final pkg = app['packageName'] ?? '';
                          final label = app['label'] ?? pkg;
                          final isChecked = _localSleepState[pkg] ?? false;

                          return CheckboxListTile(
                            title: Text(
                              label,
                              style: AppTypography.bodySmall.copyWith(color: AppColors.textPrimary),
                            ),
                            subtitle: Text(
                              pkg,
                              style: AppTypography.caption.copyWith(color: AppColors.textTertiary),
                            ),
                            value: isChecked,
                            activeColor: AppColors.emerald,
                            contentPadding: EdgeInsets.zero,
                            onChanged: (val) {
                              setState(() {
                                _localSleepState[pkg] = val ?? false;
                                _hasLocalChanges = true;
                              });
                            },
                          );
                        },
                      );
                    },
                    loading: () => Center(
                      child: CircularProgressIndicator(color: AppColors.emerald),
                    ),
                    error: (err, _) => Center(
                      child: Text('Failed to load apps: $err'),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeekdayChip(int day, List<int> weekdaysList, SleepSchedule schedule) {
    final daysStr = ['', 'M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final isSelected = weekdaysList.contains(day);

    return InkWell(
      onTap: () => _toggleWeekday(day, schedule),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isSelected ? AppColors.emerald.withValues(alpha: 0.2) : Colors.transparent,
          border: Border.all(
            color: isSelected ? AppColors.emerald : AppColors.glassBorder,
            width: 1.5,
          ),
        ),
        child: Center(
          child: Text(
            daysStr[day],
            style: AppTypography.bodySmall.copyWith(
              color: isSelected ? AppColors.emerald : AppColors.textSecondary,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProtectionLevelTile({
    required String level,
    required String title,
    required String description,
    required String currentLevel,
  }) {
    final isSelected = currentLevel == level;

    return RadioListTile<String>(
      title: Text(
        title,
        style: AppTypography.bodySmall.copyWith(
          color: isSelected ? AppColors.emerald : AppColors.textPrimary,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      subtitle: Text(
        description,
        style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
      ),
      value: level,
      groupValue: currentLevel,
      activeColor: AppColors.emerald,
      contentPadding: EdgeInsets.zero,
      onChanged: (val) {
        if (val != null) {
          ref.read(sleepModeProvider.notifier).updateProtectionLevel(val);
        }
      },
    );
  }
}
