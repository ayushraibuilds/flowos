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
import '../../widgets/flow_atmosphere_panel.dart';

class FocusScreen extends ConsumerStatefulWidget {
  final int? durationMinutes;
  final String? sessionLabel;
  final bool autoStart;

  const FocusScreen({
    super.key,
    this.durationMinutes,
    this.sessionLabel,
    this.autoStart = false,
  });

  @override
  ConsumerState<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends ConsumerState<FocusScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _breatheController;
  late Animation<double> _breatheAnimation;

  // Config state
  int _selectedSessionType =
      0; // 0=Classic, 1=DeskTime, 2=Deep Work, 3=Flowtime
  final _sessionTypes = [
    (label: 'Classic', minutes: 25, breakMin: 5),
    (label: 'DeskTime', minutes: 52, breakMin: 17),
    (label: 'Deep Work', minutes: 90, breakMin: 15),
    (label: 'Flowtime', minutes: 0, breakMin: 0),
  ];

  String _selectedSound = 'none';
  final _sounds = [
    (key: 'none', icon: Icons.volume_off_rounded, label: 'Silent'),
    (key: 'binaural', icon: Icons.psychology_rounded, label: 'Binaural'),
    (key: 'rain', icon: Icons.water_drop_rounded, label: 'Rain'),
    (key: 'cafe', icon: Icons.coffee_rounded, label: 'Café'),
    (key: 'piano', icon: Icons.music_note_rounded, label: 'Piano'),
  ];

  bool _wasBackgrounded = false;
  bool _showReturnCue = false;
  bool _isFinalizing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _breatheController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    _breatheAnimation = Tween<double>(begin: 0.98, end: 1.02).animate(
      CurvedAnimation(parent: _breatheController, curve: Curves.easeInOut),
    );

    if (widget.durationMinutes != null) {
      if (widget.durationMinutes == 25)
        _selectedSessionType = 0;
      else if (widget.durationMinutes == 52)
        _selectedSessionType = 1;
      else if (widget.durationMinutes == 90)
        _selectedSessionType = 2;
      else
        _selectedSessionType = 3;
    }

