import 'dart:async';
import 'dart:math';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/constants/xp_constants.dart';
import '../../../data/local/database/app_database.dart';
import '../../../data/local/tables/focus_sessions_table.dart';
import '../../../data/local/tables/xp_ledger_table.dart';
import '../../../features/achievements/models/achievement_checker.dart';
import '../../../features/xp/models/streak_service.dart';

const _uuid = Uuid();

/// Focus Timer Screen — full-screen immersive "flow cave."
/// No navigation visible. Circular timer, ambient sounds, live XP.
class FocusScreen extends ConsumerStatefulWidget {
  const FocusScreen({super.key});

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

  // Session config
  int _selectedSessionType = 0; // 0=Classic, 1=DeskTime, 2=Deep Work, 3=Flowtime
  final _sessionTypes = [
    (label: 'Classic', minutes: 25, breakMin: 5),
    (label: 'DeskTime', minutes: 52, breakMin: 17),
    (label: 'Deep Work', minutes: 90, breakMin: 15),
    (label: 'Flowtime', minutes: 0, breakMin: 0),
  ];

  // Ambient sound
  int _selectedSound = 3; // 0=rain, 1=café, 2=waves, 3=silence
  final _sounds = ['🌧️', '☕', '🌊', '🔇'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_isRunning && !_isPaused) {
      if (state == AppLifecycleState.paused ||
          state == AppLifecycleState.inactive) {
        setState(() => _backgroundCount++);
      }
    }
  }

  void _startTimer() async {
    _sessionId = _uuid.v4();
    final isFlowtime = _selectedSessionType == 3;
    final minutes = _sessionTypes[_selectedSessionType].minutes;

    setState(() {
      _isRunning = true;
      _isPaused = false;
      _totalSeconds = isFlowtime ? 0 : minutes * 60;
      _remainingSeconds = isFlowtime ? 0 : _totalSeconds;
      _pauseCount = 0;
      _backgroundCount = 0;
    });

    final SessionTypeColumn dbType;
    if (_selectedSessionType == 0) {
      dbType = SessionTypeColumn.pomodoro;
    } else if (_selectedSessionType == 2) {
      dbType = SessionTypeColumn.deepWork;
    } else {
      dbType = SessionTypeColumn.custom;
    }

    // Persist session start to DB
    final db = ref.read(databaseProvider);
    await db.focusSessionsDao.insertSession(FocusSessionsCompanion(
      id: Value(_sessionId),
      sessionType: Value(dbType),
      durationMinutes: Value(minutes),
      startedAt: Value(DateTime.now()),
    ));

    _runTimer();
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
      setState(() => _isPaused = false);
      _runTimer();
    } else {
      _timer?.cancel();
      setState(() {
        _isPaused = true;
        _pauseCount++;
      });
    }
    HapticFeedback.selectionClick();
  }

  void _onComplete() async {
    HapticFeedback.heavyImpact();
    final elapsed = _totalSeconds - _remainingSeconds;
    final actualMin = (elapsed / 60).round();

    // Quality: A (0 pauses, 0 bg), B (1-2), C (3+)
    final interrupts = _pauseCount + _backgroundCount;
    final quality = interrupts == 0 ? 'A' : interrupts <= 2 ? 'B' : 'C';

    // XP from XpConstants
    final isDeepWork = _selectedSessionType == 2;
    final baseXP = isDeepWork ? XpConstants.deepWorkComplete : XpConstants.pomodoroComplete;
    final xp = quality == 'A' ? baseXP : (baseXP * 0.8).round();

    // Update session in DB
    final db = ref.read(databaseProvider);
    await db.focusSessionsDao.updateSession(FocusSessionsCompanion(
      id: Value(_sessionId),
      actualMinutes: Value(actualMin),
      pauseCount: Value(_pauseCount),
      appBackgroundCount: Value(_backgroundCount),
      xpEarned: Value(xp),
      qualityScore: Value(quality),
      completedAt: Value(DateTime.now()),
    ));

    // Append XP ledger entry
    await db.xpLedgerDao.appendEntry(XpLedgerEntriesCompanion(
      id: Value(_uuid.v4()),
      actionType: const Value(XpActionTypeColumn.focusComplete),
      pointsDelta: Value(xp),
      sourceEntityId: Value(_sessionId),
      explanation: Value(
        'Completed ${actualMin}m ${_sessionTypes[_selectedSessionType].label} session (Quality: $quality)'),
    ));

    // Record streak activity & check achievements
    await StreakService.recordActivity();
    await AchievementChecker.runCheck(db);

    setState(() => _isRunning = false);

    if (mounted) {
      context.push('/break', extra: {
        'xpEarned': xp,
        'qualityGrade': quality,
        'focusMinutes': actualMin,
      });
    }
  }

  void _stopSession() async {
    _timer?.cancel();
    final isFlowtime = _selectedSessionType == 3;
    final elapsed = isFlowtime ? _remainingSeconds : (_totalSeconds - _remainingSeconds);
    final actualMin = (elapsed / 60).round();

    final db = ref.read(databaseProvider);

    if (isFlowtime) {
      // Flowtime completes on stop, if it has run for at least 1 minute
      if (actualMin >= 1) {
        final interrupts = _pauseCount + _backgroundCount;
        final quality = interrupts == 0 ? 'A' : interrupts <= 2 ? 'B' : 'C';
        final double multiplier = quality == 'A' ? 1.0 : quality == 'B' ? 0.8 : 0.6;
        final xp = (actualMin * 1.6 * multiplier).round().clamp(1, 150);

        await db.focusSessionsDao.updateSession(FocusSessionsCompanion(
          id: Value(_sessionId),
          actualMinutes: Value(actualMin),
          pauseCount: Value(_pauseCount),
          appBackgroundCount: Value(_backgroundCount),
          xpEarned: Value(xp),
          qualityScore: Value(quality),
          completedAt: Value(DateTime.now()),
        ));

        await db.xpLedgerDao.appendEntry(XpLedgerEntriesCompanion(
          id: Value(_uuid.v4()),
          actionType: const Value(XpActionTypeColumn.focusComplete),
          pointsDelta: Value(xp),
          sourceEntityId: Value(_sessionId),
          explanation: Value(
              'Completed ${actualMin}m Flowtime session (Quality: $quality)'),
        ));

        await StreakService.recordActivity();
        await AchievementChecker.runCheck(db);

        setState(() {
          _isRunning = false;
          _isPaused = false;
        });

        if (mounted) {
          context.push('/break', extra: {
            'xpEarned': xp,
            'qualityGrade': quality,
            'focusMinutes': actualMin,
          });
        }
      } else {
        // Run too short, discard or record as F
        if (_sessionId.isNotEmpty) {
          await db.focusSessionsDao.updateSession(FocusSessionsCompanion(
            id: Value(_sessionId),
            actualMinutes: Value(actualMin),
            pauseCount: Value(_pauseCount),
            appBackgroundCount: Value(_backgroundCount),
            qualityScore: const Value('F'),
            completedAt: Value(DateTime.now()),
          ));
        }
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
      final pct = elapsed / _totalSeconds;
      if (pct >= 0.6 && actualMin >= 10) {
        // Partial credit: 50% XP if > 60% complete
        final isDeepWork = _selectedSessionType == 2;
        final baseXP = isDeepWork
            ? XpConstants.deepWorkComplete
            : XpConstants.pomodoroComplete;
        final partialXP = (baseXP * pct * 0.5).round();

        await db.focusSessionsDao.updateSession(FocusSessionsCompanion(
          id: Value(_sessionId),
          actualMinutes: Value(actualMin),
          pauseCount: Value(_pauseCount),
          appBackgroundCount: Value(_backgroundCount),
          xpEarned: Value(partialXP),
          qualityScore: const Value('D'),
          completedAt: Value(DateTime.now()),
        ));

        await db.xpLedgerDao.appendEntry(XpLedgerEntriesCompanion(
          id: Value(_uuid.v4()),
          actionType: const Value(XpActionTypeColumn.focusComplete),
          pointsDelta: Value(partialXP),
          sourceEntityId: Value(_sessionId),
          explanation: Value(
            'Partial ${actualMin}m session (${(pct * 100).round()}% complete)'),
        ));

        // Record streak activity & check achievements
        await StreakService.recordActivity();
        await AchievementChecker.runCheck(db);

        setState(() {
          _isRunning = false;
          _isPaused = false;
        });

        if (mounted) {
          context.push('/break', extra: {
            'xpEarned': partialXP,
            'qualityGrade': 'D',
            'focusMinutes': actualMin,
          });
        }
      } else if (_sessionId.isNotEmpty) {
        // No credit for < 60% — still record the attempt
        await db.focusSessionsDao.updateSession(FocusSessionsCompanion(
          id: Value(_sessionId),
          actualMinutes: Value(actualMin),
          pauseCount: Value(_pauseCount),
          appBackgroundCount: Value(_backgroundCount),
          qualityScore: const Value('F'),
          completedAt: Value(DateTime.now()),
        ));
        setState(() {
          _isRunning = false;
          _isPaused = false;
        });
      }
    }
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
    final elapsed = _selectedSessionType == 3 ? _remainingSeconds : (_totalSeconds - _remainingSeconds);
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Focus',
                style: AppTypography.h1.copyWith(color: AppColors.textPrimary),
              ),
              const SizedBox(height: AppSpacing.xxxl),
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
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusCard),
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
      backgroundColor: const Color(0xFF060B14), // Darker for focus
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
              style: AppTypography.monoSmall.copyWith(
                color: AppColors.emerald,
              ),
            ),
            const Spacer(flex: 1),
            // ─── Ambient Sounds ───────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (i) {
                final isActive = i == _selectedSound;
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedSound = i);
                    HapticFeedback.selectionClick();
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
                        color: isActive
                            ? AppColors.emerald
                            : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        _sounds[i],
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
                  onTap: _stopSession,
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
