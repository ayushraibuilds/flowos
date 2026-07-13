import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/constants/xp_constants.dart';
import '../../../features/onboarding/providers/onboarding_providers.dart';
import '../../../features/attention/widgets/scroll_intent_sheet.dart';
import 'package:go_router/go_router.dart';
import '../../../data/local/database/app_database.dart';
import '../../../features/attention/widgets/attention_radar_card.dart';
import '../../../features/xp/models/xp_calculator.dart';
import '../../../features/achievements/models/achievement_checker.dart';
import '../../../features/xp/models/streak_service.dart';

const _uuid = Uuid();

/// Scroll Tracker — manual scroll time logging with live timer,
/// quick-log slider, attention budget bar, and recovery actions.
class ScrollTrackerScreen extends ConsumerStatefulWidget {
  const ScrollTrackerScreen({super.key});

  @override
  ConsumerState<ScrollTrackerScreen> createState() =>
      _ScrollTrackerScreenState();
}

class _ScrollTrackerScreenState extends ConsumerState<ScrollTrackerScreen> {
  // Timer state
  String? _activeApp;
  Timer? _timer;
  int _elapsedSeconds = 0;
  String? _currentIntent;

  // Quick log
  double _quickLogMinutes = 10;

  // Budget — loaded from DB
  int _dailyTotal = 0;
  int _budget = 30;

  @override
  void initState() {
    super.initState();
    _loadBudget();
  }

  Future<void> _loadBudget() async {
    final db = ref.read(databaseProvider);
    final total = await db.scrollLogsDao.getDailyTotal();
    final plan = await db.dailyPlansDao.getToday();
    if (mounted) {
      setState(() {
        _dailyTotal = total;
        _budget = plan?.scrollBudgetMinutes ?? 30;
      });
    }
  }

