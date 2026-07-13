import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../features/focus/services/focus_session_service.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/local/tables/focus_sessions_table.dart';
import '../../../features/celebration/services/celebration_service.dart';
import '../../../features/achievements/models/achievement_checker.dart';
import '../../../features/flow_garden/widgets/garden_growth_dialog.dart';
import '../../../features/focus/models/focus_protection.dart';
import '../../../features/focus/widgets/focus_protection_selector.dart';
import '../../../features/focus/widgets/intentional_exit_dialog.dart';
import '../../../features/settings/providers/settings_providers.dart';
import '../../../features/focus/services/ambient_sound_player.dart';

/// Focus Timer Screen — full-screen immersive "flow cave."
/// No navigation visible. Circular timer, ambient sounds, live XP.
class FocusScreen extends ConsumerStatefulWidget {
  final int? durationMinutes;
  final String? sessionLabel;
  final bool firstSeed;
  final bool autoStart;

  const FocusScreen({
    super.key,
    this.durationMinutes,
    this.sessionLabel,
    this.firstSeed = false,
    this.autoStart = false,
  });

  @override
  ConsumerState<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends ConsumerState<FocusScreen>
    with WidgetsBindingObserver {
  // Timer state
  bool _isRunning = false;
  bool _isPaused = false;
  int _totalSeconds = 25 * 60; // 25 minutes default
  int _remainingSeconds = 25 * 60;
  int _pauseCount = 0;
  int _backgroundCount = 0;
  Timer? _timer;
  String _sessionId = '';
  FocusProtectionLevel _sessionProtection = FocusProtectionLevel.softReturn;
  bool _wasBackgrounded = false;
  bool _showReturnCue = false;

  // Session config
  int _selectedSessionType =
      0; // 0=Classic, 1=DeskTime, 2=Deep Work, 3=Flowtime
  final _sessionTypes = [
    (label: 'Classic', minutes: 25, breakMin: 5),
    (label: 'DeskTime', minutes: 52, breakMin: 17),
    (label: 'Deep Work', minutes: 90, breakMin: 15),
    (label: 'Flowtime', minutes: 0, breakMin: 0),
  ];

  // Ambient sound
  String _selectedSound = 'none';
  final _sounds = [
    (key: 'none', emoji: '🔇', label: 'Silent'),
    (key: 'binaural', emoji: '🧠', label: 'Binaural'),
    (key: 'rain', emoji: '🌧️', label: 'Rain'),
    (key: 'cafe', emoji: '☕', label: 'Café'),
    (key: 'piano', emoji: '🎹', label: 'Piano'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.durationMinutes != null) {
      _totalSeconds = widget.durationMinutes! * 60;
      _remainingSeconds = _totalSeconds;
    }
    if (widget.autoStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startTimer();
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    AmbientSoundPlayer.stop();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_isRunning) return;
    final leavingApp =
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive;
    if (leavingApp && !_wasBackgrounded) {
      _wasBackgrounded = true;
      _backgroundCount++;
      if (_sessionProtection.pausesWhenLeaving && !_isPaused) {
        _timer?.cancel();
        setState(() => _isPaused = true);
      } else if (mounted) {
        setState(() => _showReturnCue = true);
      }
    } else if (state == AppLifecycleState.resumed) {
      _wasBackgrounded = false;
    }
  }

  void _startTimer() async {
    final isFlowtime = _selectedSessionType == 3;
    final int minutes = widget.firstSeed
        ? 10
        : (widget.durationMinutes ?? _sessionTypes[_selectedSessionType].minutes);
    final protection = ref.read(settingsProvider).focusProtection;

    setState(() {
      _isRunning = true;
      _isPaused = false;
      _totalSeconds = isFlowtime ? 0 : minutes * 60;
      _remainingSeconds = isFlowtime ? 0 : _totalSeconds;
      _pauseCount = 0;
      _backgroundCount = 0;
      _sessionProtection = protection;
      _wasBackgrounded = false;
      _showReturnCue = false;
    });

    final SessionTypeColumn dbType = widget.firstSeed
        ? SessionTypeColumn.custom
        : (_selectedSessionType == 0
            ? SessionTypeColumn.pomodoro
            : (_selectedSessionType == 2
                ? SessionTypeColumn.deepWork
                : SessionTypeColumn.custom));

    final service = ref.read(focusSessionServiceProvider);
    _sessionId = await service.startSession(
      type: dbType,
      durationMinutes: minutes,
    );

    _runTimer();
    AmbientSoundPlayer.play(_selectedSound);
  }

  void _runTimer() {
    final isFlowtime = _selectedSessionType == 3;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (isFlowtime) {
        setState(() => _remainingSeconds++);
      } else {
        if (_remainingSeconds <= 0) {
          timer.cancel();
          _onComplete();
          return;
        }
        setState(() => _remainingSeconds--);
      }
    });
  }

  void _togglePause() {
    if (_isPaused) {
      setState(() {
        _isPaused = false;
        _showReturnCue = false;
      });
      _runTimer();
      AmbientSoundPlayer.play(_selectedSound);
    } else {
      _timer?.cancel();
      setState(() {
        _isPaused = true;
        _pauseCount++;
      });
      AmbientSoundPlayer.stop();
    }
    HapticFeedback.selectionClick();
  }

  void _onComplete() async {
    HapticFeedback.heavyImpact();
    final elapsed = _totalSeconds - _remainingSeconds;
    final actualMin = (elapsed / 60).round();

    final SessionTypeColumn dbType;
    if (_selectedSessionType == 0) {
      dbType = SessionTypeColumn.pomodoro;
    } else if (_selectedSessionType == 2) {
      dbType = SessionTypeColumn.deepWork;
    } else {
      dbType = SessionTypeColumn.custom;
    }

    final service = ref.read(focusSessionServiceProvider);
    final result = await service.completeSession(
      sessionId: _sessionId,
      elapsedSeconds: elapsed,
      pauseCount: _pauseCount,
      backgroundCount: _backgroundCount,
      type: dbType,
    );

    final quality = (_pauseCount + _backgroundCount) == 0
        ? 'A'
        : (_pauseCount + _backgroundCount) <= 2
        ? 'B'
        : 'C';

    setState(() => _isRunning = false);
    AmbientSoundPlayer.fadeOut();

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
      context.push(
        '/break',
        extra: {
          'xpEarned': result.xpEarned,
          'qualityGrade': quality,
          'focusMinutes': actualMin,
        },
      );
    }
  }

  void _stopSession() async {
    _timer?.cancel();
    AmbientSoundPlayer.stop();
    final isFlowtime = _selectedSessionType == 3;
    final elapsed = isFlowtime
        ? _remainingSeconds
        : (_totalSeconds - _remainingSeconds);
    final actualMin = (elapsed / 60).round();

    final SessionTypeColumn dbType;
    if (_selectedSessionType == 0) {
      dbType = SessionTypeColumn.pomodoro;
    } else if (_selectedSessionType == 2) {
      dbType = SessionTypeColumn.deepWork;
    } else {
      dbType = SessionTypeColumn.custom;
    }

    final service = ref.read(focusSessionServiceProvider);

    if (isFlowtime) {
      // Flowtime completes on stop, if it has run for at least 1 minute
      if (actualMin >= 1) {
        final result = await service.completeSession(
          sessionId: _sessionId,
          elapsedSeconds: elapsed,
          pauseCount: _pauseCount,
          backgroundCount: _backgroundCount,
          type: dbType,
          isFlowtime: true,
        );
        final quality = (_pauseCount + _backgroundCount) == 0
            ? 'A'
            : (_pauseCount + _backgroundCount) <= 2
            ? 'B'
            : 'C';

        setState(() {
          _isRunning = false;
          _isPaused = false;
        });

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
          context.push(
            '/break',
            extra: {
              'xpEarned': result.xpEarned,
              'qualityGrade': quality,
              'focusMinutes': actualMin,
            },
          );
        }
      } else {
        // Run too short, discard or record as F
        await service.stopSession(
          sessionId: _sessionId,
          elapsedSeconds: elapsed,
          totalSeconds: 0,
          pauseCount: _pauseCount,
          backgroundCount: _backgroundCount,
          type: dbType,
        );
        setState(() {
          _isRunning = false;
          _isPaused = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Session too short (< 1 min) for XP.'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    } else {
      // Countdown session stop logic
      final result = await service.stopSession(
        sessionId: _sessionId,
        elapsedSeconds: elapsed,
        totalSeconds: _totalSeconds,
        pauseCount: _pauseCount,
        backgroundCount: _backgroundCount,
        type: dbType,
      );

      final pct = elapsed / _totalSeconds;
      setState(() {
        _isRunning = false;
        _isPaused = false;
      });

      if (pct >= 0.6 && actualMin >= 10) {
        if (mounted) {
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
        }
      }
    }
  }

  Future<void> _requestStopSession() async {
    if (_sessionProtection.requiresExitReflection &&
        !await IntentionalExitDialog.confirm(context)) {
      return;
    }
    _stopSession();
  }

  String get _timeString {
    final mins = _remainingSeconds ~/ 60;
    final secs = _remainingSeconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  double get _progress {
    if (_selectedSessionType == 3) {
      return (_remainingSeconds % 60) / 60.0;
    }
    if (_totalSeconds == 0) return 0;
    return 1.0 - (_remainingSeconds / _totalSeconds);
  }

  int get _liveXP {
    final elapsed = _selectedSessionType == 3
        ? _remainingSeconds
        : (_totalSeconds - _remainingSeconds);
    return (elapsed / 60 * 1.6).round(); // ~40 XP per 25 min
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    if (!_isRunning) {
      return _buildSetupView(context, size);
    }
    return _buildTimerView(context, size);
  }

  /// Pre-session: pick session type and start
  Widget _buildSetupView(BuildContext context, Size size) {
    return Scaffold(
      backgroundColor: AppColors.background0,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Focus',
                style: AppTypography.h1.copyWith(color: AppColors.textPrimary),
              ),
              const SizedBox(height: AppSpacing.xxxl),
              if (widget.firstSeed) ...[
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
                      const Text('🌱', style: TextStyle(fontSize: 48)),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Plant your first seed',
                        style: AppTypography.h3.copyWith(color: AppColors.emerald),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'This is a special 10-minute deep work session to start your garden.',
                        style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
              ] else ...[
                // Session type selector (2x2 grid to support 4 presets without squeezing screen width)
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
                    return GestureDetector(
                      onTap: () => setState(() => _selectedSessionType = i),
                      child: Container(
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
                                : Colors.transparent,
                            width: 1.5,
                          ),
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
              ],
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
                    const Text('🌱', style: TextStyle(fontSize: 24)),
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
              const SizedBox(height: AppSpacing.xxl),
              // Start button
              GestureDetector(
                onTap: _startTimer,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.focusBlue,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.focusBlueGlow,
                        blurRadius: 30,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.play_arrow_rounded,
                      size: 48,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Tap to begin',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Active session: circular timer, no distractions
  Widget _buildTimerView(BuildContext context, Size size) {
    final ringSize = size.width * 0.65;

    return Scaffold(
      backgroundColor: AppColors.background0, // Dynamic for focus theme
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 2),
            // ─── Timer Ring ────────────────────────────────────
            SizedBox(
              width: ringSize,
              height: ringSize,
              child: CustomPaint(
                painter: _TimerRingPainter(progress: _progress),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _timeString,
                        style: AppTypography.monoLarge.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        _sessionTypes[_selectedSessionType].label,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            // ─── Live XP ──────────────────────────────────────
            Text(
              '+$_liveXP XP so far',
              style: AppTypography.monoSmall.copyWith(color: AppColors.emerald),
            ),
            if (_showReturnCue) ...[
              const SizedBox(height: AppSpacing.md),
              GestureDetector(
                onTap: () => setState(() => _showReturnCue = false),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.focusBlue.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
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
            // ─── Ambient Sounds ───────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_sounds.length, (i) {
                final s = _sounds[i];
                final isActive = s.key == _selectedSound;
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _selectedSound = s.key);
                    if (_isRunning && !_isPaused) {
                      AmbientSoundPlayer.play(s.key);
                    }
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
            // ─── Controls ─────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Pause
                GestureDetector(
                  onTap: _togglePause,
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
                      _isPaused
                          ? Icons.play_arrow_rounded
                          : Icons.pause_rounded,
                      color: AppColors.textSecondary,
                      size: 28,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.xxl),
                // Stop
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
            // ─── Focus quality dots ────────────────────────────
            if (_pauseCount > 0)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _pauseCount.clamp(0, 5),
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
    );
  }
}

/// Custom painter for the circular timer ring.
class _TimerRingPainter extends CustomPainter {
  final double progress;

  _TimerRingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    const strokeWidth = 8.0;

    // Background ring
    final bgPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = AppColors.background2;
    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc
    if (progress > 0) {
      final gradient = SweepGradient(
        startAngle: -pi / 2,
        endAngle: 3 * pi / 2,
        colors: [AppColors.focusBlue, AppColors.emerald],
      );

      final progressPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..shader = gradient.createShader(
          Rect.fromCircle(center: center, radius: radius),
        );

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -pi / 2,
        2 * pi * progress,
        false,
        progressPaint,
      );

      // Glow effect
      final glowPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth + 12
        ..strokeCap = StrokeCap.round
        ..color = AppColors.focusBlue.withValues(alpha: 0.1)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -pi / 2,
        2 * pi * progress,
        false,
        glowPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TimerRingPainter old) =>
      old.progress != progress;
}
