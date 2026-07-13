import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../features/insights/providers/insights_providers.dart';
import '../../../features/rhythm/providers/rhythm_providers.dart';
import '../../widgets/rhythm_recommendation_card.dart';
import '../../../features/usage/services/device_usage_service.dart';

/// Insights Dashboard — data visualization for productivity patterns.
///
/// Charts:
/// - Time-of-day focus quality heatmap
/// - Day-of-week productivity bar chart
/// - Scroll vs Focus weekly trend
/// - Energy vs Output correlation
/// - Energy Forecast (predicted peak windows)
class InsightsDashboardScreen extends ConsumerStatefulWidget {
  const InsightsDashboardScreen({super.key});

  @override
  ConsumerState<InsightsDashboardScreen> createState() => _InsightsDashboardScreenState();
}

class _InsightsDashboardScreenState extends ConsumerState<InsightsDashboardScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(deviceUsageServiceProvider).syncUsageLogs(days: 7);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background0,
      appBar: AppBar(
        title: Text('Insights',
            style: AppTypography.h3.copyWith(color: AppColors.textPrimary)),
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

            // ─── Energy Forecast ───────────────────────────
            _sectionTitle('⚡ Energy Forecast'),
            _sectionSubtitle('Your predicted peak windows today'),
            const SizedBox(height: AppSpacing.md),
            _buildEnergyForecast(ref),
            const SizedBox(height: AppSpacing.xxl),

            // ─── Day of Week ───────────────────────────────
            _sectionTitle('📊 Daily Score by Weekday'),
            _sectionSubtitle('Average score for each day'),
            const SizedBox(height: AppSpacing.md),
            _buildDayOfWeekChart(ref),
            const SizedBox(height: AppSpacing.xxl),

            // ─── Focus Quality Heatmap ─────────────────────
            _sectionTitle('🔥 Focus Quality by Hour'),
            _sectionSubtitle('When you do your best work'),
            const SizedBox(height: AppSpacing.md),
            _buildHourlyHeatmap(ref),
            const SizedBox(height: AppSpacing.xxl),

            // ─── Scroll vs Focus ───────────────────────────
            _sectionTitle('📱 Scroll vs Focus (7 days)'),
            _sectionSubtitle('Attention allocation trend'),
            const SizedBox(height: AppSpacing.md),
            _buildScrollVsFocusChart(ref),
            const SizedBox(height: AppSpacing.xxl),

            // ─── Task Completion Funnel ────────────────────
            _sectionTitle('🎯 Task Completion Funnel'),
            _sectionSubtitle('Created → Started → Completed'),
            const SizedBox(height: AppSpacing.md),
            _buildCompletionFunnel(ref),
            const SizedBox(height: AppSpacing.xl),
            Center(
              child: Text(
                'Based on local data only · private',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xxxl),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: AppTypography.h3.copyWith(color: AppColors.textPrimary),
    );
  }

  Widget _sectionSubtitle(String text) {
    return Text(
      text,
      style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary),
    );
  }

  // ─── Energy Forecast ─────────────────────────────────────

  Widget _buildEnergyForecast(WidgetRef ref) {
    final forecastAsync = ref.watch(insightsEnergyForecastProvider);

    return forecastAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (data) {
        if (!data.hasEnoughData) {
          return _EmptyInsightCard(
            message: 'Log energy for a week to unlock your peak windows.',
            progressLabel: 'Logged check-ins',
            progressValue: (data.totalCount / 7.0).clamp(0.0, 1.0),
          );
        }

        final peaks = data.peaks;
        return Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.background2,
            borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
            border: Border.all(
              color: AppColors.emerald.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            children: peaks.map((peak) {
              final barWidth = (peak.level / 5.0).clamp(0.0, 1.0);
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Row(
                  children: [
                    SizedBox(
                      width: 100,
                      child: Text(
                        '${peak.start} – ${peak.end}',
                        style: AppTypography.monoSmall.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            peak.label,
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(
                              value: barWidth,
                              minHeight: 6,
                              backgroundColor: AppColors.background0,
                              valueColor:
                                  AlwaysStoppedAnimation(AppColors.emerald),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Text(
                      peak.level.toStringAsFixed(1),
                      style: AppTypography.monoSmall.copyWith(
                        color: AppColors.emerald,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  // ─── Day of Week Chart ────────────────────────────────────

  Widget _buildDayOfWeekChart(WidgetRef ref) {
    final scoresAsync = ref.watch(insightsWeekdayScoresProvider);
    final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return scoresAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (data) {
        if (!data.hasEnoughData) {
          return _EmptyInsightCard(
            message: 'Keep using FlowOS for a week to see weekday patterns.',
            progressLabel: 'Scored active days',
            progressValue: (data.activeDaysCount / 7.0).clamp(0.0, 1.0),
          );
        }

        final scores = data.scores;
        return Container(
          height: 200,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.background2,
            borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
          ),
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: 100,
              minY: 0,
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => AppColors.background0,
                  getTooltipItem: (group, gi, rod, ri) {
                    return BarTooltipItem(
                      '${rod.toY.round()}',
                      AppTypography.monoSmall.copyWith(
                        color: AppColors.emerald,
                        fontSize: 12,
                      ),
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final i = value.toInt();
                      if (i < 0 || i >= days.length) return const Text('');
                      return Text(
                        days[i],
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textTertiary,
                        ),
                      );
                    },
                  ),
                ),
              ),
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              barGroups: List.generate(scores.length, (i) {
                return BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: scores[i].toDouble(),
                      color: AppColors.emerald.withValues(
                        alpha: 0.4 + (scores[i] / 100 * 0.6),
                      ),
                      width: 20,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(4),
                        topRight: Radius.circular(4),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        );
      },
    );
  }

  // ─── Hourly Heatmap ──────────────────────────────────────

  Widget _buildHourlyHeatmap(WidgetRef ref) {
    final heatmapAsync = ref.watch(insightsHourlyHeatmapProvider);

    return heatmapAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (data) {
        if (!data.hasEnoughData) {
          return _EmptyInsightCard(
            message: 'Complete more focus sessions to map your best hours.',
            progressLabel: 'Focus sessions',
            progressValue: (data.completedSessionsCount / 10.0).clamp(0.0, 1.0),
          );
        }

        final hourlyScores = data.hourlyScores;
        return Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.background2,
            borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
          ),
          child: Column(
            children: [
              Wrap(
                spacing: 3,
                runSpacing: 3,
                children: List.generate(18, (i) {
                  final hour = i + 6;
                  final score = hourlyScores[hour];
                  final opacity = (score / 100).clamp(0.05, 1.0);
                  return Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: score > 0
                          ? AppColors.emerald.withValues(alpha: opacity)
                          : AppColors.background0,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Center(
                      child: Text(
                        '${hour > 12 ? hour - 12 : hour}${hour >= 12 ? 'p' : 'a'}',
                        style: AppTypography.caption.copyWith(
                          color: score > 50
                              ? AppColors.textInverse
                              : AppColors.textTertiary,
                          fontSize: 9,
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _legendDot(AppColors.background0, 'Low'),
                  const SizedBox(width: AppSpacing.lg),
                  _legendDot(AppColors.emerald.withValues(alpha: 0.4), 'Medium'),
                  const SizedBox(width: AppSpacing.lg),
                  _legendDot(AppColors.emerald, 'Peak'),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTypography.caption.copyWith(
            color: AppColors.textTertiary,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  // ─── Scroll vs Focus ──────────────────────────────────────

  Widget _buildScrollVsFocusChart(WidgetRef ref) {
    final scrollVsFocusAsync = ref.watch(insightsScrollVsFocusProvider);

    return scrollVsFocusAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (data) {
        if (!data.hasEnoughData) {
          return _EmptyInsightCard(
            message: 'Log focus or scroll to see attention trends.',
            progressLabel: 'Days tracked',
            progressValue: 0.0,
          );
        }

        final focusData = data.focusData;
        final scrollData = data.scrollData;

        // Find max value dynamically to scale chart properly
        double maxFocus = focusData.isEmpty ? 0 : focusData.reduce((a, b) => a > b ? a : b).toDouble();
        double maxScroll = scrollData.isEmpty ? 0 : scrollData.reduce((a, b) => a > b ? a : b).toDouble();
        double absoluteMax = maxFocus > maxScroll ? maxFocus : maxScroll;
        if (absoluteMax < 60) absoluteMax = 60;

        return Container(
          height: 200,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.background2,
            borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
          ),
          child: LineChart(
            LineChartData(
              minY: 0,
              maxY: absoluteMax + 10,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: AppColors.textTertiary.withValues(alpha: 0.1),
                  strokeWidth: 1,
                ),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                      final i = value.toInt();
                      if (i < 0 || i >= days.length) return const Text('');
                      return Text(
                        days[i],
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textTertiary,
                        ),
                      );
                    },
                  ),
                ),
              ),
              lineBarsData: [
                // Focus line
                LineChartBarData(
                  spots: List.generate(focusData.length,
                      (i) => FlSpot(i.toDouble(), focusData[i].toDouble())),
                  isCurved: true,
                  color: AppColors.emerald,
                  barWidth: 2,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    color: AppColors.emerald.withValues(alpha: 0.08),
                  ),
                ),
                // Scroll line
                LineChartBarData(
                  spots: List.generate(scrollData.length,
                      (i) => FlSpot(i.toDouble(), scrollData[i].toDouble())),
                  isCurved: true,
                  color: AppColors.dangerCoral,
                  barWidth: 2,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    color: AppColors.dangerCoral.withValues(alpha: 0.08),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─── Completion Funnel ────────────────────────────────────

  Widget _buildCompletionFunnel(WidgetRef ref) {
    final funnelAsync = ref.watch(insightsCompletionFunnelProvider);

    return funnelAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (data) {
        final stages = [
          (label: 'Created', count: data.created, color: AppColors.textTertiary),
          (label: 'Started', count: data.started, color: AppColors.focusBlue),
          (label: 'Completed', count: data.completed, color: AppColors.emerald),
        ];
        final maxCount = stages.first.count;

        return Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.background2,
            borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
          ),
          child: Column(
            children: stages.map((stage) {
              final ratio = maxCount > 0 ? stage.count / maxCount : 0.0;
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Row(
                  children: [
                    SizedBox(
                      width: 80,
                      child: Text(
                        stage.label,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: ratio,
                          minHeight: 20,
                          backgroundColor: AppColors.background0,
                          valueColor: AlwaysStoppedAnimation(stage.color),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Text(
                      '${stage.count}',
                      style: AppTypography.monoSmall.copyWith(
                        color: stage.color,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

class _EmptyInsightCard extends StatelessWidget {
  const _EmptyInsightCard({
    required this.message,
    required this.progressLabel,
    required this.progressValue,
  });

  final String message;
  final String progressLabel;
  final double progressValue;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.background2,
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.03),
          width: 0.5,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: AppSpacing.sm),
          const Text(
            '📊',
            style: TextStyle(fontSize: 32),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTypography.body.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (progressValue > 0.0) ...[
            const SizedBox(height: AppSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  progressLabel,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
                Text(
                  '${(progressValue * 100).round()}%',
                  style: AppTypography.monoSmall.copyWith(
                    color: AppColors.emerald,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progressValue,
                minHeight: 4,
                backgroundColor: AppColors.background0,
                valueColor: AlwaysStoppedAnimation(AppColors.emerald),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }
}
