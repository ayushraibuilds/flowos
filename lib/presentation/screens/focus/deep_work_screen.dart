import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import 'package:drift/drift.dart' show Value;
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/xp_constants.dart';
import '../../../data/local/database/app_database.dart';
import '../../../data/local/tables/focus_sessions_table.dart';
import '../../../data/local/tables/xp_ledger_table.dart';
import '../../../features/focus/services/ambient_sound_player.dart';

/// Deep Work Screen — 90-minute immersive focus with flow state visuals.
/// Features:
/// - 90-min timer with ambient glow animation
/// - Ambient sound selector (binaural, rain, café, forest)
/// - Pause/resume with count tracking
/// - 2× XP multiplier
/// - Quality grade on completion
class DeepWorkScreen extends ConsumerStatefulWidget {
  final String? taskTitle;
  final String? taskId;

  const DeepWorkScreen({super.key, this.taskTitle, this.taskId});

  @override
  ConsumerState<DeepWorkScreen> createState() => _DeepWorkScreenState();
}

class _DeepWorkScreenState extends ConsumerState<DeepWorkScreen>
    with TickerProviderStateMixin {
  // Timer state
  static const _totalSeconds = 90 * 60; // 90 minutes
  int _remainingSeconds = _totalSeconds;
  bool _isRunning = false;
  bool _isPaused = false;
  int _pauseCount = 0;
  final int _backgroundCount = 0;
  Timer? _timer;
  String _sessionId = '';
  final _uuid = const Uuid();

  // Ambient sound
  String _selectedSound = 'none';
  final _sounds = [
    (key: 'none', emoji: '🔇', label: 'Silent'),
    (key: 'binaural', emoji: '🧠', label: 'Binaural'),
    (key: 'rain', emoji: '🌧️', label: 'Rain'),
    (key: 'cafe', emoji: '☕', label: 'Café'),
    (key: 'forest', emoji: '🌲', label: 'Forest'),
  ];

  // Flow state animation
  late AnimationController _glowController;
  late AnimationController _breatheController;
  late Animation<double> _glowAnimation;
  late Animation<double> _breatheAnimation;

  @override
  void initState() {
    super.initState();

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
    _timer?.cancel();
    _glowController.dispose();
    _breatheController.dispose();
    AmbientSoundPlayer.stop();
    super.dispose();
  }

  void _startTimer() async {
    HapticFeedback.heavyImpact();
    _sessionId = _uuid.v4();

    final db = ref.read(databaseProvider);
    await db.focusSessionsDao.insertSession(FocusSessionsCompanion(
      id: Value(_sessionId),
      taskId: Value(widget.taskId),
      sessionType: const Value(SessionTypeColumn.deepWork),
      durationMinutes: const Value(90),
      startedAt: Value(DateTime.now()),
    ));

    setState(() {
      _isRunning = true;
      _isPaused = false;
    });

    if (_selectedSound != 'none') {
      await AmbientSoundPlayer.play(_selectedSound);
    }

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
      } else {
        _completeSession();
      }
    });
  }

  void _pauseTimer() {
    HapticFeedback.mediumImpact();
    _timer?.cancel();
    AmbientSoundPlayer.stop();
    setState(() {
      _isPaused = true;
      _pauseCount++;
    });
  }

  void _resumeTimer() {
    HapticFeedback.selectionClick();
    setState(() => _isPaused = false);
    if (_selectedSound != 'none') {
      AmbientSoundPlayer.play(_selectedSound);
    }
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
      } else {
        _completeSession();
      }
    });
  }

  void _completeSession() async {
    _timer?.cancel();
    HapticFeedback.heavyImpact();
    await AmbientSoundPlayer.fadeOut();

    final elapsed = _totalSeconds - _remainingSeconds;
    final actualMinutes = (elapsed / 60).round();
    final interrupts = _pauseCount + _backgroundCount;
    final quality = interrupts == 0 ? 'A' : interrupts <= 2 ? 'B' : 'C';

    final baseXP = XpConstants.deepWorkComplete;
    final xp = quality == 'A' ? baseXP : (baseXP * 0.8).round();

    final db = ref.read(databaseProvider);
    await db.focusSessionsDao.updateSession(FocusSessionsCompanion(
      id: Value(_sessionId),
      actualMinutes: Value(actualMinutes),
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
        'Completed ${actualMinutes}m Deep Work session: "${widget.taskTitle ?? 'Focus'}" (Quality: $quality)'),
    ));

    if (mounted) {
      context.go('/break', extra: {
        'xpEarned': xp,
        'qualityGrade': quality,
        'focusMinutes': actualMinutes,
      });
    }
  }

  void _abandonSession() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.background2,
        title: Text('End session?',
            style: AppTypography.h3.copyWith(color: AppColors.textPrimary)),
        content: Text(
          "You'll earn partial XP for the time completed.",
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Continue'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _completeSession();
            },
            child: Text('End',
                style: TextStyle(color: AppColors.dangerCoral)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final progress = 1.0 - (_remainingSeconds / _totalSeconds);
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    final timeStr =
        '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    return Scaffold(
      backgroundColor: AppColors.background0,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: _isRunning ? _abandonSession : () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.focusBlue.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                    ),
                    child: Row(
                      children: [
                        Text('🧠 ', style: const TextStyle(fontSize: 14)),
                        Text(
                          'DEEP WORK • 2× XP',
                          style: AppTypography.monoSmall.copyWith(
                            color: AppColors.focusBlue,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 48), // Balance
                ],
              ),
            ),

            const Spacer(),

            // ─── Flow State Timer Ring ────────────────────────
            AnimatedBuilder(
              animation: Listenable.merge([_glowController, _breatheController]),
              builder: (context, child) {
                return Transform.scale(
                  scale: _isRunning ? _breatheAnimation.value : 1.0,
                  child: SizedBox(
                    width: 260,
                    height: 260,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Glow
                        if (_isRunning)
                          Container(
                            width: 260,
                            height: 260,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.focusBlue
                                      .withValues(alpha: _glowAnimation.value),
                                  blurRadius: 60,
                                  spreadRadius: 20,
                                ),
                              ],
                            ),
                          ),
                        // Progress ring
                        SizedBox(
                          width: 240,
                          height: 240,
                          child: CircularProgressIndicator(
                            value: progress,
                            strokeWidth: 4,
                            backgroundColor:
                                AppColors.textTertiary.withValues(alpha: 0.1),
                            valueColor: AlwaysStoppedAnimation(
                              _isPaused ? AppColors.warningAmber : AppColors.focusBlue,
                            ),
                          ),
                        ),
                        // Time
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              timeStr,
                              style: AppTypography.display.copyWith(
                                color: AppColors.textPrimary,
                                fontSize: 52,
                                letterSpacing: 2,
                              ),
                            ),
                            if (widget.taskTitle != null) ...[
                              const SizedBox(height: AppSpacing.sm),
                              SizedBox(
                                width: 160,
                                child: Text(
                                  widget.taskTitle!,
                                  style: AppTypography.caption.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                            if (_isPaused) ...[
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                'PAUSED',
                                style: AppTypography.monoSmall.copyWith(
                                  color: AppColors.warningAmber,
                                  letterSpacing: 3,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: AppSpacing.xxl),

            // Pause count
            if (_pauseCount > 0)
              Text(
                'Paused $_pauseCount×',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),

            const Spacer(),

            // ─── Ambient Sounds ──────────────────────────────
            if (!_isRunning || _isPaused) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ambient Sound',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: _sounds.map((s) {
                        final isActive = _selectedSound == s.key;
                        return GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _selectedSound = s.key);
                            if (_isRunning && !_isPaused) {
                              AmbientSoundPlayer.play(s.key);
                            }
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.sm,
                            ),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? AppColors.focusBlue.withValues(alpha: 0.15)
                                  : AppColors.background2,
                              borderRadius:
                                  BorderRadius.circular(AppSpacing.radiusPill),
                              border: Border.all(
                                color: isActive
                                    ? AppColors.focusBlue
                                    : Colors.transparent,
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(s.emoji,
                                    style: const TextStyle(fontSize: 20)),
                                const SizedBox(height: 2),
                                Text(
                                  s.label,
                                  style: AppTypography.caption.copyWith(
                                    color: isActive
                                        ? AppColors.focusBlue
                                        : AppColors.textTertiary,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
            ],

            // ─── Controls ────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
              child: _buildControls(),
            ),
            const SizedBox(height: AppSpacing.xxxl),
          ],
        ),
      ),
    );
  }

  Widget _buildControls() {
    if (!_isRunning) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _startTimer,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.focusBlue,
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
          ),
          child: const Text('Enter Flow State'),
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _isPaused ? _resumeTimer : _pauseTimer,
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                color: _isPaused ? AppColors.emerald : AppColors.warningAmber,
              ),
              foregroundColor:
                  _isPaused ? AppColors.emerald : AppColors.warningAmber,
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
            ),
            child: Text(_isPaused ? 'Resume' : 'Pause'),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: ElevatedButton(
            onPressed: _completeSession,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.emerald,
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
            ),
            child: const Text('Complete'),
          ),
        ),
      ],
    );
  }
}
