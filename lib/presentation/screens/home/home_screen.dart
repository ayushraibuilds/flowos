import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/constants/xp_constants.dart';
import '../../../features/dashboard/providers/dashboard_providers.dart';
import '../../../features/xp/providers/xp_providers.dart'
    show streakProvider, streakPausedProvider, todayPlanProvider;
import '../../../features/energy/providers/energy_providers.dart';
import '../../../features/energy/widgets/energy_checkin_sheet.dart';
import '../../../features/tasks/providers/task_providers.dart';
import '../../widgets/task_card.dart';
import '../../../data/local/database/app_database.dart';
import '../../../features/tasks/services/task_completion_service.dart';
import '../../../features/attention/widgets/attention_radar_card.dart';
import '../../../features/onboarding/providers/onboarding_providers.dart';
import '../../../features/onboarding/models/user_profile.dart';
import '../../../features/flow_garden/widgets/home_garden_glance.dart';
import '../../../features/rhythm/providers/rhythm_providers.dart';
import '../../widgets/rhythm_recommendation_card.dart';
import '../../../features/onboarding/widgets/device_setup_sheet.dart';

final intentionBannerDismissedProvider =
    StateNotifierProvider<IntentionBannerDismissedNotifier, bool>((ref) {
      return IntentionBannerDismissedNotifier();
    });

class IntentionBannerDismissedNotifier extends StateNotifier<bool> {
  IntentionBannerDismissedNotifier() : super(false) {
    _load();
  }

  String get _dateKey {
    final now = DateTime.now();
    return 'flowos_intention_dismissed_${now.year}-${now.month}-${now.day}';
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_dateKey) ?? false;
  }

  Future<void> dismiss() async {
    state = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_dateKey, true);
  }
}

