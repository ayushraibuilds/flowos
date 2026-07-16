import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../features/insights/providers/insights_providers.dart';
import '../../../features/insights/widgets/score_ring_widget.dart';
import '../../../features/insights/widgets/calendar_heatmap_widget.dart';
import '../../../features/insights/widgets/focus_session_timeline.dart';
import '../../../features/insights/widgets/pillar_detail_card.dart';
import '../../../features/xp/models/daily_score_calculator.dart';
import '../../../features/insights/services/history_aggregator.dart';
import '../../../features/xp/services/daily_score_snapshot_service.dart';
import '../../../features/dashboard/providers/dashboard_providers.dart';

class InsightsDashboardScreen extends ConsumerStatefulWidget {
  const InsightsDashboardScreen({super.key});

  @override
  ConsumerState<InsightsDashboardScreen> createState() => _InsightsDashboardScreenState();
}

class _InsightsDashboardScreenState extends ConsumerState<InsightsDashboardScreen> {
  ScorePillar? _selectedPillar;
  bool _interruptionExpanded = false;

  @override
  void initState() {
    super.initState();
    // Pre-sync usage when entering insights
    Future.microtask(() {
      ref.read(dailyScoreSnapshotServiceProvider).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final period = ref.watch(insightPeriodProvider);
    final scoreAsync = ref.watch(insightScoreProvider);

    return Scaffold(
      backgroundColor: AppColors.background0,
      appBar: AppBar(
        title: Text(
          'Insights',
          style: AppTypography.h3.copyWith(color: AppColors.textPrimary),
        ),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.md),
              // Segmented Period Selector
              _buildPeriodSelector(),
              const SizedBox(height: AppSpacing.xl),

              // Score Header / Ring / Average
              scoreAsync.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 40.0),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (err, _) => Center(child: Text('Error loading insights: $err')),
                data: (data) => _buildScoreSection(data),
              ),

              const SizedBox(height: AppSpacing.xxl),

              // Detail Section (Conditional on selected tab)
              if (period == InsightPeriod.today) ...[
                _buildTodayDetails(),
              ] else if (period == InsightPeriod.week) ...[
                _buildWeeklyDetails(),
              ] else ...[
                _buildMonthlyDetails(),
              ],

              const SizedBox(height: AppSpacing.xxl),

              // Interruption Section (Android-only, collapsible)
              _buildCollapsibleInterruptionSection(),

              const SizedBox(height: AppSpacing.xl),
              Center(
                child: Text(
                  'Based on local data only · Private',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xxxl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodSelector() {
    final period = ref.watch(insightPeriodProvider);
    return Center(
      child: SegmentedButton<InsightPeriod>(
        segments: const [
          ButtonSegment<InsightPeriod>(
            value: InsightPeriod.today,
            label: Text('Today'),
          ),
          ButtonSegment<InsightPeriod>(
            value: InsightPeriod.week,
            label: Text('7 Days'),
          ),
          ButtonSegment<InsightPeriod>(
            value: InsightPeriod.month,
            label: Text('30 Days'),
          ),
        ],
        selected: {period},
        onSelectionChanged: (Set<InsightPeriod> newSelection) {
          setState(() {
            _selectedPillar = null; // Clear pillar detail card when switching tabs
          });
          ref.read(insightPeriodProvider.notifier).state = newSelection.first;
        },
        style: SegmentedButton.styleFrom(
          selectedBackgroundColor: AppColors.emerald.withValues(alpha: 0.15),
          selectedForegroundColor: AppColors.emerald,
          backgroundColor: AppColors.background2,
          foregroundColor: AppColors.textSecondary,
          side: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildScoreSection(dynamic data) {
    if (data is DashboardScore) {
      // Convert DashboardScore to DailyScoreResult
      final result = DailyScoreResult(
        score: data.score,
        grade: data.grade,
        message: data.message,
        isIncomplete: data.isIncomplete,
        availableWeight: data.availableWeight,
        coverageLabel: data.coverageLabel,
        scoringVersion: data.scoringVersion,
        focusPoints: data.focusPoints,
        intentPoints: data.intentPoints,
        attentionPoints: data.attentionPoints,
        carePoints: data.carePoints,
      );

      return Column(
        children: [
          Center(
            child: ScoreRingWidget(
              result: result,
              selectedPillar: _selectedPillar,
              onPillarTapped: (pillar) {
                setState(() {
                  if (_selectedPillar == pillar) {
                    _selectedPillar = null;
                  } else {
                    _selectedPillar = pillar;
                  }
                });
              },
            ),
          ),
          if (_selectedPillar != null) ...[
            const SizedBox(height: AppSpacing.lg),
            PillarDetailCard(pillar: _selectedPillar!, result: result),
          ] else ...[
            const SizedBox(height: AppSpacing.md),
            Center(
              child: Text(
                result.message,
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
              ),
            ),
          ],
        ],
      );
    } else if (data is WeeklyAggregate) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.background2,
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        ),
        child: Column(
          children: [
            Text(
              'Weekly Average Score',
              style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${data.averageScore}',
              style: AppTypography.display.copyWith(
                color: AppColors.emerald,
                fontSize: 64,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Based on ${data.scoredDaysCount} of ${data.totalDays} scored days',
              style: AppTypography.caption.copyWith(color: AppColors.textTertiary),
            ),
          ],
        ),
      );
    } else if (data is MonthlyAggregate) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.background2,
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        ),
        child: Column(
          children: [
            Text(
              'Monthly Average Score',
              style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${data.averageScore}',
              style: AppTypography.display.copyWith(
                color: AppColors.emerald,
                fontSize: 64,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Based on ${data.scoredDaysCount} of ${data.totalDays} scored days',
              style: AppTypography.caption.copyWith(color: AppColors.textTertiary),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildTodayDetails() {
    final timelineAsync = ref.watch(insightFocusTimelineProvider);
    final appsAsync = ref.watch(insightAppImpactProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Focus timeline
        timelineAsync.when(
          loading: () => const SizedBox(height: 60),
          error: (_, __) => const SizedBox.shrink(),
          data: (sessions) => FocusSessionTimeline(sessions: sessions),
        ),
        const SizedBox(height: AppSpacing.xxl),

        // App distraction impact list
        Text('App Impact', style: AppTypography.h3.copyWith(color: AppColors.textPrimary)),
        const SizedBox(height: AppSpacing.sm),
        appsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (apps) {
            if (apps.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.background2,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
                ),
                child: Center(
                  child: Text(
                    'No distraction apps used today.',
                    style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                  ),
                ),
              );
            }
            return Column(
              children: apps.map((app) {
                final overBudget = app.minutes > app.budget;
                return Card(
                  color: AppColors.background2,
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: ListTile(
                    title: Text(app.label, style: TextStyle(color: AppColors.textPrimary)),
                    subtitle: Text('Budget: ${app.budget}m', style: TextStyle(color: AppColors.textTertiary)),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${app.minutes} min',
                          style: TextStyle(
                            color: overBudget ? AppColors.warningAmber : AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (overBudget)
                          Text(
                            '+${app.minutes - app.budget}m reclaimable',
                            style: const TextStyle(color: AppColors.warningAmber, fontSize: 10),
                          ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildWeeklyDetails() {
    final scoreAsync = ref.watch(insightScoreProvider);
    final appsAsync = ref.watch(insightAppImpactProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        scoreAsync.maybeWhen(
          data: (data) {
            if (data is! WeeklyAggregate) return const SizedBox.shrink();
            
            // Weekly Rhythm Terrain (overlaid focus & distraction trend chart)
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Rhythm Terrain', style: AppTypography.h3.copyWith(color: AppColors.textPrimary)),
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  height: 180,
                  child: LineChart(
                    LineChartData(
                      gridData: const FlGridData(show: false),
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (val, _) {
                              final idx = val.toInt();
                              if (idx < 0 || idx >= data.days.length) return const SizedBox.shrink();
                              return Text(
                                DateFormat('E').format(data.days[idx].date),
                                style: const TextStyle(fontSize: 10, color: AppColors.textTertiary),
                              );
                            },
                          ),
                        ),
                        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        // Focus line
                        LineChartBarData(
                          spots: List.generate(data.days.length, (i) {
                            return FlSpot(i.toDouble(), data.days[i].focusMinutes.toDouble());
                          }),
                          isCurved: true,
                          color: AppColors.emerald,
                          barWidth: 3,
                          dotData: const FlDotData(show: true),
                        ),
                        // Distraction/Scroll line
                        LineChartBarData(
                          spots: List.generate(data.days.length, (i) {
                            return FlSpot(i.toDouble(), data.days[i].scrollMinutes.toDouble());
                          }),
                          isCurved: true,
                          color: AppColors.warningAmber,
                          barWidth: 3,
                          dotData: const FlDotData(show: true),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppColors.emerald,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text('Focus Time', style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
                    const SizedBox(width: 24),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppColors.warningAmber,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text('Distractions', style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                if (data.hasReclaimableData) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: AppColors.background2,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
                      border: Border.all(color: AppColors.warningAmber.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text('⚠️ ', style: TextStyle(fontSize: 18)),
                            Text(
                              'Reclaimable Attention Time',
                              style: AppTypography.monoSmall.copyWith(
                                color: AppColors.warningAmber,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          '${data.reclaimableMinutes} minutes spent over your budget limit on distracting apps this week.',
                          style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                        ),
                        if (data.topReclaimableApp != null) ...[
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'Highest sink app: ${data.topReclaimableApp}',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            );
          },
          orElse: () => const SizedBox.shrink(),
        ),
        const SizedBox(height: AppSpacing.xxl),

        // distracting app list in 7 days
        Text('Watchlist App Usage', style: AppTypography.h3.copyWith(color: AppColors.textPrimary)),
        const SizedBox(height: AppSpacing.sm),
        appsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (apps) {
            if (apps.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.background2,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
                ),
                child: Center(
                  child: Text(
                    'No distraction apps used this week.',
                    style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                  ),
                ),
              );
            }
            return Column(
              children: apps.map((app) => Card(
                color: AppColors.background2,
                elevation: 0,
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: ListTile(
                  title: Text(app.label, style: TextStyle(color: AppColors.textPrimary)),
                  trailing: Text(
                    '${app.minutes} min',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                ),
              )).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildMonthlyDetails() {
    final heatmapAsync = ref.watch(insightCalendarHeatmapProvider);
    final scoreAsync = ref.watch(insightScoreProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 30-day dynamic calendar heatmap (with 6-row capability)
        heatmapAsync.when(
          loading: () => const SizedBox(height: 120),
          error: (_, __) => const SizedBox.shrink(),
          data: (metrics) => CalendarHeatmapWidget(
            monthStart: DateTime.now().subtract(const Duration(days: 29)),
            metrics: metrics,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),

        scoreAsync.maybeWhen(
          data: (data) {
            if (data is! MonthlyAggregate) return const SizedBox.shrink();

            return Column(
              children: [
                _buildSummaryRow('Total Focus Blocks Completed', '${data.totalFocusMinutes} min'),
                if (data.hasReclaimableData)
                  _buildSummaryRow('Reclaimable Distraction Time', '${data.totalReclaimableMinutes} min'),
              ],
            );
          },
          orElse: () => const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
          Text(value, style: AppTypography.bodySmall.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildCollapsibleInterruptionSection() {
    final interruptionAsync = ref.watch(insightInterruptionProvider);

    return interruptionAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (data) {
        if (!data.isAvailable) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () {
                setState(() {
                  _interruptionExpanded = !_interruptionExpanded;
                });
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '📱 Interruption Analytics',
                      style: AppTypography.h3.copyWith(color: AppColors.textPrimary),
                    ),
                    Icon(
                      _interruptionExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
            if (_interruptionExpanded) ...[
              const SizedBox(height: AppSpacing.xs),
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.background2,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSummaryRow('Total Phone Unlocks', '${data.totalUnlocks} unlocks'),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Notifications by App',
                      style: AppTypography.monoSmall.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    if (data.notificationCounts.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                          child: Text(
                            'No notifications recorded.',
                            style: AppTypography.caption.copyWith(color: AppColors.textTertiary),
                          ),
                        ),
                      )
                    else
                      Column(
                        children: data.notificationCounts.map((notif) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    notif.appName,
                                    style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                                  ),
                                ),
                                Text(
                                  '${notif.count}',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    Divider(height: AppSpacing.lg, color: AppColors.background1),
                    Text(
                      'Interruption data is based on counts only. FlowOS never reads notification content.',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textTertiary,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
