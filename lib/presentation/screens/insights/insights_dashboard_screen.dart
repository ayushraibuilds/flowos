import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

/// Insights Dashboard — data visualization for productivity patterns.
///
/// Charts:
/// - Time-of-day focus quality heatmap
/// - Day-of-week productivity bar chart
/// - Scroll vs Focus weekly trend
/// - Energy vs Output correlation
/// - Energy Forecast (predicted peak windows)
class InsightsDashboardScreen extends ConsumerWidget {
  const InsightsDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

            // ─── Energy Forecast ───────────────────────────
            _sectionTitle('⚡ Energy Forecast'),
            _sectionSubtitle('Your predicted peak windows today'),
            const SizedBox(height: AppSpacing.md),
            _buildEnergyForecast(),
            const SizedBox(height: AppSpacing.xxl),

            // ─── Day of Week ───────────────────────────────
            _sectionTitle('📊 Daily Score by Weekday'),
            _sectionSubtitle('Average score for each day'),
            const SizedBox(height: AppSpacing.md),
            _buildDayOfWeekChart(),
            const SizedBox(height: AppSpacing.xxl),

            // ─── Focus Quality Heatmap ─────────────────────
            _sectionTitle('🔥 Focus Quality by Hour'),
            _sectionSubtitle('When you do your best work'),
            const SizedBox(height: AppSpacing.md),
            _buildHourlyHeatmap(),
            const SizedBox(height: AppSpacing.xxl),

            // ─── Scroll vs Focus ───────────────────────────
            _sectionTitle('📱 Scroll vs Focus (7 days)'),
            _sectionSubtitle('Attention allocation trend'),
            const SizedBox(height: AppSpacing.md),
            _buildScrollVsFocusChart(),
            const SizedBox(height: AppSpacing.xxl),

            // ─── Task Completion Funnel ────────────────────
            _sectionTitle('🎯 Task Completion Funnel'),
            _sectionSubtitle('Created → Started → Completed'),
            const SizedBox(height: AppSpacing.md),
            _buildCompletionFunnel(),
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

  Widget _buildEnergyForecast() {
    // Sample data — will be computed from 14+ days of energy check-ins
    final peaks = [
      (start: '9:00', end: '11:30', label: 'Deep Work Window', level: 4.2),
      (start: '14:30', end: '16:00', label: 'Afternoon Focus', level: 3.5),
    ];

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
                              const AlwaysStoppedAnimation(AppColors.emerald),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Text(
                  '${peak.level}',
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
  }

  // ─── Day of Week Chart ────────────────────────────────────

  Widget _buildDayOfWeekChart() {
    // Placeholder data
    final scores = [65, 72, 80, 55, 78, 82, 70]; // Mon–Sun
    final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

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
  }

  // ─── Hourly Heatmap ──────────────────────────────────────

  Widget _buildHourlyHeatmap() {
    // Quality scores for hours 6 AM – 11 PM (0-100)
    final hourlyScores = [
      0, 0, 0, 0, 0, 0, // 12am-5am
      30, 50, 75, 90, 85, 70, // 6am-11am
      55, 60, 65, 75, 70, 50, // 12pm-5pm
      40, 30, 20, 10, 5, 0, // 6pm-11pm
    ];

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.background2,
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
      ),
      child: Column(
        children: [
          // Hours 6 AM – 11 PM displayed as colored cells
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
          // Legend
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

  Widget _buildScrollVsFocusChart() {
    final focusData = [90, 60, 120, 45, 105, 80, 75]; // minutes
    final scrollData = [20, 35, 15, 45, 10, 25, 30]; // minutes

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
          maxY: 150,
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
  }

  // ─── Completion Funnel ────────────────────────────────────

  Widget _buildCompletionFunnel() {
    final stages = [
      (label: 'Created', count: 42, color: AppColors.textTertiary),
      (label: 'Started', count: 35, color: AppColors.focusBlue),
      (label: 'Completed', count: 28, color: AppColors.emerald),
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
  }
}
