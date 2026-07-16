import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/local/tables/focus_sessions_table.dart';
import '../../../features/focus/services/focus_session_service.dart';
import '../../../features/focus/providers/focus_timer_provider.dart';
import '../../../features/focus/models/focus_timer_stage.dart';
import '../../../features/focus/models/focus_protection.dart';
import '../../../features/focus/widgets/focus_protection_selector.dart';
import '../../../features/focus/widgets/intentional_exit_dialog.dart';
import '../../../features/focus/widgets/focus_shield_overlay.dart';
import '../../../features/focus/services/protection_policy_service.dart';
import '../../../features/focus/models/effective_policy.dart';
import '../../../features/settings/providers/settings_providers.dart';
import '../../../features/celebration/services/celebration_service.dart';
import '../../../features/achievements/models/achievement_checker.dart';
import '../../../features/flow_garden/widgets/garden_growth_dialog.dart';
import '../../../data/local/database/app_database.dart';
import '../../../features/focus/services/ambient_sound_player.dart';

class DeepWorkScreen extends ConsumerStatefulWidget {
  final String? taskTitle;
  final String? taskId;

  const DeepWorkScreen({super.key, this.taskTitle, this.taskId});

  @override
  ConsumerState<DeepWorkScreen> createState() => _DeepWorkScreenState();
}

