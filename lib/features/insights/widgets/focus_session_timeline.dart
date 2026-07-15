import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../data/local/database/app_database.dart';

class FocusSessionTimeline extends StatelessWidget {
  final List<FocusSession> sessions;

  const FocusSessionTimeline({
    super.key,
    required this.sessions,
  });

  @override
  Widget build(BuildContext context) {
    // Filter completed focus sessions with non-zero duration
    final completedSessions = sessions
        .where((s) => s.completedAt != null && s.actualMinutes > 0)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Focus Timeline',
                style: AppTypography.monoSmall.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${completedSessions.length} block${completedSessions.length == 1 ? '' : 's'} today',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (completedSessions.isEmpty) ...[
          Container(
            width: double.infinity,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.background2,
              borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
            ),
            child: Center(
              child: Text(
                'No focus sessions recorded today.',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
            ),
          ),
        ] else ...[
          LayoutBuilder(
            builder: (context, constraints) {
              final totalWidth = constraints.maxWidth;
              return Column(
                children: [
                  // The timeline bar
                  Container(
                    height: 24,
                    width: totalWidth,
                    decoration: BoxDecoration(
                      color: AppColors.background2,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Stack(
                      children: completedSessions.map((session) {
                        final started = session.startedAt;
                        final completed = session.completedAt!;

                        final startMin = started.hour * 60 + started.minute;
                        final endMin = completed.hour * 60 + completed.minute;
                        
                        final startFrac = startMin / 1440.0;
                        final endFrac = endMin / 1440.0;
                        final widthFrac = (endFrac - startFrac).clamp(0.015, 1.0); // min width to make it visible

                        final left = startFrac * totalWidth;
                        final width = widthFrac * totalWidth;

                        final isDeepWork = session.sessionType == 'deepWork';
                        final color = isDeepWork ? AppColors.focusBlue : AppColors.emerald;

                        return Positioned(
                          left: left,
                          width: width,
                          top: 2,
                          bottom: 2,
                          child: GestureDetector(
                            onTap: () {
                              final timeFormat = DateFormat('jm');
                              final title = session.taskId != null ? 'Focus task block' : 'Standalone block';
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    '$title: ${timeFormat.format(started)} - ${timeFormat.format(completed)} (${session.actualMinutes} min)',
                                  ),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  // Time labels (12 AM, 6 AM, 12 PM, 6 PM)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _timeLabel('12 AM'),
                      _timeLabel('6 AM'),
                      _timeLabel('12 PM'),
                      _timeLabel('6 PM'),
                      _timeLabel('12 AM'),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ],
    );
  }

  Widget _timeLabel(String text) {
    return Text(
      text,
      style: AppTypography.monoSmall.copyWith(
        fontSize: 10,
        color: AppColors.textTertiary,
      ),
    );
  }
}
