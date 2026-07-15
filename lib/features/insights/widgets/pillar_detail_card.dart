import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../features/xp/models/daily_score_calculator.dart';
import 'score_ring_widget.dart';

class PillarDetailCard extends StatelessWidget {
  final ScorePillar pillar;
  final DailyScoreResult result;

  const PillarDetailCard({
    super.key,
    required this.pillar,
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    final String title;
    final String scoreText;
    final List<Widget> details;
    final Color color;

    switch (pillar) {
      case ScorePillar.focus:
        title = 'Focus';
        color = AppColors.focusBlue;
        // Focus max contribution is 35 points
        scoreText = '${result.focusPoints.toStringAsFixed(1)} / 35.0';
        final focusMins = (result.focusPoints / 0.35).round();
        details = [
          _buildDetailRow('Focused today', '$focusMins min'),
          _buildDetailRow('Target guideline', '180+ min for full points'),
          _buildDetailRow('Formula', 'Calculated using actual completed focus session minutes.'),
        ];
        break;
      case ScorePillar.intent:
        title = 'Intent';
        color = AppColors.emerald;
        // Intent max contribution is 25 points
        scoreText = '${result.intentPoints.toStringAsFixed(1)} / 25.0';
        // Calculate MIT and intention status back from weights
        // intentPoints = (mitScore * 0.8 + intentionScore * 0.2) * 0.25
        // We know intentionCompleted is set, we can present it.
        details = [
          _buildDetailRow('MITs Weight', '80% of Intent (20 pts max)'),
          _buildDetailRow('Morning Intention Weight', '20% of Intent (5 pts max)'),
          _buildDetailRow('Structure', 'Intent tracks planning MITs and committing to a daily focus rhythm.'),
        ];
        break;
      case ScorePillar.attention:
        title = 'Attention';
        color = AppColors.warningAmber;
        // Attention max contribution is 25 points
        if (result.isIncomplete || result.attentionPoints == null) {
          scoreText = 'Omitted (0.0 / 0.0)';
          details = [
            _buildDetailRow('Status', 'Unavailable'),
            _buildDetailRow('Why?', 'Usage Access is disconnected, or coverage is partial. Attention points are normalized out.'),
          ];
        } else {
          scoreText = '${result.attentionPoints!.toStringAsFixed(1)} / 25.0';
          details = [
            _buildDetailRow('Distracting apps', 'Selected watchlist usage'),
            _buildDetailRow('Budget limit', 'Evaluated against scroll budget limit'),
            _buildDetailRow('Structure', 'Fewer distracting minutes = higher score.'),
          ];
        }
        break;
      case ScorePillar.care:
        title = 'Care';
        color = AppColors.recoveryTeal;
        // Care max contribution is 15 points
        scoreText = '${result.carePoints.toStringAsFixed(1)} / 15.0';
        details = [
          _buildDetailRow('Recovery Reset Actions', 'Tending soil after scrolling (1/3 weight)'),
          _buildDetailRow('Energy Logs', '3x daily logs completed (1/3 weight)'),
          _buildDetailRow('Shutdown Ritual', 'Completing daily reflection (1/3 weight)'),
        ];
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.background2,
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: AppTypography.monoSmall.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                scoreText,
                style: AppTypography.monoSmall.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          Divider(height: AppSpacing.lg, color: AppColors.background1),
          ...details,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Text(
            value,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.end,
          ),
        ],
      ),
    );
  }
}