class _DeepWorkScreenState extends ConsumerState<DeepWorkScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  
  String _selectedSound = 'none';
  final _sounds = [
    (key: 'none', emoji: '🔇', label: 'Silent'),
    (key: 'binaural', emoji: '🧠', label: 'Binaural'),
    (key: 'rain', emoji: '🌧️', label: 'Rain'),
    (key: 'cafe', emoji: '☕', label: 'Café'),
    (key: 'piano', emoji: '🎹', label: 'Piano'),
  ];

  bool _wasBackgrounded = false;

  // Flow state animation
  late AnimationController _glowController;
  late AnimationController _breatheController;
  late Animation<double> _glowAnimation;
  late Animation<double> _breatheAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _breatheController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.1, end: 0.35).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _breatheAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _breatheController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _glowController.dispose();
    _breatheController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final active = ref.read(focusTimerNotifierProvider);
    if (active == null || active.phase != FocusTimerPhase.running) return;

    final leavingApp = state == AppLifecycleState.paused || state == AppLifecycleState.inactive;
    if (leavingApp && !_wasBackgrounded) {
      _wasBackgrounded = true;
      ref.read(focusTimerNotifierProvider.notifier).recordBackground();
      final protection = ref.read(settingsProvider).focusProtection;
      if (protection.pausesWhenLeaving) {
        ref.read(focusTimerNotifierProvider.notifier).pauseSession();
      }
    } else if (state == AppLifecycleState.resumed) {
      _wasBackgrounded = false;
      _checkBlockedAppTrigger();
    }
  }

  Future<void> _checkBlockedAppTrigger() async {
    try {
      final policyService = ref.read(protectionPolicyServiceProvider);
      final trigger = await policyService.claimPendingTrigger();
      if (trigger != null && mounted) {
        final activePolicies = await policyService.getActivePolicies();
        final effectiveMode = activePolicies?.effectiveModeForPackage(trigger.packageName) ?? ProtectionMode.guard;

        if (effectiveMode == ProtectionMode.nudge) {
          if (mounted) {
            ref.read(focusTimerNotifierProvider.notifier).resumeSession();
          }
          return;
        }

        ref.read(focusTimerNotifierProvider.notifier).pauseSession();

        final db = ref.read(databaseProvider);
        final protectedApp = await db.protectedAppsDao.getByPlatformAndRef('android', trigger.packageName);
        final appDisplayName = protectedApp?.displayName ?? trigger.packageName;

        if (context.mounted) {
          await FocusShieldOverlay.show(
            context,
            packageName: trigger.packageName,
            appDisplayName: appDisplayName,
            protectionMode: effectiveMode,
            bypassAllowed: trigger.bypassAllowed,
            onKeepFocus: () {
              ref.read(focusTimerNotifierProvider.notifier).resumeSession();
            },
            onCancelSession: () {
              _stopSession();
            },
            onGrantBreak: effectiveMode == ProtectionMode.guard
                ? (minutes) async {
                    await policyService.grantScopedBreak(
                      packageName: trigger.packageName,
                      minutes: minutes,
                    );
                    ref.read(focusTimerNotifierProvider.notifier).resumeSession();
                  }
                : null,
          );
        }
      }
    } catch (_) {}
  }

  Future<void> _startTimer() async {
    final success = await ref.read(focusTimerNotifierProvider.notifier).startSession(
      type: SessionTypeColumn.deepWork,
      durationMinutes: 90,
      taskId: widget.taskId,
      taskTitle: widget.taskTitle,
      selectedSound: _selectedSound,
    );

    if (!success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('A focus session is already active.')),
        );
      }
    }
  }

  Future<void> _togglePause(FocusTimerState active) async {
    HapticFeedback.selectionClick();
    if (active.phase == FocusTimerPhase.paused) {
      await ref.read(focusTimerNotifierProvider.notifier).resumeSession();
    } else {
      await ref.read(focusTimerNotifierProvider.notifier).pauseSession();
    }
  }

  Future<void> _requestStopSession() async {
    final protection = ref.read(settingsProvider).focusProtection;
    if (protection.requiresExitReflection &&
        !await IntentionalExitDialog.confirm(context)) {
      return;
    }
    _stopSession();
  }

  Future<void> _stopSession() async {
    final active = ref.read(focusTimerNotifierProvider);
    if (active == null) return;

    final total = active.totalSeconds;
    final elapsed = active.elapsedSeconds;
    final actualMin = (elapsed / 60).round();
    final pct = elapsed / total;

    final result = await ref.read(focusTimerNotifierProvider.notifier).stopSession();
    if (mounted) {

      if (pct >= 0.6 && actualMin >= 10) {
        for (final key in result.newlyUnlockedAchievements) {
          final ach = allAchievements.firstWhere((a) => a.key == key);
          CelebrationService.showAchievementToast(
            context,
            name: ach.name,
            emoji: ach.emoji,
          );
        }
        context.push(
          '/break',
          extra: {
            'xpEarned': result.xpEarned,
            'qualityGrade': 'D',
            'focusMinutes': actualMin,
          },
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Session stopped. Unfinished sessions receive no credit.'),
            backgroundColor: Colors.redAccent,
          ),
        );
        context.pop();
      }
    }
  }

  String _formatTime(int totalSecs) {
    final mins = totalSecs ~/ 60;
    final secs = totalSecs % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final active = ref.watch(focusTimerNotifierProvider);
    final size = MediaQuery.of(context).size;

    // Listen for sound updates reactively
    ref.listen<FocusTimerState?>(focusTimerNotifierProvider, (previous, next) {
      if (next == null) {
        AmbientSoundPlayer.fadeOut();
      } else {
        if (next.phase == FocusTimerPhase.running) {
          if (ref.read(settingsProvider).soundEnabled) {
            AmbientSoundPlayer.play(next.selectedSound);
          } else {
            AmbientSoundPlayer.stop();
          }
        } else {
          AmbientSoundPlayer.stop();
        }
      }
    });

    if (active != null) {
      return _buildTimerView(context, active, size);
    }

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.xxl),
              Text(
                'Deep Work',
                style: AppTypography.display.copyWith(color: AppColors.textPrimary),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Grow a deep-root tree inside today\'s garden plot. Requires 90 minutes of protected attention.',
                style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xxl),
              if (widget.taskTitle != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: AppColors.emerald.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
                    border: Border.all(
                      color: AppColors.emerald.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    children: [
                      const Text('🎯', style: TextStyle(fontSize: 48)),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        widget.taskTitle!,
                        style: AppTypography.h3.copyWith(color: AppColors.emerald),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
              FocusProtectionSelector(
                value: ref.watch(settingsProvider).focusProtection,
                onChanged: (level) => ref
                    .read(settingsProvider.notifier)
                    .setFocusProtection(level),
              ),
              const SizedBox(height: AppSpacing.xxl),
              ElevatedButton(
                onPressed: _startTimer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.focusBlue,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Begin Deep Work',
                  style: AppTypography.body.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimerView(BuildContext context, FocusTimerState active, Size size) {
    final remaining = active.totalSeconds - active.elapsedSeconds;
    final timeVal = remaining.clamp(0, active.totalSeconds);
    final progress = active.elapsedSeconds / active.totalSeconds;
    final liveXP = (active.elapsedSeconds / 60 * 3.2).round().clamp(0, 300); // 2x deep work multi

    return Scaffold(
      backgroundColor: AppColors.background0,
      body: Stack(
        children: [
          // Dynamic glow animation
          AnimatedBuilder(
            animation: _glowAnimation,
            builder: (context, child) {
              return Container(
                width: double.infinity,
                height: double.infinity,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      AppColors.focusBlue.withValues(alpha: _glowAnimation.value),
                      Colors.transparent,
                    ],
                    radius: 1.2,
                  ),
                ),
              );
            },
          ),
          SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 2),
                AnimatedBuilder(
                  animation: _breatheAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: active.phase == FocusTimerPhase.running ? _breatheAnimation.value : 1.0,
                      child: child,
                    );
                  },
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _formatTime(timeVal),
                          style: AppTypography.display.copyWith(
                            color: AppColors.textPrimary,
                            fontSize: 72,
                            fontWeight: FontWeight.w200,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Deep Work Session',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textTertiary,
                            letterSpacing: 2.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
                Text(
                  '+$liveXP XP (2x Multiplier)',
                  style: AppTypography.monoSmall.copyWith(color: AppColors.emerald),
                ),
                const Spacer(flex: 1),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_sounds.length, (i) {
                    final s = _sounds[i];
                    final isActive = s.key == active.selectedSound;
                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        ref.read(focusTimerNotifierProvider.notifier).selectSound(s.key);
                      },
                      child: Container(
                        width: 48,
                        height: 48,
                        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isActive
                              ? AppColors.emerald.withValues(alpha: 0.15)
                              : AppColors.background2,
                          border: Border.all(
                            color: isActive ? AppColors.emerald : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            s.emoji,
                            style: const TextStyle(fontSize: 20),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: AppSpacing.xxxl),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () => _togglePause(active),
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.textTertiary,
                            width: 1.5,
                          ),
                        ),
                        child: Icon(
                          active.phase == FocusTimerPhase.paused
                              ? Icons.play_arrow_rounded
                              : Icons.pause_rounded,
                          color: AppColors.textSecondary,
                          size: 28,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xxl),
                    GestureDetector(
                      onTap: _requestStopSession,
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.dangerCoral.withValues(alpha: 0.5),
                            width: 1.5,
                          ),
                        ),
                        child: Icon(
                          Icons.stop_rounded,
                          color: AppColors.dangerCoral.withValues(alpha: 0.7),
                          size: 28,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxxl),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