/// Home Dashboard — the "command center."
/// Shows Flow Score, XP bar, MITs, quick actions, and attention budget.
/// All data is now reactive from Drift DAOs via Riverpod providers.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _setupSheetShown = false;

  void _maybeShowDeviceSetupSheet(BuildContext context) async {
    if (_setupSheetShown) return;

    final prefs = await SharedPreferences.getInstance();
    final lastDismissedStr = prefs.getString('flowos_setup_sheet_dismissed_date');
    if (lastDismissedStr != null) {
      final lastDismissed = DateTime.parse(lastDismissedStr);
      final difference = DateTime.now().difference(lastDismissed);
      if (difference.inDays < 3) {
        return;
      }
    }

    _setupSheetShown = true;
    if (mounted) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => const DeviceSetupSheet(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch profile loading and setup status
    final profileLoaded = ref.watch(profileLoadedProvider);
    final needsSetup = ref.watch(userProfileProvider.notifier).needsDeviceSetup;

    if (profileLoaded && needsSetup) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _maybeShowDeviceSetupSheet(context);
      });
    }

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.lg),
              // ─── Header: Level + Streak ────────────────────────
              _buildHeader(context, ref),
              if (ref.watch(userProfileProvider).isInProtectedWindow()) ...[
                const SizedBox(height: AppSpacing.md),
                _buildProtectedWindowBanner(context, ref.read(userProfileProvider)),
              ],
              const SizedBox(height: AppSpacing.xxl),
              // ─── Hero CTA Card (Dynamic Alignment) ──────────────
              ref.watch(hasFocusHistoryProvider).when(
                    data: (hasHistory) {
                      if (!hasHistory) {
                        return _buildFirstSeedCard(context, ref);
                      }
                      return _buildHeroCTA(context, ref);
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => _buildHeroCTA(context, ref),
                  ),
              const SizedBox(height: AppSpacing.lg),
              // ─── Today's Garden — a living reason to return ──────
              const HomeGardenGlance(),
              const SizedBox(height: AppSpacing.lg),
              // ─── Flow Score Card ────────────────────────────────
              _buildFlowScoreCard(context, ref),
              const SizedBox(height: AppSpacing.md),
              // ─── XP Progress Bar ───────────────────────────────
              _buildXPBar(context, ref),
              const SizedBox(height: AppSpacing.xxl),
              // ─── Rhythm Recommendation Card ────────────────────
              ref.watch(rhythmRecommendationProvider).when(
                    data: (rec) {
                      if (rec == null) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
                        child: RhythmRecommendationCard(recommendation: rec),
                      );
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
              // ─── MITs Section ──────────────────────────────────
              _buildMITsSection(context, ref),
              const SizedBox(height: AppSpacing.xxl),
              // ─── Quick Actions ─────────────────────────────────
              _buildQuickActions(context),
              const SizedBox(height: AppSpacing.xxl),
              // ─── Attention Budget ──────────────────────────────
              _buildAttentionBudget(context, ref),
              const SizedBox(height: AppSpacing.xxxl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    final level = ref.watch(currentLevelProvider);
    final tier = ref.watch(currentTierProvider);
    final streakAsync = ref.watch(streakProvider);
    final streak = streakAsync.valueOrNull ?? 0;
    final paused = ref.watch(streakPausedProvider).valueOrNull ?? false;

    final energyCheckIn = ref.watch(latestEnergyCheckInProvider);
    final energyValue = energyCheckIn?.value;

    return Row(
      children: [
        // Level badge
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.emerald, width: 2),
          ),
          child: Center(
            child: Text(
              '$level',
              style: AppTypography.monoSmall.copyWith(color: AppColors.emerald),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Level $level · $tier',
                style: AppTypography.h3.copyWith(color: AppColors.textPrimary),
              ),
              const SizedBox(height: 2),
              Text(
                _getTimeOfDayGreeting(),
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        // Streak counter
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: AppColors.background2,
            borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(paused ? '⏸️' : '🔥', style: const TextStyle(fontSize: 16)),
              const SizedBox(width: AppSpacing.xs),
              Text(
                '$streak',
                style: AppTypography.monoSmall.copyWith(
                  color: streak > 0
                      ? AppColors.warningAmber
                      : AppColors.textTertiary,
                ),
              ),
              if (paused) ...[
                const SizedBox(width: AppSpacing.xs),
                Text(
                  '(paused)',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textTertiary,
                    fontSize: 10,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        // Energy check-in chip
        GestureDetector(
          onTap: () => EnergyCheckInSheet.show(context),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: AppColors.background2,
              borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
              border: Border.all(
                color: AppColors.emerald.withAlpha(50),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('⚡', style: TextStyle(fontSize: 14)),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  energyValue != null ? '$energyValue/5' : 'Log',
                  style: AppTypography.monoSmall.copyWith(
                    color: energyValue != null
                        ? AppColors.emerald
                        : AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFlowScoreCard(BuildContext context, WidgetRef ref) {
    final scoreAsync = ref.watch(dailyScoreProvider);
    final score = scoreAsync.valueOrNull;
    final grade = score?.grade ?? '—';
    final value = score?.score ?? 0;
    final message = score?.message ?? 'Loading...';

    final gradeColor = switch (grade) {
      'A+' || 'A' => AppColors.gradeA,
      'B' => AppColors.gradeB,
      'C' => AppColors.gradeC,
      'D' => AppColors.gradeD,
      _ => AppColors.textTertiary,
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xxl),
      decoration: BoxDecoration(
        color: AppColors.background2,
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.06),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.emeraldGlow,
            blurRadius: 30,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            grade,
            style: AppTypography.display.copyWith(
              color: gradeColor,
              fontSize: 64,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '$value',
            style: AppTypography.monoSmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            message,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildXPBar(BuildContext context, WidgetRef ref) {
    final lifetimeXP = ref.watch(lifetimeXpProvider).valueOrNull ?? 0;
    final level = ref.watch(currentLevelProvider);
    final currentLevelXP = XpConstants.xpForLevel(level);
    final nextLevelXP = XpConstants.xpForLevel(level + 1);
    final xpInLevel = lifetimeXP - currentLevelXP;
    final xpNeeded = nextLevelXP - currentLevelXP;
    final progress = xpNeeded > 0 ? xpInLevel / xpNeeded : 0.0;

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            minHeight: 8,
            backgroundColor: AppColors.background2,
            valueColor: AlwaysStoppedAnimation(AppColors.emerald),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$lifetimeXP / $nextLevelXP XP',
              style: AppTypography.monoSmall.copyWith(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
            Text(
              'Level ${level + 1}',
              style: AppTypography.caption.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMITsSection(BuildContext context, WidgetRef ref) {
    final mitsAsync = ref.watch(mitsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Today's MITs",
          style: AppTypography.h2.copyWith(color: AppColors.textPrimary),
        ),
        const SizedBox(height: AppSpacing.md),
        mitsAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
          data: (mits) {
            if (mits.isEmpty) {
              return _buildEmptyMITs(context);
            }
            return Column(
              children: mits
                  .map(
                    (task) => TaskCard(
                      task: task,
                      onComplete: () async {
                        final db = ref.read(databaseProvider);
                        final service = TaskCompletionService(db);
                        await service.completeTask(task);
                      },
                      onDelete: () async {
                        final db = ref.read(databaseProvider);
                        await db.tasksDao.toggleMIT(task.id, false);
                      },
                      onTap: () => _startDeepWork(context, task),
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildEmptyMITs(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xxl),
      decoration: BoxDecoration(
        color: AppColors.background2,
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.06),
          width: 0.5,
        ),
      ),
      child: Column(
        children: [
          const Text('🎯', style: TextStyle(fontSize: 32)),
          const SizedBox(height: AppSpacing.md),
          Text(
            'No MITs set yet',
            style: AppTypography.body.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Start your morning intention to pick 3 MITs',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => context.push('/morning-intention'),
              child: const Text('Set Morning Intention'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      (icon: '🎯', label: 'Focus', onTap: () => context.go('/focus')),
      (icon: '📝', label: 'Add Task', onTap: () => context.go('/tasks')),
      (
        icon: '📱',
        label: 'Log Scroll',
        onTap: () => context.push('/scroll-tracker'),
      ),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: actions.map((action) {
          return Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: OutlinedButton.icon(
              onPressed: action.onTap,
              icon: Text(action.icon, style: const TextStyle(fontSize: 16)),
              label: Text(action.label),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAttentionBudget(BuildContext context, WidgetRef ref) {
    final scoreAsync = ref.watch(dailyScoreProvider);
    final budget = scoreAsync.valueOrNull?.scrollBudget ?? 30;
    return AttentionRadarCard(budgetMinutes: budget);
  }

  void _startDeepWork(BuildContext context, Task task) {
    context.push(
      '/deep-work',
      extra: {'taskId': task.id, 'taskTitle': task.title},
    );
  }

  String _getTimeOfDayGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Morning focus window 🌅';
    if (hour < 17) return 'Protect the afternoon dip ⚡';
    return 'Evening recovery & ritual 🧘';
  }

  Widget _buildHeroCTA(BuildContext context, WidgetRef ref) {
    final planAsync = ref.watch(todayPlanProvider);
    final scoreAsync = ref.watch(dailyScoreProvider);

    return planAsync.maybeWhen(
      data: (plan) {
        final now = DateTime.now();
        final hour = now.hour;

        // 1. Morning / No Plan state
        if (plan == null || !plan.intentionCompleted) {
          return _heroCard(
            title: "Morning Alignment",
            subtitle: "Define your focus and pick your 3 Most Important Tasks.",
            buttonText: "Set Intention 🌅",
            onTap: () => context.push('/morning-intention'),
            gradient: const LinearGradient(
              colors: [Color(0xFF0F3A20), Color(0xFF072111)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderColor: AppColors.emerald.withValues(alpha: 0.3),
            glowColor: AppColors.emerald.withValues(alpha: 0.15),
          );
        }

        // 2. Evening / Shutdown state
        if (hour >= 17 && !plan.shutdownCompleted) {
          return _heroCard(
            title: "Close the Loop",
            subtitle:
                "End the day clean. Run the shutdown ritual to offload pending items.",
            buttonText: "Start Shutdown Ritual 🧘",
            onTap: () => context.push('/shutdown'),
            gradient: const LinearGradient(
              colors: [Color(0xFF261835), Color(0xFF140C1C)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderColor: Colors.purple.withValues(alpha: 0.3),
            glowColor: Colors.purple.withValues(alpha: 0.15),
          );
        }

        // 3. Mid-day Energy Check-in state
        final score = scoreAsync.valueOrNull;
        final checkIns = score?.score != null
            ? ref.watch(latestEnergyCheckInProvider)
            : null;
        final needsEnergyCheck = hour >= 12 && hour < 17 && checkIns == null;

        if (needsEnergyCheck) {
          return _heroCard(
            title: "Energy Check-in",
            subtitle:
                "Track your current focus capacity to align work with your energy curve.",
            buttonText: "Log Energy ⚡",
            onTap: () => EnergyCheckInSheet.show(context),
            gradient: const LinearGradient(
              colors: [Color(0xFF332B13), Color(0xFF1C1709)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderColor: AppColors.warningAmber.withValues(alpha: 0.3),
            glowColor: AppColors.warningAmber.withValues(alpha: 0.15),
          );
        }

        // 4. Default: Smart Contextual Actions
        if (!plan.shutdownCompleted) {
          // Check for suggested peak focus window
          final suggestedWindow = ref.watch(suggestedFocusWindowProvider).valueOrNull;
          if (suggestedWindow != null && hour >= suggestedWindow.start && hour < suggestedWindow.end) {
            return _heroCard(
              title: "Start Protected Focus",
              subtitle: "You are within your predicted peak window (${_formatHour(suggestedWindow.start)} - ${_formatHour(suggestedWindow.end)}). Start a focus block now.",
              buttonText: "Start Protected Focus ⚡",
              onTap: () {
                HapticFeedback.mediumImpact();
                context.go('/focus');
              },
              gradient: const LinearGradient(
                colors: [Color(0xFF0F2B3A), Color(0xFF06151E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderColor: AppColors.focusBlue.withValues(alpha: 0.3),
              glowColor: AppColors.focusBlue.withValues(alpha: 0.15),
            );
          }

          // Check for incomplete MIT
          final mits = ref.watch(mitsProvider).valueOrNull ?? [];
          Task? incompleteMit;
          for (final task in mits) {
            if (!task.isCompleted) {
              incompleteMit = task;
              break;
            }
          }

          if (incompleteMit != null) {
            return _heroCard(
              title: "Next Priority",
              subtitle: "Start focus on your MIT: \"${incompleteMit.title}\".",
              buttonText: "Focus on MIT 🎯",
              onTap: () => _startDeepWork(context, incompleteMit!),
              gradient: const LinearGradient(
                colors: [Color(0xFF1B2E24), Color(0xFF0D1812)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderColor: AppColors.emerald.withValues(alpha: 0.3),
              glowColor: AppColors.emerald.withValues(alpha: 0.15),
            );
          }

          // Fallback Pomodoro card
          return _heroCard(
            title: "Enter the Flow Cave",
            subtitle:
                "Ready to make progress? Start an immersive focus session now.",
            buttonText: "Start Focus Session 🎯",
            onTap: () => context.go('/focus'),
            gradient: const LinearGradient(
              colors: [Color(0xFF142834), Color(0xFF0B171E)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderColor: AppColors.focusBlue.withValues(alpha: 0.3),
            glowColor: AppColors.focusBlue.withValues(alpha: 0.15),
          );
        }

        // 5. Day Complete
        return _heroCard(
          title: "Day Complete",
          subtitle:
              "You've successfully shut down for today. Protect your rest and recover.",
          buttonText: "View Insights 📊",
          onTap: () => context.pushNamed('insights'),
          gradient: const LinearGradient(
            colors: [Color(0xFF1D221F), Color(0xFF0F1210)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderColor: AppColors.textTertiary.withValues(alpha: 0.2),
          glowColor: Colors.transparent,
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }

  Widget _heroCard({
    required String title,
    required String subtitle,
    required String buttonText,
    required VoidCallback onTap,
    required Gradient gradient,
    required Color borderColor,
    required Color glowColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          if (glowColor != Colors.transparent)
            BoxShadow(
              color: glowColor,
              blurRadius: 30,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.h3.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            subtitle,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.background0.withValues(alpha: 0.5),
                foregroundColor: AppColors.textPrimary,
                side: BorderSide(color: borderColor, width: 1),
                elevation: 0,
              ),
              child: Text(buttonText),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFirstSeedCard(BuildContext context, WidgetRef ref) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F3A20), Color(0xFF061A0E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        border: Border.all(
          color: AppColors.emerald.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.emerald.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🌱', style: TextStyle(fontSize: 24)),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Plant Your First Seed',
                  style: AppTypography.h3.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Ready to cultivate your focus garden? Start your first 10-minute focus session to grow a starter plant in today\'s plot.',
            style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.lg),
          ElevatedButton(
            onPressed: () {
              HapticFeedback.mediumImpact();
              context.push('/focus', extra: {
                'durationMinutes': 10,
                'sessionLabel': 'Plant my first seed',
                'firstSeed': true,
                'autoStart': false,
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.emerald,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
              ),
            ),
            child: Text(
              'Configure Starter Session 🎯',
              style: AppTypography.bodySmall.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProtectedWindowBanner(BuildContext context, UserProfile profile) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.emerald.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        border: Border.all(
          color: AppColors.emerald.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Text('🛡️', style: TextStyle(fontSize: 20)),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Protected Focus Block',
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  'Protected window · ${profile.protectedWindowLabel}',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              HapticFeedback.mediumImpact();
              context.go('/focus');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.emerald,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusButton),
              ),
            ),
            child: Text(
              'Focus 🎯',
              style: AppTypography.caption.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _formatHour(int hour) {
    if (hour == 0) return '12 AM';
    if (hour == 12) return '12 PM';
    return hour < 12 ? '$hour AM' : '${hour - 12} PM';
  }
}