  final _apps = [
    (name: 'Instagram', emoji: '📸', color: Color(0xFFE4405F)),
    (name: 'YouTube', emoji: '▶️', color: Color(0xFFFF0000)),
    (name: 'Twitter/X', emoji: '🐦', color: Color(0xFF1DA1F2)),
    (name: 'Reddit', emoji: '🤖', color: Color(0xFFFF4500)),
    (name: 'TikTok', emoji: '🎵', color: Color(0xFF010101)),
    (name: 'Other', emoji: '📱', color: AppColors.textTertiary),
  ];

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _toggleApp(String appName) async {
    HapticFeedback.selectionClick();
    if (_activeApp == appName) {
      // Stop timer and log
      _timer?.cancel();
      final minutes = (_elapsedSeconds / 60).ceil().clamp(1, 999);
      await _logScroll(appName, minutes, intent: _currentIntent);
      setState(() {
        _activeApp = null;
        _elapsedSeconds = 0;
        _currentIntent = null;
      });
    } else {
      // Starting timer: run gate check
      final profile = ref.read(userProfileProvider);
      final isDistraction = profile.distractions.any((d) =>
        d.toLowerCase().contains(appName.toLowerCase()) ||
        appName.toLowerCase().contains(d.toLowerCase())
      );
      final forceIntent = profile.protectionMode == 'firm' || isDistraction;

      String? chosenIntent;
      if (forceIntent) {
        chosenIntent = await ScrollIntentSheet.show(context);
        if (chosenIntent == null) return; // User cancelled

        if (chosenIntent == 'rest') {
          if (mounted) context.push('/rest');
          return;
        }

        if (chosenIntent == 'avoiding') {
          final divert = await _showDivertDialog();
          if (divert == true) {
            if (mounted) context.push('/rest');
            return;
          }
        } else if (chosenIntent == 'scrolling' && profile.protectionMode == 'firm') {
          final proceed = await _showBreathingPauseDialog();
          if (!proceed) return;
        }
      }

      // Start timer for this app
      _timer?.cancel();
      setState(() {
        _activeApp = appName;
        _elapsedSeconds = 0;
        _currentIntent = chosenIntent;
      });
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        setState(() => _elapsedSeconds++);
      });
    }
  }

  Future<void> _logScroll(String appName, int minutes, {String? intent}) async {
    final db = ref.read(databaseProvider);
    final impact = (minutes ~/ 10) * XpConstants.scrollCostPer10Min;

    await db.scrollLogsDao.insertLog(ScrollLogsCompanion(
      id: Value(_uuid.v4()),
      appName: Value(appName),
      durationMinutes: Value(minutes),
      dailyScoreImpact: Value(impact),
      intent: Value(intent),
      wasTimeboxed: Value(false),
      plannedMinutes: Value(null),
    ));

    // Refresh budget display
    await _loadBudget();

    // Show recovery action sheet
    if (mounted) _showRecoverySheet(context, appName, minutes);
  }

  void _quickLog() async {
    HapticFeedback.mediumImpact();
    final appName = 'Quick Log';
    
    final profile = ref.read(userProfileProvider);
    final isDistraction = profile.distractions.any((d) =>
      d.toLowerCase().contains(appName.toLowerCase()) ||
      appName.toLowerCase().contains(d.toLowerCase())
    );
    final forceIntent = profile.protectionMode == 'firm' || isDistraction;

    String? chosenIntent;
    if (forceIntent) {
      chosenIntent = await ScrollIntentSheet.show(context);
      if (chosenIntent == null) return; // Cancelled

      if (chosenIntent == 'rest') {
        if (mounted) context.push('/rest');
        return;
      }

      if (chosenIntent == 'avoiding') {
        final divert = await _showDivertDialog();
        if (divert == true) {
          if (mounted) context.push('/rest');
          return;
        }
      } else if (chosenIntent == 'scrolling' && profile.protectionMode == 'firm') {
        final proceed = await _showBreathingPauseDialog();
        if (!proceed) return;
      }
    }

    await _logScroll(appName, _quickLogMinutes.round(), intent: chosenIntent);
  }

  Future<bool?> _showDivertDialog() {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.background2,
        title: const Text('Avoiding something?'),
        content: const Text(
          'Resistance is natural. Would you like a 2-minute breathing space instead of scrolling?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false), // Proceed to scroll
            child: Text('Scroll anyway', style: TextStyle(color: AppColors.textTertiary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true), // Divert to rest
            child: Text('Try Breathing Space', style: TextStyle(color: AppColors.emerald)),
          ),
        ],
      ),
    );
  }

  Future<bool> _showBreathingPauseDialog() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const _BreathingPauseDialog(),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background0,
      appBar: AppBar(
        title: Text(
          'Scroll Tracker',
          style: AppTypography.h3.copyWith(color: AppColors.textPrimary),
        ),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.lg),
            // ─── Attention Budget ────────────────────────────────
            AttentionRadarCard(budgetMinutes: _budget),
            const SizedBox(height: AppSpacing.xxl),
            // ─── App Buttons ─────────────────────────────────────
            Text(
              'What are you scrolling?',
              style: AppTypography.h3.copyWith(color: AppColors.textPrimary),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Tap to start timer. Tap again to stop + log.',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _buildAppGrid(),
            const SizedBox(height: AppSpacing.xxl),
            // ─── Quick Log ───────────────────────────────────────
            _buildQuickLog(),
            const SizedBox(height: AppSpacing.xxl),
            // ─── Today's Log ─────────────────────────────────────
            _buildTodayLog(),
            const SizedBox(height: AppSpacing.xxxl),
          ],
        ),
      ),
    );
  }


  Widget _buildAppGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: AppSpacing.md,
        mainAxisSpacing: AppSpacing.md,
        childAspectRatio: 1.0,
      ),
      itemCount: _apps.length,
      itemBuilder: (context, i) {
        final app = _apps[i];
        final isActive = _activeApp == app.name;
        return GestureDetector(
          onTap: () => _toggleApp(app.name),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isActive
                  ? app.color.withValues(alpha: 0.15)
                  : AppColors.background2,
              borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
              border: Border.all(
                color: isActive ? app.color : Colors.transparent,
                width: 2,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(app.emoji, style: const TextStyle(fontSize: 28)),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  app.name,
                  style: AppTypography.caption.copyWith(
                    color: isActive ? app.color : AppColors.textSecondary,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
                if (isActive) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    _formatElapsed(_elapsedSeconds),
                    style: AppTypography.monoSmall.copyWith(
                      color: app.color,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickLog() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.background2,
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Log',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: AppColors.warningAmber,
                    inactiveTrackColor: AppColors.background0,
                    thumbColor: AppColors.warningAmber,
                    overlayColor: AppColors.warningAmber.withValues(alpha: 0.12),
                    trackHeight: 4,
                  ),
                  child: Slider(
                    value: _quickLogMinutes,
                    min: 1,
                    max: 60,
                    divisions: 59,
                    onChanged: (v) => setState(() => _quickLogMinutes = v),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Text(
                '${_quickLogMinutes.round()}m',
                style: AppTypography.monoSmall.copyWith(
                  color: AppColors.warningAmber,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _quickLog,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.warningAmber),
                foregroundColor: AppColors.warningAmber,
              ),
              child: Text('Log ${_quickLogMinutes.round()} minutes'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayLog() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Today's Scroll Time",
          style: AppTypography.h3.copyWith(color: AppColors.textPrimary),
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.xxl),
          decoration: BoxDecoration(
            color: AppColors.background2,
            borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
          ),
          child: Column(
            children: [
              Text(
                '${_dailyTotal}m',
                style: AppTypography.display.copyWith(
                  color: _dailyTotal > _budget
                      ? AppColors.dangerCoral
                      : AppColors.textPrimary,
                  fontSize: 48,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                _dailyTotal == 0
                    ? 'Clean slate today 🌟'
                    : 'Daily score impact: ${(_dailyTotal ~/ 10) * 5} points',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatElapsed(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void _showRecoverySheet(BuildContext context, String app, int minutes) {
    showModalBottomSheet(
      context: context,
      builder: (context) => RecoveryActionSheet(
        appName: app,
        minutes: minutes,
      ),
    );
  }
}

/// Recovery Action Bottom Sheet — shown after scroll logging.
/// Completing any action earns BOUNCE_BACK_BONUS (+25 XP).
class RecoveryActionSheet extends ConsumerWidget {
  final String appName;
  final int minutes;

  const RecoveryActionSheet({
    super.key,
    required this.appName,
    required this.minutes,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actions = [
      (emoji: '🧘', label: '60s Breathing', desc: 'Quick reset', type: 'breathing'),
      (emoji: '🚶', label: '5-min Walk', desc: 'Move your body', type: 'walk'),
      (emoji: '✅', label: 'Tiny Task', desc: 'Easiest incomplete task', type: 'tinyTask'),
      (emoji: '⏱️', label: '15-min Focus', desc: 'Mini sprint', type: 'focusSprint'),
    ];

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textTertiary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          Text(
            'Logged ${minutes}m on $appName',
            style: AppTypography.h3.copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Bounce back? Pick a recovery action for +25 XP 🔄',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          // Recovery action buttons
          ...actions.map((action) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () async {
                  HapticFeedback.mediumImpact();
                  final db = ref.read(databaseProvider);
                  final xpCalc = XpCalculator(db.xpLedgerDao);
                  await xpCalc.awardBounceBackBonus(action.type);
                  
                  // Record streak activity & check achievements
                  await StreakService.recordActivity();
                  await AchievementChecker.runCheck(db);
                  
                  if (context.mounted) {
                    Navigator.pop(context, action.type);
                  }
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.lg,
                  ),
                  side: BorderSide(color: AppColors.recoveryTeal.withValues(alpha: 0.5)),
                  foregroundColor: AppColors.recoveryTeal,
                ),
                child: Row(
                  children: [
                    Text(action.emoji, style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            action.label,
                            style: AppTypography.body.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            action.desc,
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '+25 XP',
                      style: AppTypography.monoSmall.copyWith(
                        color: AppColors.emerald,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )),
          // Skip
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Skip — no penalty',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}

class _BreathingPauseDialog extends StatefulWidget {
  const _BreathingPauseDialog();

  @override
  State<_BreathingPauseDialog> createState() => _BreathingPauseDialogState();
}

class _BreathingPauseDialogState extends State<_BreathingPauseDialog> {
  int _secondsLeft = 10;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft <= 1) {
        _timer?.cancel();
        Navigator.pop(context, true);
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.background2,
      title: const Text('Mindful Pause', textAlign: TextAlign.center),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Take a slow breath before continuing. This helps build resistance to scrolling loops.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.emerald.withValues(alpha: 0.1),
            ),
            child: Center(
              child: Text(
                '$_secondsLeft',
                style: AppTypography.monoSmall.copyWith(
                  color: AppColors.emerald,
                  fontSize: 24,
                ),
              ),
            ),
          ),
        ],
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false), // Cancel scrolling
          child: Text('Cancel scroll request', style: TextStyle(color: AppColors.dangerCoral)),
        ),
      ],
    );
  }
}
