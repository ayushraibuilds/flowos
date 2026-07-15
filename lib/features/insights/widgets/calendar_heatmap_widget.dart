import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../services/history_aggregator.dart';

class CalendarHeatmapWidget extends StatelessWidget {
  final DateTime monthStart;
  final List<DailyMetric> metrics;
  final Function(DailyMetric)? onDayTapped;

  const CalendarHeatmapWidget({
    super.key,
    required this.monthStart,
    required this.metrics,
    this.onDayTapped,
  });

  @override
  Widget build(BuildContext context) {
    final startOfThisMonth = DateTime(monthStart.year, monthStart.month, 1);
    
    // Find weekday of 1st day of month (1 = Mon, 7 = Sun)
    final firstWeekday = startOfThisMonth.weekday;
    final leadingPaddingCells = firstWeekday - 1; // days to pad before the 1st
    
    // Find total days in the month
    final nextMonth = DateTime(startOfThisMonth.year, startOfThisMonth.month + 1, 1);
    final daysInMonth = nextMonth.subtract(const Duration(days: 1)).day;
    
    final totalCells = leadingPaddingCells + daysInMonth;
    final rowCount = (totalCells / 7.0).ceil();

    final List<String> weekdays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Month Title
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: Text(
            DateFormat('MMMM yyyy').format(startOfThisMonth),
            style: AppTypography.monoSmall.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        // Weekday labels
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: weekdays.map((day) {
            return SizedBox(
              width: 32,
              child: Center(
                child: Text(
                  day,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textTertiary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: AppSpacing.sm),
        // 6-row dynamic grid
        Column(
          children: List.generate(rowCount, (rowIndex) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(7, (colIndex) {
                  final cellIndex = rowIndex * 7 + colIndex;
                  final dayNumber = cellIndex - leadingPaddingCells + 1;
                  
                  if (cellIndex < leadingPaddingCells || dayNumber > daysInMonth) {
                    // Empty spacer
                    return const SizedBox(width: 32, height: 32);
                  }

                  final cellDate = DateTime(startOfThisMonth.year, startOfThisMonth.month, dayNumber);
                  
                  // Look up metric
                  DailyMetric? dayMetric;
                  for (final m in metrics) {
                    if (m.date.year == cellDate.year &&
                        m.date.month == cellDate.month &&
                        m.date.day == cellDate.day) {
                      dayMetric = m;
                      break;
                    }
                  }

                  return _buildHeatmapCell(context, cellDate, dayMetric);
                }),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildHeatmapCell(BuildContext context, DateTime date, DailyMetric? metric) {
    final bool hasData = metric != null;
    final bool incomplete = metric == null || metric.isIncomplete;
    final int score = metric?.score ?? 0;

    // Map color based on score if complete V2 score
    final Color cellColor;
    if (incomplete || !hasData) {
      cellColor = AppColors.background2; // gray for incomplete/no data
    } else {
      // Complete V2 score gradient mapping
      if (score >= 90) {
        cellColor = AppColors.emerald;
      } else if (score >= 75) {
        cellColor = AppColors.emerald.withValues(alpha: 0.75);
      } else if (score >= 50) {
        cellColor = AppColors.emerald.withValues(alpha: 0.50);
      } else if (score >= 25) {
        cellColor = AppColors.emerald.withValues(alpha: 0.25);
      } else {
        cellColor = AppColors.emerald.withValues(alpha: 0.10);
      }
    }

    final bool isToday = date.year == DateTime.now().year &&
        date.month == DateTime.now().month &&
        date.day == DateTime.now().day;

    return GestureDetector(
      onTap: () {
        if (metric != null && onDayTapped != null) {
          onDayTapped!(metric);
        } else {
          // Fallback toast or tooltip
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${DateFormat('MMM d').format(date)}: ' + 
                (metric == null ? 'No data' : (metric.isIncomplete ? 'Incomplete score (${metric.score})' : 'Score: ${metric.score}')),
              ),
              duration: const Duration(seconds: 1),
            ),
          );
        }
      },
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: cellColor,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isToday 
                ? AppColors.emerald 
                : (isToday && incomplete ? AppColors.warningAmber : Colors.transparent),
            width: isToday ? 1.5 : 0,
          ),
        ),
        child: Center(
          child: Text(
            '${date.day}',
            style: TextStyle(
              fontSize: 11,
              fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
              color: (incomplete || !hasData) 
                  ? AppColors.textSecondary 
                  : (score >= 50 ? AppColors.textInverse : AppColors.textPrimary),
            ),
          ),
        ),
      ),
    );
  }
}