    if (widget.autoStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startTimer();
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _breatheController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final active = ref.read(focusTimerNotifierProvider);
    if (active == null || active.phase != FocusTimerPhase.running) return;

    final leavingApp =
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive;
    if (leavingApp && !_wasBackgrounded) {
      _wasBackgrounded = true;
      ref.read(focusTimerNotifierProvider.notifier).recordBackground();
      final protection = ref.read(settingsProvider).focusProtection;
      if (protection.pausesWhenLeaving) {
        ref.read(focusTimerNotifierProvider.notifier).pauseSession();
      } else {
        setState(() => _showReturnCue = true);
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
        final effectiveMode =
            activePolicies?.effectiveModeForPackage(trigger.packageName) ??
            ProtectionMode.guard;

        if (effectiveMode == ProtectionMode.nudge) {
          if (mounted) {
            ref.read(focusTimerNotifierProvider.notifier).resumeSession();
          }
          return;
        }

        ref.read(focusTimerNotifierProvider.notifier).pauseSession();

        final db = ref.read(databaseProvider);
        final protectedApp = await db.protectedAppsDao.getByPlatformAndRef(
          'android',
          trigger.packageName,
        );
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
              setState(() => _showReturnCue = false);
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
                    setState(() {
                      _showReturnCue = false;
                    });
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '$minutes-minute break granted. Timer paused.',
                          ),
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    }
                  }
                : null,
          );
        }
      }
    } catch (_) {}
  }

  Future<void> _startTimer() async {
    final isFlowtime = _selectedSessionType == 3;
    final int minutes =
        (widget.durationMinutes ?? _sessionTypes[_selectedSessionType].minutes);

    final SessionTypeColumn dbType = _selectedSessionType == 0
        ? SessionTypeColumn.pomodoro
        : (_selectedSessionType == 2
              ? SessionTypeColumn.deepWork
              : SessionTypeColumn.custom);

    final success = await ref
        .read(focusTimerNotifierProvider.notifier)
        .startSession(
          type: dbType,
          durationMinutes: minutes,
          taskId: widget.sessionLabel != null
              ? null
              : null, // keep taskId nullable unless mapped
          taskTitle: widget.sessionLabel,
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
    if (_isFinalizing) return;
    setState(() => _isFinalizing = true);

    try {
      final active = ref.read(focusTimerNotifierProvider);
      if (active == null) return;

      final total = active.totalSeconds;
      final elapsed = active.elapsedSeconds;
      final actualMin = (elapsed / 60).round();
      final pct = elapsed / total;

      final result = await ref
          .read(focusTimerNotifierProvider.notifier)
          .stopSession();
      await ref.read(focusTimerNotifierProvider.notifier).clearActiveSession();

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
          context.pushReplacement(
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
              content: Text(
                'Session stopped. Unfinished sessions receive no credit.',
              ),
              backgroundColor: Colors.redAccent,
            ),
          );
          context.pop();
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isFinalizing = false);
      }
    }
  }

  Future<void> _onComplete() async {
    if (_isFinalizing) return;
    setState(() => _isFinalizing = true);

    try {
      HapticFeedback.heavyImpact();
      final active = ref.read(focusTimerNotifierProvider);
      if (active == null) return;

      final elapsed = active.elapsedSeconds;
      final actualMin = (elapsed / 60).round();

      final result = await ref
          .read(focusTimerNotifierProvider.notifier)
          .completeSession();
      await ref.read(focusTimerNotifierProvider.notifier).clearActiveSession();

      final quality = (active.pauseCount + active.backgroundCount) == 0
          ? 'A'
          : (active.pauseCount + active.backgroundCount) <= 2
          ? 'B'
          : 'C';

      if (mounted) {
        if (result.gardenGrowth != null) {
          await GardenGrowthDialog.celebrate(context, result.gardenGrowth!);
        }
        if (!mounted) return;
        for (final key in result.newlyUnlockedAchievements) {
          final ach = allAchievements.firstWhere((a) => a.key == key);
          CelebrationService.showAchievementToast(
            context,
            name: ach.name,
            emoji: ach.emoji,
          );
        }
        context.pushReplacement(
          '/break',
          extra: {
            'xpEarned': result.xpEarned,
            'qualityGrade': quality,
            'focusMinutes': actualMin,
          },
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isFinalizing = false);
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

    // Listen for sound updates and session completion reactively
    ref.listen<FocusTimerState?>(focusTimerNotifierProvider, (previous, next) {
      if (next == null) {
        AmbientSoundPlayer.fadeOut();
      } else {
        if (next.phase == FocusTimerPhase.completed) {
          _onComplete();
        } else if (next.phase == FocusTimerPhase.stopped) {
          _stopSession();
        } else if (next.phase == FocusTimerPhase.running) {
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
    final selectedSession = _sessionTypes[_selectedSessionType];

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            0,
            AppSpacing.xl,
            AppSpacing.xxxl + 96,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.lg),
              FlowAtmospherePanel(
                accent: AppColors.focusBlue,
                height: 172,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.focusBlue.withValues(alpha: .18),
                          border: Border.all(
                            color: AppColors.focusBlue.withValues(alpha: .5),
                          ),
                        ),
                        child: const Icon(
                          Icons.timer_outlined,
                          color: AppColors.focusBlue,
                          size: 19,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Focus Cave',
                        style: AppTypography.h1.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Choose a rhythm, protect your attention, and leave something living behind.',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'Choose your rhythm',
                style: AppTypography.h3.copyWith(color: AppColors.textPrimary),
              ),
              const SizedBox(height: AppSpacing.sm),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: AppSpacing.md,
                  mainAxisSpacing: AppSpacing.md,
                  childAspectRatio: 2.2,
                ),
                itemCount: 4,
                itemBuilder: (context, i) {
                  final isActive = i == _selectedSessionType;
                  final session = _sessionTypes[i];
                  return Semantics(
                    button: true,
                    selected: isActive,
                    label:
                        '${session.label}, ${session.minutes > 0 ? '${session.minutes} minutes' : 'flowtime'}',
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => setState(() => _selectedSessionType = i),
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusCard,
                        ),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOutCubic,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.sm,
                          ),
                          decoration: BoxDecoration(
                            color: isActive
                                ? AppColors.focusBlue.withValues(alpha: 0.12)
                                : AppColors.background2,
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusCard,
                            ),
                            border: Border.all(
                              color: isActive
                                  ? AppColors.focusBlue
                                  : Colors.white.withValues(alpha: .05),
                              width: isActive ? 1.5 : .5,
                            ),
                            boxShadow: isActive
                                ? [
                                    BoxShadow(
                                      color: AppColors.focusBlueGlow,
                                      blurRadius: 16,
                                      offset: const Offset(0, 6),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                session.label,
                                style: AppTypography.bodySmall.copyWith(
                                  color: isActive
                                      ? AppColors.focusBlue
                                      : AppColors.textSecondary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                session.minutes > 0
                                    ? '${session.minutes} min'
                                    : 'Flowtime',
                                style: AppTypography.monoSmall.copyWith(
                                  color: isActive
                                      ? AppColors.focusBlue
                                      : AppColors.textTertiary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              FocusProtectionSelector(
                value: ref.watch(settingsProvider).focusProtection,
                onChanged: (level) => ref
                    .read(settingsProvider.notifier)
                    .setFocusProtection(level),
              ),
              const SizedBox(height: AppSpacing.md),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                decoration: BoxDecoration(
                  color: AppColors.emerald.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
                  border: Border.all(
                    color: AppColors.emerald.withValues(alpha: 0.18),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.spa_outlined,
                      color: AppColors.emerald,
                      size: 26,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'This session begins as a seed in today’s garden.',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              _FocusStartControl(
                label: selectedSession.label,
                minutes: selectedSession.minutes,
                onTap: _startTimer,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimerView(
    BuildContext context,
    FocusTimerState active,
    Size size,
  ) {
    final ringSize = size.width * 0.65;
    final isFlowtime = active.sessionType == SessionTypeColumn.custom;
    final timeVal = isFlowtime
        ? active.elapsedSeconds
        : (active.totalSeconds - active.elapsedSeconds);
    final progress = isFlowtime
        ? 0.0
        : (active.totalSeconds - active.elapsedSeconds) / active.totalSeconds;
    final liveXP = (active.elapsedSeconds / 60 * 1.6).round().clamp(0, 150);

    return Scaffold(
      backgroundColor: AppColors.background0,
      body: Stack(
        children: [
          // Ambient breathing radial background glow
          AnimatedBuilder(
            animation: _breatheAnimation,
            builder: (context, child) {
              return Container(
                width: double.infinity,
                height: double.infinity,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      AppColors.emerald.withValues(
                        alpha: active.phase == FocusTimerPhase.running
                            ? 0.08 * _breatheAnimation.value
                            : 0.04,
                      ),
                      Colors.transparent,
                    ],
                    radius: 1.4,
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
                      scale: active.phase == FocusTimerPhase.running
                          ? _breatheAnimation.value
                          : 1.0,
                      child: child,
                    );
                  },
                  child: SizedBox(
                    width: ringSize,
                    height: ringSize,
                    child: CustomPaint(
                      painter: _TimerRingPainter(progress: progress),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _formatTime(timeVal),
                              style: AppTypography.monoLarge.copyWith(
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              active.sessionType == SessionTypeColumn.deepWork
                                  ? '🌳 Growing Deep Tree'
                                  : active.sessionType ==
                                        SessionTypeColumn.pomodoro
                                  ? '🌱 Growing Focus Flower'
                                  : '🌿 Flowing',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textTertiary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
                Text(
                  '+$liveXP XP so far',
                  style: AppTypography.monoSmall.copyWith(
                    color: AppColors.emerald,
                  ),
                ),
                if (_showReturnCue) ...[
                  const SizedBox(height: AppSpacing.md),
                  GestureDetector(
                    onTap: () => setState(() => _showReturnCue = false),
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xl,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.focusBlue.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusPill,
                        ),
                      ),
                      child: Text(
                        'Welcome back. Your focus is still here. Tap to continue.',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
                const Spacer(flex: 1),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_sounds.length, (i) {
                    final s = _sounds[i];
                    final isActive = s.key == active.selectedSound;
                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        ref
                            .read(focusTimerNotifierProvider.notifier)
                            .selectSound(s.key);
                      },
                      child: Container(
                        width: 48,
                        height: 48,
                        margin: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                        ),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isActive
                              ? AppColors.emerald.withValues(alpha: 0.15)
                              : AppColors.background2,
                          border: Border.all(
                            color: isActive
                                ? AppColors.emerald
                                : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            s.icon,
                            size: 20,
                            color: isActive
                                ? AppColors.emerald
                                : AppColors.textSecondary,
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
                      onTap: isFlowtime ? _onComplete : _requestStopSession,
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
                          isFlowtime ? Icons.check_rounded : Icons.stop_rounded,
                          color: isFlowtime
                              ? AppColors.emerald.withValues(alpha: 0.8)
                              : AppColors.dangerCoral.withValues(alpha: 0.7),
                          size: 28,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxxl),
                if (active.pauseCount > 0)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      active.pauseCount.clamp(0, 5),
                      (i) => Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FocusStartControl extends StatelessWidget {
  final String label;
  final int minutes;
  final VoidCallback onTap;

  const _FocusStartControl({
    required this.label,
    required this.minutes,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final duration = minutes > 0 ? '$minutes min' : 'Open-ended';
    return Semantics(
      button: true,
      label: 'Start $label focus session, $duration',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusButton),
          child: Ink(
            height: 72,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4B9CFF), Color(0xFF2D77DE)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppSpacing.radiusButton),
              boxShadow: [
                BoxShadow(
                  color: AppColors.focusBlueGlow,
                  blurRadius: 22,
                  offset: const Offset(0, 9),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: .16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: .28),
                      ),
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Start $label focus',
                          style: AppTypography.bodySmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          '$duration · a seed waits in today’s garden',
                          style: AppTypography.caption.copyWith(
                            color: Colors.white.withValues(alpha: .78),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_rounded, color: Colors.white),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TimerRingPainter extends CustomPainter {
  final double progress;

  _TimerRingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    const strokeWidth = 8.0;

    final bgPaint = Paint()
      ..color = AppColors.background2
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final activePaint = Paint()
      ..color = AppColors.focusBlue
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -3.14159 / 2,
      2 * 3.14159 * progress,
      false,
      activePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _TimerRingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
