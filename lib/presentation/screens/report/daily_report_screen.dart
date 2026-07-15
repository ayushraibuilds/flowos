import 'dart:ui' as ui;
import 'dart:convert';
import 'package:drift/drift.dart' hide Column;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/constants/xp_constants.dart';
import '../../../features/ai/services/ai_service.dart';
import '../../../features/xp/models/daily_score_calculator.dart';
import '../../../data/local/database/app_database.dart';
import '../../../features/reports/models/weekly_action.dart';
import '../../../features/attention/repository/attention_data_repository.dart';
import '../../../features/reports/services/daily_action_engine.dart';
import '../../widgets/action_commit_card.dart';

/// Daily Report Screen — the "honest mirror" for your day.
/// Shows daily score, AI insight, XP, streak, attention cost, and share button.
class DailyReportScreen extends ConsumerStatefulWidget {
  const DailyReportScreen({super.key});

  @override
  ConsumerState<DailyReportScreen> createState() => _DailyReportScreenState();
}

class _DailyReportScreenState extends ConsumerState<DailyReportScreen>
    with SingleTickerProviderStateMixin {
  final _shareKey = GlobalKey();
  late AnimationController _animController;
  late Animation<double> _fadeIn;

  // Report data — populated from DAOs in _loadReport()
  int _dailyScore = 0;
  String _grade = '—';
  int _xpToday = 0;
  int _focusMinutes = 0;
  int _tasksCompleted = 0;
  int _mitsCompleted = 0;
  int _scrollMinutes = 0;
  int _streakDays = 0;
  int _scrollBudget = 30;
  bool _intentionCompleted = false;
  DailyReportInsight _insight = DailyReportInsight.fallback();
  DataCoverage _coverage = DataCoverage.complete;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeIn = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _loadReport();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadReport() async {
    final db = ref.read(databaseProvider);

    // Collect real data from DAOs
    _focusMinutes = await db.focusSessionsDao.totalFocusMinutesToday();
    _tasksCompleted = await db.tasksDao.countCompletedToday();
    final mits = await db.tasksDao.getMITs();
    _mitsCompleted = mits.where((t) => t.isCompleted).length;
    final attentionRepo = ref.read(attentionDataRepositoryProvider);
    final todayAttention = await attentionRepo.getAttentionDay(DateTime.now());
    _scrollMinutes = todayAttention.effectiveDistractingMinutes;
    _xpToday = await db.xpLedgerDao.getDailyXP();
    final lifetimeXP = await db.xpLedgerDao.getLifetimeXP();
    final level = XpConstants.levelFromXP(lifetimeXP);
    final plan = await db.dailyPlansDao.getToday();
    _scrollBudget = plan?.scrollBudgetMinutes ?? 30;
    _intentionCompleted = plan?.intentionCompleted ?? false;

    // Calculate streak
    _streakDays = 0;
    if (plan != null && plan.intentionCompleted) _streakDays = 1;
    for (int i = 1; i <= 365; i++) {
      final d = DateTime.now().subtract(Duration(days: i));
      final start = DateTime(d.year, d.month, d.day);
      final end = start.add(const Duration(days: 1));
      final p = await db.dailyPlansDao.getByDateRange(start, end);
      if (p != null && p.intentionCompleted) {
        _streakDays++;
      } else {
        break;
      }
    }

    // Calculate score
    _coverage = todayAttention.coverage;
    final todayStart = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final todayEnd = todayStart.add(const Duration(days: 1));
    final energyCheckIns = await db.energyCheckInsDao.countToday();
    
    final todayLogs = await (db.select(db.scrollLogs)
          ..where((l) =>
              l.timestamp.isBiggerOrEqualValue(todayStart) &
              l.timestamp.isSmallerThanValue(todayEnd)))
        .get();
    final recoveryActions = todayLogs
        .where((l) => !l.appName.contains('[Auto]') && l.recoveryActionTaken)
        .length;

    final scoreResult = DailyScoreCalculator.calculate(
      focusMinutes: _focusMinutes,
      mitsCompleted: _mitsCompleted,
      scrollMinutes: _scrollMinutes,
      scrollBudget: _scrollBudget,
      intentionCompleted: _intentionCompleted,
      shutdownCompleted: plan?.shutdownCompleted ?? false,
      energyCheckIns: energyCheckIns,
      recoveryActions: recoveryActions,
      attentionCoverage: todayAttention.coverage,
    );

    _dailyScore = scoreResult.score;
    _grade = scoreResult.grade ?? '—';

    // Try AI insight with real data
    final aiService = AiService();
    final aiInsight = await aiService.generateDailyReport(dailyData: {
      'date': DateTime.now().toIso8601String().split('T')[0],
      'daily_score': _dailyScore,
      'xp_earned_today': _xpToday,
      'lifetime_xp': lifetimeXP,
      'level': level,
      'streak_days': _streakDays,
      'total_focus_minutes': _focusMinutes,
      'sessions': [],
      'tasks_completed': _tasksCompleted,
      'tasks_total': (await db.tasksDao.getAllActive()).length,
      'mits_completed': _mitsCompleted,
      'scroll_minutes': _scrollMinutes,
      'scroll_budget': _scrollBudget,
      'recovery_actions_taken': 0,
      'energy_readings': [],
      'intention_completed': _intentionCompleted,
      'shutdown_completed': plan?.shutdownCompleted ?? false,
      'private_mode': false,
      'prompt_version': 1,
    });

    final targetInsight = aiInsight ?? DailyReportInsight.fallback();

    // Persist daily score and coverage state in database
    final dateStr = DateTime.now().toIso8601String().split('T')[0];
    await db.dailyReportsDao.upsertReport(DailyReportsCompanion(
      id: Value(dateStr),
      date: Value(DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day)),
      reportJson: Value(jsonEncode(targetInsight.toJson())),
      dailyScore: Value(_dailyScore),
      xpEarnedToday: Value(_xpToday),
      attentionCostToday: Value(_scrollMinutes),
      generatedAt: Value(DateTime.now()),
      coverageState: Value(_coverage.name),
    ));

    setState(() {
      _insight = targetInsight;
      _loading = false;
    });

    _animController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background0,
      appBar: AppBar(
        title: Text('Daily Report',
            style: AppTypography.h3.copyWith(color: AppColors.textPrimary)),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close_rounded),
        ),
        actions: [
          IconButton(
            onPressed: _shareReport,
            icon: const Icon(Icons.ios_share_rounded),
          ),
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: AppColors.emerald))
          : FadeTransition(
              opacity: _fadeIn,
              child: SingleChildScrollView(
                child: RepaintBoundary(
                  key: _shareKey,
                  child: Container(
                    color: AppColors.background0,
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                    child: Column(
                      children: [
                        const SizedBox(height: AppSpacing.lg),
                        // ─── Score Card ─────────────────────────
                        _buildScoreCard(),
                        const SizedBox(height: AppSpacing.lg),
                        // ─── Stats Grid ─────────────────────────
                        _buildStatsGrid(),
                        const SizedBox(height: AppSpacing.lg),
                        // ─── AI Insight ─────────────────────────
                        _buildInsightCard(),
                        const SizedBox(height: AppSpacing.lg),
                        // ─── Attention Cost ─────────────────────
                        _buildAttentionCost(),
                        const SizedBox(height: AppSpacing.lg),
                        // ─── Streak ─────────────────────────────
                        _buildStreakBar(),
                        const SizedBox(height: AppSpacing.lg),
                        _buildTomorrowActionCard(),
                        const SizedBox(height: AppSpacing.xxxl),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildScoreCard() {
    final gradeColor = AppColors.gradeColor(_grade);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xxl),
      decoration: BoxDecoration(
        color: AppColors.background2,
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        border: Border.all(color: gradeColor.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: gradeColor.withValues(alpha: 0.08),
            blurRadius: 30,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            _grade,
            style: AppTypography.display.copyWith(
              color: gradeColor,
              fontSize: 72,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '$_dailyScore / 100',
            style: AppTypography.monoSmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            DailyScoreCalculator.messageForGrade(_grade),
            style: AppTypography.body.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          _buildCoverageBadge(),
        ],
      ),
    );
  }

  Widget _buildCoverageBadge() {
    final (label, icon, color) = switch (_coverage) {
      DataCoverage.complete => (
          'Full Screen Time Coverage',
          Icons.verified_user_rounded,
          AppColors.emerald
        ),
      DataCoverage.partial => (
          'Partial Coverage (Reweighted)',
          Icons.warning_amber_rounded,
          AppColors.warningAmber
        ),
      DataCoverage.manualOnly => (
          'Manual Logs Only (Reweighted)',
          Icons.edit_note_rounded,
          AppColors.warningAmber
        ),
      DataCoverage.notConnected => (
          'Missing Screen Time (Reweighted)',
          Icons.gpp_maybe_rounded,
          AppColors.dangerCoral
        ),
      DataCoverage.unsupported => (
          'Screen Time Unsupported (Reweighted)',
          Icons.info_outline_rounded,
          AppColors.dangerCoral
        ),
    };

    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.md),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    final stats = [
      (value: '${_focusMinutes}m', label: 'Focus', color: AppColors.focusBlue),
      (value: '+$_xpToday', label: 'XP', color: AppColors.emerald),
      (value: '$_tasksCompleted', label: 'Tasks', color: AppColors.textPrimary),
      (value: '$_mitsCompleted/3', label: 'MITs', color: AppColors.warningAmber),
    ];

    return Row(
      children: stats.map((stat) {
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 3),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.background2,
              borderRadius: BorderRadius.circular(AppSpacing.radiusButton),
            ),
            child: Column(
              children: [
                Text(
                  stat.value,
                  style: AppTypography.monoSmall.copyWith(
                    color: stat.color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  stat.label,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildInsightCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.background2,
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        border: Border(
          left: BorderSide(color: AppColors.emerald, width: 2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '💡 AI Insight',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.emerald,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            _insight.headline,
            style: AppTypography.body.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _insightRow('🌟', 'Highlight', _insight.highlight),
          _insightRow('🌱', 'Growth', _insight.growthArea),
          _insightRow('⚡', 'Energy', _insight.energyInsight),
          _insightRow('🎯', 'Tomorrow', _insight.tomorrowTip),
        ],
      ),
    );
  }

  Widget _insightRow(String emoji, String label, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttentionCost() {
    final ratio = _scrollBudget > 0 ? (_scrollMinutes / _scrollBudget).clamp(0.0, 1.5) : 0.0;
    final isOver = _scrollMinutes > _scrollBudget;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.background2,
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Attention Cost',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_scrollMinutes}m scrolled',
                style: AppTypography.body.copyWith(
                  color: isOver ? AppColors.dangerCoral : AppColors.textPrimary,
                ),
              ),
              Text(
                '${isOver ? "Over" : "Within"} budget (${_scrollBudget}m)',
                style: AppTypography.caption.copyWith(
                  color: isOver ? AppColors.dangerCoral : AppColors.emerald,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio.clamp(0.0, 1.0),
              minHeight: 4,
              backgroundColor: AppColors.background0,
              valueColor: AlwaysStoppedAnimation(
                isOver ? AppColors.dangerCoral : AppColors.emerald,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.background2,
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
      ),
      child: Row(
        children: [
          const Text('🔥', style: TextStyle(fontSize: 32)),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$_streakDays day streak',
                  style: AppTypography.h3.copyWith(
                    color: AppColors.warningAmber,
                  ),
                ),
                Text(
                  'Keep it going tomorrow!',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${XpConstants.streakMultiplier(_streakDays)}×',
            style: AppTypography.monoSmall.copyWith(
              color: AppColors.warningAmber,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _shareReport() async {
    HapticFeedback.mediumImpact();
    try {
      final boundary = _shareKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final pngBytes = byteData.buffer.asUint8List();
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile.fromData(pngBytes, mimeType: 'image/png', name: 'flowos-report.png')],
          text: 'My FlowOS Daily Score: $_grade ($_dailyScore/100) 🔥$_streakDays day streak',
        ),
      );
    } catch (e) {
      debugPrint('Share failed: $e');
    }
  }

  Widget _buildTomorrowActionCard() {
    final action = DailyActionEngine.generateDailyAction(
      todayFocusMinutes: _focusMinutes,
      todayScrollMinutes: _scrollMinutes,
      todayScrollBudget: _scrollBudget,
      todayMitsCompleted: _mitsCompleted,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'One thing for tomorrow',
          style: AppTypography.h3.copyWith(color: AppColors.textPrimary),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'A lightweight change suggested based on today\'s focus.',
          style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary),
        ),
        const SizedBox(height: AppSpacing.md),
        ActionCommitCard(
          action: action,
          onAccept: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Tomorrow\'s change accepted!')),
            );
          },
        ),
      ],
    );
  }
}
